# 硬核 | Redis 布隆（Bloom Filter）过滤器原理与实战

在[Redis 缓存击穿（失效）、缓存穿透、缓存雪崩怎么解决？](https://mp.weixin.qq.com/s?__biz=MzkzMDI1NjcyOQ==&mid=2247498378&idx=1&sn=279a82be76e518e60da6ae85d91ff4a2&scene=21#wechat_redirect)中我们说到可以使用布隆过滤器避免「缓存穿透」。

> 码哥，布隆过滤器还能在哪些场景使用呀？

比如我们使用「码哥跳动」开发的「明日头条」APP 看新闻，如何做到每次推荐给该用户的内容不会重复，过滤已经看过的内容呢？

你会说我们只要记录了每个用户看过的历史记录，每次推荐的时候去查询数据库过滤存在的数据实现**去重**。

实际上，如果历史记录存储在关系数据库里，去重就需要频繁地对数据库进行 exists 查询，当系统并发量很高时，数据库是很难扛住压力的。

> 码哥，我可以使用缓存啊，把历史数据存在 Redis 中。

万万不可，这么多的历史记录那要浪费多大的内存空间，所以这个时候我们就能使用布隆过滤器去解决这种**去重问题**。又快又省内存，互联网开发必备杀招！

当你**遇到数据量大，又需要去重的时候就可以考虑布隆过滤器**，如下场景：

- 解决 [Redis 缓存穿透问题](https://mp.weixin.qq.com/s?__biz=MzkzMDI1NjcyOQ==&mid=2247498378&idx=1&sn=279a82be76e518e60da6ae85d91ff4a2&scene=21#wechat_redirect)（面试重点）；
- 邮件过滤，使用布隆过滤器实现邮件黑名单过滤；
- 爬虫爬过的网站过滤，爬过的网站不再爬取；
- 推荐过的新闻不再推荐；

![img](http://mmbiz.qpic.cn/mmbiz_png/EoJib2tNvVtf7icAmS0BQH6oDVG37Q8NzcfdguS5qAqOhfxvZyIKqmuX5BbnDjynrBbZzktp1EiaeFLzapp1nHysw/0?wx_fmt=png)

**码哥字节**

拥抱硬核技术和对象，面向人民币编程。

112篇原创内容



公众号

# 什么是布隆过滤器

布隆过滤器 (Bloom Filter)是由 Burton Howard Bloom 于 1970 年提出，**它是一种 space efficient 的概率型数据结构，用于判断一个元素是否在集合中**。

当布隆过滤器说，**某个数据存在时，这个数据可能不存在；当布隆过滤器说，某个数据不存在时，那么这个数据一定不存在。**

哈希表也能用于判断元素是否在集合中，但是布隆过滤器只需要哈希表的 1/8 或 1/4 的空间复杂度就能完成同样的问题。

**布隆过滤器可以插入元素，但不可以删除已有元素。**

其中的元素越多，false positive rate(误报率)越大，但是 false negative (漏报)是不可能的。

# 布隆过滤器原理

BloomFilter 的算法是，首先分配一块内存空间做 bit 数组，数组的 bit 位初始值全部设为 0。

加入元素时，采用 k 个相互独立的 Hash 函数计算，然后将元素 Hash 映射的 K 个位置全部设置为 1。

检测 key 是否存在，仍然用这 k 个 Hash 函数计算出 k 个位置，如果位置全部为 1，则表明 key 存在，否则不存在。

如下图所示：

![图片](https://mmbiz.qpic.cn/mmbiz_png/EoJib2tNvVtcDkffBFQsY934IzqcYdEFv2m9xeNl5eSGiczeByd6nvtQjfLGINrrnoEf9Mqe93H0LZZO4z64hicMg/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)布隆过滤器原理

**哈希函数会出现碰撞，所以布隆过滤器会存在误判。**

这里的误判率是指，BloomFilter 判断某个 key 存在，但它实际不存在的概率，因为它存的是 key 的 Hash 值，而非 key 的值。

所以有概率存在这样的 key，它们内容不同，但多次 Hash 后的 Hash 值都相同。

**对于 BloomFilter 判断不存在的 key ，则是 100% 不存在的，反证法，如果这个 key 存在，那它每次 Hash 后对应的 Hash 值位置肯定是 1，而不会是 0。布隆过滤器判断存在不一定真的存在。**

> 码哥，为什么不允许删除元素呢？

删除意味着需要将对应的 k 个 bits 位置设置为 0，其中有可能是其他元素对应的位。

因此 remove 会引入 false negative，这是绝对不被允许的。

# Redis 集成布隆过滤器

Redis 4.0 的时候官方提供了插件机制，布隆过滤器正式登场。以下网站可以下载官方提供的已经编译好的可拓展模块。

https://redis.com/redis-enterprise-software/download-center/modules/

![图片](https://mmbiz.qpic.cn/mmbiz_png/EoJib2tNvVtcDkffBFQsY934IzqcYdEFvEzBErqzksQQu0hgRJbDCicGGDBHqRNXL9XBVtWgoMHwO9etAbmDwDFQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)RedisModules

码哥推荐使用 Redis 版本 6.x，最低 4.x 来集成布隆过滤器。如下指令查看版本，码哥安装的版本是 6.2.6。

```
redis-server -v
Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=b5524b65e12bbef5
```

## 下载

我们自己编译安装，需要从 github 下载，目前的 release 版本是 v2.2.14，下载地址：https://github.com/RedisBloom/RedisBloom/releases/tag/v2.2.14

![图片](https://mmbiz.qpic.cn/mmbiz_png/EoJib2tNvVtcDkffBFQsY934IzqcYdEFvjSDsFldBzqOm7tF9v6TyuzsyMReOguSdATVITKVgLr6cqicT6Ng5BnA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)Redis 布隆

## 解压编译

解压

```
tar -zxvf RedisBloom-2.2.14.tar
```

编译插件

```
cd RedisBloom-2.2.14
make
```

编译成功，会看到 `redisbloom.so` 文件。

## 安装集成

需要修改 redis.conf 文件，新增 `loadmodule`配置，并重启 Redis。

```
loadmodule /opt/app/RedisBloom-2.2.14/redisbloom.so
```

**如果是集群，则每个实例的配置文件都需要加入配置。**

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)module 配置

指定配置文件并启动 Redis：

```
redis-server /opt/app/redis-6.2.6/redis.conf
```

加载成功的页面如下：

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)加载布隆过滤器成功

客户端连接 Redis 测试。

```
BF.ADD --添加一个元素到布隆过滤器
BF.EXISTS --判断元素是否在布隆过滤器
BF.MADD --添加多个元素到布隆过滤器
BF.MEXISTS --判断多个元素是否在布隆过滤器
```

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)测试

# Redis 布隆过滤器实战

我们来用布隆过滤器来解决缓存穿透问题，缓存穿透：意味着有特殊请求在查询一个不存在的数据，**即数据不存在 Redis 也不存在于数据库。**

当用户购买商品创建订单的时候，我们往 mq 发送消息，把订单 ID 添加到布隆过滤器。

![图片](https://mmbiz.qpic.cn/mmbiz_png/EoJib2tNvVtcDkffBFQsY934IzqcYdEFvfj1T7q6WJXVFmUwJxFyUapC5nRIOiagFlDGxsksTMNjQd2KUg2pnyfg/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)订单同步到布隆过滤器

在添加到布隆过滤器之前，我们通过`BF.RESERVE`命令手动创建一个名字为 `orders` error_rate = 0.1 ，初始容量为 10000000 的布隆过滤器：

```
# BF.RESERVE {key} {error_rate} {capacity} [EXPANSION {expansion}] [NONSCALING]
BF.RESERVE orders 0.1 10000000
```

- key：filter 的名字；
- error_rate：期望的错误率，默认 0.1，值越低，需要的空间越大；
- capacity：初始容量，默认 100，当实际元素的数量超过这个初始化容量时，误判率上升。
- EXPANSION：可选参数，当添加到布隆过滤器中的数据达到初始容量后，布隆过滤器会自动创建一个子过滤器，子过滤器的大小是上一个过滤器大小乘以 expansion；expansion 的默认值是 2，也就是说布隆过滤器扩容默认是 2 倍扩容；
- NONSCALING：可选参数，设置此项后，当添加到布隆过滤器中的数据达到初始容量后，不会扩容过滤器，并且会抛出异常（(error) ERR non scaling filter is full） 说明：BloomFilter 的扩容是通过增加 BloomFilter 的层数来完成的。每增加一层，在查询的时候就可能会遍历多层 BloomFilter 来完成，每一层的容量都是上一层的两倍（默认）。

如果不使用`BF.RESERVE`命令创建，而是使用 Redis 自动创建的布隆过滤器，**默认的 `error_rate` 是 `0.01`，`capacity`是 100。**

布隆过滤器的 error_rate 越小，需要的存储空间就越大，对于不需要过于精确的场景，error_rate 设置稍大一点也可以。

布隆过滤器的 capacity 设置的过大，会浪费存储空间，设置的过小，就会影响准确率，所以在使用之前一定要尽可能地精确估计好元素数量，还需要加上一定的冗余空间以避免实际元素可能会意外高出设置值很多。

## 添加订单 ID 到过滤器

```
# BF.ADD {key} {item}
BF.ADD orders 10086
(integer) 1
```

使用 `BF.ADD`向名称为 `orders` 的布隆过滤器添加 10086 这个元素。

如果是多个元素同时添加，则使用 `BF.MADD key {item ...}`，如下：

```
BF.MADD orders 10087 10089
1) (integer) 1
2) (integer) 1
```

## 判断订单是否存在

```
# BF.EXISTS {key} {item}
BF.EXISTS orders 10086
(integer) 1
```

`BF.EXISTS` 判断一个元素是否存在于`BloomFilter`，返回值 = 1 表示存在。

如果需要批量检查多个元素是否存在于布隆过滤器则使用 `BF.MEXISTS`，返回值是一个数组：

- 1：存在；
- 0：不存在。

```
# BF.MEXISTS {key} {item}
BF.MEXISTS orders 100 10089
1) (integer) 0
2) (integer) 1
```

总体说，我们通过`BF.RESERVE、BF.ADD、BF.EXISTS`三个指令就能实现避免缓存穿透问题。

> 码哥，如何查看创建的布隆过滤器信息呢？

用 `BF.INFO key`查看，如下：

```
BF.INFO orders
 1) Capacity
 2) (integer) 10000000
 3) Size
 4) (integer) 7794184
 5) Number of filters
 6) (integer) 1
 7) Number of items inserted
 8) (integer) 3
 9) Expansion rate
10) (integer) 2
```

返回值：

- Capacity：预设容量；
- Size：实际占用情况，但如何计算待进一步确认；
- Number of filters：过滤器层数；
- Number of items inserted：已经实际插入的元素数量；
- Expansion rate：子过滤器扩容系数（默认 2）；

> 码哥，如何删除布隆过滤器呢？

目前布隆过滤器不支持删除，布谷过滤器Cuckoo Filter是支持删除的。

Bloom 过滤器在插入项目时通常表现出更好的性能和可伸缩性（因此，如果您经常向数据集添加项目，那么 Bloom 过滤器可能是理想的）。布谷鸟过滤器在检查操作上更快，也允许删除。

大家有兴趣可可以看下：https://oss.redis.com/redisbloom/Cuckoo_Commands/)

> 码哥，我想知道你是如何掌握这么多技术呢？

其实我也是翻阅官方文档并做一些简单加工而已，这篇的文章内容实战就是基于 Redis 官方文档上面的例子：https://oss.redis.com/redisbloom/。

大家遇到问题一定要耐心的从官方文档寻找答案，培养自己的阅读和定位问题的能力。

# Redission 布隆过滤器实战

码哥的样例代码基于 Spring Boot 2.1.4，代码地址：https://github.com/MageByte-Zero/springboot-parent-pom。

添加 Redission 依赖：

```
<dependency>
  <groupId>org.redisson</groupId>
  <artifactId>redisson-spring-boot-starter</artifactId>
  <version>3.16.7</version>
</dependency>
```

使用 Spring boot 默认的 Redis 配置方式配置 Redission：

```
spring:
  application:
    name: redission

  redis:
    host: 127.0.0.1
    port: 6379
    ssl: false
```

创建布隆过滤器

```
@Service
public class BloomFilterService {

    @Autowired
    private RedissonClient redissonClient;

    /**
     * 创建布隆过滤器
     * @param filterName 过滤器名称
     * @param expectedInsertions 预测插入数量
     * @param falseProbability 误判率
     * @param <T>
     * @return
     */
    public <T> RBloomFilter<T> create(String filterName, long expectedInsertions, double falseProbability) {
        RBloomFilter<T> bloomFilter = redissonClient.getBloomFilter(filterName);
        bloomFilter.tryInit(expectedInsertions, falseProbability);
        return bloomFilter;
    }

}
```

单元测试

```
@Slf4j
@RunWith(SpringRunner.class)
@SpringBootTest(classes = RedissionApplication.class)
public class BloomFilterTest {

    @Autowired
    private BloomFilterService bloomFilterService;

    @Test
    public void testBloomFilter() {
        // 预期插入数量
        long expectedInsertions = 10000L;
        // 错误比率
        double falseProbability = 0.01;
        RBloomFilter<Long> bloomFilter = bloomFilterService.create("ipBlackList", expectedInsertions, falseProbability);

        // 布隆过滤器增加元素
        for (long i = 0; i < expectedInsertions; i++) {
            bloomFilter.add(i);
        }
        long elementCount = bloomFilter.count();
        log.info("elementCount = {}.", elementCount);

        // 统计误判次数
        int count = 0;
        for (long i = expectedInsertions; i < expectedInsertions * 2; i++) {
            if (bloomFilter.contains(i)) {
                count++;
            }
        }
        log.info("误判次数 = {}.", count);
        bloomFilter.delete();
    }
}
```

注意事项：如果是 Redis Cluster 集群，则需要 `RClusteredBloomFilter bloomFilter = redisson.getClusteredBloomFilter("sample");`