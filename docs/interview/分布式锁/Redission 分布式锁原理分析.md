# Redission 分布式锁原理分析

- [一、前言](https://mp.weixin.qq.com/s?__biz=MzUzMTA2NTU2Ng==&mid=2247487551&idx=1&sn=18f64ba49f3f0f9d8be9d1fdef8857d9&chksm=fa496f8ecd3ee698f4954c00efb80fe955ec9198fff3ef4011e331aa37f55a6a17bc8c0335a8&scene=21&token=899450012&lang=zh_CN#wechat_redirect)
- [二、分布式锁的特性](https://mp.weixin.qq.com/s?__biz=MzUzMTA2NTU2Ng==&mid=2247487551&idx=1&sn=18f64ba49f3f0f9d8be9d1fdef8857d9&chksm=fa496f8ecd3ee698f4954c00efb80fe955ec9198fff3ef4011e331aa37f55a6a17bc8c0335a8&scene=21&token=899450012&lang=zh_CN#wechat_redirect)
- [三、Redisson 分布式锁原理](https://mp.weixin.qq.com/s?__biz=MzUzMTA2NTU2Ng==&mid=2247487551&idx=1&sn=18f64ba49f3f0f9d8be9d1fdef8857d9&chksm=fa496f8ecd3ee698f4954c00efb80fe955ec9198fff3ef4011e331aa37f55a6a17bc8c0335a8&scene=21&token=899450012&lang=zh_CN#wechat_redirect)
- [四、主从 Redis 架构中分布式锁存在的问题](https://mp.weixin.qq.com/s?__biz=MzUzMTA2NTU2Ng==&mid=2247487551&idx=1&sn=18f64ba49f3f0f9d8be9d1fdef8857d9&chksm=fa496f8ecd3ee698f4954c00efb80fe955ec9198fff3ef4011e331aa37f55a6a17bc8c0335a8&scene=21&token=899450012&lang=zh_CN#wechat_redirect)
- [五、分布式锁选型](https://mp.weixin.qq.com/s?__biz=MzUzMTA2NTU2Ng==&mid=2247487551&idx=1&sn=18f64ba49f3f0f9d8be9d1fdef8857d9&chksm=fa496f8ecd3ee698f4954c00efb80fe955ec9198fff3ef4011e331aa37f55a6a17bc8c0335a8&scene=21&token=899450012&lang=zh_CN#wechat_redirect)

------

## **[一、前言](https://mp.weixin.qq.com/s?__biz=MzUzMTA2NTU2Ng==&mid=2247487551&idx=1&sn=18f64ba49f3f0f9d8be9d1fdef8857d9&scene=21#wechat_redirect)**

我们先来说说分布式锁，为啥要有分布式锁呢? 像 JDK 提供的 synchronized、Lock 等实现锁不香吗？这是因为在单进程情况下，多个线程访问同一资源，可以使用 synchronized 和 Lock 实现；在多进程情况下，也就是分布式情况，对同一资源的并发请求，需要使用分布式锁实现。而 Redisson 组件可以实现 Redis 的分布式锁，同样 Redisson 也是 Redis 官方推荐分布式锁实现方案，封装好了让用户实现分布式锁更加的方便与简洁。

## **[二、分布式锁的特性](https://mp.weixin.qq.com/s?__biz=MzUzMTA2NTU2Ng==&mid=2247487551&idx=1&sn=18f64ba49f3f0f9d8be9d1fdef8857d9&scene=21#wechat_redirect)**

- **互斥性**

  任意时刻，只能有一个客户端获取锁，不能同时有两个客户端获取到锁。

- **同一性**

  锁只能被持有该锁的客户端删除，不能由其它客户端删除。

- **可重入性**

  持有某个锁的客户端可继续对该锁加锁，实现锁的续租。

- **容错性**

  锁失效后（超过生命周期）自动释放锁（key失效），其他客户端可以继续获得该锁，防止死锁。

> 基于 Spring Cloud Alibaba + Gateway + Nacos + RocketMQ + Vue & Element 实现的后台管理系统 + 用户小程序，支持 RBAC 动态权限、多租户、数据权限、工作流、三方登录、支付、短信、商城等功能
>
> - 项目地址：https://github.com/YunaiV/yudao-cloud
> - 视频教程：https://doc.iocoder.cn/video/

## **[三、Redisson 分布式锁原理](https://mp.weixin.qq.com/s?__biz=MzUzMTA2NTU2Ng==&mid=2247487551&idx=1&sn=18f64ba49f3f0f9d8be9d1fdef8857d9&scene=21#wechat_redirect)**

下面我们从加锁机制、锁互斥机制、锁续期机制、可重入加锁机制、锁释放机制等五个方面对 Redisson 分布式锁原理进行分析。

**3.0 整体分析**

> 注：redisson 版本 3.24.4-SNAPSHOT

```java
public class RedissonLockTest {
    public static void main(String[] args) {
        Config config = new Config();
        config.useSingleServer()
            .setPassword("admin")
            .setAddress("redis://127.0.0.1:6379");

        RedissonClient redisson = Redisson.create(config);
        RLock lock = redisson.getLock("myLock");

        try {
            lock.lock();
            // 业务逻辑
        } finally {
            lock.unlock();
        }
    }
}
```

**初始化 RedissonLock**

![图片](https://mmbiz.qpic.cn/mmbiz_png/JdLkEI9sZfcAjic6tzwea782JsANLOwSD2MVNr87QZUg5X4VWZVLF8VATZE5SZuG1z0wNzWGgNjCwBa5YXzKUPA/640?wx_fmt=png&from=appmsg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

```java
/**
 * 加锁方法
 *
 * @param leaseTime 加锁到期时间（-1：使用默认值 30 秒）
 * @param unit 时间单位
 * @param interruptibly 是否可被中断标识
 * @throws InterruptedException
 */
private void lock(long leaseTime, TimeUnit unit, boolean interruptibly) throws InterruptedException {
    // 获取当前线程ID
    long threadId = Thread.currentThread().getId();
    // 尝试获取锁（重点）
    Long ttl = tryAcquire(-1, leaseTime, unit, threadId);
    // lock acquired
    // 成功获取锁, 过期时间为空。
    if (ttl == null) {
        return;
    }

    // 订阅分布式锁, 解锁时进行通知。
    CompletableFuture<RedissonLockEntry> future = subscribe(threadId);
    pubSub.timeout(future);
    RedissonLockEntry entry;
    if (interruptibly) {
        entry = commandExecutor.getInterrupted(future);
    } else {
        entry = commandExecutor.get(future);
    }

    try {
        while (true) {
            // 再次尝试获取锁
            ttl = tryAcquire(-1, leaseTime, unit, threadId);
            // lock acquired
            // 成功获取锁, 过期时间为空, 成功返回。
            if (ttl == null) {
                break;
            }

            // waiting for message
            // 锁过期时间如果大于零, 则进行带过期时间的阻塞获取。
            if (ttl >= 0) {
                try {
                    // 获取不到锁会在这里进行阻塞, Semaphore, 解锁时释放信号量通知。
                    entry.getLatch().tryAcquire(ttl, TimeUnit.MILLISECONDS);
                } catch (InterruptedException e) {
                    if (interruptibly) {
                        throw e;
                    }
                    entry.getLatch().tryAcquire(ttl, TimeUnit.MILLISECONDS);
                }
            } else {
                // 锁过期时间小于零, 则死等, 区分可中断及不可中断。
                if (interruptibly) {
                    entry.getLatch().acquire();
                } else {
                    entry.getLatch().acquireUninterruptibly();
                }
            }
        }
    } finally {
        // 取消订阅
        unsubscribe(entry, threadId);
    }
}
```

![图片](https://mmbiz.qpic.cn/mmbiz_png/JdLkEI9sZfcAjic6tzwea782JsANLOwSDBbCR2JVsxxiaZHZXY0d8cofcOdJAfHiazLHWXsntxLnnrO9ofjS4sx9w/640?wx_fmt=png&from=appmsg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

当锁超时时间为 -1 时，而且获取锁成功时，会启动看门狗定时任务自动续锁：

![图片](https://mmbiz.qpic.cn/mmbiz_png/JdLkEI9sZfcAjic6tzwea782JsANLOwSDLS5xXrw8EZ4fxlgicQrO8XARFyib0V1o2mVz4yXWZZNibNibje4nvjxEBA/640?wx_fmt=png&from=appmsg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

![图片](https://mmbiz.qpic.cn/mmbiz_png/JdLkEI9sZfcAjic6tzwea782JsANLOwSD9jHsAjHDreZJdeacvOiaVEXDJ3mMgqQBm6SnynJa7cknLwJBic0rT5TA/640?wx_fmt=png&from=appmsg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

每次续锁都要判断锁是否已经被释放，如果锁续期成功，自己再次调度自己，持续续锁操作。

为了保证原子性，用 lua 实现的原子性加锁操作，见 3.1 加锁机制。

**3.1 加锁机制**

加锁机制的核心就是这段，将 Lua 脚本被 Redisoon 包装最后通过 Netty 进行传输。

```java
<T> RFuture<T> tryLockInnerAsync(long waitTime, long leaseTime, TimeUnit unit, long threadId, RedisStrictCommand<T> command) {
    /**
     * // 1
     * KEYS[1] 代表上面的 myLock
     * 判断 KEYS[1] 是否存在, 存在返回 1, 不存在返回 0。
     * 当 KEYS[1] == 0 时代表当前没有锁
     * // 2
     * 查找 KEYS[1] 中 key ARGV[2] 是否存在, 存在回返回 1
     * // 3
     * 使用 hincrby 命令发现 KEYS[1] 不存在并新建一个 hash
     * ARGV[2] 就作为 hash 的第一个key, val 为 1
     * 相当于执行了 hincrby myLock 91089b45... 1
     * // 4
     * 设置 KEYS[1] 过期时间, 单位毫秒
     * // 5
     * 返回 KEYS[1] 过期时间, 单位毫秒
     */
    return evalWriteAsync(getRawName(), LongCodec.INSTANCE, command,
            "if ((redis.call('exists', KEYS[1]) == 0) " + // 1
                        "or (redis.call('hexists', KEYS[1], ARGV[2]) == 1)) then " + // 2
                    "redis.call('hincrby', KEYS[1], ARGV[2], 1); " + // 3
                    "redis.call('pexpire', KEYS[1], ARGV[1]); " + // 4
                    "return nil; " +
                "end; " +
                "return redis.call('pttl', KEYS[1]);", // 5
            Collections.singletonList(getRawName()), unit.toMillis(leaseTime), getLockName(threadId));
}
```

断点走一波就很清晰了：

![图片](https://mmbiz.qpic.cn/mmbiz_png/JdLkEI9sZfcAjic6tzwea782JsANLOwSD9oGhF9ibYVR5e4CB7zbYYMqpY93Dh9uwX8TsdZlhiaKynuSbwiaDibCQKQ/640?wx_fmt=png&from=appmsg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

> KEYS[1]) ：加锁的key ARGV[1] ：key的生存时间，默认为30秒 ARGV[2] ：加锁的客户端ID (UUID.randomUUID()） + “:” + threadId)

![图片](https://mmbiz.qpic.cn/mmbiz_png/JdLkEI9sZfcAjic6tzwea782JsANLOwSDu09D0lSmJ53vVVzmibePGA4zwiao949bicC0XcfJxL8ocVTXQRdu9mgJw/640?wx_fmt=png&from=appmsg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

上面这一段加锁的 lua 脚本的作用是：第一段 if 判断语句，就是用 exists myLock 命令判断一下，如果你要加锁的那个锁 key 不存在的话（第一次加锁）或者该 key 的 field 存在（可重入锁），你就进行加锁。如何加锁呢？使用 hincrby 命令设置一个 hash 结构，类似于在 Redis 中使用下面的操作：

![图片](https://mmbiz.qpic.cn/mmbiz_png/JdLkEI9sZfcAjic6tzwea782JsANLOwSDA1R3mNhEpcUEJeMp96c0RDFn8pg2nh7kNkXD88LoBw2NLjyW6YpvqA/640?wx_fmt=png&from=appmsg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

整个 Lua 脚本加锁的流程画图如下：

![图片](https://mmbiz.qpic.cn/mmbiz_png/JdLkEI9sZfcAjic6tzwea782JsANLOwSDvGlePcpT3Nlp07T3SicEzDRF9czjL1ar1D8FfrTvTo1xAibs6dGqt8UQ/640?wx_fmt=png&from=appmsg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

可以看出，最新版本的逻辑比之前的版本更简单清晰了。

**3.2 锁互斥机制**

此时，如果客户端 2 来尝试加锁，会如何呢？首先，第一个 if 判断会执行 exists myLock，发现 myLock 这个锁 key 已经存在了。接着第二个 if 判断，判断一下，myLock 锁 key 的 hash 数据结构中，是否包含客户端 2 的 ID，这里明显不是，因为那里包含的是客户端 1 的 ID。所以，客户端 2 会执行：

```
return redis.call('pttl', KEYS[1]);
```

返回的一个数字，这个数字代表了 myLock 这个锁 key 的剩余生存时间。

锁互斥机制主流程其实在 **3.0 整体分析** 里有讲，具体可以看这个 `org.redisson.RedissonLock#lock(long, java.util.concurrent.TimeUnit, boolean)` 方法。

**3.3 锁续期机制**

客户端 1 加锁的锁 key 默认生存时间是 30 秒，如果超过了 30 秒，客户端 1 还想一直持有这把锁，怎么办呢？

Redisson 提供了一个续期机制， 只要客户端 1 一旦加锁成功，就会启动一个 Watch Dog。

**3.4 可重入加锁机制**

![图片](https://mmbiz.qpic.cn/mmbiz_png/JdLkEI9sZfcAjic6tzwea782JsANLOwSD0Ric8jHy5icSdynpb7cXTJicU1qwGicticRDqBEJVwnJCfVsGDiaEPdjYpKw/640?wx_fmt=png&from=appmsg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

![图片](https://mmbiz.qpic.cn/mmbiz_png/JdLkEI9sZfcAjic6tzwea782JsANLOwSDvZiaHLEbtvAICC4g21XchXqicDanvETJMI1MwDHbXuD5DEUVKnXIT69Q/640?wx_fmt=png&from=appmsg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

Watch Dog 机制其实就是一个后台定时任务线程，获取锁成功之后，会将持有锁的线程放入到一个 RedissonBaseLock.EXPIRATION_RENEWAL_MAP 里面，然后每隔 10 秒 （internalLockLeaseTime / 3） 检查一下，如果客户端 1 还持有锁 key（判断客户端是否还持有 key，其实就是遍历 EXPIRATION_RENEWAL_MAP 里面线程 id 然后根据线程 id 去 Redis 中查，如果存在就会延长 key 的时间），那么就会不断的延长锁 key 的生存时间。

> 注：
>
> 1. 如果服务宕机了，Watch Dog 机制线程也就没有了，此时就不会延长 key 的过期时间，到了 30s 之后就会自动过期了，其他线程就可以获取到锁。
> 2. 如果调用带过期时间的 lock 方法，则不会启动看门狗任务去自动续期。

**3.5 锁释放机制**

![图片](https://mmbiz.qpic.cn/mmbiz_png/JdLkEI9sZfcAjic6tzwea782JsANLOwSD8H4ib4t3xeaUibeicEQ2o28icGGmEicicAIcdYK7IC2fT0CmAErGE8DtjFIw/640?wx_fmt=png&from=appmsg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

```java
// 判断 KEYS[1] 中是否存在 ARGV[3]
"if (redis.call('hexists', KEYS[1], ARGV[3]) == 0) then " +
    "return nil;" +
"end; " +
// 将 KEYS[1] 中 ARGV[3] Val - 1
"local counter = redis.call('hincrby', KEYS[1], ARGV[3], -1); " +
// 如果返回大于0 证明是一把重入锁
"if (counter > 0) then " +
    // 重置过期时间
    "redis.call('pexpire', KEYS[1], ARGV[2]); " +
    "return 0; " +
"else " +
    // 删除 KEYS[1]
    "redis.call('del', KEYS[1]); " +
    // 通知阻塞等待线程或进程资源可用
    "redis.call('publish', KEYS[2], ARGV[1]); " +
    "return 1; " +
"end; " +
"return nil;"
```

> KEYS[1]: myLock KEYS[2]: redisson_lock_channel:{myLock} ARGV[1]: 0 ARGV[2]: 30000 (过期时间) ARGV[3]: 66a84a47-3960-4f3e-8ed7-ea2c1061e4cf:1 (Hash 中的锁 field)

同理，锁释放断点走一波：

![图片](https://mmbiz.qpic.cn/mmbiz_png/JdLkEI9sZfcAjic6tzwea782JsANLOwSDKe3IicWtKiavZLkJf6ZO1IxqgevVKsoiaLsWOBUYpIvwwhJ5sKbn3Jh8A/640?wx_fmt=png&from=appmsg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

锁释放机制小结一下：

- 删除锁（这里注意可重入锁）
- 广播释放锁的消息，通知阻塞等待的进程（向通道名为 redisson_lock__channel:{myLock} publish 一条 UNLOCK_MESSAGE 信息）
- 取消 Watch Dog 机制，即将 RedissonLock.EXPIRATION_RENEWAL_MAP 里面的线程 id 删除，并且 cancel 掉 Netty 的那个定时任务线程。

## **[四、主从 Redis 架构中分布式锁存在的问题](https://mp.weixin.qq.com/s?__biz=MzUzMTA2NTU2Ng==&mid=2247487551&idx=1&sn=18f64ba49f3f0f9d8be9d1fdef8857d9&scene=21#wechat_redirect)**

- 线程A从主redis中请求一个分布式锁，获取锁成功；
- 从redis准备从主redis同步锁相关信息时，主redis突然发生宕机，锁丢失了；
- 触发从redis升级为新的主redis；
- 线程B从继任主redis的从redis上申请一个分布式锁，此时也能获取锁成功；
- 导致，同一个分布式锁，被两个客户端同时获取，没有保证独占使用特性；

为了解决这个问题，redis引入了红锁的概念。

需要准备多台redis实例，这些redis实例指的是完全互相独立的Redis节点，这些节点之间既没有主从，也没有集群关系。客户端申请分布式锁的时候，需要向所有的redis实例发出申请，只有超过半数的redis实例报告获取锁成功，才能算真正获取到锁。跟大多数保证一致性的算法类似，就是多数原理。

```java
public static void main(String[] args) {
    String lockKey = "myLock";
    Config config = new Config();
    config.useSingleServer().setPassword("123456").setAddress("redis://127.0.0.1:6379");
    Config config2 = new Config();
    config.useSingleServer().setPassword("123456").setAddress("redis://127.0.0.1:6380");
    Config config3 = new Config();
    config.useSingleServer().setPassword("123456").setAddress("redis://127.0.0.1:6381");

    RLock lock = Redisson.create(config).getLock(lockKey);
    RLock lock2 = Redisson.create(config2).getLock(lockKey);
    RLock lock3 = Redisson.create(config3).getLock(lockKey);

    RedissonRedLock redLock = new RedissonRedLock(lock, lock2, lock3);

    try {
        redLock.lock();
    } finally {
        redLock.unlock();
    }
}
```

当然, 对于 Redlock 算法不是没有质疑声，两位大神前几年吵的沸沸腾腾，大家感兴趣的可以去 Redis 官网查看Martin Kleppmann 与 Redis 作者Antirez 的辩论。

额，想收一收了，再讲下去感觉要绕不开分布式经典问题 CAP了。

## **[五、分布式锁选型](https://mp.weixin.qq.com/s?__biz=MzUzMTA2NTU2Ng==&mid=2247487551&idx=1&sn=18f64ba49f3f0f9d8be9d1fdef8857d9&scene=21#wechat_redirect)**

鱼和熊掌不可兼得，如果你想强一致性的话可以选择 ZK 的分布式锁，但 ZK 的话性能就会有一定的下降，如果项目没有用到 ZK 的话，那就选择 Redis 的分布式锁吧，比较你为了那极小的概率而丢去性能以及引入一个组件很不划算，如果无法忍受 Redis 的红锁缺陷，那自己在业务中自己保证吧。

下面是常见的几种分布式锁选型对比：

![图片](https://mmbiz.qpic.cn/mmbiz_png/JdLkEI9sZfcAjic6tzwea782JsANLOwSDYS7WmNvgh95v5aTH5Lvex2jNPicGJ0sDuUicajyYdlyQs2tudvdY5W8A/640?wx_fmt=png&from=appmsg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)