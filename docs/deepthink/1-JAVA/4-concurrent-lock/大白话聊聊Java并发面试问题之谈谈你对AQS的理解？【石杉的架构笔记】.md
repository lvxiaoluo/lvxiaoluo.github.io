# 大白话聊聊Java并发面试问题之谈谈你对AQS的理解？【石杉的架构笔记】

上一篇文章聊了一下java并发中常用的原子类的原理和Java 8的优化，具体请参见文章：[《大白话聊聊Java并发面试问题之Java 8如何优化CAS性能？》](http://mp.weixin.qq.com/s?__biz=MzU0OTk3ODQ3Ng==&mid=2247484070&idx=1&sn=c1d49bce3c9da7fcc7e057d858e21d69&chksm=fba6eaa5ccd163b3a935303f10a54a38f15f3c8364c7c1d489f0b1aa1b2ef293a35c565d2fda&scene=21#wechat_redirect)。



这篇文章，我们来聊聊面试的时候比较有杀伤力的一个问题：**聊聊你对AQS的理解？**

之前有同学反馈，去互联网公司面试，面试官聊到并发时就问到了这个问题。当时那位同学内心估计受到了一万点伤害。。。

因为首先，很多人还真的连AQS是什么都不知道，可能听都没听说过。或者有的人听说过AQS这个名词，但是可能连具体全称怎么拼写都不知道。

更有甚者，可能会说：AQS？是不是一种思想？我们平时开发怎么来用AQS？

总体来说，很多同学估计都对AQS有一种云里雾里的感觉，如果用搜索引擎查一下AQS是什么？看几篇文章，估计就直接放弃了，因为密密麻麻的文字，实在是看不懂！

所以，基于上述痛点，咱们这篇文章，就用最简单的大白话配合N多张手绘图，给大家讲清楚AQS到底是什么？让各位同学面试被问到这个问题时，不至于不知所措。



**二、ReentrantLock和AQS的关系**

首先我们来看看，如果用java并发包下的ReentrantLock来加锁和释放锁，是个什么样的感觉？

这个基本学过java的同学应该都会吧，毕竟这个是java并发基本API的使用，应该每个人都是学过的，所以我们直接看一下代码就好了：



![图片](https://mmbiz.qpic.cn/mmbiz_png/1J6IbIcPCLa768DWZMrExHMwlVcn3Nw0bGzw4wxwpt1NZFbkeo6Ngp8OnribTzA07KMLuwuRRMqjhY6epzweAQQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)



上面那段代码应该不难理解吧，无非就是搞一个Lock对象，然后加锁和释放锁。



你这时可能会问，这个跟AQS有啥关系？关系大了去了！因为java并发包下很多API都是基于AQS来实现的加锁和释放锁等功能的，AQS是java并发包的基础类。



举个例子，比如说ReentrantLock、ReentrantReadWriteLock底层都是基于AQS来实现的。



那么AQS的全称是什么呢？**AbstractQueuedSynchronizer，抽象队列同步器**。给大家画一个图先，看一下ReentrantLock和AQS之间的关系。

![图片](https://mmbiz.qpic.cn/mmbiz_png/1J6IbIcPCLa768DWZMrExHMwlVcn3Nw0lvMlWkGrT1YiacaaYep4PWDo6UziahxaibvbL1b0RBvmdgicbPEjoWAGxA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

我们来看上面的图。说白了，ReentrantLock内部包含了一个AQS对象，也就是AbstractQueuedSynchronizer类型的对象。这个AQS对象就是ReentrantLock可以实现加锁和释放锁的关键性的核心组件。



**三、ReentrantLock加锁和释放锁的底层原理**



好了，那么现在如果有一个线程过来尝试用ReentrantLock的lock()方法进行加锁，会发生什么事情呢？



很简单，这个AQS对象内部有一个核心的变量叫做**state**，是int类型的，代表了**加锁的状态**。初始状态下，这个state的值是0。



另外，这个AQS内部还有一个**关键变量**，用来记录**当前加锁的是哪个线程**，初始化状态下，这个变量是null。

![图片](https://mmbiz.qpic.cn/mmbiz_png/1J6IbIcPCLa768DWZMrExHMwlVcn3Nw0IFickxjMRgoNfVClw7rsc3kLhnmsJqXFVflDwQKSryQlBjMwkw2wOgQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

接着线程1跑过来调用ReentrantLock的lock()方法尝试进行加锁，这个加锁的过程，直接就是用CAS操作将state值从0变为1。



如果不知道CAS是啥的，请看上篇文章，[《大白话聊聊Java并发面试问题之Java 8如何优化CAS性能？》](http://mp.weixin.qq.com/s?__biz=MzU0OTk3ODQ3Ng==&mid=2247484070&idx=1&sn=c1d49bce3c9da7fcc7e057d858e21d69&chksm=fba6eaa5ccd163b3a935303f10a54a38f15f3c8364c7c1d489f0b1aa1b2ef293a35c565d2fda&scene=21#wechat_redirect)



如果之前没人加过锁，那么state的值肯定是0，此时线程1就可以加锁成功。



一旦线程1加锁成功了之后，就可以设置当前加锁线程是自己。所以大家看下面的图，就是线程1跑过来加锁的一个过程。

![图片](https://mmbiz.qpic.cn/mmbiz_png/1J6IbIcPCLa768DWZMrExHMwlVcn3Nw0cXGXRFa106UuOhjsmodJfqcRBlYx5Z0tfW011ehnoDxdcVR9Xk627Q/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)



其实看到这儿，大家应该对所谓的AQS有感觉了。说白了，就是并发包里的一个核心组件，里面有state变量、加锁线程变量等核心的东西，维护了加锁状态。



你会发现，ReentrantLock这种东西只是一个外层的API，**内核中的锁机制实现都是依赖AQS组件的**。



这个ReentrantLock之所以用Reentrant打头，意思就是他是一个可重入锁。



可重入锁的意思，就是你可以对一个ReentrantLock对象多次执行lock()加锁和unlock()释放锁，也就是可以对一个锁加多次，叫做可重入加锁。



大家看明白了那个state变量之后，就知道了如何进行可重入加锁！



其实每次线程1可重入加锁一次，会判断一下当前加锁线程就是自己，那么他自己就可以可重入多次加锁，每次加锁就是把state的值给累加1，别的没啥变化。



接着，如果线程1加锁了之后，线程2跑过来加锁会怎么样呢？



**我们来看看锁的互斥是如何实现的？**线程2跑过来一下看到，哎呀！state的值不是0啊？所以CAS操作将state从0变为1的过程会失败，因为state的值当前为1，说明已经有人加锁了！



接着线程2会看一下，是不是自己之前加的锁啊？当然不是了，**“加锁线程”**这个变量明确记录了是线程1占用了这个锁，所以线程2此时就是加锁失败。



给大家来一张图，一起来感受一下这个过程：

![图片](https://mmbiz.qpic.cn/mmbiz_png/1J6IbIcPCLa768DWZMrExHMwlVcn3Nw0LtGCxkTaBFK8pm6ian7lRUGc0Phniaibfyg1UJojxajs4nJUcq5Q0YqXQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)





接着，线程2会将自己放入AQS中的一个等待队列，因为自己尝试加锁失败了，此时就要将自己放入队列中来等待，等待线程1释放锁之后，自己就可以重新尝试加锁了



所以大家可以看到，AQS是如此的核心！AQS内部还有一个等待队列，专门放那些加锁失败的线程！



同样，给大家来一张图，一起感受一下：

![图片](https://mmbiz.qpic.cn/mmbiz_png/1J6IbIcPCLa768DWZMrExHMwlVcn3Nw0nHWvYETmSkZffNUKw9RrzAQA5Z4m0BUcBMqRWgv0yG2L3ezW86ic1PQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)



接着，线程1在执行完自己的业务逻辑代码之后，就会释放锁！**他释放锁的过程非常的简单**，就是将AQS内的state变量的值递减1，如果state值为0，则彻底释放锁，会将“加锁线程”变量也设置为null！



整个过程，参见下图：

![图片](https://mmbiz.qpic.cn/mmbiz_png/1J6IbIcPCLa768DWZMrExHMwlVcn3Nw0dwBI8k2icGZETibUZowsia54nB3sHFXRQDkjbHWNvpY6kBI5V4bbiae1bQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)





接下来，会从**等待队列的队头唤醒线程2重新尝试加锁。**



好！线程2现在就重新尝试加锁，这时还是用CAS操作将state从0变为1，此时就会成功，成功之后代表加锁成功，就会将state设置为1。



此外，还要把**“加锁线程”**设置为线程2自己，同时线程2自己就从等待队列中出队了。



最后再来一张图，大家来看看这个过程。

![图片](https://mmbiz.qpic.cn/mmbiz_png/1J6IbIcPCLa768DWZMrExHMwlVcn3Nw0wvO5PVEbulcYWKaqPXKEzr5fONBeUjZic0LdFibp8Khw31pemSibnlsMw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)









**四、总结**

OK，本文到这里为止，基本借着ReentrantLock的加锁和释放锁的过程，给大家讲清楚了其底层依赖的AQS的核心原理。

基本上大家把这篇文章看懂，以后再也不会担心面试的时候被问到：谈谈你对AQS的理解这种问题了。

其实一句话总结**AQS就是一个并发包的基础组件，用来实现各种锁，各种同步组件的。**  v** 它包含了state变量、加锁线程、等待队列等并发中的核心组件。**



[本文地址](https://mp.weixin.qq.com/s?__biz=MzU0OTk3ODQ3Ng==&mid=2247484094&idx=1&sn=b337161f934b1c27ff1f059350ef5e65&chksm=fba6eabdccd163abc8978b65e155d79a133f20ee8a5bff79a33ed20a050c2bd576581db69fe6&mpshare=1&scene=1&srcid=0608yIcfsyrDG1NIBSsF58jq%23rd)