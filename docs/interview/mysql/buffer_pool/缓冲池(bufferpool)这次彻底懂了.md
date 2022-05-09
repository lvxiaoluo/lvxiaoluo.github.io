# 缓冲池 (buffer pool)，这次彻底懂了！！！

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/0251b21faac041ff93068f5571c21fd0~tplv-k3u1fbpfcp-zoom-1.image)

应用系统分层架构，为了加速数据访问，会把最常访问的数据，放在**缓存** (cache) 里，避免每次都去访问数据库。

操作系统，会有**缓冲池** (buffer pool) 机制，避免每次访问磁盘，以加速数据的访问。

MySQL 作为一个存储系统，同样具有**缓冲池** (buffer pool) 机制，以避免每次查询数据都进行磁盘 IO。

今天，和大家聊一聊 InnoDB 的缓冲池。

**InnoDB 的缓冲池缓存什么？有什么用？**

缓存表数据与索引数据，把磁盘上的数据加载到缓冲池，避免每次访问都进行磁盘 IO，起到加速访问的作用。

速度快，那**为啥不把所有数据都放到缓冲池里**？

凡事都具备两面性，抛开数据易失性不说，访问快速的反面是存储容量小：

（1）缓存访问快，但容量小，数据库存储了 200G 数据，缓存容量可能只有 64G；

（2）内存访问快，但容量小，买一台笔记本磁盘有 2T，内存可能只有 16G；

因此，只能把 “最热” 的数据放到 “最近” 的地方，以 “最大限度” 的降低磁盘访问。

**如何管理与淘汰缓冲池，使得性能最大化呢？**

在介绍具体细节之前，先介绍下 “预读” 的概念。

**什么是预读？**

磁盘读写，并不是按需读取，而是按页读取，一次至少读一页数据（一般是 4K），如果未来要读取的数据就在页中，就能够省去后续的磁盘 IO，提高效率。

**预读为什么有效？**

数据访问，通常都遵循 “集中读写” 的原则，使用一些数据，大概率会使用附近的数据，这就是所谓的“局部性原理”，它表明提前加载是有效的，确实能够减少磁盘 IO。

**按页 (4K) 读取，和 InnoDB 的缓冲池设计有啥关系？**

（1）磁盘访问按页读取能够提高性能，所以缓冲池一般也是按页缓存数据；

（2）预读机制启示了我们，能把一些 “可能要访问” 的页提前加入缓冲池，避免未来的磁盘 IO 操作；

**InnoDB 是以什么算法，来管理这些缓冲页呢？**

最容易想到的，就是 LRU(Least recently used)。

*画外音：memcache，OS 都会用 LRU 来进行页置换管理，但 MySQL 的玩法并不一样。*

**传统的 LRU 是如何进行缓冲页管理？**

最常见的玩法是，把入缓冲池的页放到 LRU 的头部，作为最近访问的元素，从而最晚被淘汰。这里又分两种情况：

（1）**页已经在缓冲池里**，那就只做 “移至”LRU 头部的动作，而没有页被淘汰；

（2）**页不在缓冲池里**，除了做 “放入”LRU 头部的动作，还要做 “淘汰”LRU 尾部页的动作；

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/b4eec8cd84f04138a15f0839995a9cbf~tplv-k3u1fbpfcp-zoom-1.image)

如上图，假如管理缓冲池的 LRU 长度为 10，缓冲了页号为 1，3，5…，40，7 的页。

假如，接下来要访问的数据在页号为 4 的页中：

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/d99e2b235a834b64857a692919ca0de5~tplv-k3u1fbpfcp-zoom-1.image)

（1）页号为 4 的页，本来就在缓冲池里；

（2）把页号为 4 的页，放到 LRU 的头部即可，没有页被淘汰；

*画外音：为了减少数据移动，LRU 一般用链表实现。*

假如，再接下来要访问的数据在页号为 50 的页中：

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/cd0712c8b4f74780839f7321c377da8a~tplv-k3u1fbpfcp-zoom-1.image)

（1）页号为 50 的页，原来不在缓冲池里；

（2）把页号为 50 的页，放到 LRU 头部，同时淘汰尾部页号为 7 的页；

**传统的 LRU 缓冲池算法十分直观**，OS，memcache 等很多软件都在用，**MySQL 为啥这么矫情，不能直接用呢？**

这里有两个问题：

（1）预读失效；

（2）缓冲池污染；

**什么是预读失效？**

由于预读 (Read-Ahead)，提前把页放入了缓冲池，但最终 MySQL 并没有从页中读取数据，称为预读失效。

**如何对预读失效进行优化？**

要优化预读失效，思路是：

（1）让预读失败的页，停留在缓冲池 LRU 里的时间尽可能短；

（2）让真正被读取的页，才挪到缓冲池 LRU 的头部；

以保证，真正被读取的热数据留在缓冲池里的时间尽可能长。

具体方法是：

（1）将 LRU 分为两个部分：

- 新生代 (new sublist)
- 老生代 (old sublist)

（2）新老生代收尾相连，即：新生代的尾 (tail) 连接着老生代的头 (head)；

（3）新页（例如被预读的页）加入缓冲池时，只加入到老生代头部：

- 如果数据真正被读取（预读成功），才会加入到新生代的头部
- 如果数据没有被读取，则会比新生代里的 “热数据页” 更早被淘汰出缓冲池

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/5ea5a704ea924787a95a3e073ef262d2~tplv-k3u1fbpfcp-zoom-1.image)

举个例子，整个缓冲池 LRU 如上图：

（1）整个 LRU 长度是 10；

（2）前 70% 是新生代；

（3）后 30% 是老生代；

（4）新老生代首尾相连；

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/aa0a4f2f5adf4e68972e6b81d2c6a56f~tplv-k3u1fbpfcp-zoom-1.image)

假如有一个页号为 50 的新页被预读加入缓冲池：

（1）50 只会从老生代头部插入，老生代尾部（也是整体尾部）的页会被淘汰掉；

（2）假设 50 这一页不会被真正读取，即预读失败，它将比新生代的数据更早淘汰出缓冲池；

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/8f0df6e3aa4940838d08fdba2d18ed5f~tplv-k3u1fbpfcp-zoom-1.image)

假如 50 这一页立刻被读取到，例如 SQL 访问了页内的行 row 数据：

（1）它会被立刻加入到新生代的头部；

（2）新生代的页会被挤到老生代，此时并不会有页面被真正淘汰；

改进版缓冲池 LRU 能够很好的解决 “预读失败” 的问题。

*画外音：但也不要因噎废食，因为害怕预读失败而取消预读策略，大部分情况下，局部性原理是成立的，预读是有效的。*

新老生代改进版 LRU 仍然解决不了缓冲池污染的问题。

**什么是 MySQL 缓冲池污染？**

当某一个 SQL 语句，要批量扫描大量数据时，可能导致把缓冲池的所有页都替换出去，导致大量热数据被换出，MySQL 性能急剧下降，这种情况叫缓冲池污染。

例如，有一个数据量较大的用户表，当执行：

select * from user where name like "%shenjian%";

虽然结果集可能只有少量数据，但这类 like 不能命中索引，必须全表扫描，就需要访问大量的页：

（1）把页加到缓冲池（插入老生代头部）；

（2）从页里读出相关的 row（插入新生代头部）；

（3）row 里的 name 字段和字符串 shenjian 进行比较，如果符合条件，加入到结果集中；

（4）… 直到扫描完所有页中的所有 row…

如此一来，所有的数据页都会被加载到新生代的头部，但只会访问一次，真正的热数据被大量换出。

**怎么处理扫描大量数据导致的缓冲池污染问题呢？**

MySQL 缓冲池加入了一个 “老生代停留时间窗口” 的机制：

（1）假设 T = 老生代停留时间窗口；

（2）插入老生代头部的页，即使立刻被访问，并不会立刻放入新生代头部；

（3）只有**满足** “被访问” 并且 “在老生代停留时间” 大于 T，才会被放入新生代头部；

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/251ac636f81844fea8606656676ef4ac~tplv-k3u1fbpfcp-zoom-1.image)

继续举例，假如批量数据扫描，有 51，52，53，54，55 等五个页面将要依次被访问。

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/e0c81ad37c1144daac23ded0adc14013~tplv-k3u1fbpfcp-zoom-1.image)

如果没有 “老生代停留时间窗口” 的策略，这些批量被访问的页面，会换出大量热数据。

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/69fe975a01cb403c95d541bfb87e4c02~tplv-k3u1fbpfcp-zoom-1.image)

加入 “老生代停留时间窗口” 策略后，短时间内被大量加载的页，并不会立刻插入新生代头部，而是优先淘汰那些，短期内仅仅访问了一次的页。

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/5e69f5bcda624a2281e2bf5f1bf1c025~tplv-k3u1fbpfcp-zoom-1.image)

而只有在老生代呆的时间足够久，停留时间大于 T，才会被插入新生代头部。

**上述原理，对应 InnoDB 里哪些参数？**

有三个比较重要的参数。

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/434a0354f7454adbb09ba377bf5c1a75~tplv-k3u1fbpfcp-zoom-1.image)

**参数**：innodb_buffer_pool_size

**介绍**：配置缓冲池的大小，在内存允许的情况下，DBA 往往会建议调大这个参数，越多数据和索引放到内存里，数据库的性能会越好。

**参数**：innodb_old_blocks_pct

**介绍**：老生代占整个 LRU 链长度的比例，默认是 37，即整个 LRU 中新生代与老生代长度比例是 63:37。

*画外音：如果把这个参数设为 100，就退化为普通 LRU 了。*

**参数**：innodb_old_blocks_time

**介绍**：老生代停留时间窗口，单位是毫秒，默认是 1000，即同时满足 “被访问” 与“在老生代停留时间超过 1 秒”两个条件，才会被插入到新生代头部。

**总结**

（1）缓冲池 (buffer pool) 是一种**常见的降低磁盘访问的机制；**

（2）缓冲池通常**以页 (page) 为单位缓存数据；**

（3）缓冲池的**常见管理算法是 LRU**，memcache，OS，InnoDB 都使用了这种算法；

（4）InnoDB 对普通 LRU 进行了优化：

- 将缓冲池分为**老生代和新生代**，入缓冲池的页，优先进入老生代，页被访问，才进入新生代，以解决预读失效的问题
- 页被访问，且在老生代**停留时间超过配置阈值**的，才进入新生代，以解决批量数据访问，大量热数据淘汰的问题

**思路**，比结论重要。

解决了什么问题，比方案重要。

***\*架构师之路\** - 分享技术思路**

相关推荐：

《[写一个 cache，要掌握哪些技术点](https://link.juejin.cn/?target=http%3A%2F%2Fmp.weixin.qq.com%2Fs%3F__biz%3DMjM5ODYxMDA5OQ%3D%3D%26mid%3D2651962373%26idx%3D1%26sn%3D7bb5925b94ea1240abcf89e2e5f89916%26chksm%3Dbd2d09d98a5a80cf9e16ab67df608989012e503b116edbf0feac12e05f280ec4da97bf44b952%26scene%3D21%23wechat_redirect) 》

《[6 条 shell 小技巧，让脚本更专业 | 1 分钟系列](https://link.juejin.cn/?target=http%3A%2F%2Fmp.weixin.qq.com%2Fs%3F__biz%3DMjM5ODYxMDA5OQ%3D%3D%26mid%3D2651962411%26idx%3D1%26sn%3Dd6d46fd5ae0b4779770cbbfd808fa430%26chksm%3Dbd2d09f78a5a80e12c96f4dcc810c2a44708b62232afca1ad065a3060458bcdf88132eec8c45%26scene%3D21%23wechat_redirect) 》

《[MyISAM 与 InnoDB 的索引差异 | 1 分钟系列](https://link.juejin.cn/?target=http%3A%2F%2Fmp.weixin.qq.com%2Fs%3F__biz%3DMjM5ODYxMDA5OQ%3D%3D%26mid%3D2651961494%26idx%3D1%26sn%3D34f1874c1e36c2bc8ab9f74af6546ec5%26chksm%3Dbd2d0d4a8a5a845c566006efce0831e610604a43279aab03e0a6dde9422b63944e908fcc6c05%26scene%3D21%23wechat_redirect) 》

《[两个小工具，分析 MySQL 死锁](https://link.juejin.cn/?target=http%3A%2F%2Fmp.weixin.qq.com%2Fs%3F__biz%3DMjM5ODYxMDA5OQ%3D%3D%26mid%3D2651962432%26idx%3D1%26sn%3D3459e82428cb9bb1de4677fa6b5a1c2d%26chksm%3Dbd2d099c8a5a808af5926a8be9c900c0bca57a8b8e61b192272d919e38d607a03b5ac4e0990a%26scene%3D21%23wechat_redirect) 》

调研：**缓冲池**是**缓存**的差别是啥？

*画外音：长文阅读和转发低，为啥？*