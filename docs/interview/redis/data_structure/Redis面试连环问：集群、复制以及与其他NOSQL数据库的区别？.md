# Redis面试连环问：集群、复制以及与其他NOSQL数据库的区别？

### 前言

面试官问:您熟悉redis?搭建过redis集群？rediscluster底层的主从复制rdb如何工作的？……

接下来，就是一轮迫击炮，犹如把面试者按在砧板上，轮番炮击……

### 您目前用redis那种集群模式？

采用Redis Cluster无中心结构集群模式

#### 拓展

master-slave模式模式存在的问题是，master宕机之后，从机只能读，不可写，不能保证高可用。Redis Cluster每个节点保存数据和整个集群状态,每个节点都和其他所有节点连接。节点之间使用gossip协议传播信息以及发现新节点。

- Redis 集群是一个分布式（distributed）、容错（fault-tolerant）的 Redis 实现，集群可以使用的功能是普通单机 Redis 所能使用的功能的一个子集（subset）。
- Redis 集群中不存在中心（central）节点或者代理（proxy）节点，集群的其中一个主要设计目标是，达到线性可扩展性（linear scalability）。
- Redis 集群为了保证一致性（consistency），而牺牲了一部分容错性：系统会在保证对网络断线（net split）和节点失效（node failure）具有有限（limited）抵抗力的前提下，尽可能地保持数据的一致性。

redis集群技术，是构建高性能网站架构的重要手段，试想在网站承受高并发访问压力的同时，还需要从海量数据中查询出满足条件的数据，并快速响应，在单个 redis 内存不足时，使用 Cluster 进行分片存储，把数据根据某种规则放入多个不同的服务器节点，来降低单节点服务器的压力。

### Redis集群中的节点如何保证数据一致？

采用异步复制，进行数据同步，保持各个节点数据一致。

![图片](https://mmbiz.qpic.cn/mmbiz_png/JfTPiahTHJhpQCibgccXKWcuOltk9dADB7oazyrXvoicTqaiabUAEOON9cpWFUEqSuR6tibfGM68W4sWVpRhxicoWMOA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

当客户端向从S服务器发送SLAVEOF命令，要求从S服务器复制主M服务器时，从S服务器首先需要执行同步操作，也即是，将从S服务器的数据库状态更新至主M服务器当前所处的数据库状态。

从S服务器对主M服务器的同步操作,需要通过向主M服务器发送SYNC命令来完成，以下是SYNC命令的执行步骤：

1. 从S服务器向主M服务器发送SYNC命令。
2. 收到SYNC命令的主M服务器执行BGSAVE命令，在后台生成一个RDB文件，并使用一个缓冲区,记录从现在开始执行的所有写命令。
3. 当主M服务器的BGSAVE命令执行完毕时，主M服务器会将BGSAVE命令生成的RDB文件,发送给从S服务器，从S服务器接收并载入这个RDB文件，将自己的数据库状态更新至主M服务器,执行BGSAVE命令时的数据库状态。
4. 主M服务器将记录在缓冲区里面的所有写命令,发送给从S服务器，从S服务器执行这些写命令，将自己的数据库状态更新至主M服务器数据库当前所处的状态。

### Redis有哪些适合的场景？

- Session共享(单点登录)
- 页面缓存
- 队列
- 排行榜/计数器
- 发布/订阅

### Redis如何做内存优化？

尽可能使用散列c表（hash）----是说散列表里面存储的数少，使用的内存非常小，所以尽可能的，将你的数据模型抽象到一个散列表里面。

比如你的web系统中有一个用户对象，不要为这个用户的名称，姓氏，邮箱，密码设置单独的key，而是应该把这个用户的所有信息存储到一张散列表里面.

### Redis回收进程如何工作的？

一个客户端运行了新的命令，添加了新的数据。

Redi检查内存使用情况，如果大于maxmemory的限制, 则根据设定好的LRU算法策略进行回收。

### Redis 的持久化机制是什么？各自的优缺点？

Redis提供两种持久化机制 RDB 和 AOF 机制:

##### 1、RDB（Redis DataBase)持久化方式：

是指用数据集快照的方式，半持久化模式记录 redis 数据库的所有键值对,在某个时间点，将数据写入一个临时文件，持久化结束后，用这个临时文件替换上次持久化的文件，达到数据恢复。

**优点：**

- 只有一个文件 dump.rdb，方便持久化。
- 容灾性好，一个文件可以保存到安全的磁盘。
- 性能最大化，fork 子进程来完成写操作，让主进程继续处理命令，所以是 IO最大化。
- 使用单独子进程来进行持久化，主进程不会进行任何 IO 操作，保证了 redis的高性能。
- 相对于数据集大时，比 AOF 的启动效率更高。

**缺点：**

- 数据安全性低。
- RDB 是间隔一段时间进行持久化，如果持久化期间 ，redis 发生故障，会发生数据丢失。所以这种方式更适合数据要求不严谨的时候

##### 2、AOF（Append-only file)持久化方式：

是指所有的命令行记录，以 redis 命令请求协议的格式，完全持久化存储，保存为 aof 文件。

**优点：**

- 数据安全，aof持久化，可以配置appendfsync属性，有always，每进行一次命令操作就记录到aof文件中一次。
- 通过append模式写文件，即使中途服务器宕机，可以通过redis-check-aof工具解决数据一致性问题。
- AOF机制的rewrite模式。AOF文件没被rewrite之前（文件过大时，会对命令进行合并重写），可以删除其中的某些命令（比如误操作的flushall）)

![图片](https://mmbiz.qpic.cn/mmbiz_png/JfTPiahTHJhpQCibgccXKWcuOltk9dADB7cWu7Dh2YUuEIicBqprqP65YWWRPmvB6p3Jt21VTmOc0OKaZgkENS1wQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

**缺点：**

- AOF 文件比 RDB 文件大，且恢复速度慢。
- 数据集大的时候，比 rdb 启动效率低。

### Redis是单线程的，那它为什么这么快？

Redis的单线程，其实是指执行Redis命令的核心模块是单线程的，也就是文件事件处理器，主要由四个部分组成：套接字、IO多路复用、文件事件分派器和事件处理器。

Redis6.0其实已经支持多线程来提高性能了。而Redis之所以快主要原因：

- Redis是基于内存的，数据都存放在内存中，速度非常快
- Redis的IO模型是非阻塞IO
- Redis核心模块的单线程使得可以避免线程切换带来的开销
- Redis是单线程的，可以通过开启多个Redis实例来利用多核

![图片](https://mmbiz.qpic.cn/mmbiz_png/JfTPiahTHJhpQCibgccXKWcuOltk9dADB7fDewZDERtsOP0icsbS230KuMhiaGbuvSeicueq2QyV1hTaxP9YIEhv90A/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

### Redis支持哪几种数据类型？优势是什么？比其他key-value存储数据库有什么不同？

##### 支持多种类型的数据结构

![图片](https://mmbiz.qpic.cn/mmbiz_png/JfTPiahTHJhpQCibgccXKWcuOltk9dADB7W41dPJsJ5Aa4Jp8qZ7jjJeMAJiael3lZQoecficBRtZ3oX4AzhYpfmYA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

![图片](https://mmbiz.qpic.cn/mmbiz_png/JfTPiahTHJhpQCibgccXKWcuOltk9dADB7Nr7wMjDyjicFzoXibnSYImKn4x0bAsxUAxMDs2UKPbUpFibuydp2qN27Q/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

### Redis优势

- **性能极高**--------Redis能读的速度是11万次/s,写的速度是8.1万次/s。
- **丰富的数据类型**--------Redis支持二进制案例的Strings,Lists,Hashes,Sets及OrderedSets数据类型操作。
- **原子**--------Redis的所有操作都是原子性的，意思就是要么成功执行，要么失败完全不执行。单个操作是原子性的。多个操作也支持事务，即原子性，结合lua脚本，用MULTI和EXEC指令包起来。
- **丰富的特性**--------Redis还支持publish/subscribe,通知,key过期等等特性。
- **Redis单点吞吐量**--------单点TPS达到8万/秒，QPS达到10万/秒。

可以复制脚本生成的单个写入命令，而不是复制整个脚本，我们称之为【脚本影响复制】（script effects replication）。

- 在这种复制模式下，当执行Lua脚本时，Redis会收集由Lua脚本引擎执行的所有实际修改数据集的命令。
- 当脚本执行完成后，由脚本生成的命令序列，将被包装到 MULTI/EXEC 事务中，并发送到从节点，和进行AOF持久化保存。
- 当我们加了`replicate_commands()`以后，到AOF备份文件里面查看，发现会把写命令转换为MULTI...EXEC命令:

![图片](https://mmbiz.qpic.cn/mmbiz_png/JfTPiahTHJhpQCibgccXKWcuOltk9dADB77Zb3JdcjFZhVdQJIThGuIyk4xaps451Dgr4XmBfJkbmadibkIVzLynQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

结合lua脚本，用MULTI和EXEC指令包起来，并且在Lua脚本中读多写少的情况下，只持久化和复制写命令，可以节省重启和备库的CPU时间。

### Redis与其他key-value存储NOSQL数据库有什么不同？

- Redis是一个开源（BSD许可），内存存储的数据结构服务器，可用作数据库，高速缓存和消息队列代理。
- Memcached是一个自由开源的，高性能，分布式内存对象缓存系统。
- MongoDB是一个基于分布式文件存储的数据库,文档型的非关系型数据库，与上面两者不同， MongoDB不支持事务。

#### 性能上：

- Memcached单个key-value大小有限，一个value最大只支持1MB，而Redis最大支持512MB。
- 而在100k以上的数据中，Memcached性能要高于Redis，虽然Redis最近也在存储大数据的性能上进行优化，但是比起 Memcached，还是稍有逊色。
- Memcached只是个内存缓存，对可靠性无要求；而Redis更倾向于内存数据库，因此对对可靠性方面要求比较高。

#### 内存空间和数据量大小：

- MemCached可以修改最大内存，采用LRU算法。
- Redis增加了VM的特性，突破了物理内存的限制。
- MongoDB 适合大数据量的存储，依赖操作系统 VM 做内存管理，吃内存也比较厉害。

#### 操作便利上：

- MemCached数据结构单一，仅用来缓存数据。
- 而Redis支持更加丰富的数据类型，也可以在服务器端直接对数据进行丰富的操作,这样可以减少网络IO次数和数据体积。
- Mongodb 支持丰富的数据表达，索引，最类似关系型数据库，支持的查询语言非常丰富。

#### 可靠性上：

- MemCached不支持数据持久化，断电或重启后数据消失，但其稳定性是有保证的。
- Redis支持数据持久化和数据恢复，允许单点故障，但是同时也会付出性能的代价。
- MongoDB 从 1.8 版本开始采用 binlog 方式支持持久化的可靠性。

#### 应用场景：

- Memcached：动态系统中减轻数据库负载，提升性能；做缓存，适合多读少写，大数据量的情况（如人人网大量查询用户信息、好友信息、文章信息等）。
- Redis：适用于对读写效率要求都很高，数据处理业务复杂和对安全性要求较高的系统（如新浪微博的计数和微博发布部分系统，对数据安全性、读写要求都很高）。
- MongoDB:主要解决海量数据的访问效率问题（没有事务性要求的，适合kv存储，评论，文章，邮件存储，文本存储，json存储，爬虫存储，游戏领域，tb级以上的大数据存储，这种数据用mongodb存储，mongodb更容易实现水平扩展，可以存储比数据库更多的数据）。