## [MySQL_2_索引](https://mp.weixin.qq.com/s?__biz=MzU0ODk5NzM1OA==&mid=2247484695&idx=1&sn=2fa36c7c279213aa0a266233d7195441&chksm=fbb7d496ccc05d800ac6cacbdfdee8240ce27af663c6fdd822365db1d3ee0a37e89d2d181de2&scene=178&cur_album_id=1645696492390694916#rd)

- \1. 索引

- - 1.1 索引概述
  - 1.2 索引的优势和劣势
  - 1.3 索引数据结构
  - 1.4 索引的分类
  - 1.5 聚簇索引和非聚簇索引
  - 1.6 索引覆盖
  - 1.7 索引下推
  - 1.8 索引语法
  - 1.9 索引原则

- \2. 索引的使用

- - 2.1 索引的使用
  - 2.2 查看索引的使用情况

- \3. 索引面试题

- - 3.1 数据库中最常见的慢查询优化方式？
  - 3.2 为什么加索引能优化慢查询？
  - 3.3 你知道哪些数据结构可以提高查询速度？
  - 3.4 那这些数据结构既然都能优化查询速度，MySQL为何选择使用B+树？
  - 3.5 为什么一个节点为1页（16K）就够了？
  - 3.6 什么情况下设置了索引但无法使用？





## 1. 索引

**索引（Index）\**是帮助MySQL高效获取数据的\**数据结构**。索引的本质：数据结构。

------

### 1.1 索引概述

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUavtUzZJ1X9HLR6w0F219nictvEtjbzRUxN3vtn9nQH1L1ic7heMxmNVyO7tv2Gib6VicNmPvqBgwr7tg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)索引概述

上图展示了一种可能的索引方式。左边是数据表，一共有两列七条记录，最左边的是数据记录的物理地址（注意逻辑上相邻的记录在磁盘上也并不是一定物理相邻的）。为了加快Col2的查找，可以维护一个右边所示的二叉查找树，每个节点分别包含索引键值和一个指向对应数据记录物理地址的指针，这样就可以运用二叉查找在O(log2n)的复杂度内获取到相应数据。虽然这是一个货真价实的索引，但是实际的数据库系统几乎没有使用二叉查找树或其进化品种红黑树（red-black tree）实现的，大多采用 **`B+树`** 实现。



### 1.2 索引的优势和劣势

**优势**：

1. 类似于书籍的目录索引，提高数据检索的效率，降低数据库的IO成本
2. 通过索引列对数据进行排序，降低数据排序的成本，降低CPU的消耗

**劣势**：

1. 占用空间
2. 虽然大大提高了查找的效率，但是也降低了更新表的速度，如对表进行`insert`、`update`、`delete`。因为更新表时，`MySql`不仅要保存数据，还要保存一下索引文件每次更新增加了索引列的字段，都会调整因为更新所带来的的键值对变化后的索引信息。



### 1.3 索引数据结构

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUavtUzZJ1X9HLR6w0F219nicAEfwqXLGLICicKWKQmFnwNQgr9ehx0gAbmm8OcMBtphfhICjvxX1hCQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)索引数据结构

InnoDB支持自适应哈希，人为不可控。

#### 1.3.1 B-Tree结构

**B-Tree**又叫多路平衡搜索树。一棵m叉的BTree的特性如下： 说明：ceil表示向上取整。

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUavtUzZJ1X9HLR6w0F219nicEDcxaZGKXl0GvM4ClKYpVAGXPDqmVcjE3vN4sUllWice4LqekceO5JA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)B-Tree性质





![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUavtUzZJ1X9HLR6w0F219nic8TuzFn4YRwqdQHibMDc8RyCUZdEn0N5RMPFbOjP12ejcXLttWrIDf1w/640)B-Tree性质

**B树相对于二叉树，层级结构更小，因此查询数据的效率更高，搜索速度更快**。

#### 1.3.2 B+ Tree结构

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUavtUzZJ1X9HLR6w0F219nicN0pSd88WNBdx7zP4iazWeqUoYE4v3zEpOyKAEJib63z3poA1bPsM04VQ/640)B+Tree性质



![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUavtUzZJ1X9HLR6w0F219nicFVhTwgnHyXvLFUMNIibjSx7Lw4qJRic1qMFunP7okdtGYVhmn4o7ia9xQ/640)B+Tree

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUavtUzZJ1X9HLR6w0F219nicOwhlqleuaH5yFdweBdrLSPzFiaKZDGlQWcG6Mf4gH0Tu28mGOeg1cGw/640)B+Tree

**特色：所有的数据都存储在叶子节点中**。

#### 1.3.3 MySql中的B+Tree

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUavtUzZJ1X9HLR6w0F219nic16yBtkzJicqlsyeichdJbnDlfQCiajtPQDRC2QVxYSPBLiba02aIeCXf9g/640)MySQL中的B+Tree

**特色：提高了区间访问的能力**。



### 1.4 索引的分类

**在一个表中，主键索引只能有一个，唯一索引可以有多个**：

- 主键索引（Primary Key）：

- - 唯一的标识，主键不可重复，只能有一个列作为主键

- 唯一索引（Unique Key）：

- - 避免重复的列出现，唯一索引可以重复。多个列都可以标识为唯一索引

- 常规索引（key / index）：

- - 默认的index，key关键字来设置

- 全文索引（FullText）：

- - 在特定的数据库引擎下才有，MyIsam

- 快速定位数据

- 联合索引（或组合索引）：

- - 索引列包含的是多个列，那么就称之为联合索引或者组合索引。
  - **最左匹配原则**：在包含多个列的查询过程中，会依靠先查第一个列，再查第二个列。

（1）基础语法：

```
  -- 索引的使用
  --  创建索引
  create index index_name on table_name(col_name);

  -- 显示所有的索引信息
  show index from table_name\G;

  --  删除索引
  drop index index_name on table_name;

  -- 增加索引
  alter table table_name add primary key(col_name); -- 主键索引
  alter table table_name add [unique/index/fulltext] index_name(col_name); -- 唯一索引、普通索引、全文索引 

  -- EXPLAIN分析sql执行的状况
  Explain select * from student; --非全文索引
  Explain select * from student where match(studentName) against('刘');
```

### 

### 1.5 聚簇索引和非聚簇索引

聚簇索引和非聚簇索引。狭义理解：InnoDB使用的就是聚簇索引；MyISAM使用的是非聚簇索引。

1）InnoDB**聚集索引**的叶子节点存储行记录，因此， **InnoDB必须要有，且只有一个聚集索引**：

- 如果表定义了PK，则PK就是聚集索引；
- 如果表没有定义PK，则第一个not NULL unique列（第一个**非空唯一索引**）是聚集索引；
- 否则，InnoDB会创建一个隐藏的row-id（6个字节，用户不可见）作为聚集索引；

总结：所以PK查询非常快，直接定位行记录。**InnoDB支持聚簇索引**。

2）InnoDB**普通索引（又名非聚簇索引、二级索引）**的叶子节点存储主键值。

举例如下：table(id PK, name KEY, sex, flag);

说明：id是主键（聚集索引），name是普通索引。

表中有四条记录：

```
1, shenjian, m, A
3, zhangsan, m, A
5, lisi, m, A
9, wangwu, f, B
```

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUavtUzZJ1X9HLR6w0F219nicJGgp6zdVLsKnzuGB8y2HOp3MOkdiaYq1aZ5GDQOkGVejicZF52SQTQ9Q/640)

聚簇索引和非聚簇索引

两个B+树索引分别如上图：

（1）id为PK，聚集索引，叶子节点存储行记录；

（2）name为KEY，普通索引，叶子节点存储PK值，即id；

既然从普通索引无法直接定位行记录，那**普通索引的查询过程是怎么样的呢？**

通常情况下，需要扫码两遍索引树。

例如：

```
select \* from t where name='lisi'
```

**是如何执行的呢？**



![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUavtUzZJ1X9HLR6w0F219nicMRPOGOyT4rPJ2UbjMibuu11ib5UELHn4GCiaofibic1WA4ApEASVwKPEIug/640)

非聚簇索引时回表查询

如**粉红色**路径，需要扫码两遍索引树：

（1）先通过普通索引定位到主键值id=5；

（2）在通过聚集索引定位到行记录；

这就是所谓的**回表查询**，先定位主键值，再定位行记录，它的性能较扫一遍索引树更低。

**AJCoder一句话总结：聚簇索引指索引和数据保存在一起，因此不需要回表就能一次得到相应的数据；而非聚簇索引则需要先得到索引再回表得到对应的数据**。



### 1.6 索引覆盖

1）  **定义**1：如果一个索引包含了（或覆盖了）满足查询语句中字段与条件的数据就叫做**索引覆盖**。

**定义**2：在 `EXPLAIN` 的 `Extra` 列可以看到 `Using index` 的信息即为使用了**索引覆盖**。

2）**作用**：索引覆盖对`InnoDB`尤其有用，因为`InnoDB`使用**聚集索引**组织数据，如果二级索引包含查询所需的数据，就不再需要在聚集索引中查找了。

举例：（id, name）

```
select id from table_name where name=zhangsan -- 索引覆盖：没有进行回表查询（进行非聚簇索引查询的时候已经得到了id，即不需要再次进行回表查询了）
select * from table_name where name=zhangsan -- 进行了回表查询
```

3）**使用说明**：如果要使用覆盖索引，一定要注意`SELECT`列表值取出需要的列，不可以`SELECT *`，因为如果将所有字段一起做索引会导致索引文件过大，查询性能下降。



### 1.7 索引下推

- 索引条件下推(Index Condition Pushdown),简称**ICP**。MySQL5.6新添加，用于优化数据的查询。
- 当你不使用ICP,通过使用非主键索引（普通索引or二级索引）进行查询，存储引擎通过索引检索数据，然后返回给MySQL服务器，服务器再判断是否符合条件。
- 使用ICP，当存在索引的列做为判断条件时，MySQL服务器将这一部分判断条件传递给存储引擎，然后存储引擎通过判断索引是否符合MySQL服务器传递的条件，只有当索引符合条件时才会将数据检索出来返回给MySQL服务器。

案例：

当我们创建一个用户表(userinfo),其中有字段：id,name,age,addr。我们将 `name,age` 建立联合索引。

```
select * from userinfo where name like "zhang%" and age=23;
```

- 对于MySQL5.6之前：我们在索引内部首先通过name进行查找，在联合索引name,age树形查询结果可能存在多个，然后再拿着id值去回表查询，整个过程需要回表多次。
- 对于MySQL5.6之后：我们是在索引内部就判断age是否等于20，对于不等于20跳过。因此在联合索引name,age索引树只匹配一个记录，此时拿着这个id去主键索引树种回表查询全部数据，整个过程就回一次表。

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUavtUzZJ1X9HLR6w0F219nicPbG9RfQ3QKcHLtbtp3uXqgV3sX3OFsngDklbcvtLCJDonJH0uhcgpg/640)

索引下推示例

注意：

- innodb引擎的表，索引下推只能用于二级索引。
- 索引下推一般可用于所求查询字段（select列）不是/不全是联合索引的字段，查询条件为多条件查询且查询条件子句（where/order by）字段全是联合索引。



### 1.8 索引语法

环境准备：

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUavtUzZJ1X9HLR6w0F219nicRCbypCAWh3Ikku7U5x85qTVWluatZPyLeHXpg5rSibZYFkpuf04V6oQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)案例

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUavtUzZJ1X9HLR6w0F219nic5JIaR8ANUia0Aiat3MdiaejF3VAkF1aIWYz1uFbygZ6OdfEOmSsdAPXmQ/640)

案例

1）创建索引（普通索引）

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUavtUzZJ1X9HLR6w0F219nichqSh9zlK98kowDyPhCxp5EOT8t1bga8p0ia8w6yicmNTniaxrYwzNUH4Q/640)

创建索引

2）查看索引

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUavtUzZJ1X9HLR6w0F219nich3aHpqYJFk9YQqcM4NnmtrSeSUb69LHdBo4GJqb6ly8pgBnBOeksyA/640)

查看索引

3）删除索引

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUavtUzZJ1X9HLR6w0F219nicpurYJYlliaONQShHvGtk5l9O38O35Iovwl1des37xGQ4f2zo9c2sVMQ/640)删除索引

4）Alter命令

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUavtUzZJ1X9HLR6w0F219nicWCbeQs1UpzFibCTgX0XzZIBaNug10soTJPFW26ut0nfGb4xjKh0Ky1Q/640)

修改索引

索引在小数据量的时候，用处不大。但是在大数据量的时候，区别十分明显。



### 1.9 索引原则

- 索引不是越多越好
- 不要对经常变动的数据加索引
- 小数据量的表不需要加索引
- 索引一般加载常用来查询的字段上

扩展：

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUavtUzZJ1X9HLR6w0F219nicIMjQXloibbN2iccY34chKw9lyGVYgdUTZQPum1DZp36zZibnlnOKu4tDw/640)

索引设计



## 2. 索引的使用

索引是数据库优化最常用的也最重要的手段之一，通过索引通常可以帮助用户解决大多数MySQL的性能优化问题。

------

### 2.1 索引的使用

1）全值匹配。对索引中所有列都指定具体值。该情况下，索引生效，执行效率高。

2）**最左前缀法则**。如果索引了多列，要遵守最左前缀法则。指的是查询从索引的最左前列开始，并且不跳过索引中的列。

3）范围查询右边的列，不能使用索引。

4）不要在索引列上进行运算操作，否则索引将失效。

5）字符串不加单引号，索引将失效。

6）尽量使用**覆盖索引**（只访问联合索引其中的字段），避免使用 `select *`

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUavtUzZJ1X9HLR6w0F219nic1VZz5RrWFAfrwuQUModtK4ay8SyWMEBSciblyHtZIwoC5akjPtHruBw/640)

索引使用

7）用or分隔开的条件，如果or前的条件中的列有索引，而后面的列中没有索引，那么涉及的索引都不会被用到。

8）以%开头的模糊查询，索引失效。（使用覆盖索引可以解决问题）

9）如果MySQL评估使用索引比全表更慢，则不使用索引。

10）is NULL，is not NULL有时索引失效。

11）in走索引，not in索引失效。

12）单列索引和复合索引。尽量使用复合索引，而少使用单列索引。因为数据库会选择一个最优的索引（辨识度最高的索引）来使用，并不会使用全部索引。



### 2.2 查看索引的使用情况

```
show [global] status like 'Handler_read%';
```

![图片](https://mmbiz.qpic.cn/mmbiz_png/jW4jBcwJbUavtUzZJ1X9HLR6w0F219nicZtXvuhhOsiaPm1AwoOPEnlcTt8UrW7TyFfVfvHmr0jUicVO25xukO92A/640)

status说明



## 3. 索引面试题

### 3.1 数据库中最常见的慢查询优化方式？

答：增加索引。



### 3.2 为什么加索引能优化慢查询？

答：因为索引是一种优化查询的数据结构，比如MySQL中的索引是B+树实现的，而B+树就是一种数据结构，可以优化查询速度，可以利用索引快速查找数据，所以能优化查询！



### 3.3 你知道哪些数据结构可以提高查询速度？

答：哈希表、完全平衡二叉搜索树、B树、B+树等等。



### 3.4 那这些数据结构既然都能优化查询速度，MySQL为何选择使用B+树？

答：Mysql选用B+树这种数据结构作为索引，可以提高查询索引时的磁盘IO效率，并且可以提高范围查询的效率，并且B+树里的元素也是有序的。



### 3.5 为什么一个节点为1页（16K）就够了？

答：MySQL的Innodb引擎中一页的默认大小是16K（如果操作系统中一页大小是4K，那么MySQL中1页 = 操作系统中的4页），这样存取数据的时候都是一页一页的获取索引文件中节点数据的！

可以发现B+树中的一个节点存储的内容是：

\1. 非叶子节点：主键 + 指针

```
      2. 叶子节点：数据
```

那么，假设我们一行数据大小为1K，那么一页就能存16条数据，也就是一个叶子节点能存16条数据；再看非叶子节点，假设主键ID为bigint类型，那么长度为8B，指针大小在Innodb源码中为6B，一共就是14B，那么一页里就可以存储16K/14=1170个(主键+指针)，那么一颗高度为2的B+树能存储的数据为：1170 * 16=18720条，一颗高度为3的B+树能存储的数据为：1170 * 1170 * 16=21902400（千万级条）。所以在InnoDB中B+树高度一般为1-3层，它就能满足千万级的数据存储。在查找数据时一次页的查找代表一次IO，所以通过主键索引查询通常只需要1-3次IO操作即可查找到数据。所以也就回答了我们的问题，1页=16k这么设置是比较合适的，是适用大多数的企业的，当然这个值是可以修改的，所以也能根据业务的时间情况进行调整。



### 3.6 什么情况下设置了索引但无法使用？

答：1.以“%”开头的LIKE语句，模糊匹配

1. OR语句前后没有同时使用索引
2. 数据类型出现隐式转化（如varchar不加单引号的话可能会自动转换为int型）

