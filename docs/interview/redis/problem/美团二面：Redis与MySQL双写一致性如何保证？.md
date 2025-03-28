## 美团二面：Redis与MySQL双写一致性如何保证？

## **前言**

四月份的时候，有位好朋友去美团面试。他说，被问到Redis与MySQL双写一致性如何保证？这道题其实就是在问缓存和数据库在双写场景下，一致性是如何保证的？本文将跟大家一起来探讨如何回答这个问题。

![图片](https://mmbiz.qpic.cn/mmbiz_png/PoF8jo1Pmpzr8VflicsVn7fr1ksck7SCRHLOO7rkqKpuUVApd6OqOhyTyQrRYrE4cOmo5HgPZunajON2lb9E6ZA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

- 公众号：**捡田螺的小男孩**

## **谈谈一致性**

![图片](https://mmbiz.qpic.cn/mmbiz_png/PoF8jo1Pmpzr8VflicsVn7fr1ksck7SCRS99F4S1uorz4BGI1I5sv0WYenLTgREsCMMtMwxEHs5Adykt6xZP47g/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

一致性就是数据保持一致，在分布式系统中，可以理解为多个节点中数据的值是一致的。

- **强一致性**：这种一致性级别是最符合用户直觉的，它要求系统写入什么，读出来的也会是什么，用户体验好，但实现起来往往对系统的性能影响大
- **弱一致性**：这种一致性级别约束了系统在写入成功后，不承诺立即可以读到写入的值，也不承诺多久之后数据能够达到一致，但会尽可能地保证到某个时间级别（比如秒级别）后，数据能够达到一致状态
- **最终一致性**：最终一致性是弱一致性的一个特例，系统会保证在一定时间内，能够达到一个数据一致的状态。这里之所以将最终一致性单独提出来，是因为它是弱一致性中非常推崇的一种一致性模型，也是业界在大型分布式系统的数据一致性上比较推崇的模型

## **三个经典的缓存模式**

缓存可以提升性能、缓解数据库压力，但是使用缓存也会导致数据**不一致性**的问题。一般我们是如何使用缓存呢？有三种经典的缓存使用模式：

- Cache-Aside Pattern
- Read-Through/Write-through
- Write-behind

### Cache-Aside Pattern

Cache-Aside Pattern，即**旁路缓存模式**，它的提出是为了尽可能地解决缓存与数据库的数据不一致问题。

#### Cache-Aside读流程

**Cache-Aside Pattern**的读请求流程如下：

![图片](https://mmbiz.qpic.cn/mmbiz_png/PoF8jo1Pmpzr8VflicsVn7fr1ksck7SCRAZ68JX9LyG7LT6bJfOHgWhbeXypQd0RE3LcicVxian4UtLW1enj6icCkw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)
Cache-Aside
读请求

1. 读的时候，先读缓存，缓存命中的话，直接返回数据
2. 缓存没有命中的话，就去读数据库，从数据库取出数据，放入缓存后，同时返回响应。

#### Cache-Aside 写流程

**Cache-Aside Pattern**的写请求流程如下：

![图片](https://mmbiz.qpic.cn/mmbiz_png/PoF8jo1Pmpzr8VflicsVn7fr1ksck7SCR6HyLYMqNc3o0JAQaSaLqhThRAtNml8mNqBpTDRNAicAXOkakeE00bkA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)
Cache-Aside
写请求

更新的时候，先**更新数据库，然后再删除缓存**。

### Read-Through/Write-Through（读写穿透）

**Read/Write-Through**模式中，服务端把缓存作为主要数据存储。应用程序跟数据库缓存交互，都是通过**抽象缓存层**完成的。

#### Read-Through

**Read-Through**的简要流程如下

![图片](https://mmbiz.qpic.cn/mmbiz_png/PoF8jo1Pmpzr8VflicsVn7fr1ksck7SCRNg934JicTpmXwHn9orTn4dSYzxF4nA5bAvS78OSylNrTBSr9A7icL74Q/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)
Read-Through
简要流程

1. 从缓存读取数据，读到直接返回
2. 如果读取不到的话，从数据库加载，写入缓存后，再返回响应。

这个简要流程是不是跟**Cache-Aside**很像呢？其实**Read-Through**就是多了一层**Cache-Provider**而已，流程如下：

![图片](https://mmbiz.qpic.cn/mmbiz_png/PoF8jo1Pmpzr8VflicsVn7fr1ksck7SCRcUc7P99fMX2P9zHice4nB6S4crMdIOKt7euG6tPFbdRdshVPT7wSDWA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

Read-Through流程

Read-Through实际只是在**Cache-Aside**之上进行了一层封装，它会让程序代码变得更简洁，同时也减少数据源上的负载。

#### Write-Through

**Write-Through**模式下，当发生写请求时，也是由**缓存抽象层**完成数据源和缓存数据的更新,流程如下：![图片](https://mmbiz.qpic.cn/mmbiz_png/PoF8jo1Pmpzr8VflicsVn7fr1ksck7SCRcOlpgny0miaY8Cll4uAsv96WO1JdBjiaqYUv2TX2XiaP2ZicSDJ99GOS1A/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

### Write-behind （异步缓存写入）

**Write-behind** 跟Read-Through/Write-Through有相似的地方，都是由**Cache Provider**来负责缓存和数据库的读写。它们又有个很大的不同：**Read/Write-Through**是同步更新缓存和数据的，**Write-Behind**则是只更新缓存，不直接更新数据库，通过**批量异步**的方式来更新数据库。

![图片](https://mmbiz.qpic.cn/mmbiz_png/PoF8jo1Pmpzr8VflicsVn7fr1ksck7SCRfbHibY85ws4ejO2iaCEGuJicXYKIqt4gpdxVsqdxFksutMl0TwGKicdrrw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)
Write behind 流程

这种方式下，缓存和数据库的一致性不强，**对一致性要求高的系统要谨慎使用**。但是它适合频繁写的场景，MySQL的**InnoDB Buffer Pool机制**就使用到这种模式。

## **操作缓存的时候，到底是删除缓存呢，还是更新缓存？**

日常开发中，我们一般使用的就是**Cache-Aside**模式。有些小伙伴可能会问， **Cache-Aside**在写入请求的时候，为什么是**删除缓存而不是更新缓存**呢？

![图片](https://mmbiz.qpic.cn/mmbiz_png/PoF8jo1Pmpzr8VflicsVn7fr1ksck7SCRjKRUkFM9hicTx41HbEF3ag8E1w3sTSAPArSrWukm2mgHBHqiczEK29Pg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)
Cache-Aside写入流程

我们在操作缓存的时候，到底应该删除缓存还是更新缓存呢？我们先来看个例子：

![图片](https://mmbiz.qpic.cn/mmbiz_png/PoF8jo1Pmpzr8VflicsVn7fr1ksck7SCRQ6w0X82sktmFkLHHUK7ib6giczGKYgflkUJC0flDDGsficibpCLU6B1u4g/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

1. 线程A先发起一个写操作，第一步先更新数据库
2. 线程B再发起一个写操作，第二步更新了数据库
3. 由于网络等原因，线程B先更新了缓存
4. 线程A更新缓存。

这时候，缓存保存的是A的数据（老数据），数据库保存的是B的数据（新数据），数据**不一致**了，脏数据出现啦。如果是**删除缓存取代更新缓存**则不会出现这个脏数据问题。

**更新缓存相对于删除缓存**，还有两点劣势：

- 如果你写入的缓存值，是经过复杂计算才得到的话。更新缓存频率高的话，就浪费性能啦。
- 在写数据库场景多，读数据场景少的情况下，数据很多时候还没被读取到，又被更新了，这也浪费了性能呢(实际上，写多的场景，用缓存也不是很划算的,哈哈)

## **双写的情况下，先操作数据库还是先操作缓存？**

`Cache-Aside`缓存模式中，有些小伙伴还是会有疑问，在写请求过来的时候，为什么是**先操作数据库呢**？为什么**不先操作缓存**呢？

假设有A、B两个请求，请求A做更新操作，请求B做查询读取操作。![图片](https://mmbiz.qpic.cn/mmbiz_png/PoF8jo1Pmpzr8VflicsVn7fr1ksck7SCR5feBdDendzWqLo1AjBdmoPPiaVROOOnvbyia7QxeomOy863JlrlxHTBw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

1. 线程A发起一个写操作，第一步del cache
2. 此时线程B发起一个读操作，cache miss
3. 线程B继续读DB，读出来一个老数据
4. 然后线程B把老数据设置入cache
5. 线程A写入DB最新的数据

酱紫就有问题啦，**缓存和数据库的数据不一致了。缓存保存的是老数据，数据库保存的是新数据**。因此，Cache-Aside缓存模式，选择了先操作数据库而不是先操作缓存。

- 个别小伙伴可能会问，先操作数据库再操作缓存，不一样也会导致数据不一致嘛？它俩又不是原子性操作的。这个是**会的**，但是这种方式，一般因为删除缓存失败等原因，才会导致脏数据，这个概率就很低。小伙伴们可以画下操作流程图，自己先分析下哈。接下来我们再来分析这种**删除缓存失败**的情况，**如何保证一致性**。

## **数据库和缓存数据保持强一致，可以嘛？**

实际上，没办法做到数据库与缓存**绝对的一致性**。

- 加锁可以嘛？并发写期间加锁，任何读操作不写入缓存？
- 缓存及数据库封装CAS乐观锁，更新缓存时通过lua脚本？
- 分布式事务，3PC？TCC？

其实，这是由**CAP理论**决定的。缓存系统适用的场景就是非强一致性的场景，它属于CAP中的AP。**个人觉得，追求绝对一致性的业务场景，不适合引入缓存**。

> ★
>
> CAP理论，指的是在一个分布式系统中， Consistency（一致性）、 Availability（可用性）、Partition tolerance（分区容错性），三者不可得兼。
>
> ”

但是，通过一些方案优化处理，是可以**保证弱一致性，最终一致性**的。

## **3种方案保证数据库与缓存的一致性**

### 缓存延时双删

有些小伙伴可能会说，并不一定要先操作数据库呀，采用**缓存延时双删**策略，就可以保证数据的一致性啦。什么是延时双删呢？

![图片](https://mmbiz.qpic.cn/mmbiz_png/PoF8jo1Pmpzr8VflicsVn7fr1ksck7SCRx1UG6aQZibAnC9yS5UezHXE4H8QXN9ahFyVxbPwiaPRXtm96logZpSAA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)
延时双删流程

1. 先删除缓存
2. 再更新数据库
3. 休眠一会（比如1秒），再次删除缓存。

这个休眠一会，一般多久呢？都是1秒？

> ★
>
> 这个休眠时间 =  读业务逻辑数据的耗时 + 几百毫秒。为了确保读请求结束，写请求可以删除读请求可能带来的缓存脏数据。
>
> ”

这种方案还算可以，只有休眠那一会（比如就那1秒），可能有脏数据，一般业务也会接受的。但是如果**第二次删除缓存失败**呢？缓存和数据库的数据还是可能不一致，对吧？给Key设置一个自然的expire过期时间，让它自动过期怎样？那业务要接受**过期时间**内，数据的不一致咯？还是有其他更佳方案呢？

### 删除缓存重试机制

不管是**延时双删**还是**Cache-Aside的先操作数据库再删除缓存**，都可能会存在第二步的删除缓存失败，导致的数据不一致问题。可以使用这个方案优化：删除失败就多删除几次呀,保证删除缓存成功就可以了呀~ 所以可以引入**删除缓存重试机制**

![图片](https://mmbiz.qpic.cn/mmbiz_png/PoF8jo1Pmpzr8VflicsVn7fr1ksck7SCRDvhO050QGHAEyVgsvtmSBg6OeNsDLt0PEWajMHwzElgKLpqcAfZ1xA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)
删除缓存重试流程

1. 写请求更新数据库
2. 缓存因为某些原因，删除失败
3. 把删除失败的key放到消息队列
4. 消费消息队列的消息，获取要删除的key
5. 重试删除缓存操作

### 读取biglog异步删除缓存

重试删除缓存机制还可以吧，就是会造成好多**业务代码入侵**。其实，还可以这样优化：通过数据库的**binlog来异步淘汰key**。

![图片](https://mmbiz.qpic.cn/mmbiz_png/PoF8jo1Pmpzr8VflicsVn7fr1ksck7SCRM182GqMXbibp67wye0xXvUqrAEQiby4VLrIiaLfia3VRYm6CHXraJuXiaXQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

以mysql为例吧

- 可以使用阿里的canal将binlog日志采集发送到MQ队列里面

- 然后通过ACK机制确认处理这条更新消息，删除缓存，保证数据缓存一致性

  

  

### 参考与感谢

- [并发环境下，先操作数据库还是先操作缓存？](https://mp.weixin.qq.com/s?__biz=Mzg3NzU5NTIwNg==&mid=2247488079&idx=1&sn=49255f6c0c540deeb3333bcf86d6c77c&chksm=cf21cd66f856447061b5eca47f51199e120a9eaa83fa7546b4bd2667218403ccc97e726ab456&token=840824242&lang=zh_CN&scene=21#wechat_redirect)

- [高并发场景下，到底先更新缓存还是先更新数据库？](https://mp.weixin.qq.com/s?__biz=MzIwODI1OTk1Nw==&mid=2650322566&idx=1&sn=2142fe29c6a32e5a2100f4f39ee8953d&scene=21#wechat_redirect)

- [两难！先更新数据库再删缓存？还是先删缓存再更新数据库？](https://mp.weixin.qq.com/s?__biz=MzU1NTA0NTEwMg==&mid=2247485178&idx=1&sn=a5965c7af37ad79ee811bc8a2c15a488&scene=21#wechat_redirect)

- [3种缓存读写策略都不了解？面试很难让你通过啊兄弟](https://mp.weixin.qq.com/s?__biz=Mzg2OTA0Njk0OA==&mid=2247496386&idx=1&sn=67a5e28bddfac15e3200765df05dcfd0&scene=21#wechat_redirect)

  