# Kafka学习---分区与副本原理解析

**一、kafka集群**

kafka集群是由broker组成的。Broker 是 Kafka 的服务节点，即 Kafka 的服务器。其架构图下图：

![img](https://oss-emcsprod-public.modb.pro/image/auto/modb_20240227_d844376c-d538-11ee-8247-fa163eb4f6be.png)

Producer：生产者，也就是发送消息的一方。生产者负责创建消息，然后将其发送到 Kafka。

Consumer：消费者，也就是接受消息的一方。消费者连接到 Kafka 上并接收消息，进而进行相应的业务逻辑处理。

Consumer Group：一个消费者组可以包含一个或多个消费者。使用多分区 + 多消费者方式可以极大提高数据下游的处理速度，同一消费组中的消费者不会重复消费消息，同样的，不同消费组中的消费者消息消息时互不影响。Kafka 就是通过消费组的方式来实现消息 P2P 模式和广播模式。

Broker：服务代理节点。Broker 是 Kafka 的服务节点，即 Kafka 的服务器。

Topic：Kafka 中的消息以 Topic 为单位进行划分，生产者将消息发送到特定的 Topic，而消费者负责订阅 Topic 的消息并进行消费。

Partition：Topic 是一个逻辑的概念，它可以细分为多个分区，每个分区只属于单个主题。同一个主题下不同分区包含的消息是不同的，分区在存储层面可以看作一个可追加的日志（Log）文件，消息在被追加到分区日志文件的时候都会分配一个特定的偏移量（offset）。

Offset：offset 是消息在分区中的唯一标识，Kafka 通过它来保证消息在分区内的顺序性，不过 offset 并不跨越分区，也就是说，Kafka 保证的是分区有序性而不是主题有序性。

Replication：副本，是 Kafka 保证数据高可用的方式，Kafka 同一 Partition 的数据可以在多 Broker 上存在多个副本，通常只有主副本对外提供读写服务，当主副本所在 broker 崩溃或发生网络一场，Kafka 会在 Controller 的管理下会重新选择新的 Leader 副本对外提供读写服务。

Record：实际写入 Kafka 中并可以被读取的消息记录。每个 record 包含了 key、value 和 timestamp。

**1.1、Kakfa Broker Leader的选举**

​     Broker集群受Zookeeper管理。所有的Kafka Broker节点一起去zookeeper上创建/controller临时节点，因为只有一个Kafka Broker会注册成功，其他的都会失败，所以这个成功在Zookeeper上注册临时节点的这个Kafka Broker会成为Kafka Broker Controller，其他的Kafka broker叫Kafka Broker follower。（这个过程叫Controller在ZooKeeper注册Watch）。这个Controller会监听其他的Kafka Broker的所有信息，如果这个kafka broker controller宕机了，在zookeeper上面的那个临时节点就会消失，此时所有的kafka broker又会一起去 Zookeeper上注册一个临时节点，因为只有一个Kafka Broker会注册成功，其他的都会失败，所以这个成功在Zookeeper上注册临时节点的这个Kafka Broker会成为Kafka Broker Controller，其他的Kafka broker叫Kafka Broker follower 。

**二、topic 的分区与副本**

**![img](https://oss-emcsprod-public.modb.pro/image/auto/modb_20240227_d8641730-d538-11ee-8247-fa163eb4f6be.png)**

  **2.1 分区**

  Kafka的每个topic都可以分为多个Partition，并且多个partition会均匀分布在集群的各个节点下。虽然这种方式能够有效的对数据进行分片，但是对于每个partition来说，都是单点的，当其中一个partition不可用的时候，那么这部分消息就没办法消费。所以kafka为了提高partition的可靠性而提供了副本的概念（Replica）,通过副本机制来实现冗余备份。

   每个分区可以有多个副本，并且在副本集合中会存在一个leader的副本，所有的读写请求都是由leader 副本来进行处理。剩余的其他副本都做为follower副本，follower副本会从leader副本同步消息日志。这个有点类似zookeeper中leader和follower的概念，但是具体的时间方式还是有比较大的差异。所以 我们可以认为，副本集会存在一主多从的关系。

区和副本的分配方式如下图：

![img](https://oss-emcsprod-public.modb.pro/image/auto/modb_20240227_d88345ba-d538-11ee-8247-fa163eb4f6be.png)

可能通过上图，你云里雾里，既然知道命令，我们就通过命令来看看，到底如何分配。

```
bin/kafka-topics.sh --create --zookeeper localhost:2181

--replication-factor 2

--partitions 5

--topic test-part
```



通过命令可以看出 topic：test-part 指定了 5个分区，拷贝因子为2（代表只有一个副本），通过 执行命令 查看 topic：test-part 信息如下：

![img](https://oss-emcsprod-public.modb.pro/image/auto/modb_20240227_d8a4b1fa-d538-11ee-8247-fa163eb4f6be.png)

**分区个数选择**

既然分区效果这么好，是不是越多分区越好呢？显而易见并非如此。

分区越多，所需要消耗的资源就越多。甚至如果足够大的时候，还会触发到操作系统的一些参数限制。比如linux中的文件描述符限制，一般在创建线程，创建socket，打开文件的场景下，linux默认的文件描述符参数，只有1024，超过则会报错。

看到这里有读者就会不耐烦了，说这么多有啥用，能不能直接告诉我分区分多少个比较好？很遗憾，暂时没有。

因为每个业务场景都不同，只能结合具体业务来看。假如每秒钟需要从主题写入和读取1GB数据，而消费者1秒钟最多处理50MB的数据，那么这个时候就可以设置20-25个分区，当然还要结合具体的物理资源情况。

而如何无法估算出大概的处理速度和时间，那么就用基准测试来测试吧。创建不同分区的topic，逐步压测测出最终的结果。如果实在是懒得测，那比较无脑的确定分区数的方式就是broker机器数量的2~3倍

**2.2、副本replica**  ![img](https://oss-emcsprod-public.modb.pro/image/auto/modb_20240227_d8ce267a-d538-11ee-8247-fa163eb4f6be.png)

   每个分区可以有多个副本，并且在副本集合中会存在一个leader的副本，所有的读写请求都是由leader副本来进行处理。剩余的其他副本都做为follower副本，follower副本会从leader副本同步消息日志。

**为什么 follower 副本不提供读服务？**

   这个问题本质上是对性能和一致性的取舍。试想一下，如果 follower 副本也对外提供服务那会怎么样呢？首先，性能是肯定会有所提升的。但同时，会出现一系列问题。类似数据库事务中的幻读，脏读。比如你现在写入一条数据到 kafka 主题 a，消费者 b 从主题 a 消费数据，却发现消费不到，因为消费者 b 去读取的那个分区副本中，最新消息还没写入。而这个时候，另一个消费者 c 却可以消费到最新那条数据，因为它消费了 leader 副本。Kafka 通过 WH 和 Offset 的管理来决定 Consumer 可以消费哪些数据，已经当前写入的数据。

**2.2.1、副本类型集合**

​    ISR：In-Sync Replicas。Kafka 中特别重要的概念，指代的是 AR 中那些与 Leader 保 持同步的副本集合。在 AR 中的副本可能不在 ISR 中，但 Leader 副本天然就包含在 ISR 中。关于 ISR，还有一个常见的面试题目是如何判断副本是否应该属于 ISR。目前的判断 依据是：Follower 副本的 LEO 落后 Leader LEO 的时间，是否超过了 Broker 端参数 replica.lag.time.max.ms 值。如果超过了，副本就会被从 ISR 中移除。

 ISR数据保存在Zookeeper的 brokers/topics//partitions//state 节点中

Kafka判断一个节点是否活着有两个条件：

- 1. 节点必须可以维护和ZooKeeper的连接，Zookeeper通过心跳机制检查每个节点的连接。
- 2. 如果节点是个follower,他必须能及时的同步leader的写操作，延时不能太久。

 AR：Assigned Replicas 所有副本集合。AR 是主题被创建后，分区创建时被分配的副本集合，副本个 数由副本因子决定。

**2.2.2、Leader副本的选举过程**

1. KafkaController会监听ZooKeeper的/brokers/ids节点路径，一旦发现有broker挂了，执行下面 的逻辑。这里暂时先不考虑KafkaController所在broker挂了的情况，KafkaController挂了，各个 broker会重新leader选举出新的KafkaController。
2. leader副本在该broker上的分区就要重新进行leader选举，目前的选举策略是：

 a) 优先从isr列表中选出第一个作为leader副本，这个叫优先副本，理想情况下有限副本就是该分 区的leader副本

 b) 如果isr列表为空，则查看该topic的unclean.leader.election.enable配置。unclean.leader.election.enable：为true则代表允许选用非isr列表的副本作为leader，那么此 时就意味着数据可能丢失，为 false的话，则表示不允许，直接抛出NoReplicaOnlineException异常，造成leader副本选举失 败。

 c) 如果上述配置为true，则从其他副本中选出一个作为leader副本，并且isr列表只包含该leader 副本。一旦选举成功，则将选举后 的leader和isr和其他副本信息写入到该分区的对应的zk路径上。

  在ISR中至少有一个follower时，Kafka可以确保已经commit的数据不丢失，但如果某个Partition的所 有Replica都宕机了，就无法保证数据不丢失了

- 1. 等待ISR中的任一个Replica“活”过来，并且选它作为Leader

  

- 2. 选择第一个“活”过来的Replica（不一定是ISR中的）作为Leader

  

   这就需要在可用性和一致性当中作出一个简单的折衷。如果一定要等待ISR中的Replica“活”过来，那不可用的时间就可能会相对较长。而且如果ISR中的所有 Replica都无法“活”过来了，或者数据都丢失了，这个Partition将永远不可用。选择第一个“活”过来的Replica作为Leader，而这个Replica不是ISR中的Replica，那即使它并不保证已 经包含了所有已commit的消息，它也会成为Leader而作为consumer的数据源（前文有说明，所有读 写都由Leader完成）。

**2.3、副本数据同步**

**![img](https://oss-emcsprod-public.modb.pro/image/auto/modb_20240227_d8f859b8-d538-11ee-8247-fa163eb4f6be.png)**

LEO：即日志末端位移(log end offset)，记录了该副本底层日志(log)中下一条消息的位移值。注意是下 一条消息！也就是说，如果LEO=10，那么表示该副本保存了10条消息，位移值范围是[0, 9]。另外， leader LEO和follower LEO的更新是有区别的。

HW：即上面提到的水位值（Hight Water）。对于同一个副本对象而言，其HW值不会大于LEO值。小 于等于HW值的所有消息都被认为是“已备份”的（replicated）。同理，leader副本和follower副本的 HW更新是有区别的。

通过下面这幅图来表达LEO、HW的含义，随着follower副本不断和leader副本进行数据同步，follower 副本的LEO会主键后移并且追赶到leader副本，这个追赶上的判断标准是当前副本的LEO是否大于或者 等于leader副本的HW，这个追赶上也会使得被踢出的follower副本重新加入到ISR集合中。

  另外， 假如说下图中的最右侧的follower副本被踢出ISR集合，也会导致这个分区的HW发生变化，变成 了3

![img](https://oss-emcsprod-public.modb.pro/image/auto/modb_20240227_d935519c-d538-11ee-8247-fa163eb4f6be.png)      

**2.3.0、副本数据同步原理**

了解了副本的协同过程以后，还有一个最重要的机制，就是数据的同步过程。它需要解决

- 1. 怎么传播消息

- 2. 在向消息发送端返回ack之前需要保证多少个Replica已经接收到这个消息

  

**数据的处理过程是**

下图中，深红色部分表示test_replica分区的leader副本，另外两个节点上浅色部分表示follower副本

![img](https://oss-emcsprod-public.modb.pro/image/auto/modb_20240227_d948e108-d538-11ee-8247-fa163eb4f6be.png)

Producer在发布消息到某个Partition时，

 先通过ZooKeeper找到该Partition的Leader get brokers/topics//partitions/2/state ，然后无论该Topic的Replication Factor为多 少（也即该Partition有多少个Replica），Producer只将该消息发送到该Partition的Leader。

 Leader会将该消息写入其本地Log。每个Follower都从Leader pull数据。这种方式上，Follower 存储的数据顺序与Leader保持一致。

 Follower在收到该消息并写入其Log后，向Leader发送ACK。

 一旦Leader收到了ISR中的所有Replica的ACK，该消息就被认为已经commit了，Leader将增加 HW(HighWatermark)并且向Producer发送ACK。

**2.3.1、副本初始状态**

​    初始状态下，leader 和 follower 的 HW 和 LEO 都是 0，leader 副本会保存 remote LEO，表示所有 follower LEO，也会被初始化为 0，这个时候，producer 没有发送消息。follower 会不断地个 leader 发送 FETCH 请求，但是因为没有数据，这个请求会被 leader 寄存，当在指定的时间之后会 强 制 完 成 请 求 ， 这 个 时 间 配 置 是 (replica.fetch.wait.max.ms)，如果在指定时间内 producer有消息发送过来，那么 kafka 会唤醒 fetch 请求，让 leader继续处理

![img](https://oss-emcsprod-public.modb.pro/image/auto/modb_20240227_d9724930-d538-11ee-8247-fa163eb4f6be.png)

数据的同步处理会分两种情况，这两种情况下处理方式是不一样的

第一种是 leader 处理完 producer 请求之后，follower 发送一个 fetch 请求过来、

第二种是follower 阻塞在 leader 指定时间之内，leader 副本收到producer 的请求。

这两种情况下处理方式是不一样的。

**2.3.2、leader 处理完 producer 请求之后，follower 发送一个 fetch 请求过来**

生产者发送一条消息

leader 处理完 producer 请求之后，follower 发送一个fetch 请求过来 。状态图如下:![img](https://oss-emcsprod-public.modb.pro/image/auto/modb_20240227_d98cbaea-d538-11ee-8247-fa163eb4f6be.png)

leader 副本收到请求以后，会做几件事情

把消息追加到 log 文件，同时更新 leader 副本的 LEO

尝试更新 leader HW 值。这个时候由于 follower 副本还没有发送 fetch 请求，那么 leader 的 remote LEO 仍然是 0。leader 会比较自己的 LEO 以及 remote LEO 的值发现最小值是 0，与 HW 的值相同，所以不会更新 HW。

follower 第一次发送 fetch 请求

![img](https://oss-emcsprod-public.modb.pro/image/auto/modb_20240227_d9ac2574-d538-11ee-8247-fa163eb4f6be.png)

follower 发送 fetch 请求，leader 副本的处理逻辑是:

读取 log 数据、更新 remote LEO=0(follower 还没有写入这条消息，这个值是根据 follower 的 fetch 请求中的offset 来确定的)

尝试更新 HW，因为这个时候 LEO 和 remoteLEO 还是不一致，所以仍然是 HW=0

把消息内容和当前分区的 HW 值发送给 follower 副本，follower 副本收到 response 以后

follower副本收到response以后

将消息写入到本地 log，同时更新 follower 的 LEO

更新 follower HW，本地的 LEO 和 leader 返回的 HW进行比较取小的值，所以仍然是 0 第一次交互结束以后，HW 仍然还是 0，这个值会在下一次follower 发起 fetch 请求时被更新

follower 第二次发送 fetch 请求 如下图：

![img](https://oss-emcsprod-public.modb.pro/image/auto/modb_20240227_d9d0a7b4-d538-11ee-8247-fa163eb4f6be.png)

follower 发第二次 fetch 请求，leader 收到请求以后

读取 log 数据

更新 remote LEO=1， 因为这次 fetch 携带的 offset 是1.

更新当前分区的 HW，这个时候 leader LEO 和 remoteLEO 都是 1，所以 HW 的值也更新为 1

把数据和当前分区的 HW 值返回给 follower 副本，这个时候如果没有数据，则返回为空

follower 副本收到 response 以后

如果有数据则写本地日志，并且更新 LEO

更新 follower 的 HW 值到目前为止，数据的同步就完成了，意味着消费端能够消费 offset=0 这条消息。

**2.3.2、follower 的 fetch 请求是直接从阻塞过程中触发**

前面说过，由于 leader 副本暂时没有数据过来，所以follower 的 fetch 会被阻塞，直到等待超时或者 leader 接 收到新的数据。当 leader 收到请求以后会唤醒处于阻塞的fetch 请求。处理过程基本上和前面说的一直

leader 将消息写入本地日志，更新 Leader 的 LEO

唤醒 follower 的 fetch 请求

更新 HW

kafka 使用 HW 和 LEO 的方式来实现副本数据的同步，本身是一个好的设计，但是在这个地方会存在一个数据丢失的问题，当然这个丢失只出现在特定的背景下。我们回想一下，HW 的值是在新的一轮 FETCH 中才会被更新。我们分析下这个过程为什么会出现数据丢失。

**2.4、数据丢失的问题**

前提：min.insync.replicas=1 的时候。->设定 ISR 中的最小副本数是多少，默认值为 1, 当且仅当 acks 参数设置为-1（表示需要所有副本确认）时，此参数才生效. 表达的含义是，至少需要多少个副本同步才能表示消息是提交的所以，当 min.insync.replicas=1 的时候一旦消息被写入 leader 端 log 即被认为是“已提交”，而延迟一轮 FETCH RPC 更新 HW 值的设计使得 follower HW值是异步延迟更新的，倘若在这个过程中 leader 发生变更，那么成为新 leader 的 follower 的 HW 值就有可能是过期的，使得 clients 端认为是成功提交的消息被删除。

![img](https://oss-emcsprod-public.modb.pro/image/auto/modb_20240227_d9f8c78a-d538-11ee-8247-fa163eb4f6be.png)

**数据丢失的解决方案**

在 kafka0.11.0.0 版本以后，提供了一个新的解决方案，使用 leader epoch 来解决这个问题，leader epoch 实际上是一对之(epoch,offset), epoch 表示 leader 的版本号，从 0开始，当 leader 变更过 1 次时 epoch 就会+1，而 offset 则对应于该 epoch 版本的 leader 写入第一条消息的位移。比如说

(0,0) ; (1,50); 表示第一个 leader 从 offset=0 开始写消息，一共写了 50 条，第二个 leader 版本号是 1，从 50 条处开始写消息。这个信息保存在对应分区的本地磁盘文件中，文 件 名 为 ：/tml/kafka-log/topic/leader-epochcheckpoint

leader broker 中会保存这样的一个缓存，并定期地写入到一个 checkpoint 文件中。

当 leader 写 log 时它会尝试更新整个缓存——如果这个leader 首次写消息，则会在缓存中增加一个条目；否则就 不做更新。而每次副本重新成为 leader 时会查询这部分缓存，获取出对应 leader 版本的 offset

![img](https://oss-emcsprod-public.modb.pro/image/auto/modb_20240227_da1d8e76-d538-11ee-8247-fa163eb4f6be.png)

**如何处理所有的 Replica 不工作的情况**

在 ISR 中至少有一个 follower 时，Kafka 可以确保已经commit 的数据不丢失，但如果某个 Partition 的所有 Replica 都宕机了，就无法保证数据不丢失了

等待 ISR 中的任一个 Replica“活”过来，并且选它作为Leader

这就需要在可用性和一致性当中作出一个简单的折衷。如果一定要等待 ISR 中的 Replica“活”过来，那不可用的时 间就可能会相对较长。而且如果 ISR 中的所有 Replica 都无法“活”过来了，或者数据都丢失了，这个 Partition 将永远不可用。

2.选择第一个“活”过来的 Replica（不一定是 ISR 中的）作为 Leader

选择第一个“活”过来的 Replica 作为 Leader，而这个Replica 不是 ISR 中的 Replica，那即使它并不保证已经包 含了所有已 commit 的消息，它也会成为 Leader 而作为consumer 的数据源（前文有说明，所有读写都由 Leader完成）。使用的是第一种策略

![img](https://oss-emcsprod-public.modb.pro/image/auto/modb_20240227_da3fb8c0-d538-11ee-8247-fa163eb4f6be.png)