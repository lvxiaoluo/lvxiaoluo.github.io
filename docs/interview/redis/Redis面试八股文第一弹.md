# Redis面试八股文第一弹



***\*推荐阅读：\****

- ***\*[程序人生系列](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=MzA4NjU1MzA2MQ==&action=getalbum&album_id=1816486914183512067#wechat_redirect)\****
- ***\*[大厂面经系列](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=MzA4NjU1MzA2MQ==&action=getalbum&album_id=2105056235833131010#wechat_redirect)\****
- ***\*[面试八股文系列](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=MzA4NjU1MzA2MQ==&action=getalbum&album_id=1966226418825035778#wechat_redirect)\****
- ***\*[写了篇小作文：在清华大学当学霸是种怎样的体验？](http://mp.weixin.qq.com/s?__biz=MzA4NjU1MzA2MQ==&mid=2647725533&idx=1&sn=ecb1c509f25069888653afdab97c2d39&chksm=87e34d57b094c44162f21a3d88b71c368d484e7132ddaf19680986dc6fcc96ef7e548edafb28&scene=21#wechat_redirect)\****
- ***\*[一文搞定动态规划常考算法题](http://mp.weixin.qq.com/s?__biz=MzA4NjU1MzA2MQ==&mid=2647725524&idx=1&sn=2a33ad0d0f1c160e5429437f581a4be5&chksm=87e34d5eb094c4484d258a63255ef9fa203f430168c9d8b44fad1ce4b70d18868d78e8fbfbb1&scene=21#wechat_redirect)
  \****

***\*文章目录：\****

- Redis概述

- - 什么是Redis？
  - Redis的优缺点？
  - Redis为什么常常用做缓存？相比于guava有什么优势？
  - Redis和Memcached的区别与共同点？
  - Redis是单线程还是多线程？Redis为什么这么快？
  - Redis6.0之后为什么引入了多线程？
  - Redis的数据类型有哪些？
  - Redis的数据结构有哪些？
  - Redis的应用场景有哪些？
  - Redis是单线程的，如何提高CPU的利用率？

- 过期键的删除策略

- - 键的过期删除策略
  - Redis的内存淘汰机制是什么样的？

- Redis的持久化

- - 什么是Redis的持久化？
  - Redis常见的持久化机制有哪些？有什么有优缺点？



## Redis概述

### 什么是Redis？

Redis是一个高性能的非关系型的键值对数据库，使用**C**编写实现的。与传统的数据库不同的是Redis是存在内存中的，所以读写速度非常快，每秒可以处理超过**10万次**的读写操作，这也是Redis常常被用作**缓存**的原因。

### Redis的优缺点？

优点：

- **读写性能好**，读的速度可达110000次/s，写的速度可达81000次/s。
- **支持数据持久化**，有AOF和RDB两中持久化方式
- **数据结构丰富**，支持String、List、Set、Hash等结构
- **支持事务**，Redis所有的操作都是原子性的，并且还支持几个操作合并后的原子性执行，原子性指操作要么成功执行，要么失败不执行，不会执行一部分。
- **支持主从复制**，主机可以自动将数据同步到从机，进行读写分离。

缺点：

- 因为Redis是将数据存到内存中的，所以会受到内存大小的限制，不能用作海量数据的读写
- Redis不具备自动容错和恢复功能，主机或从机宕机会导致前端部分读写请求失败，需要重启机器或者手动切换前端的IP才能切换

### Redis为什么常常用做缓存？相比于guava有什么优势？

缓存的定义是访问速度比一般随机存取存储器快的一种高速存储器，而因为Redis是基于内存提供了高性能的数据存取功能，其比较显著的优势就是非常地快。

缓存可以分为本地缓存或者分布式缓存，比较常用的guava缓存就是一种本地缓存，其主要特点是**轻量并且快速**，生命周期随着JVM的销毁而结束，缺点是在多实例的情况下，每个实例都要自己保存一份缓存，这样会导致缓存的一致性出现问题。

Redis则是分布式缓存，在多实例情况下，每个实例都共享一份缓存数据，缓存具备一致性。缺点是要保持Redis的高可用整体架构会比较复杂。

### Redis和Memcached的区别与共同点？

相同点：

- 两者的读写性能都比较高
- 都是基于内存的数据库，通常被当作缓存使用
- 都有过期策略
- 都是基于C语言实现

不同点：

|    不同点    |                            Redis                             |         Memcached         |
| :----------: | :----------------------------------------------------------: | :-----------------------: |
| 是否支持复制 |                         支持主从复制                         |        不支持复制         |
|   key长度    |                        长度最大为 2GB                        |   长度最多为 250 个字节   |
|   数据类型   | 不仅支持key-value类型的数据，还支持hash、list、set、zset等数据等数据类型的数据 | 仅支持key-value类型的数据 |
|  数据持久化  |             支持数据持久化，可以将数据保存到磁盘             |     不支持数据持久化      |
|  网络IO模型  |                   单线程的多路 IO 复用模型                   |   多线程的非阻塞IO模式    |
|     集群     |                   原生支持cluster 模式集群                   |          无原生           |

### Redis是单线程还是多线程？Redis为什么这么快？

Redis6.0之前是单线程的，为什么Redis6.0之前采用单线程而不采用多线程呢？

简单来说，就是Redis官方认为没必要，单线程的Redis的瓶颈通常在**CPU的IO**，而在使用Redis时几乎不存在CPU成为瓶颈的情况。使用Redis主要的瓶颈在内存和网络，并且使用单线程也存在一些优点，比如系统的复杂度较低，可为维护性较高，避免了并发读写所带来的一系列问题。

Redis为什么这么快主要有以下几个原因：

- 运行在内存中
- 数据结构简单
- 使用多路IO复用技术
- 单线程实现，单线程避免了线程切换、锁等造成的性能开销。

### Redis6.0之后为什么引入了多线程？

前面说了那么多Redis使用单线程的原因，但从Redis6.0后开始支持多线程了，简直打脸有点快。那么为什么较新的Redis版本又开始支持多线程了呢？

前面也说了Redis的瓶颈在**内存和网络**，Redis6.0引入多线程主要是为了解决**网路IO**读写这个瓶颈，**执行命令还是单线程执行的**，所以也不存在线程安全问题。

Redis6.0默认是否开启了多线程呢？

默认是没有开启的，如需开启，需要修改配置文件redis.conf：io-threads-do-reads  no，no改为yes

### Redis的数据类型有哪些？

Redis的常见的数据类型有S**tring、Hash、Set、List、ZSet**。还有三种不那么常见的数据类型：**Bitmap、HyperLogLog、Geospatial**。

| 数据类型 | 可以存储的值                       | 可进行的操作                                                 | 应用场景                              |
| :------- | :--------------------------------- | :----------------------------------------------------------- | :------------------------------------ |
| STRING   | 字符串、整数、浮点数               | 对整数或浮点数可以进行自增、自减操作 对字符串操作            | 键值对缓存及常规计数: 微博数， 粉丝数 |
| LIST     | 列表（内部使用双向列表实现）       | 向列表两端添加元素，或者获得列表的某一个片段                 | 存储文章ID列表、存储评论列表等        |
| SET      | 无序集合（内部使用值为空的散列表） | 增加/删除元素、获取集合中元素、取交集并集等等                | 共同好友、共同关注等                  |
| ZSET     | 有序集合（内部使用散列表和跳表）   | 添加、获取、删除元素 根据分值范围或者成员来获取元素 计算一个键的排名 | 去重、获取排名前几的用户              |
| HASH     | 包含键值对的无序散列表             | 添加、获取、移除单个键值对 获取所有键值对 检查某个键是否存在 | 常用于存储对象                        |

**Bitmap：\**位图，是一个以位为单位的数组，数组中只能存储1或0，数组的下标在Bitmap中叫做偏移量。Bitmap实现统计功能，更省空间。面试中常问的布隆过滤器就有用到这种数据结构，布隆过滤器可以判断出\**哪些数据一定不在数据库中**，所以常被用来解决**Redis缓存穿透**问题。

**Hyperloglog：\**HyperLogLog 是一种用于\**统计基数**的数据集合类型，每个 HyperLogLog 键只需要花费 12 KB 内存，就可以计算接近 2^64 个不同元素的基数。HyperLogLog 的**优点**是，在输入元素的数量或者体积非常大时，计算基数所需的空间总是固定 的、并且是很小的。**缺点**是 HyperLogLog 的统计规则是基于概率完成的，所以它给出的统计结果是有一定误差的，标准误算率是 0.81%。常见的应用场景：统计网站的UV

**Geospatial：**主要用于存储地理位置信息，常用于定位附近的人，打车距离的计算等。

### Redis的数据结构有哪些？

> 很多人都会把数据结构和数据类型混为一谈，包括很多面试官问的时候也没有刻意区分这两个。Redis的数据结构比较多，篇幅有限，这里只重点介绍面试常问的跳跃表。

Redis的数据结构有**简单动态字符串**、**链表**、**字典**、**跳跃表**、**整数集合**、**压缩列表**等。

**简单动态字符串：**大家都知道，Redis的底层是用C语言编写，但Redis并没有直接使用C语言传统的字符串表示，而是构建了一种名为简单动态字符串的抽象类型。

**链表：**链表提供了高效的节点重排能力，以及顺序性的节点访问方式，并且可以通过增删节点来灵活地调整链表的长度。**链表是列表的底层实现之一**。

**字典：**字典，又称为符号表（symbol table）、关联数组（associativearray）或映射（map），是一种用于保存键值对（key-value pair）的抽象数据结构。字典在Redis中的应用相当广泛，比如Redis的数据库就是使用字典来作为底层实现的，对数据库的增、删、查、改操作也是构建在对字典的操作之上的。

**整数集合：** **整数集合（intset）是集合键的底层实现之一**，当一个集合只包含整数值元素，并且这个集合的元素数量不多时，Redis就会使用整数集合作为集合键的底层实现。

**压缩列表（ziplist）：**压缩列表是Redis为了节约内存而开发的，是由一系列特殊编码的连续内存块组成的顺序型（sequential）数据结构。

**对象：\**可能看到这里，很多人在想Redis的数据结构和数据类型的区别，其实上面介绍的是Redis的底层数据结构，但Redis并没有直接使用这些数据结构来实现键值对数据库，而是基于这些数据结构创建了一个\**对象系统**，这个系统包含**字符串对象、列表对象、哈希对象、集合对象**和**有序集合对象**这五种类型的对象，每种对象都用到了至少一种我们前面所介绍的数据结构，是不是这就和前面对上了。

看到这里很多人会好奇，为什么不直接使用这些底层数据结构，而是要创建对象系统。对象系统主要有以下优点：

- 通过这五种不同类型的对象，Redis可以在执行命令之前，根据对象的类型来判断一个对象是否可以执行给定的命令。
- 我们可以针对不同的使用场景，为对象设置多种不同的数据结构实现，从而优化对象在不同场景下的使用效率。
- 实现了基于引用计数技术的内存回收机制，当程序不再使用某个对象的时候，这个对象所占用的内存就会被自动释放，了解Java虚拟机的垃圾回收机制看到这里是不是很熟悉。
- edis还通过引用计数技术实现了对象共享机制，这一机制可以在适当的条件下，通过让多个数据库键共享同一个对象来节约内存。

**对象**这部分占了比较大的篇幅，其实面试中问的也不多，但为了更方便理解，介绍地多些。顺便看下这些底层数据结构和对象系统的对应关系。

![图片](https://mmbiz.qpic.cn/mmbiz_png/cBnxLn7axrx0VTnvCTPgad9olen13bA5f9I5bbicMr3uIqpbAvZan1jImI4g6q06tAza6Fe29wR1DGibaK4D96hw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

最后介绍下面试中常问的跳跃表。

**跳跃表（skiplist）：\**跳跃表（skiplist）是一种有序数据结构，它通过在每个节点中维持多个指向其他节点的指针，从而达到快速访问节点的目的。跳跃表支持\**平均O（logN）、最坏O（N）复杂度**的节点查找，还可以通过顺序性操作来批量处理节点。**跳跃表作是序集合键的底层实现之一**。

和链表、字典等数据结构被广泛地应用在Redis内部不同，Redis只在两个地方用到了跳跃表，一个是实现**有序集合键**，另一个是在**集群节****点中用作内部数据结构**，除此之外，跳跃表在Redis里面没有其他用途。

跳跃表本质上采用的是一种空间换时间的策略，是一种可以可以进行**二分查找**的**有序链表**，跳表在原有的有序链表上增加了**多级索引**，通过索引来实现快速查询。跳表不仅能提高搜索性能，同时也可以提高插入和删除操作的性能。

这是一个原始的有序列表，时间复杂度为O(n)。

![图片](https://mmbiz.qpic.cn/mmbiz_png/cBnxLn7axrx0VTnvCTPgad9olen13bA59VbiahWP6udcqCXiaRrsV66tAibUFhjqcNOu9ibfamkxKaPZBzneTax2aQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

为了提高查找效率，可以对链表建立一级索引，如下图，在之前找到11这个元素需要遍历6个节点，现在需要5个。链表越长，效率提升越明显。

![图片](https://mmbiz.qpic.cn/mmbiz_png/cBnxLn7axrx0VTnvCTPgad9olen13bA5GXw1cu4ja9NLuPzfUcFeVFlmm6KwsK29k9SfCGukw0yT6iaLRiczDENg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

为了继续提高查找效率可以继续增加索引

![图片](https://mmbiz.qpic.cn/mmbiz_png/cBnxLn7axrx0VTnvCTPgad9olen13bA5cGsQoGyIfQib5vm4JiaO1PTk84u64yxltIvzBt9x8gqnzTSaiakTCM0qA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

对于理想的跳表，每向上一层索引节点数量都是下一层的1/2，跳表的**时间复杂度为o(logn)，空间复杂度为o(n)**，虽然是空间换时间的策略，这里举例存储的只是数字，如果是存储比较大的对象，浪费的空间就不值得一提了，因为索引结点只需要存储关键值和几个指针，并不需要存储对象。

跳表相比于红黑树的优点（redis为什么用跳表不同红黑树）：

- 内存占用更少，自定义参数化决定使用多少内存
- 查询性能至少不比红黑树差
- 简单更容易实现和维护

上面这三个优点是我在一篇博客中看到，这个问题redis作者本人也回应过。我这蹩脚的英文水平就不翻译了，以免跑偏了。

- They are not very memory intensive. It's up to you basically. Changing parameters about the probability of a node to have a given number of levels will make then less memory intensive than btrees.
- A sorted set is often target of many ZRANGE or ZREVRANGE operations, that is, traversing the skip list as a linked list. With this operation the cache locality of skip lists is at least as good as with other kind of balanced trees.
- They are simpler to implement, debug, and so forth. For instance thanks to the skip list simplicity I received a patch (already in Redis master) with augmented skip lists implementing ZRANK in O(log(N)). It required little changes to the code.

最后，**说下Redis中的跳跃表和普通的跳跃表有什么区别？**

- Redis中的跳跃表分数（score）允许重复，即跳跃表的key允许重复，如果分数重复，还需要根据数据内容来进字典排序。普通的跳跃表是不支持的。
- 第1层链表不是一个单向链表，而是一个双向链表。这是为了方便以倒序方式获取一个范围内的元素。
- 在Redis的跳跃表中可以很方便地计算出每个元素的排名。

篇幅有限，关于跳表的实现细节就不过多介绍了，有兴趣的同学可以自行了解，本小节部分内容参考《Redis设计与实现》

### Redis的应用场景有哪些？

- 缓存：Redis基于内存，读写速度非常快，并且有键过期功能和键淘汰策略，可以作为缓存使用。
- 排行榜：Redis提供的有序集合可以很方便地实现排行榜。
- 分布式锁：Redis的setnx功能来实现分布式的锁。
- 社交功能：实现共同好友、共同关注等
- 计数器：通过String进行自增自减实现计数功能
- 消息队列：Redis提供了发布、订阅、阻塞队列等功能，可以实现一个简单的消息队列。

### Redis是单线程的，如何提高CPU的利用率？

可以在一个服务器上部署多个Redis实例，把他们当作不同的服务器使用。

## 过期键的删除策略

### 键的过期删除策略

常见的过期删除策略是**惰性删除**、**定期删除**、**定时删除**。

- 惰性删除：只有访问这个键时才会检查它是否过期，如果过期则清除。**优点：**最大化地节约CPU资源。**缺点：**如果大量过期键没有被访问，会一直占用大量内存。
- 定时删除：为每个设置过期时间的key都创造一个定时器，到了过期时间就清除。**优点：**该策略可以立即清除过期的键。**缺点：**会占用大量的CPU资源去处理过期的数据。
- 定期删除：每隔一段时间就对一些键进行检查，删除其中过期的键。该策略是惰性删除和定时删除的一个折中，既避免了占用大量CPU资源又避免了出现大量过期键不被清除占用内存的情况。

Redis中同时使用了**惰性删除**和**定期删除**两种。

### Redis的内存淘汰机制是什么样的？

Redis是基于内存的，所以容量肯定是有限的，有效的内存淘汰机制对Redis是非常重要的。

当存入的数据超过Redis最大允许内存后，会触发Redis的内存淘汰策略。在Redis4.0前一共有6种淘汰策略。

- volatile-lru：当Redis内存不足时，会在设置了过期时间的键中使用LRU算法移除那些最少使用的键。（注：在面试中，手写LRU算法也是个高频题，使用双向链表和哈希表作为数据结构）
- volatile-ttl：从设置了过期时间的键中移除将要过期的
- volatile-random：从设置了过期时间的键中随机淘汰一些
- allkeys-lru：当内存空间不足时，根据LRU算法移除一些键
- allkeys-random：当内存空间不足时，随机移除某些键
- noeviction：当内存空间不足时，新的写入操作会报错

前三个是在设置了**过期时间**的键的空间进行移除，后三个是在**全局的空间**进行移除

在Redis4.0后可以增加两个

- volatile-lfu：从设置过期时间的键中移除一些最不经常使用的键（LFU算法：Least Frequently Used)）
- allkeys-lfu：当内存不足时，从所有的键中移除一些最不经常使用的键

这两个也是一个是在设置了过期时间的键的空间，一个是在全局空间。

## Redis的持久化

### 什么是Redis的持久化？

因为Redis是基于内存的，为了让防止一些意外情况导致数据丢失，需要将数据持久化到磁盘上。

### Redis常见的持久化机制有哪些？有什么有优缺点？

Redis提供了两种不同的持久化方式，一种是**RDB**，一种是**AOF**。

**RDB**

RDB是redis默认的持久化方式，按照一定的时间间隔将内存的数据以快照的形式保存到硬盘，恢复时是将快照读取到内存中。RDB持久化实际操作过程是fork一个子进程，先将数据集写入临时文件，写入成功后，再替换之前的文件，用二进制压缩存储。如下图

![图片](https://mmbiz.qpic.cn/mmbiz_png/cBnxLn7axrx0VTnvCTPgad9olen13bA5eaCefOwaHeOlDxqwoE9bLOnd9zhzVScz6d7vgZSASbUZjjes38icXjQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

**优点：**

- 适合对大规模的数据恢复，比AOF的启动效率高
- 只有一个文件 dump.rdb，方便持久化
- 性能最大化，在开始持久化时，它唯一需要做的只是fork出子进程，之后再由子进程完成这些持久化的工作，这样就可以极大的避免服务进程执行IO操作了。

**缺点：**

- 数据安全性低，在一定间隔时间内做一次备份，如果Redis突然宕机，会丢失最后一次快照的修改
- 由于RDB是通过fork子进程来协助完成数据持久化工作的，因此当数据集较大时，可能会导致整个服务器停止服务几百毫秒，甚至是1秒钟。

**AOF**

AOF持久化以日志的形式记录服务器所处理的每一个写、删除操作，查询操作不会记录，以文本的方式记录，可以打开文件看到详细的操作记录。

![图片](https://mmbiz.qpic.cn/mmbiz_png/cBnxLn7axrx0VTnvCTPgad9olen13bA515NfEQjAHJgo2VazhvicLCZ2oaXqwjcUOZu46ssc7iasLeKbKdxl36icg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

**优点：**

- 具备更高的安全性，Redis提供了3种同步策略，分别是每秒同步、每修改同步和不同步。相比RDB突然宕机丢失的数据会更少，每秒同步会丢失一秒种的数据，每修改同步会不会丢失数据。
- 由于该机制对日志文件的写入操作采用的是append模式，因此在写入过程中即使出现宕机现象，也不会破坏日志文件中已经存在的内容。
- AOF包含一个格式清晰、易于理解的日志文件用于记录所有的修改操作，可以通过该文件完成数据的重建。

**缺点：**

- 对于相同数量的数据集而言，AOF文件通常要大于RDB文件。RDB 在恢复大数据集时的速度比 AOF 的恢复速度要快。
- 根据AOF选择同步策略的不同，效率也不同，但AOF在运行效率上往往会慢于RDB。