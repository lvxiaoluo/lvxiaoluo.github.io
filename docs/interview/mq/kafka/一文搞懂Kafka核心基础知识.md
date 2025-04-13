## 一文搞懂Kafka核心基础知识



Kafka是最初由Linkedin公司开发，是一个分布式、支持分区的（partition）、多副本的（replica），基于zookeeper协调的分布式消息系统，它的最大的特性就是可以实时的处理大量数据以满足各种需求场景：比如基于hadoop的批处理系统、低延迟的实时系统、Storm/Spark流式处理引擎，web/nginx日志、访问日志，消息服务等等，用scala语言编写，Linkedin于2010年贡献给了Apache基金会并成为顶级开源 项目。

**「下面这篇文章会从以下方面会带大家介绍下这个强大的开源项目，希望对大家收获」**

![图片](https://mmbiz.qpic.cn/mmbiz_png/hC3oNAJqSRyXloc4TOssA4p3PiabAoWd2Xjck8f2RC2Ddd2X1kbATia8jEhQ4QAnaJwLicRwtbMpmOwKvMMkgeeyg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

# 快速入门

## 版本介绍

Kafka 官网的下载地址是 https://kafka.apache.org/downloads ；打开下载页面后我们可以看 到不同版本的 Kafka 二进制代码压缩包

![图片](https://mmbiz.qpic.cn/mmbiz_png/hC3oNAJqSRyXloc4TOssA4p3PiabAoWd2ibcdpMP71P62geb6D7zdtxVZWwFmKXgPicc1kHT7WqUcW3c9mBuicSnCg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

如图，当前最新的 Kafka 版本是 2.6.0，提供了两个二进制压缩包可供下载 。

- katka_2.12 2.6.0.tgz
- katka_2.13-2.6.0.tgz

上面两个文件中的 2.12 /2.13 分别表示编译 Kafka 的 Scala 语言版本，后面的 2.6.0 是 Kafka 的版本 。

其中前面的 2 表示大版本号，即 Major Version；中间的 6 表示小版本号或次版本号，即 Minor Version；最后的 0 表示修订版 本号，也就是 Patch 号。

## 安装教程

由于Kafka是用Scala语言开发的，运行在JVM上，因此在安装Kafka之前需要先安装JDK。

还有kafka也依赖zookeeper，所以需要先安装zookeeper

```
wget http://mirror.bit.edu.cn/apache/zookeeper/stable/zookeeper-3.5.8.tar.gz  
tar -zxvf zookeeper-3.5.8.tar.gz  
cd zookeeper-3.5.8.tar.gz  

# 启动zookeeper
bin/zkServer.sh start
bin/zkCli.sh 
ls /   #查看zk的根目录相关节点
```

**「下载安装包」**

下载并解压：

```
wget https://archive.apache.org/dist/kafka/2.6.0/kafka_2.12-2.6.0.tgz
tar -xzf kafka_2.12-2.6.0.tgz
cd kafka_2.12-2.6.0
```

**「启动服务」**

```
bin/kafka-server-start.sh -daemon config/server.properties

# 我们进入zookeeper目录通过zookeeper客户端查看下zookeeper的目录树
bin/zkCli.sh 
ls /  #查看zk的根目录kafka相关节点
ls /brokers/ids #查看kafka节点
```

## 消息引擎模型

**「我们用一句话概括Kafka就是它是一款开 源的消息引擎系统。」**

其中最常见的两种消息引擎模型是点对点模型和发布／订阅模型

**「点对点模型」**

点对点模型是基于队列提供消息传输服务的，该模型定义了消息队列、发送者和接收者 , 提供了一种点对点的消息传递方式，即发送者发送每条消息到队列的指定位置，接收者从指定位置获取消息，一旦消息被消费， 就会从队列中移除该消息 。 每条消息由一个发送者生产出来， 且只被一个消费者处理一一发送者和消费者之间是一对一的关系

![图片](https://mmbiz.qpic.cn/mmbiz_png/hC3oNAJqSRyXloc4TOssA4p3PiabAoWd2RIcqrDvDAAObdibFqzibFUUv7WUByqqurZ7l8HqWgS5BIvIibZh6VMfTQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

**「发布／订阅模型」**

发布／订阅模型与前一种模型不同， 它有主题(topic)的概念。 这种模型也定义了类似于生产者／消费者这样的角色，即发布者和订阅者，发布者将消息生产出来发送到指定的topic中， 所有订阅了该 topic的订阅者都可以接收到该topic下的所有消息，通常具有相同订阅 topic 的所有订阅者将接收到 同样的消息

![图片](https://mmbiz.qpic.cn/mmbiz_png/hC3oNAJqSRyXloc4TOssA4p3PiabAoWd2B1iaKbibDzd54qdR5ceQLSOAr8we6dRSvTXwPIrEmzbLEl2aqZyibhEpg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

**「Kafka 同时支持这两种消息引擎模型的，后面会介绍」**

![图片](https://mmbiz.qpic.cn/mmbiz_png/hC3oNAJqSRyXloc4TOssA4p3PiabAoWd29ia584w4dF4NJjPnWHmeeye4UQUJMfibWYQxGB1ibPV5WjXzfH4SfXvicw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

## 基本概念

### 消息

既然Kafka是消息引擎，这里的消息就是指 Kafka 处理的主要对象

### Broker

broker 指一个 kafka 服务器。如果多个 broker 形成集群会依靠 Zookeeper 集群进行服务的协调管理。

生产者发送消息给 Kafka 服务器。消费者从 Kafka 服务器读取消息。

### Topic和Partition

topic代表了一类消息， 也可以认为是消息被 发送到的地方。 通常我们可以使用 topic 来区分实际业务， 比如业务 A 使用 一个 topic ， 业务 B 使用另外一个 topic。

Kafka 中的 topic 通常都会被多个消费者订阅， 因此出于性能的考量 ， Kafka 并不是 topic-message 的两级结构， 而是采用了 topic-partition-messa ge 的三级结构来分散负 载。 从本质上说， 每个 Kafka topic 都由若干个 partition 组成

![图片](https://mmbiz.qpic.cn/mmbiz_png/hC3oNAJqSRyXloc4TOssA4p3PiabAoWd2mjwE3rucfj7U1cLNC9TaUGtiaibyUppV83usdbBXXnOOcnJFo9mOUHLw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

如图： topic 是由多个 partition 组成的， 而 Kafka 的 partition 是不可修改的有序消 息序列， 也可以说是 有序的消息日志。 每个 partition 有自己专属的 partition 号， 通常是从 0 开始的。 用户对 partition 唯一能做的操作就是 在消息序列的尾部追 加写入消息。 partition 上的每条消息都会被分配一个唯一 的序列号

该序列号被称为位移（ offset ） 是从 0 开始顺序递增 的整数。 位移信息可以 唯一定位到某 partition 下的一条消息 。

**「kafka为什么要设计分区？」**

解决伸缩性的问题。假如一个broker积累了太多的数据以至于单台 Broker 机器都无法容纳了，此时应该怎么办呢？一个很自然的想法就 是，能否把数据分割成多份保存在不同的 Broker 上？所以kafka设计了分区

![图片](https://mmbiz.qpic.cn/mmbiz_png/hC3oNAJqSRyXloc4TOssA4p3PiabAoWd28aJFl5BTDF7NWV57a5iaIV76RqAiaJNNAV49McXQqB7ia5bQpyLRUsLgA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

### 生产者和消费者

向主题发布消息的客户端应用程序称为生产者（Producer），生产者程序通常持续不断地 向一个或多个主题发送消息，而订阅这些主题消息的客户端应用程序就被称为消费者 （Consumer）。和生产者类似，消费者也能够同时订阅多个主题的消息

### 消费者组

Consumer Group 是指组里面有多个消费者或消费者实例，它 们共享一个公共的 ID，这个 ID 被称为 Group ID。组内的 所有消费者协调在一起来消费订阅主题的所有分区（Partition）。当然，每个分区只能由 同一个消费者组内的一个 Consumer 实例来消费。

**「Consumer Group 三个特性。」**

1. Consumer Group 下可以有一个或多个 Consumer 实 例。
2. Group ID 是一个字符串，在一个 Kafka 集群中，它标识 唯一的一个 Consumer Group。
3. Consumer Group 下所有实例订阅的主题的单个分区， 只能分配给组内的某个 Consumer 实例消费。这个分区 当然也可以被其他的 Group 消费。

**「还记得上面提到的两种消息引擎模型」**

Kafka 仅仅使用 Consumer Group 这一种机制，却同时实现了传统消息引 擎系统的两大模型：如果所有实例都属于同一个 Group， 那么它实现的就是点对点模型；如果所有实例分别属于不 同的 Group，那么它实现的就是发布 / 订阅模型。

![图片](https://mmbiz.qpic.cn/mmbiz_png/hC3oNAJqSRyXloc4TOssA4p3PiabAoWd2Uiawc3JgYIHIiaXjPId8Kbtq77WqIjx4ezScYtbsg0vywLGuU7GBzf2Q/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

**「在实际使用场景中，一个 Group 下该有多少个 Consumer 实例呢？」**

理想情况下， Consumer 实例的数量应该等于该 Group 订阅主题的分区 总数。

举个简单的例子，假设一个 Consumer Group 订阅了 3 个 主题，分别是 A、B、C，它们的分区数依次是 1、2、3， 那么通常情况下，为该 Group 设置 6 个 Consumer 实例是 比较理想的情形，因为它能最大限度地实现高伸缩性。

#### 消费顺序问题

按照上面的设计，可能会导致消费顺序问题，下面一一介绍

**「乱序场景一」**

因为一个topic可以有多个partition，kafka只能保证partition内部有序

当partition数量=同一个消费者组中消费者数量时，可能需要顺序的数据分布到了不同的partition，导致处理时乱序

**「解决方案」**

1、可以设置topic 有且只有一个partition

2、根据业务需要，需要顺序的 指定为同一个partition

**「乱序场景二」**

对于同一业务进入了同一个消费者组之后，用了多线程来处理消息，会导致消息的乱序

**「解决方案」**

消费者内部根据线程数量创建等量的内存队列，对于需要顺序的一系列业务数据，根据key或者业务数据，放到同一个内存队列中，然后线程从对应的内存队列中取出并操作

### Rebalance

Rebalance 本质上是一种协议，规定了一个 Consumer Group 下的所有 Consumer 如何达成一致，来分配订阅 Topic 的每个分区。比如某个 Group 下有 20 个 Consumer 实例，它订阅了一个具有 100 个分区的 Topic。正常情况下，Kafka 平均会为每个 Consumer 分配 5 个分区。这个分配的过程就叫 Rebalance。

**「Consumer Group 何时进行 Rebalance 呢？ Rebalance 的触发条件有 3 个。」**

1. 组成员数发生变更。比如有新的 Consumer 实例加入组 或者离开组，或是有 Consumer 实例崩溃被“踢出”组。

2. 1. 订阅主题数发生变更。Consumer Group 可以使用正则 表达式的方式订阅主题，比如`consumer.subscribe(Pattern.compile(“t.*c”))` 就表 明该 Group 订阅所有以字母 t 开头、字母 c 结尾的主 题。在 Consumer Group 的运行过程中，你新创建了一 个满足这样条件的主题，那么该 Group 就会发生 Rebalance。

3. 订阅主题的分区数发生变更。Kafka 当前只能允许增加一 个主题的分区数。当分区数增加时，就会触发订阅该主题 的所有 Group 开启 Rebalance。

Rebalance 过程对 Consumer Group 消费过程有极 大的影响。会stop the world，简称 STW。我们知道在 STW 期间，所有应用线程都会停止工作，表现为 整个应用程序僵在那边一动不动。Rebalance 过程也和这个 类似，在 Rebalance 过程中，所有 Consumer 实例都会停 止消费，等待 Rebalance 完成。这是 Rebalance 为人诟病 的一个方面。

![图片](https://mmbiz.qpic.cn/mmbiz_png/hC3oNAJqSRyXloc4TOssA4p3PiabAoWd28icccaDvzvdfoA5JCvGeaBIJiaM97Q05JRxLjibsTd3dNKK5G40Ym0d6g/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

### Offset

前面说过，topic partition 下的每条消息都被分配一个位移值。 实际上 ，Kafka消费者端也有位移（ offset）的概念， 但一定要注意 这两个offset 属于不同的概念

![图片](https://mmbiz.qpic.cn/mmbiz_png/hC3oNAJqSRyXloc4TOssA4p3PiabAoWd2o6nibBjEls3eo2CRvyzicqXoTUdwtYdKn0vltPSFQgIpSjHjSEvpjB3g/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

显然， 每条消息在某个 partition 的位移是固定的， 但消费该 partition 的消费者的位移会随 着消费进度不断前移

### Replica

既然我们己知 partition 是有序消息日志， 那么一定不能只保存这一份日志，否则一旦保存 partition 的 Kafka 服务器挂掉了， 其上保存的消息也就都丢失了。 分布式系统必然要实现高可靠性， 而目前实现的主要途径还是依靠冗余机制，通过备份多份日志 。 这些备份日志在 Kafka 中被称为副本（ replica ），它们存在的唯一目的就是防止数据丢失

**「副本分为两类 ：」**

领导者副本（ leader replica ）和追随者副本（ follower replica ）。

follower replica 是不能提供服务给客户端的，也就是说不负 责响应客户端发来的消息写入和消息消费请求。它只是被动地向领导者副本（ leader replica ）获取数据， 而 一旦 leader replica 所在的 broker 岩机， Kafka 会从剩余的 replica 中选举出新的 leader 继续提供服务。

### Leader和Follower

前面说的， Kafka 的 replica 分为两个角色：领导者（ leader ）和追随者（ follower ） 。 Kafka 保证同一个 partition 的多个 replica 一定不会分配在同一台 broker 上 。 毕竟如果同一个 broker 上有同一个 partition 的多个 replica， 那么将无法实现备份冗余的效果。

![图片](https://mmbiz.qpic.cn/mmbiz_png/hC3oNAJqSRyXloc4TOssA4p3PiabAoWd2hyRSpFMFosibHaUIVWpvgKkrXFfOlth3yzoqvWoIa5eSK77NLLpfiaGg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

### ISR

ISR 的全称是 in-sync replica，翻译过来就是与 leader replica 保持同步的 replica 集合 。

Kafka 为 partition 动态维护一个 replica 集合。该集合中的所有 replica 保存的消息日志都与leader replica 保持同步状态。只有这个集合中的 replica 才能被选举为 leader，也只有该集合中 所有 replica 都接收到了同一条消息， Kafka 才会将该消息置于“己提交”状态，即认为这条消 息发送成功。

如果因为各种各样的原因，一小部分 replica 开始落后于 leader replica 的进度 。当滞后 到 一定程度时， Kafka 会将这些 replica “踢”出 ISR。相反地，当这些 replica 重新“追上”了 leader 的进度时 ， 那么 Kafka 会将它们加 回到 ISR 中。这一切都 是自动维护的， 不需要用户进行人工干预。

**「最后用2张图来展示上面提到的这些概念以及运行流程：」**

![图片](https://mmbiz.qpic.cn/mmbiz_png/hC3oNAJqSRyXloc4TOssA4p3PiabAoWd25jc7tlhGTGoVEEHkrU9tibU9bjQHqQZTsc2EwtUmo2yibc14QDQblbJg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

![图片](https://mmbiz.qpic.cn/mmbiz_png/hC3oNAJqSRyXloc4TOssA4p3PiabAoWd2yXbq07osFXjlmywzW4tKPicfLdGs0tZ3T06gbgCcweUrXGXiblHmOiadA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

# 使用场景

日志收集：一个公司可以用Kafka收集各种服务的log，通过kafka以统一接口服务的方式开放给各种consumer，例如hadoop、Hbase、Solr等。

消息系统：解耦和生产者和消费者、缓存消息等。

用户活动跟踪：Kafka经常被用来记录web用户或者app用户的各种活动，如浏览网页、搜索、点击等活动，这些活动信息被各个服务器发布到kafka的topic中，然后订阅者通过订阅这些topic来做实时的监控分析，或者装载到hadoop、数据仓库中做离线分析和挖掘。

运营指标：Kafka也经常用来记录运营监控数据。包括收集各种分布式应用的数据，生产各种操作的集中反馈，比如报警和报告。

下面是一个日志方面的典型使用场景。

![图片](https://mmbiz.qpic.cn/mmbiz_png/hC3oNAJqSRyXloc4TOssA4p3PiabAoWd2uk8mmGv4g26tEQfAqFsmlc3vSbeMeXKPAusCANleUUib0oPzOACyrOw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

## KAFKA为什么快

**「顺序读写」**

kafka的消息是不断追加到文件中的，这个特性使kafka可以充分利用磁盘的顺序读写性能

顺序读写不需要硬盘磁头的寻道时间，只需很少的扇区旋转时间，所以速度远快于随机读写

**「零拷贝」**

服务器先将文件从复制到内核空间，再复制到用户空间，最后再复制到内核空间并通过网卡发送出去，而零拷贝则是直接从内核到内核再到网卡，省去了用户空间的复制

Zero copy对应的是Linux中sendfile函数，这个函数会接受一个offsize来确定从哪里开始读取。现实中，不可能将整个文件全部发给消费者，他通过消费者传递过来的偏移量来使用零拷贝读取指定内容的数据返回给消费者

**「分区」**

kafka中的topic中的内容可以被分为多分partition存在,每个partition又分为多个段segment,所以每次操作都是针对一小部分做操作，很轻便，并且增加`并行操作`的能力

**「批量发送」**

kafka允许进行批量发送消息，producer发送消息的时候，可以将消息缓存在本地,等到了固定条件发送到kafka

1. 等消息条数到固定条数
2. 一段时间发送一次

**「数据压缩」**

Kafka还支持对消息集合进行压缩，Producer可以通过GZIP或Snappy格式对消息集合进行压缩。

压缩的好处就是减少传输的数据量，减轻对网络传输的压力。

Producer压缩之后，在Consumer需进行解压，虽然增加了CPU的工作，但在对大数据处理上，瓶颈在网络上而不是CPU，所以这个成本很值得

# 基本使用

## Java客户端访问Kafka

下面介绍使用Java客户端访问Kafka

引入maven依赖

```
<dependency>
   <groupId>org.apache.kafka</groupId>
   <artifactId>kafka-clients</artifactId>
   <version>2.6.0</version>
</dependency>
```

消息发送端代码

```
public class MsgProducer {
    public static void main(String[] args) throws InterruptedException, ExecutionException {
        Properties props = new Properties();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "192.168.0.60:9092,192.168.0.60:9093,192.168.0.60:9094");
        /*
         发出消息持久化机制参数
        （1）acks=0： 表示producer不需要等待任何broker确认收到消息的回复，就可以继续发送下一条消息。性能最高，但是最容易丢消息。
        （2）acks=1： 至少要等待leader已经成功将数据写入本地log，但是不需要等待所有follower是否成功写入。就可以继续发送下一条消息。这种情况下，如果follower没有成功备份数据，而此时leader又挂掉，则消息会丢失。
        （3）acks=-1或all： 这意味着leader需要等待所有备份(min.insync.replicas配置的备份个数)都成功写入日志，这种策略会保证只要有一个备份存活就不会丢失数据。
         这是最强的数据保证。一般除非是金融级别，或跟钱打交道的场景才会使用这种配置。
        */
        props.put(ProducerConfig.ACKS_CONFIG, "1");
        //发送失败会重试，默认重试间隔100ms，重试能保证消息发送的可靠性，但是也可能造成消息重复发送，比如网络抖动，所以需要在接收者那边做好消息接收的幂等性处理
        props.put(ProducerConfig.RETRIES_CONFIG, 3);
        //重试间隔设置
        props.put(ProducerConfig.RETRY_BACKOFF_MS_CONFIG, 300);
        //设置发送消息的本地缓冲区，如果设置了该缓冲区，消息会先发送到本地缓冲区，可以提高消息发送性能，默认值是33554432，即32MB
        props.put(ProducerConfig.BUFFER_MEMORY_CONFIG, 33554432);
        //kafka本地线程会从缓冲区取数据，批量发送到broker，
        //设置批量发送消息的大小，默认值是16384，即16kb，就是说一个batch满了16kb就发送出去
        props.put(ProducerConfig.BATCH_SIZE_CONFIG, 16384);
        //默认值是0，意思就是消息必须立即被发送，但这样会影响性能
        //一般设置100毫秒左右，就是说这个消息发送完后会进入本地的一个batch，如果100毫秒内，这个batch满了16kb就会随batch一起被发送出去
        //如果100毫秒内，batch没满，那么也必须把消息发送出去，不能让消息的发送延迟时间太长
        props.put(ProducerConfig.LINGER_MS_CONFIG, 100);
        //把发送的key从字符串序列化为字节数组
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        //把发送消息value从字符串序列化为字节数组
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());

        Producer<String, String> producer = new KafkaProducer<>(props);

        int msgNum = 5;
        for (int i = 1; i <= msgNum; i++) {
            Order order = new Order(i, 100 + i, 1, 1000.00);
            //指定发送分区
            ProducerRecord<String, String> producerRecord = new ProducerRecord<String, String>("order-topic"
                    , 0, order.getOrderId().toString(), JSON.toJSONString(order));
            //未指定发送分区，具体发送的分区计算公式：hash(key)%partitionNum
            /*ProducerRecord<String, String> producerRecord = new ProducerRecord<String, String>("my-replicated-topic"
                    , order.getOrderId().toString(), JSON.toJSONString(order));*/

            //等待消息发送成功的同步阻塞方法
         /*RecordMetadata metadata = producer.send(producerRecord).get();
         System.out.println("同步方式发送消息结果：" + "topic-" + metadata.topic() + "|partition-"
                 + metadata.partition() + "|offset-" + metadata.offset());*/

            //异步方式发送消息
            producer.send(producerRecord, new Callback() {
                @Override
                public void onCompletion(RecordMetadata metadata, Exception exception) {
                    if (exception != null) {
                        System.err.println("发送消息失败：" + exception.getStackTrace());

                    }
                    if (metadata != null) {
                        System.out.println("异步方式发送消息结果：" + "topic-" + metadata.topic() + "|partition-"
                                + metadata.partition() + "|offset-" + metadata.offset());
                    }
                }
            });


        }

        producer.close();
    }
}
```

消息接收端代码

```
public class MsgConsumer {
    public static void main(String[] args) {
        Properties props = new Properties();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, "192.168.0.60:9092,192.168.0.60:9093,192.168.0.60:9094");
        // 消费分组名
        props.put(ConsumerConfig.GROUP_ID_CONFIG, "testGroup");
        // 是否自动提交offset
      //props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "true");
      // 自动提交offset的间隔时间
      props.put(ConsumerConfig.AUTO_COMMIT_INTERVAL_MS_CONFIG , "1000");
        props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "false");
      /*
      心跳时间，服务端broker通过心跳确认consumer是否故障，如果发现故障，就会通过心跳下发
      rebalance的指令给其他的consumer通知他们进行rebalance操作，这个时间可以稍微短一点
      */
        props.put(ConsumerConfig.HEARTBEAT_INTERVAL_MS_CONFIG, 1000);
        //服务端broker多久感知不到一个consumer心跳就认为他故障了，默认是10秒
        props.put(ConsumerConfig.SESSION_TIMEOUT_MS_CONFIG, 10 * 1000);
        /*
        如果两次poll操作间隔超过了这个时间，broker就会认为这个consumer处理能力太弱，
        会将其踢出消费组，将分区分配给别的consumer消费
        */
        props.put(ConsumerConfig.MAX_POLL_INTERVAL_MS_CONFIG, 30 * 1000);
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props);
        // 消费主题
        String topicName = "order-topic";
        //consumer.subscribe(Arrays.asList(topicName));
        // 消费指定分区
        //consumer.assign(Arrays.asList(new TopicPartition(topicName, 0)));

        //消息回溯消费
        consumer.assign(Arrays.asList(new TopicPartition(topicName, 0)));
        consumer.seekToBeginning(Arrays.asList(new TopicPartition(topicName, 0)));
        //指定offset消费
        //consumer.seek(new TopicPartition(topicName, 0), 10);

        while (true) {
            /*
             * poll() API 是拉取消息的长轮询，主要是判断consumer是否还活着，只要我们持续调用poll()，
             * 消费者就会存活在自己所在的group中，并且持续的消费指定partition的消息。
             * 底层是这么做的：消费者向server持续发送心跳，如果一个时间段（session.
             * timeout.ms）consumer挂掉或是不能发送心跳，这个消费者会被认为是挂掉了，
             * 这个Partition也会被重新分配给其他consumer
             */
            ConsumerRecords<String, String> records = consumer.poll(Integer.MAX_VALUE);
            for (ConsumerRecord<String, String> record : records) {
                System.out.printf("收到消息：offset = %d, key = %s, value = %s%n", record.offset(), record.key(),
                        record.value());
            }

            if (records.count() > 0) {
                // 提交offset
                consumer.commitSync();
            }
        }
    }
}
```

## Spring Boot整合Kafka

引入spring boot kafka依赖

```
<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka</artifactId>
</dependency>
```

application.yml配置如下：

```
server:
  port: 8080

spring:
  kafka:
    bootstrap-servers: 192.168.0.60:9092,192.168.0.60:9093
    producer: # 生产者
      retries: 3 # 设置大于0的值，则客户端会将发送失败的记录重新发送
      batch-size: 16384
      buffer-memory: 33554432
      # 指定消息key和消息体的编解码方式
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.apache.kafka.common.serialization.StringSerializer
    consumer:
      group-id: mygroup
      enable-auto-commit: true
```

发送者代码：

```
@RestController
public class KafkaController {

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    @RequestMapping("/send")
    public void send() {
        kafkaTemplate.send("mytopic", 0, "key", "this is a msg");
    }

}
```

消费者代码：

```
@Component
public class MyConsumer {

    /**
     * @KafkaListener(groupId = "testGroup", topicPartitions = {
     *             @TopicPartition(topic = "topic1", partitions = {"0", "1"}),
     *             @TopicPartition(topic = "topic2", partitions = "0",
     *                     partitionOffsets = @PartitionOffset(partition = "1", initialOffset = "100"))
     *     },concurrency = "6")
     *  //concurrency就是同组下的消费者个数，就是并发消费数，必须小于等于分区总数
     * @param record
     */
    @KafkaListener(topics = "mytopic",groupId = "testGroup")
    public void listen(ConsumerRecord<String, String> record) {
        String value = record.value();
        System.out.println(value);
        System.out.println(record);
    }
}
```

# 常用参数配置

## Broker端参数

log.dirs：指定了 Broker 需要 使用的若干个文件目录路径。

auto.create.topics.enable：是否允许自动创建 Topic。

unclean.leader.election.enable：是否允许 Unclean Leader 选举。

**「Unclean 领导者选举（Unclean Leader Election）」**

既然 ISR 是可以动态调整的，那么自然就可以出现这样的情形：ISR 为空。因为 Leader 副 本天然就在 ISR 中，如果 ISR 为空了，就说明 Leader 副本也“挂掉”了，Kafka 需要重新 选举一个新的 Leader。可是 ISR 是空，此时该怎么选举新 Leader 呢？

Kafka 把所有不在 ISR 中的存活副本都称为非同步副本。通常来说，非同步副本落后Leader 太多，因此，如果选择这些副本作为新 Leader，就可能出现数据的丢失。毕竟， 这些副本中保存的消息远远落后于老 Leader 中的消息。在 Kafka 中，选举这种副本的过 程称为 Unclean 领导者选举。

开启 Unclean 领导者选举可能会造成数据丢失，但好处是，它使得分区 Leader 副本一直 存在，不至于停止对外提供服务，因此提升了高可用性。反之，禁止 Unclean 领导者选举 的好处在于维护了数据的一致性，避免了消息丢失，但牺牲了高可用性。

auto.leader.rebalance.enable：是否允许定期进 行 Leader 选举。

auto.create.topics.enable：是否允许自动创建 Topic。

log.retention.hourminutes|ms：都是控制一条消息数据被保存多长时间。从优先 级上来说 ms 设置最高、minutes 次之、hour 最低。

log.retention.bytes：这是指定 Broker 为消息保存 的总磁盘容量大小。

message.max.bytes：控制 Broker 能够接收的最大消 息大小。

## Topic级别参数

Topic 级别参数会覆盖全局 Broker 参数的值，而每个 Topic 都能设置自己的参数值

retention.ms：规定了该 Topic 消息被保存的时长。 默认是 7 天，即该 Topic 只保存最近 7 天的消息。一旦 设置了这个值，它会覆盖掉 Broker 端的全局参数值。

retention.bytes：规定了要为该 Topic 预留多大的磁 盘空间。和全局参数作用相似，这个值通常在多租户的 Kafka 集群中会有用武之地。当前默认值是 -1，表示可以 无限使用磁盘空间。

# 总结

本文是KAFKA相关的最核心基础的知识，基本可以带大家入门了，当然，Kafka还有很多高级特性，如幂等，事务，压缩，流处理等，以及常见的消息丢失，重复，堆积等问题的解决方案和配置，因为篇幅有限，今后会陆续编写相应的文章讲解

![图片](https://mmbiz.qpic.cn/mmbiz_png/hC3oNAJqSRyXloc4TOssA4p3PiabAoWd2WBGmvLg1J6EQaojjL0FvXd1AIfCBqOQ3lbhmL5UlSFY9PH26A0A96g/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

**「觉得不错，记得点赞，转发，分享，谢谢」**