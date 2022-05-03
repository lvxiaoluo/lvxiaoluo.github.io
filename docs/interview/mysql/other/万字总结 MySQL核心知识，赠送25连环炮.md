# 万字总结 MySQL核心知识，赠送25连环炮

原创 田维常 [Java后端技术全栈](javascript:void(0);) *2021-04-09 17:18*

收录于合集

\#面试连环炮20个

\#面试大合集62个

**关注\**“\******Java后端技术全栈****”**

**回复“000”获取大量电子书**

本文总结了MySQL的核心知识点，然后结合20个连环炮，可以帮助大家学习MySQL、快速复习MySQL有所帮助。

MySQL的20个连环炮，如下：

1、数据库的三范式是什么?

2、DDL、DML、DCL、TCL分表代码什么含义？

3、熟悉MySQL的整体架构吗？

4、说说存储引擎 Inno DB和MyISAM的区别

5、熟悉哪些日志文件？

6、熟悉慢查询吗？

7、MySQL优化手段有哪些？

8、什么是事务？

9、事务的四大特性是什么？

10、说说Mysql的四种隔离级别

11、MySQL默认隔离级别是哪个？

12、知道MySQL中哪些锁？

13、并发读写容易带来什么问题？

14、说说你对MySQL中MVCC的认识

15、是如何解决幻读的？

15、索引是什么？

17、MySQL索引数据结构有哪几种？

18、有哪些类型的索引呢？

19、Hash和BTree作为MySQL索引，说说你对此有什么想法？

20、索引优化有哪些方式？

21、哪些场景建议创建索引？

22、哪些场景不建议使用索引？

23、用过explain吗？怎么用的？

24、熟悉MySQL锁优化吗？

25、熟悉哪些MySQL调优策略？

MySQL知识点

![图片](https://mmbiz.qpic.cn/mmbiz_png/07BicZywOVtmkFuS2OF98dgx5tyrRObicVvm9hrL5dpFrY4B4C3DEeRQ4BYFM0Swos3b1mWCujNzEBFNGBFZ3ltQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

需要思维导图的，加微信tj20120622，免费获取

## 基础知识

### 范式

#### 第一范式

数据库中的所有字段（列）都是单一属性，不可再分的。 这个单一属性由基本的数据类型所构成，如整型、浮点型、字符串等。第一范式是为了保证列的原子性。

#### 第二范式

数据库中的表不存在非关键字段对任一关键字字段的部分函数依赖  部分函数依赖是指存在着组合关键字中的某一关键字决定非关键字的情况。第二范式在满足了第一范式的基础上，消除非主键列对联合主键的部分依赖

#### 第三范式

所有非主键属性都只和候选键有相关性，也就是说非主键属性之间应该是独立无关的。第三范式是在满足了第二范式的基础上，消除列与列之间的传递依赖。

## SQL语句汇总

### DDL

DDL是数据定义语言（Data Definition Language）的简称，  它处理数据库schemas和描述数据应如何驻留在数据库中。

CREATE：创建数据库及其对象（如表，索引，视图，存储过程，函数和触发器）  ALTER：改变现有数据库的结构  DROP：从数据库中删除对象  TRUNCATE：从表中删除所有记录，包括为记录分配的所有空间都将被删除  COMMENT：添加注释  RENAME：重命名对象

### DML

DML是数据操纵语言（Data Manipulation Language）的简称，  包括最常见的SQL语句

SELECT、INSERT、UPDATE、DELETE、GROUP BY、HAVING

### DCL

DCL是数据控制语言（Data Control Language）的简称，  它包含诸如GRANT之类的命令，并且主要涉及数据库系统的权限，权限和其他控件。

GRANT ：允许用户访问数据库的权限  REVOKE：撤消用户使用GRANT命令赋予的访问权限

### TCL

TCL是事务控制语言（Transaction Control Language）的简称，  用于处理数据库中的事务

COMMIT：提交事务  ROLLBACK：在发生任何错误的情况下回滚事务

## 架构介绍

![图片](https://mmbiz.qpic.cn/mmbiz_png/07BicZywOVtmkFuS2OF98dgx5tyrRObicVka9ibZ2ZT54Ohm69eibdYnIdiaeuViaggZy5zabPiauv5TqtDA2L71XDExQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)



连接层：负责处理客户端的连接以及权限的认证。

服务层：定义有许多不同的模块，包括权限判断，SQL接口，SQL解析，SQL分析优化， 缓存查询的处理以及部分内置函数执行等。MySQL的查询语句在服务层内进行解析、优化、缓存以及内置函数的实现和存储。

引擎层：负责MySQL中数据的存储和提取。MySQL中的服务器层不管理事务，事务是由存储引擎实现的。其中使用最为广泛的存储引擎为InnoDB，其它的引擎都不支持事务。

存储层：负责将数据存储于设备的文件系统中。

## 存储引擎

### 查看命令

```
show engines; 
show variables like '%storage_engine%'
```

### Inno DB和MyISAM对比

Mysql5.5 版本之前默认的存储引擎就是 MyISAM 存储引擎，MySQL 中比较多的系统表使用 MyISAM 存储引擎，系统临时表也会用到 MyISAM 存储引擎，但是在 Mysql5.5 之后默认的存储引擎就是 InnoDB 存储引擎了。原因主要是 MyISAM 是表级锁定，限制了数据库读/写的性能；另外一个原因 MyISAM 不支持事务，基于以上两点，InnoDB 引擎使用的非常广泛。

| 对比          | InnoDB                         | MyISAM                                        |
| :------------ | :----------------------------- | :-------------------------------------------- |
| 文件存储方式  | .frm 表定义文件；.ibd 数据文件 | .frm 表定义文件；.myd 数据文件；.myi 索引文件 |
| 索引方式      | B+ Tree                        | B+ Tree                                       |
| count(*) 操作 | 全表扫描                       | 无需扫描                                      |
| 锁机制        | 表锁、 行锁                    | 表锁                                          |
| 事务          | 支撑事务的 ACID                | 不支持事务                                    |
| 常用场景      | 读写操作                       | 读多写少操作，比如配置表                      |

### 常见存储引擎介绍

#### Inno DB

MySQL的默认事务型引擎、它被用来处理大量短期事务。 除非有非常特别的原因需要使用其他的存储引擎，否则建议优先考虑Inno DB引擎。

#### MyISAM

提供了大量的特性，包含全文索引，压缩，空间行数等，  但不支持事务和行级锁，有个缺陷就是崩溃后无法恢复

#### Memory

Memory存储引擎使用存在内存中的内容来创建表。每个 Memory表实际只对应一个磁盘文件，格式是 .frm。Memory类型的表访问速度很快，因为其数据是存放在内存中。默认使用 HASH 索引。

#### Merge

Merge存储引擎是一组 MyISAM 表的组合，Merge表本身没有数据，对 Merge类型的表进行查询、更新、删除的操作，  实际上是对内部的 MyISAM 表进行的。Merge表在磁盘上保留两个文件，一个是`.frm`文件存储表定义、  一个是 `.MRG`文件存储 Merge表的组成等。

### 如何选择存储引擎

MyISAM：如果应用程序通常以检索为主，只有少量的插入、更新和删除操作，并且对事物的完整性、  并发程度不是很高的话，通常建议选择 MyISAM 存储引擎。

InnoDB：如果使用到外键、需要并发程度较高，数据一致性要求较高，那么通常选择 InnoDB 引擎，  一般互联网大厂对并发和数据完整性要求较高，所以一般都使用 InnoDB 存储引擎。

MEMORY：MEMORY 存储引擎将所有数据保存在内存中，在需要快速定位下能够提供及其迅速的访问。MEMORY 通常用于更新不太频繁的小表，用于快速访问取得结果。

MERGE：MERGE 的内部是使用 MyISAM 表，MERGE 表的优点在于可以突破对单个 MyISAM 表大小的限制，  并且通过将不同的表分布在多个磁盘上， 可以有效地改善 MERGE 表的访问效率。

## 日志文件

MySQL中有八种日志文件，分别是：

- 重做日志（redo log）
- 回滚日志（undo log）
- 二进制日志（binlog）
- 错误日志（errorlog）
- 慢查询日志（slow query log）
- 一般查询日志（general log）
- 中继日志（relay log）
- DDL日志 （metadata log）

他们分别都有各自的作用，而且默认情况下，服务器的日志文件都位于数据目录（datadir）中。

### 常见日志介绍

#### 重做日志（redo log）

确保事务的持久性。防止在发生故障的时间点，尚有脏页未写入磁盘，在重启mysql服务的时候，根据redo log进行重做，从而达到事务的持久性这一特性。

事务开始之后就产生redo log，redo log的落盘并不是随着事务的提交才写入的，而是在事务的执行过程中，便开始写入redo log文件中。

对应的物理文件：

默认情况下，对应的物理文件位于数据库的data目录下的ib_logfile1&ib_logfile2

- innodb_log_group_home_dir 指定日志文件组所在的路径，默认./ ，表示在数据库的数据目录下。
- innodb_log_files_in_group 指定重做日志文件组中文件的数量，默认2

关于文件的大小和数量，由以下两个参数配置：

- innodb_log_file_size 重做日志文件的大小。
- innodb_mirrored_log_groups 指定了日志镜像文件组的数量，默认1

#### 回滚日志（undo log）

保存了事务发生之前的数据的一个版本，可以用于回滚，同时可以提供多版本并发控制下的读（MVCC），也即非锁定读 。undo日志是逻辑格式的日志，在执行undo的时候，仅仅是将数据从逻辑上恢复至事务之前的状态，而不是从物理页面上操作实现的，这一点是不同于redo log的。

关于MySQL5.7之后的独立undo 表空间配置参数如下：

- innodb_undo_directory = /data/undospace/ –undo独立表空间的存放目录
- innodb_undo_logs = 128 –回滚段为128KB
- innodb_undo_tablespaces = 4 –指定有4个undo log文件

#### 二进制日志（binlog）

用于复制，在主从复制中，从库利用主库上的binlog进行重播，实现主从同步。用于数据库的基于时间点的还原。

内容是以逻辑格式的日志，可以简单认为就是执行过的事务中的sql语句。

但又不完全是sql语句这么简单，而是包括了执行的sql语句（增删改）反向的信息，也就意味着delete对应着delete本身和其反向的insert；update对应着update执行前后的版本的信息；insert对应着delete和insert本身的信息。

在使用mysqlbinlog解析binlog之后一些都会真相大白。

因此可以基于binlog做到类似于oracle的闪回功能，其实都是依赖于binlog中的日志记录。

对应的物理文件：

配置文件的路径为log_bin_basename，binlog日志文件按照指定大小，当日志文件达到指定的最大的大小之后，进行滚动更新，生成新的日志文件。

#### 错误日志（errorlog）

MySQL 错误日志（error log）记录了 mysqld 启动和停止的相关信息，同时还记录了服务器在启动、停止以及运行期间发生的诊断消息，例如错误、警告和通知等。例如，当 mysqld 发现某个表需要执行自动检查或修复时，它会向错误日志中写入一条消息。

#### 慢查询日志（slow query log）

见后面的SQL优化部分。

## 性能优化

### 硬件层

#### CPU相关

1、选择Performance Per Watt Optimized(DAPC)模式，发挥CPU最大性能，跑DB这种通常需要高运算量的服务就不要考虑节电了；

2、关闭C1E和C States等选项，目的也是为了提升CPU效率；

3、Memory Frequency（内存频率）选择Maximum Performance（最佳性能）；

4、内存设置菜单中，启用Node Interleaving，避免NUMA问题；

#### 磁盘I/O相关

1、使用SSD或者PCIe SSD设备，至少获得数百倍甚至万倍的IOPS提升；

2、购置阵列卡同时配备CACHE及BBU模块，可明显提升IOPS（主要是指机械盘，SSD或PCIe SSD除外。 同时需要定期检查CACHE及BBU模块的健康状况，确保意外时不至于丢失数据）；

3、有阵列卡时，设置阵列写策略为WB，甚至FORCE WB（若有双电保护，或对数据安全性要求不是特别高的话），  严禁使用WT策略。并且闭阵列预读策略，基本上是鸡肋，用处不大；

4、尽可能选用RAID-10，而非RAID-5；

5、使用机械盘的话，尽可能选择高转速的，例如选用15KRPM，而不是7.2KRPM的盘，不差几个钱的；

### 系统层

#### 文件系统层优化

1、使用deadline/noop这两种I/O调度器，千万别用cfq（它不适合跑DB类服务）；

2、使用xfs文件系统，千万别用ext3；ext4勉强可用，但业务量很大的话，则一定要用xfs；

3、文件系统mount参数中增加：noatime, nodiratime, nobarrier几个选项（nobarrier是xfs文件系统特有的）；

#### 其他内核参数优化

1、将vm.swappiness设置为5-10左右即可，甚至设置为0（RHEL 7以上则慎重设置为0，除非你允许OOM kill发生），以降低使用SWAP的机会；

2、将vm.dirty_background_ratio设置为5-10，将vm.dirty_ratio设置为它的两倍左右，以确保能持续将脏数据刷新到磁盘，避免瞬间I/O写，产生严重等待（和MySQL中的innodb_max_dirty_pages_pct类似）；

3、将net.ipv4.tcp_tw_recycle、net.ipv4.tcp_tw_reuse都设置为1，减少TIME_WAIT，提高TCP效率；

4、至于网传的read_ahead_kb、nr_requests这两个参数，我经过测试后，发现对读写混合为主的OLTP环境影响并不大（应该是对读敏感的场景更有效果），不过没准是我测试方法有问题，可自行斟酌是否调整；

### MySQL层

#### 参数调整

1、选择Percona或MariaDB版本的话，强烈建议启用thread pool特性，可使得在高并发的情况下，性能不会发生大幅下降。此外，还有extra_port功能，非常实用， 关键时刻能救命的。还有另外一个重要特色是 QUERY_RESPONSE_TIME 功能，也能使我们对整体的SQL响应时间分布有直观感受；

2、设置default-storage-engine=InnoDB，也就是默认采用InnoDB引擎，强烈建议不要再使用MyISAM引擎了，InnoDB引擎绝对可以满足99%以上的业务场景；

3、调整innodb_buffer_pool_size大小，如果是单实例且绝大多数是InnoDB引擎表的话，可考虑设置为物理内存的50% ~ 70%左右；

4、根据实际需要设置innodb_flush_log_at_trx_commit、sync_binlog的值。如果要求数据不能丢失，那么两个都设为1。如果允许丢失一点数据，则可分别设为2和10。而如果完全不用care数据是否丢失的话（例如在slave上，反正大不了重做一次），则可都设为0。这三种设置值导致数据库的性能受到影响程度分别是：高、中、低；

5、设置innodb_file_per_table = 1，使用独立表空间，我实在是想不出来用共享表空间有什么好处了；

6、设置innodb_data_file_path = ibdata1:1G:autoextend，千万不要用默认的10M，否则在有高并发事务时，会受到不小的影响；

7、设置innodb_log_file_size=256M，设置innodb_log_files_in_group=2，基本可满足90%以上的场景；

8、设置long_query_time = 1，而在5.5版本以上，已经可以设置为小于1了，建议设置为0.05（50毫秒），记录那些执行较慢的SQL，用于后续的分析排查；

9、根据业务实际需要，适当调整max_connection（最大连接数）、max_connection_error（最大错误数，建议设置为10万以上，而open_files_limit、innodb_open_files、table_open_cache、table_definition_cache这几个参数则可设为约10倍于max_connection的大小；

10、常见的误区是把tmp_table_size和max_heap_table_size设置的比较大，曾经见过设置为1G的，这2个选项是每个连接会话都会分配的，因此不要设置过大，否则容易导致OOM发生；其他的一些连接会话级选项例如：sort_buffer_size、join_buffer_size、read_buffer_size、read_rnd_buffer_size等，也需要注意不能设置过大；

11、由于已经建议不再使用MyISAM引擎了，因此可以把key_buffer_size设置为32M左右，并且强烈建议关闭query cache功能；

#### Schema设计规范及SQL使用建议

1、所有的InnoDB表都设计一个无业务用途的自增列做主键，对于绝大多数场景都是如此，真正纯只读用InnoDB表的并不多，真如此的话还不如用TokuDB来得划算；

2、字段长度满足需求前提下，尽可能选择长度小的。此外，字段属性尽量都加上NOT NULL约束，可一定程度提高性能；

3、尽可能不使用TEXT/BLOB类型，确实需要的话，建议拆分到子表中，不要和主表放在一起，避免SELECT * 的时候读性能太差。

4、读取数据时，只选取所需要的列，不要每次都SELECT *，避免产生严重的随机读问题，尤其是读到一些TEXT/BLOB列；

5、对一个VARCHAR(N)列创建索引时，通常取其50%（甚至更小）左右长度创建前缀索引就足以满足80%以上的查询需求了，没必要创建整列的全长度索引；

6、通常情况下，子查询的性能比较差，建议改造成JOIN写法；

7、多表联接查询时，关联字段类型尽量一致，并且都要有索引；

8、多表连接查询时，把结果集小的表（注意，这里是指过滤后的结果集，不一定是全表数据量小的）作为驱动表；

9、多表联接并且有排序时，排序字段必须是驱动表里的，否则排序列无法用到索引；

10、多用复合索引，少用多个独立索引，尤其是一些基数（Cardinality）太小（比如说，该列的唯一值总数少于255）的列就不要创建独立索引了；

11、类似分页功能的SQL，建议先用主键关联，然后返回结果集，效率会高很多；

#### 其他建议

1、通常地，单表物理大小不超过10GB，单表行数不超过1亿条，行平均长度不超过8KB，如果机器性能足够，这些数据量MySQL是完全能处理的过来的，不用担心性能问题，这么建议主要是考虑ONLINE DDL的代价较高；

2、不用太担心mysqld进程占用太多内存，只要不发生OOM kill和用到大量的SWAP都还好；

3、在以往，单机上跑多实例的目的是能最大化利用计算资源，如果单实例已经能耗尽大部分计算资源的话，就没必要再跑多实例了；

4、定期使用pt-duplicate-key-checker检查并删除重复的索引。定期使用pt-index-usage工具检查并删除使用频率很低的索引；

5、定期采集slow query log，用pt-query-digest工具进行分析，可结合Anemometer系统进行slow query管理以便分析slow query并进行后续优化工作；

6、可使用pt-kill杀掉超长时间的SQL请求，Percona版本中有个选项 innodb_kill_idle_transaction 也可实现该功能；

7、使用pt-online-schema-change来完成大表的ONLINE DDL需求；

8、定期使用pt-table-checksum、pt-table-sync来检查并修复mysql主从复制的数据差异；

## 事务

### 事务

数据库事务(Database Transaction) ，是指作为单个逻辑工作单元执行的一系列操作，要么完整地执行，要么完全地不执行。

经典的银行转账例子: A从银行转账1w块钱给B，此时数据库会涉及2个最基本的操作:

- A银行卡余额减少1w
- B银行卡余额增加1w

那么这2个操作是一个整体，要么一起成功，要么一起失败，不会存在只有部分成功。例如A银行卡余额减少1w，但是B银行卡余额没有增加1w，这就会出大问题了。

### 四大特性

#### 原子性（Atomicity）

原子性是指事务是一个不可分割的工作单位，事务中的操作要么全部成功，要么全部失败

#### 一致性（Consistency）

事务按照预期生效，数据的状态是预期的状态。

#### 隔离性（Isolation）

事务的隔离性是多个用户并发访问数据库时，数据库为每一个用户开启的事务，  不能被其他事务的操作数据所干扰，多个并发事务之间要相互隔离。

#### 持久性（Durability）

持久性是指一个事务一旦被提交，它对数据库中数据的改变就是永久性的，  接下来即使数据库发生故障也不应该对其有任何影响。

### 两个操作

#### 提交（commit）

将事务执行结果写入数据库

#### 回滚（rollback）

回滚所有已执行的语句，返回修改之前的数据

### 锁机制

#### 按照粒度划分

- 行锁
- 页锁
- 表锁

#### 按照使用方式划分

- 共享锁
- 排它锁

#### 按照思想划分

- 悲观锁
- 乐观锁

#### 行锁

- record lock ：单个行记录删搞的锁。
- Grap lock ：间隙锁锁定一个范围，但不包括记录本身。
- Next-key lock：锁定一个范围，包括锁记录本身。

#### 读写锁

- 共享锁Share lock、又叫读锁。
- 排它锁（exclusive lock） 又叫写锁。

通过写锁，可以做到读读并行，但不能做到读写、写写并行。

#### 减少死锁的方式

- 自动死锁检测，优先回滚小事务
- 超时参数设置（innodb*lock*wait_timeout）
- 尽量提交事务，小事务不容易产生死锁
- 加 for update、lock in share mode 读锁时，最好降低事务隔离级别，比如 rc 级别，降低死锁发生概率
- 事务中涉及多个表，或者涉及多行记录时，每个事务的操作顺序都要保持一致，降低死锁概率，最好用存储过程
- 通过索引等方式优化 sql 效率，降低死锁概率（目的是减少扫描 / 锁范围，降低概率）

#### 并发读写带问题

- 脏读
- 不可重复度
- 幻读

##### 脏读(Drity Read)

某个事务已更新一份数据，另一个事务在此时读取了同一份数据，由于某些原因，前一个RollBack了操作，则后一个事务所读取的数据就会是不正确的。

##### 不可重复读(Non-repeatable read)

在一个事务的两次查询之中数据不一致，这可能是两次查询过程中间插入了一个事务更新的原有的数据。

##### 幻读(Phantom Read)

在一个事务的两次查询中数据笔数不一致，例如有一个事务查询了几列(Row)数据，而另一个事务却在此时插入了新的几列数据，先前的事务在接下来的查询中，就有几列数据是未查询出来的，如果此时插入和另外一个事务插入的数据，就会报错。

#### Mysql的四种隔离级别

SQL标准定义了4类隔离级别，包括了一些具体规则，用来限定事务内外的哪些改变是可见的，哪些是不可见的。低级别的隔离级一般支持更高的并发处理，并拥有更低的系统开销。

- 读未提交
- 读已提交
- 可重复度
- 可串行化

##### Read Uncommitted（读取未提交内容）

在该隔离级别，所有事务都可以看到其他未提交事务的执行结果。本隔离级别很少用于实际应用，因为它的性能也不比其他级别好多少。读取未提交的数据，也被称之为脏读（Dirty Read）。

##### Read Committed（读取提交内容）

这是大多数数据库系统的默认隔离级别（但不是MySQL默认的）。它满足了隔离的简单定义：一个事务只能看见已经提交事务所做的改变。这种隔离级别 也支持所谓的不可重复读（Nonrepeatable Read），因为同一事务的其他实例在该实例处理其间可能会有新的commit，所以同一select可能返回不同结果。

##### Repeatable Read（可重读）

这是MySQL的**默认**事务隔离级别，它确保同一事务的多个实例在并发读取数据时，会看到同样的数据行。不过理论上，这会导致另一个棘手的问题：幻读 （Phantom Read）。简单的说，幻读指当用户读取某一范围的数据行时，另一个事务又在该范围内插入了新行，当用户再读取该范围的数据行时，会发现有新的“幻影” 行。InnoDB和Falcon存储引擎通过多版本并发控制（MVCC，Multiversion Concurrency Control）机制解决了该问题。

##### Serializable（可串行化）

这是最高的隔离级别，它通过强制事务排序，使之不可能相互冲突，从而解决幻读问题。简言之，它是在每个读的数据行上加上共享锁。在这个级别，可能导致大量的超时现象和锁竞争。

在MySQL中，实现了这四种隔离级别，分别有可能产生问题如下所示：

![图片](https://mmbiz.qpic.cn/mmbiz_png/07BicZywOVtmkFuS2OF98dgx5tyrRObicVRFicC9udGCkIqH6eOhPP361TGLQmcMYV8U5TOXwnUXv7UicOcnK8yrfA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

### MVCC

#### 定义

MVCC (Multi­ Version Concurrency Control) 是一种基于多版本的并发控制协议，只有在InnoDB引 擎下存在。另外，这里千万别和Spring MVC联想到一起了。

MVCC是为了实现事务的隔离性，通过版本号，避免同一数据在不同事务间的竞争，你 可以把它当成基于多版本号的一种乐观锁。当然，这种乐观锁只在事务级别未提交锁和已提交锁时 才会生效。MVCC最大的好处，相信也是耳熟能详：读不加锁，读写不冲突。在读多写少的OLTP 应用中，读写不冲突是非常重要的，极大的增加了系统的并发性能。

**注意**：MVCC只在 `READ COMMITTED` 和 `REPEATABLE READ```两个隔离级别下工作。其他两个隔离级别不和MVCC不兼容, 因为`READ UNCOMMITTED`总是读取最新的数据行, 而不是符合当前事务版本的数据行。而`SERIALIZABLE` 则会对所有读取的行都加锁。

Mysql默认隔离级别是RR（可重复读），是通过“行锁+MVCC”来实现的，正常读时不加锁，写时加锁，MVCC的实现依赖于：**三个隐藏字段**，**Read View**、**Undo log** 来实现。

#### InnoDB MVCC 实现原理

`InnoDB` 中 `MVCC` 的实现方式为：每一行记录都有两个隐藏列：`DATA_TRX_ID`、`DATA_ROLL_PTR`（如果没有主键，则还会多一个隐藏的主键列）。

1、DB_TRX_ID：6个字节，记录每一行最近修改他的事务ID

2、DB_ROLL_PTR：表示指向该行回滚段`（rollback segment）`的指针，大小为 `7` 个字节，`InnoDB` 便是通过这个指针找到之前版本的数据。该行记录上所有旧版本，在 `undo` 中都通过链表的形式组织。

3、DB_ROW_ID：行标识（隐藏单调自增 ID），大小为 `6` 字节，如果表没有主键，`InnoDB` 会自动生成一个隐藏主键，因此会出现这个列。

#### 快照读和当前读

读快照，可以读取数据的所有版本信息，包括旧版本的信息。其实就是读取MVCC中的read_view，同时结合MVCC进行相对应的控制；

```
select * from table where ?;
```

读当前，读取当前数据的最新版本。而且读取到这个数据之后会对这个数据加锁，防止别的事务更改。（分析：在进行写操作的时候就需要进行“当前读”，读取数据记录的最新版本）

```
select * from table where ? lock in share mode;  # 读锁
select * from table where ? for update;          # 写锁
insert into table values (…); 
update table set ? where ?; 
delete from table where ?;
```

### RC和RR隔离级别下的快照读和当前读：

- RC隔离级别下，快照读和当前读结果一样，都是读取已提交的最新；
- RR隔离级别下，当前读结果是其他事务已经提交的最新结果，快照读是读当前事务之前读到的结果。RR下创建快照读的时机决定了读到的版本。

#### 解决幻读

对于快照读：通过MVCC来进行控制的，不用加锁。按照MVCC中规定的“语法”进行增删改查等操作，以避免幻读。

对于当前读：通过next-key锁（行锁+gap锁）来解决问题的。

## 索引详情

### 索引概念

索引（在MySQL中也叫“键key”）是存储引擎快速找到记录的一种数据结构。

索引一般以文件形式存储在磁盘上，索引检索需要磁盘I/O操作

索引是数据结构，而且是实现了高级查找算法的数据结构

帮助MySQL高效获取数据的数据结构

### 索引分类

- 普通索引
- 唯一所有
- 主键索引
- 复合索引
- 全文索引

### MySQL索引结构

- BTree索引
- Hash索引
- full-text全部问索引
- r-tree索引

在计算机数据结构体系中，为了加速查找的速度，常见的数据结构有两种：

- Hash哈希结构，例如Java中的HashMap，这种数据组织结构可以让查询/插入/修改/删除的平均时间复杂度都为O(1);
- Tree 树 结构 ， 这种数据组织结构可以让查询/插入/修改/删除的平均时间复杂度都为O(log(n));

Hash这种类型比Tree树这种类型都要更快一些，那为什么MySQL的开发者既使用Hash类型作为索引，又使用了BTREE呢？

确实用Hash索引更快，因为每次都只查询一条信息（重名的雇员姓名也才几条而已），但实际上业务对于SQL的应用场景是：

order by 需要排个序、group by 还要分个组还要比较大小 大于或小于等等

这种情况下如果继续用HASH类型做索引结构，其时间复杂度会从O(1)直接退化为O(n)，相当于全表扫描了，而Tree的特性保证了不管是哪种操作，依然能够保持O(log(n))的高效率。

### 索引实操

#### 创建索引

```
CREATE [UNIQUE] INDEX indexName ON mytable(columnname(length));  
ALTER mytable ADD [UNIQUE] INDEX indexName
```

#### 删除索引

drop index 索引名 on 表名

#### 查看索引

show index from 表名

### 索引维护

- 慢查询
- 删除不用的索引
- 查询重复一句冗余索引

### 索引优化

- 使用索引注意点
- 最左前缀法则
- 不要在索引列上做任何操作（计算、函数、（自动或手动）类型转  换），会导致索引失效而转向全表扫描
- 存储引擎不能使用索引中范围条件右边的列
- 尽量使用覆盖索引（只访问索引的查询（索引列包含查询列）），  减少select *语句
- mysql在使用不等于（！=或者<>）的时候无法使用索引会导致全  表扫描
- 字符串不加单引号索引失效

### 哪些场景不要建索引

- 表记录太少
- 经常增删改的字段
- where条件中用不到的字段
- 区分度不够的（性别）

### 哪些场景下可建索引

- 主键自动建议唯一索引
- 频繁作为查询字段可以考虑建索引
- 查询中与其他表关联的字段、外键建立索引
- 查询中统计或分组字段
- 查询中排序的字段，排序后通过索引去访问将大大提升排序性能

## SQL优化

### explain查询优化器详解

模拟优化器执行SQL语句，从而知道MySQL是 如何处理你的SQL语句的，分析  你的查询语句或者表结构的性能瓶颈。

#### 使用方式

在 select 语句之前增加 explain 关键字，MySQL 会在查询上设置一个标记，  执行查询时，会返回执行计划的信息，而不是执行这条SQL。

```
explain select * from user where id = 1001;
--为了方便查看，可以在语句后面加一个\G，表示按字段顺序展开
explain select * from user where id = 1001 \G
```

#### 作用

- 表的读取顺序
- 数据读取操作的操作类型
- 哪些索引可以使用
- 哪些索引被实际使用
- 表之间的引用
- 每张表有多少行被优化器查询

#### explain变种

##### explain extended

会在 explain 的基础上额外提供一些查询优化的信息。 紧随其后通过 show warnings 命令可以 得到优  化后的查询语句，从而看出优化器优化了什么

##### explain partitions

相比 explain 多了个 partitions 字段，  如果查询是基于分区表的话，会显示查询将访问的分区。

### explain 结果列详情

#### id

id列的编号是 select 的序列号，有几个 select 就有几个id，并且id的顺序是按 select 出现的顺序增长  的。

id列越大执行优先级越高，id相同则从上往下执行，id为NULL最后执行。

#### select_type

SIMPLE：简单查询。查询不包含子查询和union

PRIMARY：最外层SELECT

UNION：第二层，在SELECT之后使用了UNION。

DEPENDENT UNION：UNION语句中的第二个SELECT，依赖于外部子查询。

UNION RESULT：UNION的结果

SUBQUERY：子查询中的第一个SELECT。

DEPENDENT SUBQUERY：子查询中的第一个SELECT，取决于外面的查询。

DERIVED ：导出表的SELECT（FROM子句的子查询）

MATERIALIZED：物化子查询

UNCACHEABLE SUBQUERY：无法缓存结果的子查询，必须为外部查询的每一行重新计算

UNCACHEABLE UNION  ：UNION 属于不可缓存的子查询的第二个或后一个选择

#### table

##### union

``：该行指的是id值为M和id值为N的并集。

##### derived

``：该行是指用于与该行的派生表结果id的值 N。 例如，派生表可以来自FROM子句

##### subquery

``：该行指的是id 值为的行的具体化子查询的结果N

#### type

##### NULL

MySQL在优化过程中分解语句，执行时甚至不用访问表或索引，  例如从一个索引列里选取最小值可以通过单独索引查找完成。

##### system

该表只有一行（如：系统表）。这是const连接类型的特例

##### const

该表最多只有一个匹配行，在查询开头读取。因为只有一行，  所以优化器的其余部分可以将此行中列的值视为常量。 const表非常快，因为它们只读一次。SELECT * FROM tbl_name WHERE primary_key=1;

##### eq_ref

除了 system和 const类型之外，这是最好的连接类型。 当连接使用索引的所有部分且索引是 索引PRIMARY KEY或UNIQUE NOT NULL索引时使用它。

##### ref

表示上述表的连接匹配条件，即哪些列或常量被用于查找索引列上的值

##### fulltext

使用FULLTEXT 索引执行连接。

##### ref_or_null

该联接类型如同ref，但是添加了MySQL可以专门搜索包含NULL值的行。SELECT * FROM ref_table WHERE key_column IS NULL;

##### index_merge

该指数合并访问方法检索与多行 range扫描和他们的结果合并到一个。 此访问方法仅合并来自单个表的索引扫描，而不扫描多个表。

##### unique_subquery

该类型替换了下面形式的IN子查询的 ref：value IN (SELECT primary_key FROM single_table WHERE some_expr) unique_subquery是一个索引查找函数，  可以完全替换子查询，效率更高。【不常用】

##### index_subquery

该联接类型类似于unique_subquery。可以替换IN子查询，但只适合下列形式的子查询中的非唯一索引：value IN (SELECT key_column FROM single_table WHERE some_expr)。【不常用】

##### range

只检索给定范围的行，使用一个索引来选择行。

##### index

该联接类型与ALL相同，Full Index Scan，index与ALL区别为index类型只遍历索引树。 这通常比ALL快，因为索引文件通常比数据文件小。

##### ALL

Full Table Scan， MySQL将遍历全表以找到匹配的行。

##### 各个类型对比

结果值从好到坏依次是：Null > system > const > eq_ref > ref >  ref_or_null> index_merge > unique_subquery > index_subquery  > range > index > ALL

##### 建议类型

一般来说，得保证查询至少达到range级别，最好能达到ref。

#### possible_keys

表示查询时，可能使用的索引。( MySQL能使用哪个索引在该表中找到行)

#### key

实际使用的索引(键)，必然包含在possible_keys中。如果没有选择索引，索引是NULL。 要想强制MySQL使用或忽视possible_keys列中的索引，  在查询中使用FORCE INDEX、USE INDEX或者IGNORE INDEX。

#### key_len

索引的长度 ( 使用的字节数 )。如果索引是NULL，则长度为NULL。不损失精确性的情况下，长度越短越好 。key_len显示的值为索引字段的最大可能长度，并非实际使用长度，即key_len是根据表定义计算而得，不是通过表内检索出的。

#### ref

使用哪个列或常数，与索引一起被用于从表中查找索引列上的值。 ( 列与索引的比较，表示上述表的连接匹配条件。)  显示索引的哪一列被使用了，如果可能得话，是一个常数。

#### rows

MySQL认为它执行查询时必须检查的行数。( 扫描出的行数 [估算的行数 ]。)

#### filtered

通过表条件过滤出的行数的百分比估计值。

#### Extra

Mysql执行情况的描述和详细说明。信息 Extra 的常用值说明：

Using filesort：使用了文件进行排序，效率较低

Using index：使用了覆盖索引，效率较高

Using temporary：使用了临时表

Using where：使用了 where 条件

### 慢查询

#### 获取慢查询的方式

在工作中，我们发现慢查询一般有 2 个途径，一个是被动的，一个是主动的。估计大部分人都是被动的在处理慢查询，被动的就是当业务人员反馈某个查询界面响应的时间特别长，你才去处理。主动的就是通过通过分析慢查询日志来主动发现执行效率缓慢的 sql 语句，或者通过 information_schema.processlist 实时查询执行缓慢的 sql。

#### 分析慢查询日志

分析慢查询日志的步骤：

- 通过命令查看数据库是否开启慢查询日志：`show variables like 'slow_query_log';`
- 设置开启慢查询日志：`set global slow_query_log=on;`
- 没有命中索引的查询记入慢查询日志：`set global log_queries_not_using_indexes = on;`
- sql 语句超过多少秒记入慢查询日志：`set global long_query_time=1;`
- 查看慢查询日志保存为准：`show variables like 'slow_query_log_file';`
- 直接打开日志进行查看：`vi + file 路径`
- 慢查询日志工具：`mysqldumpslow -s at -t 15 file 路径`

#### 慢查询日志参数介绍

Time：日志记录时间

User@Host：执行的用户与主机

Query time：查询耗费时间

Lock time：锁表时间

Rows_sent：返回的结果行数

Rows_examined：扫描的记录行数

Set timestamp：sql 语句执行的时间

sql 语句表示执行的具体语句。

#### 分析 information_schema.processlist

```
SELECT id,user,host,DB,command,time,state,info
FROM information_schema.processlist
WHERE TIME>=30;
```

查询当前服务器执行超过 30 秒的 sql，可以通过定时任务周期性的来执行这个 sql，就能找到查询缓慢的 sql 语句。

通过以上两种方式找出查询较慢的 sql，进行优化即可。

### MySQL锁优化

#### 表级锁

对整张表加锁。 开销小，加锁快； 不会出现死锁； 锁定粒度大，发生锁冲突的概率最高，并发度最低。

#### 行级锁

对某行记录加锁。 开销大，加锁慢； 会出现死锁； 锁定粒度最小，发生锁冲突的概率最低，并发度也最高。

#### 页面锁

开销和加锁时间介于表锁和行锁之间； 会出现死锁； 锁定粒度界于表锁和行锁之间，并发度一般。

### MySQL 常用调优策略

![图片](https://mmbiz.qpic.cn/mmbiz_png/07BicZywOVtmkFuS2OF98dgx5tyrRObicVq73ByXLW3q4OFsVPWFTOf8ExZLhIBxlY5zkDlUswK10UwEdwkngYqQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

文章部分图片来源于网络，侵删