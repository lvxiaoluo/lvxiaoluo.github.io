# Redis常见面试题（二）:redis分布式锁、redisson；Redis集群、主从复制，哨兵模式，分片集群；Redis为什么这么快，I/O多路复用模型

[Redis分布式锁的实现原理是什么？](https://copilot.tencent.com/chat?s=Redis分布式锁的实现原理是什么？&gwzcw.9271036.9271036.9271036&utm_medium=cpc&utm_id=gwzcw.9271036.9271036.9271036)

[Redisson在Redis分布式锁中扮演什么角色？](https://copilot.tencent.com/chat?s=Redisson在Redis分布式锁中扮演什么角色？&gwzcw.9271036.9271036.9271036&utm_medium=cpc&utm_id=gwzcw.9271036.9271036.9271036)

[Redis集群如何实现数据分布？](https://copilot.tencent.com/chat?s=Redis集群如何实现数据分布？&gwzcw.9271036.9271036.9271036&utm_medium=cpc&utm_id=gwzcw.9271036.9271036.9271036)

**文章目录**

一、[redis](https://cloud.tencent.com/product/crs?from_column=20065&from=20065)分布式锁

- 1.1 redis分布式锁 是如何实现的
- 1.2 Redission
- 1.3 Redis实现分布式锁如何合理的控制锁的有效时长
- 1.4 redisson实现的分布式锁-可重入
- 1.5 redisson实现的分布式锁-主从一致性
- 1.6 总结

二、Redis集群

- 2.1 Redis集群有哪些方案, 知道嘛

三、主从复制

- 3.1 主从复制——全量同步、增量同步
- 3.2 总结

四、哨兵

- 4.1 哨兵的作用
- 4.2 服务状态监控
- 4.3 redis集群（哨兵模式）脑裂
- 4.4 总结

五、分片集群

- 5.1 分片集群结构
- 5.2 分片集群结构——数据读写
- 5.3 总结

六、其他问题

- 6.1 Redis是单线程的，但是为什么还那么快
- 6.2 解释一下I/O多路复用模型
  - 6.2.1 用户空间和内核空间
  - 6.2.2 阻塞IO
  - 6.2.3 非阻塞IO
  - 6.2.4 IO多路复用
- 6.3 Redis网络模型
- 6.4 总结

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/d45449a83f8ba4020cb472bb9b893558.png)

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/8833d9c5c42b5da8553c9736b56cfe52.png)

还记得Redis使用场景、缓存穿透、缓存击穿、缓存雪崩、Redis持久化、数据过期策略、数据淘汰策略吗？如果忘记可以到这里重新温习， [Redis常见面试题（一）：Redis使用场景，缓存、分布式锁；缓存穿透、缓存击穿、缓存雪崩；双写一致，Canal，Redis持久化，数据过期策略，数据淘汰策略](https://cloud.tencent.com/developer/tools/blog-entry?target=https%3A%2F%2Fblog.csdn.net%2Fqq_44700578%2Farticle%2Fdetails%2F140474138&objectId=2438438&objectType=1&isNewArticle=undefined)。

## 一、redis分布式锁

### 1.1 redis分布式锁 是如何实现的

需要结合项目中的业务进行回答，通常情况下，分布式锁使用的场景：**集群情况下的定时任务、抢单、幂等性场景**

抢券场景

代码语言：java

AI代码解释



```java
/**
* 抢购优惠券
* @throws InterruptedException
*/
public void rushToPurchase() throws InterruptedException {      //获取优惠券数量
    Integer num = (Integer) redisTemplate.opsForValue().get(“num”);
    //判断是否抢完
    if (null == num || num <= 0) {
        throw new RuntimeException(“优惠券已抢完");
    }
    //优惠券数量减一，说明抢到了优惠券
    num = num - 1;       
    //重新设置优惠券的数量
    redisTemplate.opsForValue().set("num", num);
}
```

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/2733ac71d1068f709482164d25d837dd.png)

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/6550f80e00d4ba492c25eb15f453fc2f.png)

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/89758ae87557ab1360f7dfcc7e5a818a.png)

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/6bd3775970a5fe2cc96d2bf9503d46cc.png)

代码语言：java

AI代码解释



```java
public void rushToPurchase() throws InterruptedException {
    synchronized (this){
    	//查询优惠券数量
        Integer num = (Integer) redisTemplate.opsForValue().get("num");
        //判断是否抢完
        if (null == num || num <= 0) {
            throw new RuntimeException("商品已抢完");
        }
        //优惠券数量减一（减库存）
        num = num - 1;
        //重新设置优惠券的数量
        redisTemplate.opsForValue().set("num", num);
    }
}
```

**服务集群部署**

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/822d53185ef1ad496ccc9da707521b66.png)

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/12ccd126551698367732b3de7b170bc1.png)

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/f9c8aebe0a0ba20784e0f304edee7b20.png)

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/1b8cdb43a7a8052b8e6b82f38ff3efc0.png)

Redis实现分布式锁主要利用Redis的**setnx**命令。setnx是SET if not exists(如果不存在，则 SET)的简写。

- 获取锁：

代码语言：shell

AI代码解释



```shell
# 添加锁，NX是互斥、EX是设置超时时间
SET lock value NX EX 10

#正常set命令
set key value [EX seconds] [PX milliseconds] [NX|XX]
```

- 释放锁：

代码语言：shell

AI代码解释



```shell
# 释放锁，删除即可
DEL key
```

### 1.2 Redission

使用redisson实现的分布式锁，底层是setnx和lua脚本（保证原子性）。

redisson原理如下：

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/038f15dc19073d080dae26cfb1aa24dc.png)

### 1.3 Redis实现分布式锁如何合理的控制锁的有效时长

- 根据业务执行时间评估
- 给锁续期

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/2f2eb0dcee117b9e82f61e84cd6eb59c.png)

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/3afea06c08595ce43d5e1d765f5a2c52.png)

加锁、设置过期时间等操作都是基于lua脚本完成。

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/8a272d78f07b239d7f4f04f72dfbd40c.png)

### 1.4 redisson实现的分布式锁-可重入

**redisson实现的分布式锁-可重入**

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/b28e71f0593ab1d02b4c863e5aee4919.png)

代码语言：java

AI代码解释



```java
public void add1(){
    RLock lock = redissonClient.getLock(“wjlock");
    boolean isLock = lock.tryLock();
    //执行业务
    add2();
    //释放锁
    lock.unlock();
}
                                        
public void add2(){
    RLock lock = redissonClient.getLock(“wjlock");
    boolean isLock = lock.tryLock();
    //执行业务
    //释放锁
    lock.unlock();
}
```

### 1.5 redisson实现的分布式锁-主从一致性

**redisson实现的分布式锁-主从一致性**

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/c27ff32b3de9785a9d8ece78a5ded49a.png)

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/32b6606dde66eb23fbba497ad29791a6.png)

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/6540cc9515b1a1afe01e095acce0ea9e.png)

### 1.6 总结

- redis分布式锁，是如何实现的？    - 先按照自己简历上的业务进行描述分布式锁使用的场景    - 我们使用的redisson实现的分布式锁，底层是**setnx**和**lua脚本**（保证原子性） 【由于redis的单线程，用了命令之后，只能有一个客户对某一个key设置值，在没有过期或删除key的时候其他客户端是不能设置这个key的】
- Redisson实现分布式锁如何合理的控制锁的有效时长？    - 在redisson的分布式锁中，提供了一个**WatchDog**(看门狗），一个线程获取锁成功以后， WatchDog会给持有锁的线程**续期（默认是每隔10秒续期一次）** 【在redisson中需要手动加锁，并且可以控制锁的失效时间和等待时间，当锁住的一个业务还没有执行完成的时候，在redisson中引入了一个看门狗机制，就是说每隔一段时间就检查当前业务是否还持有锁，如果持有就增加加锁的持有时间，当业务执行完成之后需要使用释放锁就可以了 还有一个好处就是，在高并发下，一个业务有可能会执行很快，先客户1持有锁的时候，客户2来了以后并不会马上拒绝，它会自选不断尝试获取锁，如果客户1释放之后，客户2就可以马上持有锁，性能也得到了提升】
- Redisson的这个锁，可以重入吗？    - 可以重入，多个锁重入需要判断是否是当前线程，在redis中进行存储的时候使用的**hash结构**，来存储**线程信息和重入的次数** 【是可以重入的。这样做是为了避免死锁的产生。这个重入其实在内部就是判断是否是当前线程持有的锁，如果是当前线程持有的锁就会计数，如果释放锁就会在计算上减一。在存储数据的时候采用的hash结构，大key可以按照自己的业务进行定制，其中小key是当前线程的唯一标识，value是当前线程重入的次数】
- Redisson锁能解决主从数据一致的问题吗    - 不能解决，但是可以使用redisson提供的**红锁**来解决，但是这样的话，**性能就太低了**，如果业务中非要保证数据的强一致性，建议采用**zookeeper**实现的分布式锁 【这个是不能的，比如，当线程1加锁成功后，master节点数据会异步复制到slave节点，此时当前持有Redis锁的master节点宕机，slave节点被提升为新的master节点，假如现在来了一个线程2，再】

**Redisson实现的分布式锁**

- 底层基于redis的setnx命令做了改进封装，使用lua脚本保证命令的原子性
- 利用hash结构，记录线程标示和重入次数；
- 利用watchDog延续锁时间；
- 控制锁重试等待
- Redlock红锁解决主从数据一致的问题（不推荐）性能差
- 如果业务非要保证强一致性，建议采用zookeeper实现的分布式锁

## 二、Redis集群

### 2.1 Redis集群有哪些方案, 知道嘛

在Redis中提供的集群方案总共有三种

- 主从复制
- 哨兵模式
- 分片集群

## 三、主从复制

### 3.1 主从复制——全量同步、增量同步

单节点Redis的并发能力是有上限的，要进一步提高Redis的并发能力，就需要搭建主从集群，实现读写分离。

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/5d850df705ea9d4b1e1b532f21d52faa.png)

**主从**[**数据同步**](https://cloud.tencent.com/product/datainlong?from_column=20065&from=20065)**原理：全量同步、增量同步**

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/36fcf4fac5fc696aa980a4bb1cd28575.png)

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/42ce571b0f72c3de462769c63e3d1a65.png)

- 全量同步

  ：

  1. 从节点请求主节点同步数据（replication id、 offset ）
  2. 主节点判断是否是第一次请求，是第一次就与从节点同步版本信息（replication id和offset）
  3. 主节点执行bgsave，生成rdb文件后，发送给从节点去执行
  4. 在rdb生成执行期间，主节点会以命令的方式记录到缓冲区（一个日志文件）
  5. 把生成之后的命令日志文件发送给从节点进行同步

- 增量同步

  ：

  1. 从节点请求主节点同步数据，主节点判断不是第一次请求，不是第一次就获取从节点的offset值
  2. 主节点从命令日志中获取offset值之后的数据，发送给从节点进行数据同步

### 3.2 总结

**1）Redis集群有哪些方案**

在Redis中提供的集群方案总共有三种：主从复制、哨兵模式、Redis分片集群

**2）介绍一下redis的主从同步**

单节点Redis的并发能力是有上限的，要进一步提高Redis的并发能力，就需要搭建主从集群，实现读写分离。一般都是一主多从，主节点负责写数据，从节点负责读数据

**3）能说一下，主从同步数据的流程**

主从同步分为了两个阶段，一个是全量同步、一个是增量同步。

全量同步是指从节点第一次与主节点建立连接的时候使用全量同步，流程是这样的：

- 第一：从节点请求主节点同步数据，其中从节点会携带自己的replicationid和offset偏移量。
- 第二：主节点判断是否是第一次请求，主要判断的依据就是，**主节点与从节点是否是同一个replicationid**，如果不是，就说明是第一次同步，那主节点就会把自己的replicationid和offset发送给从节点，让从节点与主节点的信息保持一致。
- 第三：在同时主节点会执行bgsave，生成rdb文件后，发送给从节点去执行，从节点先把自已的数据清空，然后执行主节点发送过来的rdb文件，这样就保持了一致

当然，**如果在rdb生成执行期间，依然有请求到了主节点，而主节点会以命令的方式记录到缓冲区**，缓冲区是一个日志文件，最后把这个日志文件发送给从节点，这样就能保证主节点与从节点完全一致了，**后期再同步数据的时候，都是依赖于这个日志文件**，这个就是全量同步。

增量同步指的是，当从节点服务重启之后，数据就不一致了，所以这个时候，从节点会请求主节点同步数据，主节点还是判断不是第一次请求，**不是第一次就获取从节点的offset值**，然后主节点从命令日志中获取offset值之后的数据，发送给从节点进行数据同步。

## 四、哨兵

### 4.1 哨兵的作用

Redis提供了哨兵（Sentinel）机制来实现主从集群的自动故障恢复。哨兵的结构和作用如下：

- **监控**：Sentinel 会不断检查您的master和slave是否按预期工作
- **自动故障恢复**：如果master故障，Sentinel会将一个slave提升为master。当故障实例恢复后也以新的master为主
- **通知**：Sentinel充当Redis客户端的服务发现来源，当集群发生故障转移时，会将最新信息推送给Redis的客户端

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/3e130f7ee681f49b1f847d286650b8a0.png)

### 4.2 服务状态监控

Sentinel基于心跳机制监测服务状态，每隔1秒向集群的每个实例发送ping命令：

- 主观下线：如果某sentinel节点发现某实例未在规定时间响应，则认为该实例主观下线。
- 客观下线：若超过指定数量（quorum）的sentinel都认为该实例主观下线，则该实例客观下线。quorum值最好超过Sentinel实例数量的一半。

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/581980692c63b82680f0e18a901dbff6.png)

**哨兵选主规则**

- 首先判断主与从节点断开时间长短，如超过指定值就排该从节点
- 然后判断从节点的slave-priority值，越小优先级越高
- **如果slave-prority一样，则判断slave节点的offset值，越大优先级越高**
- 最后是判断slave节点的运行id大小，越小优先级越高。

### 4.3 redis集群（哨兵模式）脑裂

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/2a4313dcac7db9134d8400df1cf585ac.png)

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/fe923deec13dda0b8393189915e222dc.png)

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/b85a0a4f12f049b45d1bb1059ff8c57e.png)

### 4.4 总结

1）怎么保证Redis的高并发高可用

哨兵模式：实现主从集群的自动故障恢复（监控、自动故障恢复、通知）

【首先可以搭建主从集群，再加上使用redis中的哨兵模式，哨兵模式可以实现主从集群的自动故障恢复，里面就包含了对主从服务的监控、自动故障恢复、通知；如果master故障，Sentinel会将一个slave提升为master。当故障实例恢复后也以新的master为主；同时Sentinel也充当Redis客户端的服务发现来源，当集群发生故障转移时，会将最新信息推送给Redis的客户端，所以一般项目都会采用哨兵的模式来保证redis的高并发高可用】

2）你们使用redis是单点还是集群，哪种集群

主从（1主1从）+哨兵就可以了。单节点不超过10G内存，如果Redis内存不足则可以给不同服务分配独立的Redis主从节点

【我们当时使用的是主从（1主1从）加哨兵。一般单节点不超过10G内存，如果Redis内存不足则可以给不同服务分配独立的Redis主从节点。尽量不做分片集群。因为集群维护起来比较麻烦，并且集群之间的心跳检测和数据通信会消耗大量的网络带宽，也没有办法使用lua脚本和事务】

3）redis集群脑裂，该怎么解决呢？

**集群脑裂**是由于主节点和从节点和sentinel处于不同的网络分区，使得sentinel没有能够心跳感知到主节点，所以通过选举的方式提升了一个从节点为主，这样就存在了两个master，就像大脑分裂了一样，这样会导致客户端还在老的主节点那里写入数据，新节点无法同步数据，当网络恢复后，sentinel会将老的主节点降为从节点，这时再从新master同步数据，就会导致数据丢失

**解决**：我们可以修改redis的配置，可以设置最少的从节点数量以及缩短主从数据同步的延迟时间，达不到要求就拒绝请求，就可以避免大量的数据丢失

【这个在项目中很少见，不过脑裂的问题是这样的，我们现在用的是redis的哨兵模式集群。有的时候由于网络等原因可能会出现脑裂的情况，就是说，由于redis master节点和redis salve节点和sentinel处于不同的网络分区，使得sentinel没有能够心跳感知到master，所以通过选举的方式提升了一个salve为master，这样就存在了两个master，就像大脑分裂了一样，这样会导致客户端还在old master那里写入数据，新节点无法同步数据，当网络恢复后，sentinel会将old master降为salve，这时再从新master同步数据，这会导致oldmaster中的大量数据丢失。

关于解决的话，我记得在redis的配置中可以设置：第一可以设置最少的salve节点个数，比如设置至少要有一个从节点才能同步数据，第二个可以设置主从数据复制和同步的延迟时间，达不到要求就拒绝请求，就可以避免大量的数据丢失】

## 五、分片集群

主从和哨兵可以解决高可用、高并发读的问题。但是依然有两个问题没有解决：

- 海量[数据存储](https://cloud.tencent.com/product/cdcs?from_column=20065&from=20065)问题
- 高并发写的问题

### 5.1 分片集群结构

使用分片集群可以解决上述问题，分片集群特征：

- 集群中有多个master，每个master保存不同数据
- 每个master都可以有多个slave节点
- master之间通过ping监测彼此健康状态
- 客户端请求可以访问集群任意节点，最终都会被转发到正确节点

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/1d52b0ef13ff63fdb2c2b56210d70285.png)

### 5.2 分片集群结构——数据读写

Redis 分片集群引入了哈希槽的概念，Redis 集群有 16384 个哈希槽，每个 key通过 CRC16 校验后对 16384 取模来决定放置哪个槽，集群的每个节点负责一部分 hash 槽。

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/3984fc00b69925607cde0e2a68a16ac6.png)

### 5.3 总结

1）redis的分片集群有什么作用

- 集群中有多个master，每个master保存不同数据
- 每个master都可以有多个slave节点
- master之间通过ping监测彼此健康状态
- 客户端请求可以访问集群任意节点，最终都会被转发到正确节点

【分片集群主要解决的是，海量数据存储的问题，集群中有多个master，每个master保存不同数据，并且还可以给每个master设置多个slave节点，就可以继续增大集群的高并发能力。同时每个master之间通过ping监测彼此健康状态，就类似于哨兵模式了。当客户端请求可以访问集群任意节点，最终都会被转发到正确节点】

2）Redis分片集群中数据是怎么存储和读取的？

- Redis 分片集群引入了哈希槽的概念，Redis 集群有 16384 个哈希槽
- 将16384个插槽分配到不同的实例
- 读写数据：根据key的**有效部分**计算哈希值，对16384取余（**有效部分**，如果key前面有大括号，大括号的内容就是有效部分，如果没有，则以key本身做为有效部分）余数做为插槽，寻找插槽所在的实例

【在redis集群中是这样的Redis集群引入了哈希槽的概念，有16384个哈希槽，集群中每个主节点绑定了一定范围的哈希槽范围，key通过CRC16校验后对16384取模来决定放置哪个槽，通过槽找到对应的节点进行存储。取值的逻辑是一样的】

## 六、其他问题

### 6.1 Redis是单线程的，但是为什么还那么快

- Redis是纯内存操作，执行速度非常快
- 采用单线程，避免不必要的上下文切换可竞争条件，多线程还要考虑线程安全问题
- 使用I/O多路复用模型，非阻塞IO

### 6.2 解释一下I/O多路复用模型

Redis是纯内存操作，执行速度非常快，它的性能瓶颈是**网络延迟**而不是执行速度， I/O多路复用模型主要就是实现了高效的网络请求

- 用户空间和内核空间
- 常见的IO模型
  - 阻塞IO（Blocking IO）
  - 非阻塞IO（Nonblocking IO）
  - IO多路复用（IO Multiplexing）
- Redis网络模型

#### 6.2.1 用户空间和内核空间

- Linux系统中一个进程使用的内存情况划分两部分：**内核空间、用户空间**
- **用户空间**只能执行受限的命令（Ring3），而且不能直接调用系统资源，必须通过内核提供的接口来访问
- **内核空间**可以执行特权命令（Ring0），调用一切系统资源

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/ce8bbb3c76cc37e8ccf5567f096a6dee.png)

Linux系统为了提高IO效率，会在用户空间和内核空间都加入缓冲区：

- 写数据时，要把用户缓冲数据拷贝到内核缓冲区，然后写入设备
- 读数据时，要从设备读取数据到内核缓冲区，然后拷贝到用户缓冲区

#### 6.2.2 阻塞IO

顾名思义，阻塞IO就是两个阶段都必须阻塞等待：

阶段一：

- 用户进程尝试读取数据（比如网卡数据）
- 此时数据尚未到达，内核需要等待数据
- 此时用户进程也处于阻塞状态

阶段二：

- 数据到达并拷贝到内核缓冲区，代表已就绪
- 将内核数据拷贝到用户缓冲区
- 拷贝过程中，用户进程依然阻塞等待
- 拷贝完成，用户进程解除阻塞，处理数据

可以看到，阻塞IO模型中，用户进程在两个阶段都是阻塞状态。

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/14749051bc105f1cb2109f99a6683325.png)

#### 6.2.3 非阻塞IO

顾名思义，非阻塞IO的recvfrom操作会立即返回结果而不是阻塞用户进程。

阶段一：

- 用户进程尝试读取数据（比如网卡数据）
- 此时数据尚未到达，内核需要等待数据
- 返回异常给用户进程
- 用户进程拿到error后，再次尝试读取
- 循环往复，直到数据就绪

阶段二：

- 将内核数据拷贝到用户缓冲区
- 拷贝过程中，用户进程依然阻塞等待
- 拷贝完成，用户进程解除阻塞，处理数据

可以看到，非阻塞IO模型中，用户进程在第一个阶段是非阻塞，第二个阶段是阻塞状态。虽然是非阻塞，但性能并没有得到提高。而且忙等机制会导致CPU空转，CPU使用率暴增。

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/6fb76e137c30df4e2ce69d0dcb8321e4.png)

#### 6.2.4 IO多路复用

**IO多路复用**：是利用单个线程来同时监听多个Socket ，并在某个Socket可读、可写时得到通知，从而避免无效的等待，充分利用CPU资源。不过监听Socket的方式、通知的方式又有多种实现，常见的有：

- select
- poll
- epoll

差异：

- select和poll只会通知用户进程有Socket就绪，但不确定具体是哪个Socket ，需要用户进程逐个遍历Socket来确认
- epoll则会在通知用户进程Socket就绪的同时，把已就绪的Socket写入用户空间

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/5de4abf6c2a6dcd04ec7e54c4a1a5ec3.png)

### 6.3 Redis网络模型

Redis通过IO多路复用来提高网络性能，并且支持各种不同的多路复用实现，并且将这些实现进行封装， 提供了统一的高性能事件库

![img](https://developer.qcloudimg.com/http-save/yehe-10925111/d13a0f9135cfdc45d3068c582e086af1.png)

### 6.4 总结

1）Redis是单线程的，但是为什么还那么快

有以下几个原因：

- 完全基于内存的，C语言编写
- 采用单线程，避免不必要的上下文切换可竞争条件
- 使用多路I/O复用模型，非阻塞IO

例如：bgsave和bgrewriteaof都是在后台执行操作，不影响主线程的正常使用，不会产生阻塞。

2）能解释一下I/O多路复用模型？

I/O多路复用是指利用单个线程来同时监听多个Socket ，并在某个Socket可读、可写时得到通知，从而避免无效的等待，充分利用CPU资源。目前的I/O多路复用都是采用的epoll模式实现，它会在通知用户进程Socket就绪的同时，把已就绪的Socket写入用户空间，不需要挨个遍历Socket来判断是否就绪，提升了性能。

其中Redis的网络模型就是使用I/O多路复用结合事件的处理器来应对多个Socket亲戚，比如提供了连接应答处理器、命令回复处理器、命令请求处理器。

在Redis6.0之后，为了提升更好的性能，在命令回复处理器使用了多线程来处理回复事件，在命令请求处理器中。将命令的转换使用了多线程，增加命令转换速度，在命令执行的时候，依然是单线程。

3）Redis网络模型

就是使用I/O多路复用结合事件的处理器来应对多个Socket请求

- 连接应答处理器
- 命令回复处理器，在Redis6.0之后，为了提升更好的性能，使用了多线程来处理回复事件
- 命令请求处理器，在Redis6.0之后，将命令的转换使用了多线程，增加命令转换速度，在命令执行的时候，依然是单线程





[原文地址](https://cloud.tencent.com/developer/article/2438438)