# 面试官：你能说出MySQL主从复制的几种复制方式吗？

## 目录

- 异步复制
- 多线程复制
- 增强半同步复制

## 异步复制

MySQL的复制默认是异步的，主从复制至少需要两个MYSQL服务，这些MySQL服务可以分布在不同的服务器上，也可以在同一台服务器上。

MySQL主从异步复制是最常见的复制场景。数据的完整性依赖于主库BINLOG的不丢失，只要主库的BINLOG不丢失，那么就算主库宕机了，我们还可以通过BINLOG把丢失的部分数据通过手工同步到从库上去。

> 注意：主库宕机的情况下，DBA可以通过mysqlbinlog工具手工访问主库binlog，抽取缺失的日志并同步到从库上去；也可以通过配置高可用MHA架构来自动抽取缺失的数据补全从库，或者启用Global Transaction Identifiers（GTID)来自动抽取缺失binlog到从库。

MySQL在BINLOG中记录事务(或SQL语句),也就是说对于支持事务的的引擎(例如InnoDB)来说，每个事务提交时都需要写BINLOG；对于不支持事务的引擎(例如MyISAM)来说，每个SQL语句执行完成时，都需要些BINLOG。为了保证Binlog的安全，MySQL引入sync_binlog参数来控制BINLOG刷新到磁盘的频率。

```
show variables like 'sync_binlog';
```

![图片](https://mmbiz.qpic.cn/mmbiz_png/8KKrHK5ic6XA9ypdfBMw1K6v2bmonL2d5KYN4nz7icJgIgwzBzMaONuNRJG9EcLm6Mh7Ez60JbOAzqPfEaBTeIzQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

- 在默认情况下，sync_binlog=1，表示事务提交之前，MySQL都需要先把BINLOG刷新到磁盘，这样的话，即使出现数据库主机操作系统崩溃或者主机突然掉电的情况，系统最多损失prepared状态的事务；设置sync_binlog=1，尽可能保证数据安全。
- sync_binlog=0,表示MySQL不控制binlog的刷新，由文件系统自己控制文件缓存的刷新。
- sync_binlog=N,如果N不等于0或者1，刷新方式同sync_binlog=1类似，只不过此时会延长刷新频率至N次binlog提交组之后。

以上是传统的异步复制，在MySQL5.7的并行复制技术(也称多线程复制)到来之前，为人诟病最多的还是效率问题，slave延迟是一个顽疾，虽然之前已经出现了schema级别的并行复制，但实际效果并不好。

## 多线程复制

在MySQL5.7中，带来了全新的多线程复制技术，解决了当master同一个schema下的数据发生了变更，从库不能并发应用的问题，同时也真正将binlog组提交的优势充分发挥出来，保障了从库并发应用Relay Log的能力。

在MySQL8.0中，多线程复制又进行了技术更新，引入了writeset的概念，而在之前的版本中，如果主库的同一个会话顺序执行多个不同相关对象的事务，例如，先执行了Update A表的数据，又执行了Update B表的数据，那么BINLOG在复制到从库后，这两个事务是不能并行执行的，writeset的到来，突破了这个限制。

## 增强半同步复制

前面介绍的复制是异步操作，主库和从库的数据之间难免会存在一定的延迟，这样存在一个隐患：当在主库上写入一个事务并提交成功，而从库尚未得到主库的BINLOG日志时，主库由于磁盘损坏、内存故障、断电等原因意外宕机，导致主库上该事务BINLOG丢失，此时从库就会损失这个事务，从而造成主从不一致。

为了解决这个问题，从MySQL5.5开始，引入了半同步复制，此时的技术暂且称之为传统的半同步复制，因该技术发展到MySQL5.7后，已经演变为增强半同步复制(也成为无损复制)。在异步复制时，主库执行Commit提交操作并写入BINLOG日志后即可成功返回客户端，无需等待BINLOG日志传送给从库，如图所示。

![图片](https://mmbiz.qpic.cn/mmbiz_png/8KKrHK5ic6XA9ypdfBMw1K6v2bmonL2d5OKicS8UdjiaAI2jfoxPTicjeDMnrIUw0zoiagas6QOyvEewpgol4U5hkQg/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

而半同步复制时，为了保证主库上的每一个BINLOG事务都能够被可靠地复制到从库上，主库在每次事务成功提交时，并不及时反馈给前端应用用户，而是等待至少一个从库(详见参数rpl_semi_sync_master_wait_for_slave_count)也接收到BINLOG事务并成功写入中继日志后，主库才返回Commit操作成功给客户端(不管是传统的半同步复制，还是增强的半同步复制，目的都是一样的，只不过两种方式有一个席位地方不同，将在下面说明)

半同步复制保证了事务成功提交后，至少有两份日志记录，一份在主库的BINLOG日志上，另一份在至少一个从库的中继日志Relay Log上，从而更进一步保证了数据的完整性。

在传统的半同步复制中，主库写数据到BINLOG，且执行Commit操作后，会一直等待从库的ACK，即从库写入Relay Log后，并将数据落盘，返回给主库消息，通知主库可以返回前端应用操作成功，这样会出现一个问题，就是实际上主库已经将该事务Commit到了事务引擎层，应用已经可以可以看到数据发生了变化，只是在等待返回而已，如果此时主库宕机，有可能从库还没能写入Relay Log，就会发生主从库不一致。

增强半同步复制就是为了解决这个问题，做了微调，即主库写数据到BINLOG后，就开始等待从库的应答ACK，直到至少一个从库写入Relay Log后，并将数据落盘，然后返回给主库消息，通知主库可以执行Commit操作，然后主库开始提交到事务引擎层，应用此时可以看到数据发生了变化。增强半同步复制的大致流程如下图所示。

![图片](https://mmbiz.qpic.cn/mmbiz_png/8KKrHK5ic6XA9ypdfBMw1K6v2bmonL2d5FiaXViaDCaUeictvyOHbiclFlmtgcOqLZyoPyibbJVfIQictZtaXbYQHflog/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

半同步复制模式下，假如在传送BINLOG日志到从库时，从库宕机或者网络延迟，导致BINLOG并没有即使地传送到从库上，此时主库上的事务会等待一段时间(时间长短由参数rpl_semi_sync_master_timeout设置的毫秒数决定)，如果BINLOG在这段时间内都无法成功发送到从库上，则MySQL自动调整复制为异步模式，事务正常返回提交结果给客户端。

半同步复制很大程度上取决于主从库之间的网络情况，往返时延RTT越小决定了从库的实时性越好。通俗地说，主从库之间的网络越快，从库约实时。

注意：往返时延RTT(Round-Trip Time)在计算机网络中是一个重要的性能指标，它表示从发送端发送数据开始到发送端接收到接收端的确认，总共经历的时长(这里可能有点拗口，我们可以理解为TCP三次握手的前两次握手)。

<END>