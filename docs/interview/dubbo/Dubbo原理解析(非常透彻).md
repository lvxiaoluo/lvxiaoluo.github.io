# Dubbo原理解析(非常透彻)

> **一.概述**

dubbo是一款经典的rpc框架，用来远程调用服务的。

dubbo的作用：

- 面向接口的远程方法调用
- 智能容错和负载均衡
- 服务自动注册和发现。
- 自定义序列化协议

------

Dubbo 架构中的核心角色有哪些？

![图片](https://mmbiz.qpic.cn/mmbiz_png/QoaHqP3fOibaogPePWNbxcT9mGYIVr5xSP51xv9wGTWmO40IdGoNekTyMBts4c8Kuk2IlnsEvDxKKicgazfEOKsA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

- Container**：** 服务运行容器，负责加载、运行服务提供者。必须。
- Provider**：** 暴露服务的服务提供方，会向注册中心注册自己提供的服务。必须。
- Consumer**：** 调用远程服务的服务消费方，会向注册中心订阅自己所需的服务。必须。
- Registry**：** 服务注册与发现的注册中心。注册中心会返回服务提供者地址列表给消费者。非必须。
- Monitor： 统计服务的调用次数和调用时间的监控中心。服务消费者和提供者会定时发送统计数据到监控中心。非必须。

------

Dubbo 中的 Invoker 概念了解么？

- `Invoker` 是 Dubbo 领域模型中非常重要的一个概念，你如果阅读过 Dubbo 源码的话，你会无数次看到这玩意。就比如下面我要说的负载均衡这块的源码中就有大量 `Invoker` 的身影。

- 简单来说，`Invoker` 就是 Dubbo 对远程调用的抽象。分为2种：

- - 服务提供 `Invoker`
  - 服务消费 `Invoker`

- 我们需要调用一个远程方法，我们需要动态代理来屏蔽远程调用的细节吧！我们屏蔽掉的这些细节就依赖对应的 `Invoker` 实现， `Invoker` 实现了真正的远程服务调用

------

Dobbo的分层架构(工作原理)

 ![图片](https://mmbiz.qpic.cn/mmbiz_png/QoaHqP3fOibaogPePWNbxcT9mGYIVr5xSSgiaA9yrdS7aB2h6PvTQQov5Bl5Z7jx7vk82QwXemyWbgm1UwJEwy3A/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

- Service业务层：就是我们写代码的层，我们使用rpc只需要关注该层就行，主要是定义接口和实现类。
- config 配置层：Dubbo 相关的配置。支持代码配置，同时也支持基于 Spring 来做配置，以 `ServiceConfig`, `ReferenceConfig` 为中心
- proxy 服务代理层：调用远程方法像调用本地的方法一样简单的一个关键，真实调用过程依赖代理类，以 `ServiceProxy` 为中心。
- registry 注册中心层：封装服务地址的注册与发现。
- cluster 路由层：封装多个提供者的路由及负载均衡，并桥接注册中心，以 `Invoker` 为中心。
- monitor 监控层：RPC 调用次数和调用时间监控，以 `Statistics` 为中心。
- protocol 远程调用层：封装 RPC 调用，以 `Invocation`, `Result` 为中心。
- exchange 信息交换层：封装请求响应模式，同步转异步，以 `Request`, `Response` 为中心。
- transport 网络传输层：抽象 mina 和 netty 为统一接口，以 `Message` 为中心。
- serialize 数据序列化层 ：对需要在网络传输的数据进行序列化。

>  **二.SPI**

Dubbo 的 SPI 机制了解么？

- SPI（Service Provider Interface） 机制被大量用在开源项目中(比如Dubbo，SpringBoot...)，它可以帮助我们进行功能扩展。
- SPI 的具体原理是这样的：我们将接口的实现类放在配置文件中，我们在程序运行过程中读取配置文件，通过反射加载实现类。这样，我们可以在运行的时候，动态替换接口的实现类。
- 一些配置类就可以使用SPI进行加载，如果我们需要进行扩展，就自定义类放在指定文件夹下。
- Java 本身就提供了 SPI 机制的实现。不过，Dubbo 没有直接用，而是对 Java 原生的 SPI 机制进行了增强，以便更好满足自己的需求。

------

为什么 Dubbo 不用 JDK 的 SPI，而是要自己实现?

- 因为 Java SPI 在查找扩展实现类的时候遍历 SPI 的配置文件并且将实现类全部实例化，假设一个实现类初始化过程比较消耗资源且耗时，但是你的代码里面又用不上它，这就产生了资源的浪费。
- 因此 Dubbo 就自己实现了一个 SPI，给每个实现类配了个名字，通过名字去文件里面找到对应的实现类全限定名然后加载实例化，按需加载。

如果想深入研究Java SPI：请看一位大佬写的文章：[SPI源码分析](http://mp.weixin.qq.com/s?__biz=MzA3NTI4NzY4Ng==&mid=2247484499&idx=1&sn=854cdab5d4b9eba07ec774884e323183&chksm=9f7399baa80410aca96e7b6e057278e5a6966f4f4fc5eec6610f9ae99b1f6a4b3d8fdd37a5c5&scene=21#wechat_redirect)

------

如何扩展 Dubbo 中的默认实现？

-  比如说我们想要实现自己的负载均衡策略，我们创建对应的实现类 `XxxLoadBalance` 实现 `LoadBalance` 接口或者 `AbstractLoadBalance` 类。
- 我们将这个是实现类的路径写入到`resources` 目录下的 `META-INF/dubbo/org.apache.dubbo.rpc.cluster.LoadBalance`文件中即可。

```
public class XxxLoadBalance implements LoadBalance {
    public <T> Invoker<T> select(List<Invoker<T>> invokers, Invocation invocation) throws RpcException {
        // ...
    }
}
```

>  **三.Dubbo 的负载均衡策略**

- RandomLoadBalance：随机。随机的选择一个。是Dubbo的**默认**负载均衡策略。(加权/不加权)
- RoundRobinLoadBalance：轮询。轮询选择一个。(加权/不加权)
- LeastActiveLoadBalance：最少活跃数。每个服务维护一个活跃数计数器。当A机器开始处理请求，该计数器加1，此时A还未处理完成。若处理完毕则计数器减1。而B机器接受到请求后很快处理完毕。那么A,B的活跃数分别是1，0。当又产生了一个新的请求，则选择B机器去执行(B活跃数最小)，这样使慢的机器A收到少的请求。
- ConsistentHashLoadBalance：一致性哈希。相同参数的请求总是落在同一台机器上。

> **四.服务暴露，服务引用，服务调用过程**

服务暴露**：**生成代理类**，**将信息注册到ZK

- 组装URL：Spring IOC 容器刷新完毕之后，会根据配置参数组装成 URL， 然后根据 URL 的参数来进行代理类的生成。

- 生成代理类：会通过 `proxyFactory.getInvoker`，利用 javassist 来进行动态代理，封装真的实现类。

- 根据协议生成暴露对象(exporter)：通过 URL 参数选择对应的协议来进行 protocol.export，默认是 Dubbo 协议。

- - 自适应：代理类会根据 Invoker 里面的 URL 参数得知具体的协议，然后通过 Dubbo SPI 机制选择对应的实现类进行 export。

- 注册到ZK：将 export 得到的 exporter 存入一个 Map 中，供之后的远程调用查找，然后会向注册中心注册提供者的信息。

![图片](https://mmbiz.qpic.cn/mmbiz_png/QoaHqP3fOibaogPePWNbxcT9mGYIVr5xSj5bQUYFSj9CVkdRC5lVv8X0Dw8qkobTPmC31eIopaeloKAZenCictrA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

 想要深究源码的小伙伴可以看一位大佬写的文章：[服务暴露源码分析](http://mp.weixin.qq.com/s?__biz=MzA3NTI4NzY4Ng==&mid=2247484602&idx=1&sn=c634cb1349771693f366818f45a9db93&chksm=9f739953a80410451b292b678977ae00c171ff29824129e25208b9bfb24b897861dac3ae1f14&scene=21#wechat_redirect)

------

 服务引用：获取远程调用的类，生成代理类。可以看作服务引用的逆过程。

- 组装URL：会根据配置参数组装成 URL， 然后根据 URL 的参数来进行代理类的生成。(2种时机)

- - 在应用的Spring Context初始化完成事件时触发，扫描所有的Bean，将Bean中带有@Reference注解的field获取到，然后创建field类型的代理对象，创建完成后，将代理对象set给此field。后续就通过该代理对象创建服务端连接，并发起调用。(dubbo默认)
  - 饿汉式：饿汉式是通过实现 Spring 的`InitializingBean`接口中的 `afterPropertiesSet`方法，容器通过调用 `ReferenceBean`的 `afterPropertiesSet`方法时引入服务。(在Spring启动时，给所有的属性注入实现类，包含远程和本地的实现类)
  - 懒汉式：只有当这个服务被注入到其他类中时启动引入流程，也就是说用到了才会开始服务引入。

- 从ZK中获取需要的服务提供者的信息：得到Map。

- 根据协议解析传过来的exporter：

- - 协议的不同，获取的路径也不同：本地，直接，从ZK。

![图片](https://mmbiz.qpic.cn/mmbiz_png/QoaHqP3fOibaogPePWNbxcT9mGYIVr5xSCYzbtJnqkGj7eqCwkl159SW1Vov8ykkCEemFWib7NFvhkpdJuBHd6gg/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

- 生成代理类：供消费者使用Netty进行远程调用。invoker。

![图片](https://mmbiz.qpic.cn/mmbiz_png/QoaHqP3fOibaogPePWNbxcT9mGYIVr5xSnY77Xt2FibUgib9uIQaF6LG2pmh9rRhpchop4dV8icSeFjEiaZmyTsvbYw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

 想要深究源码的小伙伴可以看一位大佬写的文章：。

------

服务调用：

- 服务调用是在生成代理对象后，使用Netty，生成Netty Client进行远程调用。Netty Server通过反射返回调用结果。

- 在调用之前，就会进行智能容错和负载均衡。

- - 首先客户端调用接口的某个方法，实际调用的是代理类，代理类会通过 cluster 从 directory(invoker的集合) 中获取一堆 invokers(如果有一堆的话)，然后进行 router 的过滤（其中看配置也会添加 mockInvoker 用于服务降级），然后再通过 SPI 得到 loadBalance 进行一波负载均衡。

补充：cluster 是什么？

- 一个中间层，为消费者屏蔽了服务提供者的情况，简化了消费者的使用。
- 它可以负责选择哪个invoker返回给调用者，比如选择一个 invoker ，调用出错了可以换一个等等。

想要深究源码的小伙伴可以看一位大佬写的文章：[Dubbo远程调用过程](http://mp.weixin.qq.com/s?__biz=MzA3NTI4NzY4Ng==&mid=2247484655&idx=1&sn=833dd4a1af6c04224e73f8f18b56a1d4&chksm=9f739906a8041010ae155b25a14c8a1a76d814cef60ea7fc574b209eae86e0493bce1c62edd9&scene=21#wechat_redirect)。

------

容错机制：先容错，再负载均衡。

- 首先在服务引入的时候，将多个远程调用都塞入 Directory 中，然后通过 Cluster 来封装这个目录，封装的同时提供各种容错功能，比如 FailOver、FailFast 等等，最终暴露给消费者的就是一个 invoker。
- 然后消费者调用的时候会目录里面得到 invoker 列表，当然会经过路由的过滤，得到这些 invokers 之后再由 loadBalance 来进行负载均衡选择一个 invoker，最终发起调用。

dubbo常见的容错机制

- Failover Cluster(默认)

- - 失败自动切换，当出现失败，重试其它服务器。
  - 通常用于读操作，但重试会带来更长延迟。

- Failfast Cluster

- - 快速失败，只发起一次调用，失败立即报错。
  - 通常用于非幂等性的写操作，比如新增记录。

- Failsafe Cluster

- - 失败安全，出现异常时，直接忽略。
  - 通常用于写入审计日志等操作。

- Failback Cluster

- - 失败自动恢复，后台记录失败请求，定时重发。
  - 通常用于消息通知操作。

- Forking Cluster

- - 并行调用多个服务器，只要一个成功即返回。
  - 通常用于实时性要求较高的读操作，但需要浪费更多服务资源。

 想要深究源码的小伙伴可以看一位大佬写的文章：[Dubbo集群容错 - 容错机制的实现](http://mp.weixin.qq.com/s?__biz=MzA3NTI4NzY4Ng==&mid=2247484862&idx=1&sn=79726016912897720bf8769ca593b784&chksm=9f739857a80411418c87b4a7f56323ab1b8c77a86f10712f18a747a3834ff65183bc58761ebd&scene=21#wechat_redirect)

> **五.其他小问题**

Dubbo 为什么默认用 Javassist？

- 很简单，就是快，且字节码生成方便。

- 其他常见的动态代理：JDK 的动态代理、ASM、cglib。

- - ASM 比 Javassist 更快，但是没有快一个数量级，而Javassist 只需用字符串拼接就可以生成字节码，而 ASM 需要手工生成，成本较高，比较麻烦。

------

Dubbo 支持多种序列化方式?

- JDK 自带的序列化：不支持跨语言调用 ；性能差
- JSON：性能差
- ProtoBuf ：支持跨语言
- hessian2(默认)：支持跨语言
- Protostuff：支持跨语言
- Kryo：新引入的，只支持JAVA
- FST：新引入的，只支持JAVA

 

寄语：我们愈是学习，愈觉得自己的贫乏。 