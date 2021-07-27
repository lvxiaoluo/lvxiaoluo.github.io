- - ## 面试题：Kafka如何保证高可用？有图有真相

    原创 日常加油站 [月伴飞鱼](javascript:void(0);) *4月6日*

    收录于话题
    > ❝
    >
    > Kafka如何保证高可用的?
    >
    > ❞

    **「下面来跟大家分享下当时我答到的点」**

    # 什么是高可用

    **「高可用性」**，指系统无间断地执行其功能的能力，代表系统的可用性程度

    Kafka从0.8版本开始提供了高可用机制，可保障一个或多个Broker宕机后，其他Broker能继续提供服务

    # 备份机制

    Kafka允许同一个Partition存在多个消息副本，每个Partition的副本通常由1个Leader及0个以上的Follower组成，生产者将消息直接发往对应Partition的Leader，Follower会周期地向Leader发送同步请求

    同一Partition的Replica不应存储在同一个Broker上，因为一旦该Broker宕机，对应Partition的所有Replica都无法工作，这就达不到高可用的效果

    所以Kafka会尽量将所有的Partition以及各Partition的副本均匀地分配到整个集群的各个Broker上

    **「如下图举个例子：」**

    ![图片](https://mmbiz.qpic.cn/mmbiz_png/hC3oNAJqSRxPRzrRVRibibiagnX6xp0sTLBhs2y55QS4ryOULLTJARLFxibpiac2MkibYwlzb2CQ0kpSCVhJ7BLXEBgw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

    # ISR机制
    **「ISR 副本集合」**

    ISR 中的副本都是与 Leader 同步的副本，相反，不在 ISR 中的追随者副本就被认为是与 Leader 不同步的

    这里的保持同步不是指与Leader数据保持完全一致，只需在`replica.lag.time.max.ms`时间内与Leader保持有效连接

    Follower周期性地向Leader发送FetchRequest请求，发送时间间隔配置在`replica.fetch.wait.max.ms`中，默认值为500

    ```
    public class FetchRequest {
        private final short versionId;
        private final int correlationId;
        private final String clientId;
        private final int replicaId;
        private final int maxWait;    // Follower容忍的最大等待时间: 到点Leader立即返回结果，默认值500
        private final int minBytes;   // Follower容忍的最小返回数据大小：当Leader有足够数据时立即返回，兜底等待maxWait返回，默认值1
        private final Map<TopicAndPartition, PartitionFetchInfo> requestInfo;  // Follower中各Partititon对应的LEO及获取数量
    }
    ```

    各Partition的Leader负责维护ISR列表并将ISR的变更同步至ZooKeeper，被移出ISR的Follower会继续向Leader发FetchRequest请求，试图再次跟上Leader重新进入ISR

    ISR中所有副本都跟上了Leader，通常只有ISR里的成员才可能被选为Leader

    **「Unclean领导者选举」**

    当Kafka中`unclean.leader.election.enable`配置为true(默认值为false)且ISR中所有副本均宕机的情况下，才允许ISR外的副本被选为Leader，此时会丢失部分已应答的数据

    开启 Unclean 领导者选举可能会造成数据丢失，但好处是，它使得分区 Leader 副本一直存在，不至于停止对外提供服务，因此提升了高可用性，反之，禁止 Unclean 领导者选举的好处在于维护了数据的一致性，避免了消息丢失，但牺牲了高可用性

    ![图片](https://mmbiz.qpic.cn/mmbiz_png/hC3oNAJqSRxPRzrRVRibibiagnX6xp0sTLBdoPwg0TGpibXe9t1O9HkEATy1KkJ5tGu3JCLM3lBgm6PlGVO1ypsCicw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

    # ACK机制

    生产者发送消息中包含acks字段，该字段代表Leader应答生产者前Leader收到的应答数

    - **「acks=0」**

    生产者无需等待服务端的任何确认，消息被添加到生产者套接字缓冲区后就视为已发送，因此acks=0不能保证服务端已收到消息

    - **「acks=1」**

    只要 `Partition Leader` 接收到消息而且写入本地磁盘了，就认为成功了，不管它其他的 Follower 有没有同步过去这条消息了

    - **「acks=all」**

    Leader将等待ISR中的所有副本确认后再做出应答，因此只要ISR中任何一个副本还存活着，这条应答过的消息就不会丢失

    acks=all是可用性最高的选择，但等待Follower应答引入了额外的响应时间。Leader需要等待ISR中所有副本做出应答，此时响应时间取决于ISR中最慢的那台机器

    如果说 Partition Leader 刚接收到了消息，但是结果 `Follower` 没有收到消息，此时 Leader 宕机了，那么客户端会感知到这个消息没发送成功，他会重试再次发送消息过去

    Broker有个配置项`min.insync.replicas`(默认值为1)代表了正常写入生产者数据所需要的最少ISR个数

    当ISR中的副本数量小于`min.insync.replicas`时，Leader停止写入生产者生产的消息，并向生产者抛出NotEnoughReplicas异常，阻塞等待更多的Follower赶上并重新进入ISR

    被Leader应答的消息都至少有`min.insync.replicas`个副本，因此能够容忍`min.insync.replicas-1`个副本同时宕机

    **「结论：」**

    发送的acks=1和0消息会出现丢失情况，为不丢失消息可配置生产者`acks=all & min.insync.replicas >= 2`

    ![图片](https://mmbiz.qpic.cn/mmbiz_png/hC3oNAJqSRxPRzrRVRibibiagnX6xp0sTLB3eMvcEQBFq7gyQmZy1bl3VwM4U58vBUibV1wKNXbf3RqtfDc5j4OPCQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1&retryload=1)

    # 故障恢复机制

    **「Kafka从0.8版本开始引入了一套Leader选举及失败恢复机制」**

    首先需要在集群所有Broker中选出一个Controller，负责各Partition的Leader选举以及Replica的重新分配

    - 当出现Leader故障后，Controller会将Leader/Follower的变动通知到需为此作出响应的Broker。

    Kafka使用ZooKeeper存储Broker、Topic等状态数据，Kafka集群中的Controller和Broker会在ZooKeeper指定节点上注册Watcher(事件监听器)，以便在特定事件触发时，由ZooKeeper将事件通知到对应Broker

    ## Broker

    **「当Broker发生故障后，由Controller负责选举受影响Partition的新Leader并通知到相关Broker」**

    - 当Broker出现故障与ZooKeeper断开连接后，该Broker在ZooKeeper对应的znode会自动被删除，ZooKeeper会触发Controller注册在该节点的Watcher；
    - Controller从ZooKeeper的`/brokers/ids`节点上获取宕机Broker上的所有Partition；
    - Controller再从ZooKeeper的`/brokers/topics`获取所有Partition当前的ISR；
    - 对于宕机Broker是Leader的Partition，Controller从ISR中选择幸存的Broker作为新Leader；
    - 最后Controller通过LeaderAndIsrRequest请求向的Broker发送LeaderAndISRRequest请求。

    ![图片](https://mmbiz.qpic.cn/mmbiz_png/hC3oNAJqSRxPRzrRVRibibiagnX6xp0sTLBZUS9KkuY0wLWNldGsOBp0XZMq7WFRmwgmSKOW04tXyiav1rYqHiaCF6A/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

    ## Controller

    集群中的Controller也会出现故障，因此Kafka让所有Broker都在ZooKeeper的Controller节点上注册一个Watcher

    Controller发生故障时对应的Controller临时节点会自动删除，此时注册在其上的Watcher会被触发，所有活着的Broker都会去竞选成为新的Controller(即创建新的Controller节点，由ZooKeeper保证只会有一个创建成功)

    竞选成功者即为新的Controller

    # 最后

    **「写文章画图不易，喜欢的话，希望帮忙点赞，转发下哈，谢谢」**

    微信搜索：月伴飞鱼，交个朋友

    公众号后台回复666，获得免费电子书籍，必读经典书籍这里全都有

    参考文档：

    - Apache Zookeeper
    - Apache Kafka