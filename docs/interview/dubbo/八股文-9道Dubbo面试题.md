# 《八股文》9道Dubbo面试题

Dubbo本身并不复杂，而且官方文档写的非常清楚详细，面试中dubbo的问题一般不会很多，从分层到工作原理、负载均衡策略、容错机制、SPI机制基本就差不多了，最大的一道大题一般就是怎么设计一个RPC框架了，但是如果你工作原理分层都搞明白了这个问题其实也就相当于回答了不是吗。

## 说说Dubbo的分层？

从大的范围来说，dubbo分为三层，business业务逻辑层由我们自己来提供接口和实现还有一些配置信息，RPC层就是真正的RPC调用的核心层，封装整个RPC的调用过程、负载均衡、集群容错、代理，remoting则是对网络传输协议和数据转换的封装。

划分到更细的层面，就是图中的10层模式，整个分层依赖由上至下，除开business业务逻辑之外，其他的几层都是SPI机制。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/ibBMVuDfkZUnmqYcY60pNmbWxW01EYSbe5WTfSm0etrwxU3oXeaAeu4x6OhicoPMeVSOfoic00ankhtGxVibYicbuPA/640?wx_fmt=jpeg&tp=wxpic&wxfrom=5&wx_lazy=1&wx_co=1)

## 能说下Dubbo的工作原理吗？

1. 服务启动的时候，provider和consumer根据配置信息，连接到注册中心register，分别向注册中心注册和订阅服务
2. register根据服务订阅关系，返回provider信息到consumer，同时consumer会把provider信息缓存到本地。如果信息有变更，consumer会收到来自register的推送
3. consumer生成代理对象，同时根据负载均衡策略，选择一台provider，同时定时向monitor记录接口的调用次数和时间信息
4. 拿到代理对象之后，consumer通过代理对象发起接口调用
5. provider收到请求后对数据进行反序列化，然后通过代理调用具体的接口实现

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/ibBMVuDfkZUnmqYcY60pNmbWxW01EYSbeUsCibyAOzMW6bHnMPsoUOEBHe9ZVNb3sQnu0MVrAYPib55rMZ2AlMMcg/640?wx_fmt=jpeg&tp=wxpic&wxfrom=5&wx_lazy=1&wx_co=1)

## 为什么要通过代理对象通信？

主要是为了实现接口的透明代理，封装调用细节，让用户可以像调用本地方法一样调用远程方法，同时还可以通过代理实现一些其他的策略，比如：

1、调用的负载均衡策略

2、调用失败、超时、降级和容错机制

3、做一些过滤操作，比如加入缓存、mock数据

4、接口调用数据统计

## 说说服务暴露的流程？

1. 在容器启动的时候，通过ServiceConfig解析标签，创建dubbo标签解析器来解析dubbo的标签，容器创建完成之后，触发ContextRefreshEvent事件回调开始暴露服务
2. 通过ProxyFactory获取到invoker，invoker包含了需要执行的方法的对象信息和具体的URL地址
3. 再通过DubboProtocol的实现把包装后的invoker转换成exporter，然后启动服务器server，监听端口
4. 最后RegistryProtocol保存URL地址和invoker的映射关系，同时注册到服务中心

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/ibBMVuDfkZUnmqYcY60pNmbWxW01EYSbeepGx1CibegWKMty6tcQfWH50kH07H15d6ibwTAzrib0icgoaw9TzFBSqRg/640?wx_fmt=jpeg&tp=wxpic&wxfrom=5&wx_lazy=1&wx_co=1)

## 说说服务引用的流程？

服务暴露之后，客户端就要引用服务，然后才是调用的过程。

1. 首先客户端根据配置文件信息从注册中心订阅服务

2. 之后DubboProtocol根据订阅的得到provider地址和接口信息连接到服务端server，开启客户端client，然后创建invoker

3. invoker创建完成之后，通过invoker为服务接口生成代理对象，这个代理对象用于远程调用provider，服务的引用就完成了

   ![图片](https://mmbiz.qpic.cn/mmbiz_jpg/ibBMVuDfkZUnmqYcY60pNmbWxW01EYSbex1hL19GwTGKxhXndfE5EU8Q4PticgA52SWZ89y7EzkKee4iawibCiad8YQ/640?wx_fmt=jpeg&tp=wxpic&wxfrom=5&wx_lazy=1&wx_co=1)

## 有哪些负载均衡策略？

1. 加权随机：假设我们有一组服务器 servers = [A, B, C]，他们对应的权重为 weights = [5, 3, 2]，权重总和为10。现在把这些权重值平铺在一维坐标值上，[0, 5) 区间属于服务器 A，[5, 8) 区间属于服务器 B，[8, 10) 区间属于服务器 C。接下来通过随机数生成器生成一个范围在 [0, 10) 之间的随机数，然后计算这个随机数会落到哪个区间上就可以了。
2. 最小活跃数：每个服务提供者对应一个活跃数 active，初始情况下，所有服务提供者活跃数均为0。每收到一个请求，活跃数加1，完成请求后则将活跃数减1。在服务运行一段时间后，性能好的服务提供者处理请求的速度更快，因此活跃数下降的也越快，此时这样的服务提供者能够优先获取到新的服务请求。
3. 一致性hash：通过hash算法，把provider的invoke和随机节点生成hash，并将这个 hash 投射到 [0, 2^32 - 1] 的圆环上，查询的时候根据key进行md5然后进行hash，得到第一个节点的值大于等于当前hash的invoker。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/ibBMVuDfkZUnmqYcY60pNmbWxW01EYSbeqIx4aoPVoQ0mEn0ZWnicgI01U55t6PMj4Q3TakKYHB1jJHg1OhAzEKg/640?wx_fmt=jpeg&tp=wxpic&wxfrom=5&wx_lazy=1&wx_co=1)图片来自dubbo官方

1. 加权轮询：比如服务器 A、B、C 权重比为 5:2:1，那么在8次请求中，服务器 A 将收到其中的5次请求，服务器 B 会收到其中的2次请求，服务器 C 则收到其中的1次请求。

## 集群容错方式有哪些？

1. Failover Cluster失败自动切换：dubbo的默认容错方案，当调用失败时自动切换到其他可用的节点，具体的重试次数和间隔时间可用通过引用服务的时候配置，默认重试次数为1也就是只调用一次。
2. Failback Cluster失败自动恢复：在调用失败，记录日志和调用信息，然后返回空结果给consumer，并且通过定时任务每隔5秒对失败的调用进行重试
3. Failfast Cluster快速失败：只会调用一次，失败后立刻抛出异常
4. Failsafe Cluster失败安全：调用出现异常，记录日志不抛出，返回空结果
5. Forking Cluster并行调用多个服务提供者：通过线程池创建多个线程，并发调用多个provider，结果保存到阻塞队列，只要有一个provider成功返回了结果，就会立刻返回结果
6. Broadcast Cluster广播模式：逐个调用每个provider，如果其中一台报错，在循环调用结束后，抛出异常。

## 了解Dubbo SPI机制吗？

SPI 全称为 Service Provider Interface，是一种服务发现机制，本质是将接口实现类的全限定名配置在文件中，并由服务加载器读取配置文件，加载实现类，这样可以在运行时，动态为接口替换实现类。

Dubbo也正是通过SPI机制实现了众多的扩展功能，而且dubbo没有使用java原生的SPI机制，而是对齐进行了增强和改进。

SPI在dubbo应用很多，包括协议扩展、集群扩展、路由扩展、序列化扩展等等。

使用方式可以在META-INF/dubbo目录下配置：

```
key=com.xxx.value
```

然后通过dubbo的ExtensionLoader按照指定的key加载对应的实现类，这样做的好处就是可以按需加载，性能上得到优化。

## 如果让你实现一个RPC框架怎么设计？

1. 首先需要一个服务注册中心，这样consumer和provider才能去注册和订阅服务
2. 需要负载均衡的机制来决定consumer如何调用客户端，这其中还当然要包含容错和重试的机制
3. 需要通信协议和工具框架，比如通过http或者rmi的协议通信，然后再根据协议选择使用什么框架和工具来进行通信，当然，数据的传输序列化要考虑
4. 除了基本的要素之外，像一些监控、配置管理页面、日志是额外的优化考虑因素。

那么，本质上，只要熟悉一两个RPC框架，就很容易想明白我们自己要怎么实现一个RPC框架。

**END**