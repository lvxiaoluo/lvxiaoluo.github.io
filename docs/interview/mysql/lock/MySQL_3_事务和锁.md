## [MySQL_3_事务和锁](https://mp.weixin.qq.com/s?__biz=MzU0ODk5NzM1OA==&mid=2247484743&idx=1&sn=38caf3e9a25ffe0add1110c5d0713ded&chksm=fbb7d4c6ccc05dd0db75411f229ee4250e6d35bd357220cb229961a9d4c6642f4d5844a04855&scene=178&cur_album_id=1645696492390694916#rd)

原创 7cchen [AJCoder](javascript:void(0);) *2020-12-13*

收录于话题

\#MySQL

3个

# 事务与锁





## 1. 事务

### 1.1 什么是事务

**要么都成功，要么都失败**

（1）**事务原则**（**ACID**）

**原子性（Atomicity）**：要么都成功，要么都失败。

**一致性（Consistency）**：事务前后的数据完整性要保证一致。

**隔离性（Isolation）**：多个用户并发访问数据库时，数据库为每个用户开启的事务不能被其他事务的操作所干扰。

**持久性（Durability）**：事务一旦提交则不可逆，被持久化到数据库中。

**事务的隔离性是通过锁实现，而事务的原子性、一致性和持久性是通过事务的日志实现的**。



（2）**事务的隔离级别**（隔离性产生的问题）

**赃读**：指一个事务读取了另外一个事务未提交的数据。

**不可重复读：\**在一个事务内读取表中某一行数据，多次读取结果不同。（不一定是错误，只是某些场合不对，主要指其他事务的\**更新语句和删除语句**的影响）

**幻读：\**指在一个事务内读取到了别的事务插入的数据，导致前后读取不一致。（主要指其他事务的\**插入语句**的影响）


（3）**执行事务的原理**

```
-- 1.mysql是默认开启事务自动提交的
set autocommit = 0 --关闭
set autocommit = 1 --开启（默认的）

-- 2.1手动开启事务
set autocommit = 0
-- 2.2事务开启
start transaction  --标记一个事物的开始，从这个之后的sql都在同一个事务内
insert...... --模拟一个事务
insert...... --模拟一个事务
-- 2.3提交：持久化（成功！）
commit
-- 2.4回滚：回到原来的样子（失败的话）
rollback
-- 2.5事务结束
set autocommit = 1
```

事务的执行过程如下，以 `begin` 或者 `start transaction` 开始，然后执行一系列操作，最后要执行 `commit` 操作，事务才算结束。当然，如果进行回滚操作(`rollback`)，事务也会结束。需要注意的是，`begin` 命令并不代表事务的开始，事务开始于`begin` 命令之后的第一条语句执行的时候。

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uKicD9o1Jt4PQUXW308ibUxVy613hiaiajqJXw7SXgMje1mvVY6JxQjUXGw/640)事务执行流程

（4）**事务的四种隔离级别**

- **读未提交、读已提交、可重复读、串行化**：

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7u71icF4W3HB9mVzqBqvCqOlMBVRicVl39c8dCaUx9Yw2WA5k9zkAnzrlA/640)隔离级别

说明：

1）一般不考虑**读未提交**和**串行化**。因为读未提交什么问题都没有解决，而序列化虽然解决了所有的问题，但是序列化杜绝了并发问题，改为串行执行了，没有太大的意义，性能反而越来越低了。

2）主要使用的是**可重复读**，它是InnoDB引擎默认使用的隔离级别；**不可重复读**是Oracle默认使用的隔离级别。



**扩展：思考题**：

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7unFBg0a3emcWs6WUayOj1mfdApDITiapN82KkZWgtia8rIpfvM99W6NWw/640)不同隔离级别下的运行效果

参考答案：

- 读未提交：V1=20；V2=20；V3=20
- 读已提交：V1=18；V2=20；V3=20
- **可重复读**：V1=18；V2=18；V3=20
- 序列化：V1=18；V2=18；V3=20



### 1.2 事务高级语法

```
-- 1.查看事务是否已经开启（默认开启的ON）
show variables like 'autocommit'

-- 2.autocommit等同于以下一系列操作
begin;
update ...;
delete...;
insert...;
commit;
rollback;
```

#### 

#### 1.2.1 事务隔离级别的实现方式

主要指的是**可重复读**的实现方式。**主要靠锁来实现的**。

总结：**读已提交**解决了脏读问题，**行锁**解决了并发更新的问题。并且 **MySQL 在可重复读级别解决了幻读问题，通过行锁和间隙锁的组合 Next-Key 锁实现的**。

```
-- 1.查看当前数据库使用的是哪种隔离级别？
show variables like 'transaction_isolation';
```

------

1）**LBCC**（Lock-Based Concurrent Control，基于锁的并发控制）、**MVCC**（Multi-Version Concurrent Control，**多版本并发控制**，行级锁的变种）。

2）**表锁**和**行锁**

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uvHxBvtJVEL4VrJbUSuFdpfqJIibl2UQNFaibHlhqofv8ibJFRiaV87HnAQ/640)行锁与表锁

表锁（类似于订整个酒店），行锁（类似于订酒店里的一个房间）。**行锁与表锁是基于索引来说的（且索引要生效），不带索引 （表锁）要全表扫描**。

3）**InnoDB锁**

##### 角度一：**锁的模式**

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uy6heBUZp0BQ1ebHu0MWvHatRpCbgpyt9nVefgEic7qUGMWhOTr5oPCg/640)锁的模式

###### 3.1 共享锁（行锁）——Shared Locks

又名**读锁（简称S锁）**，对某一资源加共享锁，自身可以读该资源，其他人也可以读该资源（也可以再继续加共享锁，即共享锁可以多个加在同一个记录上），但无法修改。要想修改就必须等待所有共享锁都释放完之后才能进行。

```
-- 1.加锁
select * from table_nale lock in share mode; -- lock in share mode

-- 2.释放锁
commit;
rollback;
```

情况一：有且仅有我自己访问，我加了行锁后，我仍然可以更改数据；

情况二：还有别人的读锁时，我就不能再修改了。

应用场景：财务统计。

###### 3.2 排它锁（行锁）——Exclusive Locks

又名**写锁（简称X锁）**，多某一资源加排他锁，自身可以进行增删改查，其他人无法进行任何操作。注意：排它锁不能与其他锁并存。

```
-- 1.DML语句默认会加排它锁

-- 2.手动加排它锁
select * from user where id=1 for update;  -- for update

-- 3.释放锁
commit;
rollback;
```

###### 3.3 意向锁（表锁）——Intention Locks

意向共享锁（**IS**）——Intention Shared Locks

表示事务准备给数据行加入共享锁之前——数据行加共享锁的前提是获取此表的**IS锁**。

意向排它锁（**IX**）——Intention Exclusive Locks

表示事务准备给数据行加入排它锁之前——数据行加排它锁的前提是获取此表的**IX锁**。

注意：**均是表锁、无法手动创建**。

意义：**提高了加锁的效率**。

##### 角度二：**锁的算法**

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uZymiaGqvkLxYDTxRY90dDI8icHaZW4v6UkGLDNwlt7sLhPL4XSQeJVgg/640)锁的算法

案例：

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uZYPAd6rlHf0SM8VpzaFomgI2WaUTYlZVbLbtLernLNmWRbXm4s97dw/640)示例表

根据上表的记录进行划分得到下述锁：

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uW9ia7fPRwibyHyMPXWSuIQXxjTdo6g2ibFZoC95hBS8sLQbvmnnia4BSEw/640)锁的种类

###### 3.1 记录锁——Record Locks

```
-- 1.锁住本条id=1的记录
select * from user_key_index where id=1 for update;  -- for update
```

###### 3.2 间隙锁——Gap Locks

```
-- 1.锁住（5，9）的开区间
select * from user_key_index where id > 5 and id < 9 for update; -- for update
-- 注意：Gap Locks只存在于可重复读隔离级别
```

说明：**Gap Locks只存在于RR（可重复读）隔离级别**。

###### 3.3 临键锁——Next-Key Locks

```
-- 1.会锁住(5，9]、(9，11]
select * from user_key_index where id > 5 and id < 11 for update; -- for update
```

说明：**Next-key Locks = Gap Locks + Record Locks**

**
**

#### 1.2.2 MySQL事务隔离的实现原理

##### 解释一

- 首先说**读未提交**，它是性能最好，也可以说它是最野蛮的方式，因为它压根儿就不加锁，所以根本谈不上什么隔离效果，可以理解为没有隔离。
- 再来说**串行化**。**读的时候加共享锁**，也就是其他事务可以并发读，但是不能写。**写的时候加排它锁**，其他事务不能并发写也不能并发读。

最后说**读已提交**和**可重复读**。这两种隔离级别是比较复杂的，既要允许一定的并发，又想要兼顾的解决问题。



**1）实现可重复读**：MySQL 采用了 MVCC (多版本并发控制) 的方式

我们在数据库表中看到的一行记录可能实际上有多个版本，每个版本的记录除了有数据本身外，还要有一个表示版本的字段，记为 `row trx_id`，而这个字段就是使其产生的事务的 id，事务 ID 记为 `transaction id`，它在事务开始的时候向事务系统申请，按时间先后顺序递增。

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7u2WHMIIsGn5AHVMdUD5D4Kia2ZfTz3gLvBKTxHZgqgqf5CHLrurNHknQ/640)记录的版本链（多版本）

按照上面这张图理解，一行记录现在有 3 个版本，每一个版本都记录这使其产生的事务 ID，比如事务A的`transaction id` 是100，那么版本1的`row trx_id` 就是 100，同理版本2和版本3。

在上面介绍**读已提交**和**可重复读**的时候都提到了一个词，叫做**快照**，学名叫做**一致性视图（read-view）**。**读已提交则是每次执行语句的时候都重新生成一次快照，而可重复读是在事务开始的时候生成一个当前事务全局性的快照**。

对于一个快照来说，它能够读到哪些版本数据，要遵循以下规则：

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uFHbCLXJGKmuhfeJKcxRzyCX2J2mhHYQoJkdr4PzXQS8SeTJJ0zV5cQ/640)MVCC示例

- 说明：read-view：数组[100,200]表示未提交事务的trx_id

利用上面的规则，还是要强调，**读提交**和**可重复读**两者主要的区别就是在**快照的创建上**，**可重复读**仅在事务开始时创建一次（**可重复读**沿用第一次生成的readview），而**读已提交**每次执行语句的时候都要重新创建一次。



**2）解决幻读**：

MySQL 已经在**可重复读**隔离级别下解决了幻读的问题。解决幻读用的也是锁，叫做**间隙锁**，**MySQL 把行锁和间隙锁合并在一起，解决了并发写和幻读的问题**，这个锁叫做 **Next-Key锁**。

假设现在表中有两条记录，并且 age 字段已经添加了索引，两条记录 age 的值分别为 10 和 30。

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uGKsm6kfnYvARzbgM2lzDZRic8Nmrxg6ygdsdwczj35NN9bEg2k74gAw/640)

此时，在数据库中会为索引维护一套B+树，用来快速定位行记录。B+索引树是有序的，所以会把这张表的索引分割成几个区间。

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7ubNKsOLukckp1IcdvEWw2kehUl9rukUT1gUSW6sh50W3MibSfIuugjBA/640)

如图所示，分成了3 个区间，(负无穷,10]、(10,30]、(30,正无穷]，在这3个区间是可以加间隙锁的。

之后，我用下面的两个事务演示一下加锁过程。

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7upAED3eK7gR3xiaQbHCINcfpw2Kw3BvxkzayCZSELkWJcQok8PvsfO8Q/640)

在事务A提交之前，事务B的插入操作只能等待，这就是**间隙锁**起的作用。当事务A执行`update user set name='风筝2号’ where age = 10;` 的时候，由于条件 where age = 10 ，数据库不仅在 age =10 的行上添加了行锁，而且在这条记录的两边，也就是(负无穷,10]、(10,30]这两个区间加了间隙锁，从而导致事务B插入操作无法完成，只能等待事务A提交。不仅插入 age = 10 的记录需要等待事务A提交，age<10、10<age<30 的记录页无法完成，而大于等于30的记录则不受影响，这足以解决幻读问题了。

这是**有索引的情况**，如果 age 不是索引列，那么数据库会为整个表加上间隙锁。所以，如果是没有索引的话，不管 age 是否大于等于30，都要等待事务A提交才可以成功插入。



##### 解释二

1）**知识储备**：

**1.1）MVCC**：

**MVCC的全称是“多版本并发控制”**。这项技术使得InnoDB的事务隔离级别下执行**一致性读操作**有了保证，换言之，就是为了查询一些正在被另一个事务更新的行，并且可以看到它们被更新之前的值。这是一个可以用来增强并发性的强大的技术，**因为这样的一来的话查询就不用等待另一个事务释放锁**。这项技术在数据库领域并不是普遍使用的。一些其它的数据库产品，以及mysql其它的存储引擎并不支持它。

严格的来讲，**InnoDB会给数据库中的每一行增加三个字段**，它们分别是`DB_TRX_ID（6个字节，事务ID）`、`DB_ROLL_PTR（7个字节，回滚指针）`、`DB_ROW_ID（6个字节，用于聚集索引中的id）`。



**1.2）增删改查**：

在InnoDB中，给每行增加两个隐藏字段来实现MVCC，一个用来记录数据行的创建时间，另一个用来记录行的过期时间（删除时间）。在实际操作中，存储的并不是时间，而是事务的版本号，每开启一个新事务，事务的版本号就会递增。

于是乎，默认的隔离级别（REPEATABLE READ）下，增删查改变成了这样：

- SELECT

- - 读取创建版本小于或等于当前事务版本号，并且删除版本为空或大于当前事务版本号的记录。这样可以保证在读取之前记录是存在的。

- INSERT

- - 将当前事务的版本号保存至行的创建版本号

- UPDATE

- - 新插入一行，并以当前事务的版本号作为新行的创建版本号，同时将原记录行的删除版本号设置为当前事务版本号

- DELETE

- - 将当前事务的版本号保存至行的删除版本号



**1.3）快照读和当前读**：

**快照读**：读取的是快照版本，也就是历史版本

**当前读**：读取的是最新版本

**普通的SELECT就是快照读**，**而  `UPDATE、DELETE、INSERT、SELECT ... LOCK IN SHARE MODE、SELECT ... FOR UPDATE` 是当前读**。



**1.4）一致性读和锁定读**：

**锁定读**：在一个事务中，标准的SELECT语句是不会加锁，但是有两种情况例外。SELECT ... **LOCK IN SHARE MODE** 和 SELECT ... **FOR UPDATE**。

- `SELECT ... LOCK IN SHARE MODE`：给记录加上共享锁，这样一来的话，其它事务只能读不能修改，直到当前事务提交
- `SELECT ... FOR UPDATE`：给索引记录加锁，这种情况下跟`UPDATE`的加锁情况是一样的

**一致性读**：consistent read （一致性读），InnoDB用多版本来提供查询数据库在某个时间点的快照。

- 如果隔离级别是`REPEATABLE READ`，那么在同一个事务中的所有一致性读都读的是事务中第一个这样的读读到的快照；
- 如果是`READ COMMITTED`，那么一个事务中的每一个一致性读都会读到它自己刷新的快照版本。

Consistent read（一致性读）是`READ COMMITTED`和`REPEATABLE READ`隔离级别下普通`SELECT`语句默认的模式。一致性读不会给它所访问的表加任何形式的锁，因此其它事务可以同时并发的修改它们。



**1.5）悲观锁和乐观锁**：

**悲观锁**，正如它的名字那样，数据库总是认为别人会去修改它所要操作的数据，因此在数据库处理过程中将数据加锁。其实现依靠数据库底层。

**乐观锁**，如它的名字那样，总是认为别人不会去修改，只有在提交更新的时候去检查数据的状态。通常是给数据增加一个字段来标识数据的版本。



**1.6）锁**：

有这样三种锁我们需要了解

- **Record Locks（记录锁）**：在索引记录上加锁。
- **Gap Locks（间隙锁）**：在索引记录之间加锁，或者在第一个索引记录之前加锁，或者在最后一个索引记录之后加锁。
- **Next-Key Locks**：在索引记录上加锁，并且在索引记录之前的间隙加锁。它相当于是Record Locks与Gap Locks的一个结合。

假设一个索引包含以下几个值：10,11,13,20。那么这个索引的next-key锁将会覆盖以下区间：

(负无穷, 10]、 (10, 11]、 (11, 13]、 (13, 20]、 (20, 正无穷)



**2）可重复读的实现原理**：

在默认的隔离级别中，普通的SELECT用的是**一致性读不加锁**。而对于锁定读、UPDATE和DELETE，则需要加锁，至于加什么锁视情况而定。如果你对一个唯一索引使用了唯一的检索条件，那么只需锁定索引记录即可；如果你没有使用唯一索引作为检索条件，或者用到了索引范围扫描，那么将会使用间隙锁或者next-key锁以此来阻塞其它会话向这个范围内的间隙插入数据。

只有普通的SELECT才是**快照读**，其它诸如UPDATE、删除都是**当前读**。修改的时候加锁这是必然的，同时为了防止幻读的出现还需要加间隙锁。

- 一致性读保证了可用重复读
- 间隙锁防止了幻读

总结：

- **利用MVCC实现一致性非锁定读，这就有保证在同一个事务中多次读取相同的数据返回的结果是一样的，解决了不可重复读的问题**
- **利用Gap Locks和Next-Key可以阻止其它事务在锁定区间内插入数据，因此解决了幻读问题**

综上所述，默认隔离级别的实现依赖于MVCC和锁，再具体一点是一致性读和锁。



### 1.3 MVCC原理

**MVCC(Multi Version Concurrency Control的简称)，代表多版本并发控制。与MVCC相对的，是基于锁的并发控制，Lock-Based Concurrency Control)。多版本表示每行记录都有多个版本。MVCC最大的优势：** 读不加锁，读写不冲突。在读多写少的应用中，读写不冲突是非常重要的，极大的增加了系统的并发性能**。

**1）知识储备**：

**1.1）事务隔离级别**：

数据库事务具备ACID特性，即Atomicity(原子性), Consistency(一致性), Isolation(隔离性), Durability(持久性)。

- **原子性**：要执行的事务是一个独立的操作单元，要么全部执行，要么全部不执行
- **一致性**：事务的一致性是指事务的执行不能破坏数据库的一致性，一致性也称为完整性。一个事务在执行后，数据库必须从一个一致性状态转变为另一个一致性状态。
- **隔离性**：多个事务并发执行时，一个事务的执行不应影响其他事务的执行，SQL92规范中对隔离性定义了不同的隔离级别：
- **持久性**：事务一旦提交则不可逆，被持久化到数据库中。

读未提交(READ UNCOMMITED)->读已提交(READ COMMITTED)->可重复读(REPEATABLE READ)->序列化(SERIALIZABLE)。隔离级别依次增强，但是导致的问题是并发能力的减弱。大多数数据库系统的默认隔离级别都是READ COMMITTED（但MySQL不是)，**InnoDB存储引擎默认隔离级别`REPEATABLE READ`**，**通过多版本并发控制（MVCC，Multiversion Concurrency Control）解决了幻读的问题**。



**1.2）MySQL事务日志**：

事务日志可以帮助提高事务的效率。使用事务日志，存储引擎在修改表的数据时只需要修改其内存拷贝，再把该修改行为记录到持久在硬盘上的事务日志中，而不用每次都将修改的数据本身持久到磁盘。事务日志采用的是追加的方式，因此写日志的操作是磁盘上一小块区域内的顺序I/O，而不像随机I/O需要在磁盘的多个地方移动磁头，所以采用事务日志的方式相对来说要快得多。事务日志持久以后，内存中被修改的数据在后台可以慢慢地刷回到磁盘。目前大多数存储引擎都是这样实现的，我们通常称之为预写式日志（Write-Ahead Logging），修改数据需要写两次磁盘。如果数据的修改已经记录到事务日志并持久化，但数据本身还没有写回磁盘，此时系统崩溃，存储引擎在重启时能够自动恢复这部分修改的数据。

MySQL Innodb中跟数据持久性、一致性有关的日志，有以下几种：

- **Bin Log**:是mysql服务层产生的日志，常用来进行数据恢复、数据库复制，常见的mysql主从架构，就是采用slave同步master的binlog实现的
- **Redo Log**:记录了数据操作在物理层面的修改，mysql中使用了大量缓存，修改操作时会直接修改内存，而不是立刻修改磁盘，事务进行中时会不断的产生redo log，在事务提交时进行一次flush操作，保存到磁盘中。当数据库或主机失效重启时，会根据redo log进行数据的恢复，如果redo log中有事务提交，则进行事务提交修改数据。
- **Undo Log**: 除了记录redo log外，当进行数据修改时还会记录undo log，undo log用于数据的撤回操作，它记录了修改的反向操作，比如，插入对应删除，修改对应修改为原来的数据，通过undo log可以实现事务回滚，并且可以根据undo log回溯到某个特定的版本的数据，实现MVCC。



**2）MVCC实现**：

**MVCC是通过在每行记录后面保存两个隐藏的列来实现的。这两个列，一个保存了行的创建时间，一个保存行的过期时间（或删除时间）。当然存储的并不是实际的时间值，而是系统版本号（system version number)。每开始一个新的事务，系统版本号都会自动递增。事务开始时刻的系统版本号会作为事务的版本号，用来和查询到的每行记录的版本号进行比较**。

下面看一下在`REPEATABLE READ`隔离级别下，MVCC具体是如何操作的。

- SELECT

  InnoDB会根据以下两个条件检查每行记录：

  只有符合上述两个条件的记录，才能返回作为查询结果

- - InnoDB只查找版本早于当前事务版本的数据行（也就是，行的系统版本号小于或等于事务的系统版本号），这样可以确保事务读取的行，要么是在事务开始前已经存在的，要么是事务自身插入或者修改过的。
  - 行的删除版本要么未定义，要么大于当前事务版本号。这可以确保事务读取到的行，在事务开始之前未被删除。

- INSERT

  InnoDB为新插入的每一行保存当前系统版本号作为行版本号。

- DELETE

  InnoDB为删除的每一行保存当前系统版本号作为行删除标识。

- UPDATE

  InnoDB为插入一行新记录，保存当前系统版本号作为行版本号，同时保存当前系统版本号到原来的行作为行删除标识。保存这两个额外系统版本号，使大多数读操作都可以不用加锁。这样设计使得读数据操作很简单，性能很好，并且也能保证只会读取到符合标准的行，不足之处是每行记录都需要额外的存储空间，需要做更多的行检查工作，以及一些额外的维护工作。

**总结**：

- 1.MVCC手段只适用于Msyql隔离级别中的读已提交（Read committed）和可重复读（Repeatable Read）.
- 2.Read uncimmitted由于存在脏读，即能读到未提交事务的数据行，所以不适用MVCC.

  原因是MVCC的创建版本和删除版本只要在事务提交后才会产生。
- 3.串行化由于是会对所涉及到的表加锁，并非行锁，自然也就不存在行的版本控制问题。
- 4.通过以上总结，可知，MVCC主要作用于事务性的，有行锁控制的数据库模型。
- 5.每行记录都有多个版本，即**多版本**。

**案例**：

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uDdgqGPxHltWY1mr5fBCaoiaYq3bSjKAG1QWNW9CL0fQ5wkXe8ttb2hA/640)

验证MVCC

问题：**在RR隔离级别下，age初始为18，Q1和Q2的值是多少**？

答：**Q1 = 20**；**Q2 = 18**。

解释：

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uOQMmAN8zao6JcBAjG99LVPpp5yQTNKeIKIxXmb3CYujdzOHyia8H73w/640)
示例

**事务A触发的是快照读（历史版本）**；**事务B触发的是当前读（最新版本）**。所以**MySQL在一定程度上解决了幻读问题（前提：触发的是快照读）**。





## 2. MySQL锁

### 2.1 锁概述

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uLgxmzBSIKtfDCSicgzSJ7wfspPKgre0FsahXWHNcbkibF2LCnW1qVS6Q/640)
表概述

### 2.2 锁分类

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uJakGlQkCqO9rLyZ05oAICrwicEv32zpd2MlQJCLPkbBqs8Kic20G2SiaA/640)

### 

### 2.3 MySQL锁

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uYbjnibVQWj1LMIKf4HFXr5V00vicy1tdb6UEltMRsvLiaeL7g1OCG0d0w/640)

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uUmUUrykXoZ9H7tsnIxIiaYmo2ia3q9OLqEhfqSdgV1MXdicrqyWzias0Zg/640)

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7u38y3WMuh7La6hQTrb6ia1aGX9sszC0Fxk4w0vaBWt45ad1vxGR1G3OQ/640)

###  

### 2.4 MyISAN表锁

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uQF2uTqtcEIpdzSO9yppico6FYYicyQz1LGmRWKy9FyyVroyBvIicyiazeA/640)

#### 2.4.1 如何加表锁

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uzhkTPFumg4cIfERnHTqlZBj9bVTlViaQO0yGZWG2BSOZ92jibBLrTBCQ/640)

释放锁：unlock。

#### 2.4.2 结论

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uXib7ChWN4GSNq2uwudFKxBCLc489vibGnoPGkvC9dIybDRCzf4KTsCfA/640)

#### 2.4.3 查看锁的争用情况

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uPb0GU417dAmCJUKWolYDgghThibEN4coS3nw70WYHUQQqbbcShboqXA/640)

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uEWBP4I0Yg6GjhYx528bzWd2ymNLZV9ghTyKic4oOT4aAk9MHWHg9RkA/640)

###  

### 2.5 InnoDB行锁

#### 2.5.1 行锁介绍

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uQUYcvXAGcTwCpfiaKI5qWR2oTG82rKjU1XdBD48bTZCXKQzDOzrf1kQ/640)

#### 2.5.2 背景知识

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uQPQyQSYdWo0eZRBzwtjx1b7FvjwIreJjfJCzvQQTSiaOdOQ1O6LRauQ/640)

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7u80c6WP544EiaNvkRrcp7ickVnv3dtjHOI7pRuQ3ItKPrwBCniaLFib8aGg/640)

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uaNO1AmdibDQbV7Xjlgk7GnicSiar4uwP0xKxAJibkhyrb7wWB4RDSclACQ/640)

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uuvqoZ0dHfunwoxl1BXMfXibceP7f9oqjnyibK7BpoiaBncA8ffD5V5CMg/640)

#### 2.5.3 无索引行锁升级为表锁

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7u9a7tMK76UkOPtOkvOoKfQAdrbmDCqN4X9Rp8C3teg3VNDZ2WPgUtjQ/640)

#### 2.5.4 间隙锁危害

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uMaqDHK3bjnWehQCqHHe8IibW9icJpWc30M3rH1gP1UEb7UfxBfViclE4Q/640)

#### 2.5.5 InnoDB行锁争用情况

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uwheMWXia5Z8gCCPTFUbuHpJ4lISsrmDbk2wKZFejGiaDHOb48KJJvd0w/640)

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uR8Kat2VMsF4kOwWhJJQHUvOVwtK4zspreG9w5b2CxEB80tIODicbANQ/640)



![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7uRfFL4kx8V7dXqkqvo7jRZByIEP2IEyxQoWbqKHe6usMhlqgotrYRfQ/640)

#### 2.5.6 总结

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUZCAbtMxL8RKSSrOxW6Yl7udb9K05hnnG85aKHfP5krMezZ8sNl3ticMZU803nrJYe6cfSelYeAdug/640?)



## 3. 面试题

参考：https://www.jianshu.com/p/788ebb7075b8

### 3.1 你对MVCC的理解？

答：**MVCC**也即**多版本并发控制**。**为了提升并发性能的考虑，通过行级锁的变种，避免了很多情况下加锁的操作，减小开销。其次MVCC只适用于读已提交和可重复读两个隔离级别下**。**MVCC相较于加锁更有效，并且开销更小**。

参考：https://baijiahao.baidu.com/s?id=1629409989970483292&wfr=spider&for=pc



### 3.2 MySQL事务的实现原理？

答：事务的实现是基于数据库的存储引擎，不同的存储引擎对事务的支持程度不一样。比如**InnoDB是通过多版本并发控制（MVCC）机制解决幻读问题**。因此InnoDB的可重复读级别其实实现了串行化级别的效果，而且保留了良好的并发性能。



### 3.3 MySQL中的锁？

答：锁是数据库并发控制的重要手段，可以保证数据库在多人同时操作时能够正常运行。MySQL提供了全局锁、表级锁、行级锁。其中**InnoDB支持表级锁、行级锁，MyISAM只支持表级锁**MySQL中的锁：1）**表级锁**：开销小，加锁快；不会出现死锁；锁定粒度大，发生锁冲突的概率最高，并发度最低 2）**行级锁**：开销大，加锁慢；会出现死锁；锁定粒度最小，发生锁冲突的概率最低，并发度也最高 3）**页级锁**：开销和加锁时间界于表锁和行锁之间；会出现死锁；锁定粒度界于表锁和行锁之间，并发度一般。



### 3.4 InnoDB中的行锁？

答：InnoDB实现了两种行锁：1）**共享锁（S锁）**：某个事务对数据加上共享锁以后，只能读取该数据，其他事务不能加排他锁，只可以加共享锁，或者直接读 2）**排他锁（X锁）**：加了以后只能允许该事务进行读取或者修改，其他事务不能上锁，只能不加锁的读，或者等释放了锁以后再加锁。



### 3.5 什么是死锁？

答：死锁是指两个或两个以上的进程在执行过程中，因争夺资源而造成的一种互相等待的现象，若无外力作用，它们都将无法推进下去。此时称系统产生了死锁。



### 3.6 如何处理死锁？

答：1）等待，直到超时（innodb_lock_wait_timeout=50s） 2）发起死锁检测，发现死锁后，主动回滚死锁中的某一个事务，让其他事务继续进行。



### 3.7 如何避免死锁？

答：1）在事务中，如果要更新记录，应该直接申请足够级别的锁，即排他锁，而不应该先申请共享锁，更新时再申请排他锁 2）如果事务需要修改或锁定多个表，则应在每个事务中以相同的顺序使用加锁语句。



### 3.8 InnoDB默认是如何对待死锁的？

答：InnoDB默认是使用设置死锁时间来让死锁超时的策略默认innodb_lock_wait_timeout=50s



### 3.9 优化锁？

答：

1）选择合适的事务大小，小的事务发生锁冲突的几率也更小 2）可以适当降低隔离级别 3）创建索引，并尽量使用索引访问数据库，使锁更精确，从而减少锁冲突 4）除非必须，查询时不要显示加锁。MySQL的MVCC可以实现事务中的查询不用加锁，优化事务性能 5）不同的程序访问一组表时，尽量约定以相同的顺序访问各表，对一个表而言，尽可能以固定的顺序存取表中的行，这样可以大大减少死锁的机会。



### 3.10 行锁锁的是什么？

答：**存在唯一性索引和主键索引的时候锁的是指定的记录**；**而没有索引的时候锁的是全表**。



### 3.11 不声明主键创建表的危害？

答：

1）不声明主键的情况下，当主键id达到2^32-1时，归0，重新计算，相同的主键直接覆盖记录。声明了主键的情况下，当主键达到最大值时，报错主键冲突。（int改为bigint）

2）行锁锁的是全表。

3）每行记录附加一个隐藏字段叫做_rowid（6个byte），相较于我们自己声明的4个byte，造成了资源的浪费。





参考：

https://www.cnblogs.com/fengzheng/p/12557762.html

https://www.cnblogs.com/cjsblog/p/8365921.html