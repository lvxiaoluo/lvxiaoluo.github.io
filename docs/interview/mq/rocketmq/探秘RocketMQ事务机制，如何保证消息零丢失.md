# 探秘RocketMQ事务机制，如何保证消息零丢失

**公众号：慕枫技术笔记**

**真正的大师永远怀着一颗学徒的心**

# 引言

事务的概念就不用多说了，我相信阅读文章的童鞋都是有着非常深刻的认识。我们都知道`MQ`可以实现微服务之间的异步以及解耦，那么引入`MQ`之后，如何实现微服务之间的数据一致性是一个值得思考的问题。RocketMQ事务消息正是解决这个问题的解决方案。另外事务消息也是为了解决消息丢失问题。

# 哪些场景会出现消息丢失

在分析`RocketMQ`事务消息之前，我们先来分析下引入消息中间件之后，整个消息链路在哪些场景会出现消息丢失的异常情况。

当我们支付订单之后，我们账户的购物积分也会进行相应的积分调整。我们结合下面的订单服务、`RocketMQ`、积分服务的简化交互图来看，我们来分析下整个链路中可能会出现的消息丢失问题。

![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/7cca688a46ef40b6ab7cde1859aa19e9~tplv-k3u1fbpfcp-watermark.image)

**场景1：**

在订单服务向RocketMQ发送订单成功生成的消息的时候，可能由于网络抖动的问题导致订单消息没能正常投递到RocketMQ，导致消息丢失。

**场景2：**

那么假如订单服务以及RocketMQ之间的网络没问题，消息正常被RocketMQ接收到了，那么会存在消息丢失的情况吗？答案是肯定的，这和RocketMQ的持久化机制有关系，当消息到达RocketMQ之后，并不是立马落盘存储，而是存储在page cache中的。如果此时出现服务器断电或者宕机情况，那么还没来得及落盘的消息数据就有可能丢失。另外即使是落到磁盘当中，如果出现磁盘坏道的话，依然会出现消息数据的可能。

**场景3：**

如果前面两种场景都没问题，积分服务拿到订单消息了。还会出现消息丢失的问题吗？答案依然是肯定的。即便是积分服务拿到了订单消息，当积分服务自动提交消息offset到RocketMQ中，但是此时如果出现宕机或者积分服务挂了，没有将本该增加的积分进行处理，此时也就出现了消息丢失的情况。

# 事务消息机制原理

## half消息

所谓的`RocketMQ`事务机制，其实是`RocketMQ`提供了一种`half`消息的机制。当订单服务接受到订单支付信息后，订单服务会发送`half`消息到`RocketMQ`中，这个`half`消息是不被消费者所见的。怎么理解这个`half`信息呢，按照我自己的理解，就是它实现了一半的消息功能，只在生产端可见，在消费端不可见。另外这个`half`信息相当于一种`RocketMQ`的可用性探测，如果`half`消息都发送失败的话，就不必再进行下游业务的一系列操作了。

![image.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/0b5e5424457c439891dc2c61c39e4663~tplv-k3u1fbpfcp-watermark.image)

如果此时用于探测RocketMQ的可用性的half消息发送失败了，那么说明此时订单服务与RocketMQ存在异常，则会对之前订单进行一系列的回滚操作。如果half消息被成功投递，则需要进行本地事务操作，更新订单状态。

如果本地事务执行失败了怎么办，订单服务可以发送rollback请求，将之前的half消息从RocketMQ中进行删除，不再进行后续的消息投递。

## half消息原理分析

上文提到`half`消息不被消费端可见，那么这个`half`消息是怎么实现在`RocketMQ`中不被积分服务所见的呢？

订单服务发送`half`消息，实际并不是将消息投递到积分服务订阅的`topic`，而是将消息投递到`RocketMQ`中的`RMQ_SYS_TRANS_HALF_TOPIC`对应的`messeageQueue`。由于积分服务并没有订阅这个`Topic`，所以这个消息对于积分服务是不可见的。

另外有个`OP_TOPIC`用于记录对应`half`消息的`commit/rollback`状态。大致的交互如下如所示：

![image.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/1b91fa04fa634e82b77a01dafd54f9c3~tplv-k3u1fbpfcp-watermark.image)

如果订单服务`half`消息发送失败了，由于网络原因或者`RocketMQ`挂了，那么此时需要执行一些回滚操作，让订单进行关闭。因为订单信息无法通知到下游服务了。

![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/fe458eb58e154d9abf0b4ce90a967f32~tplv-k3u1fbpfcp-watermark.image)

那么如果`half`消息已经写入`RocketMQ`中，但是本地事务执行失败又该怎么办呢？也就是说当订单服务接收到`half`消息写入成功的响应后，更新订单信息时发生了异常，无法完成状态更新。那么此时订单服务需要发送`rollback`的请求给`RocketMQ`，通知其将原来的`half`信息进行删除。如果本地事务执行成功，则需要发送commit请求给`RocketMQ`，`RocketMQ`会将原先存在`RMQ_SYS_TRANS_HALF_TOPIC`中的消息重新投递到积分服务订阅的`TOPIC`中去，这样积分服务就可以正常消费信息进行下一步的积分操作了。

再考虑一种情况，如果订单服务发送`commit`或者`rollback`请求未正常投递到`RocketMQ`中，`RocketMQ`不知道`half`消息到底是对应的本地事务到底是执行成功了还是执行失败了。针对这种情况，订单服务需要提供状态回查接口，`RocketMQ`定时检测是否还有没有处理的`half`消息，当存在这样的消息时，`RocketMQ`调用回查接口确认本地事务执行情况。执行失败的则删除`half`消息，执行成功则重新投递消息。

![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/67ad0afa263e438d97148563467fb113~tplv-k3u1fbpfcp-watermark.image)

# 总结

通过上文的分析，订单服务和`RocketMQ`之间的交互，通过事务消息机制可以保证消息可以被可靠投递。至少在订单服务和`RocketMQ`之间不会出现消息丢失的问题。