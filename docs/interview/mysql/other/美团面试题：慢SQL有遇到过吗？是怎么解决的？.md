# 美团面试题：慢SQL有遇到过吗？是怎么解决的？

关于慢SQL，我和面试官扯了很久，面试官也是很谦虚的，总是点头，自己以为回答的还可以。最后的最后，还是说了“`你先回去等通知吧！`”。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/07BicZywOVtmXoZHgNy7iaicsz04eTqgJT7MxG702OC86lEjjEiaGhickFZeibJqmPP393bfm1uFGWoNtKFjFOPv7T5g/640?wx_fmt=jpeg&wxfrom=5&wx_lazy=1&wx_co=1)

所以，我决定把这个慢SQL技术点，好好和你分享分享。希望你下次在遇到类似的面试，能顺顺利利轻轻松松的斩获自己想要的offer。

> 人生最大的喜悦是每个人都说你做不到，你却完成它了!

## 什么是慢SQL?

MySQL的慢查询日志是MySQL提供的一种日志记录，它用来记录MySQL中查询时间超过（大于）设置阈值（long_query_time）的语句，记录到慢查询日志中。

其中，long_query_time的默认值是10，单位是秒，也就是说默认情况下，你的SQL查询时间超过10秒就算慢SQL了。

## 如何开启慢SQL日志？

在MySQL中，慢SQL日志默认是未开启的，也就说就算出现了慢SQL，也不会告诉你的，如果需要知道哪些SQL是慢SQL，需要我们手动开启慢SQL日志的。

关于慢SQL是否开启，我们可以通过下面这个命令来查看：

```
-- 查看慢查询日志是否开启
show variables like '%slow_query_log%';
```

![图片](https://mmbiz.qpic.cn/mmbiz_png/07BicZywOVtmXoZHgNy7iaicsz04eTqgJT7IS407iagib1yUU5dQiawdXdicpo20C9AkWxWtCpqib5MSWCABvpP3iapxmhQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)在这里插入图片描述

通过命令，我们就可以看到slow_query_log项为OFF，说明我们的慢SQL日志并未开启。另外我们也可以看到我们慢SQL日志存放于哪个目录下和日志文件名。

下面我们来开启慢SQL日志，执行下面的命令：

```
set global slow_query_log = 1;
```

这里需要注意，这里开启的是我们当前的数据库，并且，我们重启数据库后会失效的。

开启慢SQL日志后，再次查看：

![图片](https://mmbiz.qpic.cn/mmbiz_png/07BicZywOVtmXoZHgNy7iaicsz04eTqgJT7NJovee0MuU1UccfNHAa1UCZXBnbOw2cLVOJ95agD37SfkpfIHrZlJA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)



slow_query_log项已经变成ON，说明开启成功。

上面说过慢SQL默认时间是10秒，我们通过下面的命令就可以看到我们慢SQL的默认时间：

```
show variables like '%long_query_time%';
```

![图片](https://mmbiz.qpic.cn/mmbiz_png/07BicZywOVtmXoZHgNy7iaicsz04eTqgJT7sb7ZMeZUta2F5NZY2dG6iau45NAUBKe4eGraS2rwiaFVoia3w8JKfiamjA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)在这里插入图片描述

我们总不能一直使用这个默认值，可能很多业务需要时间更短或更长，所以此时，我们就需要对默认时间进行修改，修改命令如下：

```
set long_query_time = 3;
```

修改完了，我们再来看看是否已经改成了3秒。

![图片](https://mmbiz.qpic.cn/mmbiz_png/07BicZywOVtmXoZHgNy7iaicsz04eTqgJT7GBszkqInZibdeOtMz843mg2PZb5RqvtuibIcJ32A2LbWgD6YvMzDD4LQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)



这里需要注意：想要永久的生效，还需要修改MySQL下面的配置文件my.cnf 文件。

```
[mysqld]
slow_query_log=1
slow_query_log_file=/var/lib/mysql/atguigu-slow.log
long_query_time=3
log_output=FILE
```

注意：不同操作系统，配置有些区别。

Linux操作系统中

> 在mysql配置文件my.cnf中增加
>
> log-slow-queries=/var/lib/mysql/slowquery.log (指定日志文件存放位置，可以为空，系统会给一个缺省的文件host_name-slow.log)
>
> long_query_time=2 (记录超过的时间，默认为10s)
>
> log-queries-not-using-indexes (log下来没有使用索引的query,可以根据情况决定是否开启)
>
> log-long-format (如果设置了，所有没有使用索引的查询也将被记录)

Windows操作系统中

> 在my.ini的[mysqld]添加如下语句：
>
> log-slow-queries = E:\web\mysql\log\mysqlslowquery.log
>
> long_query_time = 3(其他参数如上)

执行一条慢SQL，因为我们前面已经设置好了慢SQL时间为3秒，所以，我们只要执行一条SQL时间超过3秒即可。

```
SELECT SLEEP(4);
```

![图片](https://mmbiz.qpic.cn/mmbiz_png/07BicZywOVtmXoZHgNy7iaicsz04eTqgJT7tWC47qfh2qQRjicXwPqnoCEziab3iamibTU1Jp7lDYRVWvt3LAY5rWj5fg/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)



该SQL耗时4.024秒，下面我们就来查看慢SQL出现了多少条。

使用命令：

```
show global status like '%Slow_queries%';
```

![图片](https://mmbiz.qpic.cn/mmbiz_png/07BicZywOVtmXoZHgNy7iaicsz04eTqgJT77eLkX33ZTib8dlprYKjjJrMnhckAqb0W6TwNFe5wecpbveicUSTF86xQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

## 查询SQL历程

找到慢SQL日志文件，打开后就会出现类似下面这样的语句；

```
# Time: 2021-07-20T09:17:49.791767Z
# User@Host: root[root] @ localhost []  Id:   150
# Query_time: 0.002549  Lock_time: 0.000144 Rows_sent: 1  Rows_examined: 4079
SET timestamp=1566292669;
select * from city where Name = 'Salala';
```

简单说明：

> 1.Time 该日志记录的时间
>
> 2.User @Host MySQL登录的用户和登录的主机地址
>
> 3.Query_time一行 第一个时间是查询的时间、第二个是锁表的时间、第三个是返回的行数、第四个是扫描的行数
>
> 4.SET timestamp 这一个是MySQL查询的时间
>
> 5.sql语句 这一行就很明显了，表示的是我们执行的sql语句

**切记**

> 如果你将long_query_time=0 ，那就意味着，我们所有的查询SQL语句都会输出到慢SQL日志文件中。

## 如何定位慢SQL？

通常我们定位慢SQL有两种方式：

第一种：定位慢查询**SQL**可以通过两个表象进行判断

- **系统级表象:**

- - 使用**sar**命令和**top**命令查看当前系统的状态
  - 也可以使用**Prometheus**和**Grafana**监控工具查看当前系统状态
  - **CPU**消耗严重
  - **IO**等待严重
  - 页面响应时间过长
  - 项目日志出现超时等错误

- **SQL语句表象:**

- - **SQL**语句冗长
  - **SQL**语句执行时间过长
  - **SQL**从全表扫描中获取数据
  - 执行计划中的**rows**和**cost**很大

第二种：根据不同的数据库使用不同的方式获取问题**SQL**

- **MySQL:**

- - 慢查询日志
  - 测试工具**loadrunner**
  - **ptquery**工具

- **Oracle:**

- - **AWR**报告
  - 测试工具**loadrunner**
  - 相关内部视图**vsession_wait**
  - **GRID CONTROL**监控工具

## 熟悉慢SQL日志分析工具吗？

如果开启了慢SQL日志后，可能会有大量的慢SQL日志产生，此时再用肉眼看，那是不太现实的，所以大佬们就给我搞了个工具：`mysqldumpslow`。

`mysqldumpslow`能将相同的慢SQL归类，并统计出相同的SQL执行的次数，每次执行耗时多久、总耗时，每次返回的行数、总行数，以及客户端连接信息等。

通过命令

```
mysqldumpslow --help
```

可以看到相关参数的说明：

```
~# mysqldumpslow --help
Usage: mysqldumpslow [ OPTS... ] [ LOGS... ]

Parse and summarize the MySQL slow query log. Options are

  --verbose    verbose
  --debug      debug
  --help       write this text to standard output

  -v           verbose
  -d           debug
  -s ORDER     what to sort by (al, at, ar, c, l, r, t), 'at' is default
                al: average lock time
                ar: average rows sent
                at: average query time
                 c: count
                 l: lock time
                 r: rows sent
                 t: query time  
  -r           reverse the sort order (largest last instead of first)
  -t NUM       just show the top n queries
  -a           don't abstract all numbers to N and strings to 'S'
  -n NUM       abstract numbers with at least n digits within names
  -g PATTERN   grep: only consider stmts that include this string
  -h HOSTNAME  hostname of db server for *-slow.log filename (can be wildcard),
               default is '*', i.e. match all
  -i NAME      name of server instance (if using mysql.server startup script)
  -l           don't subtract lock time from total time
```

比较常用的参数有这么几个：

```
-s 指定输出的排序方式
   t  : 根据query time(执行时间)进行排序；
   at : 根据average query time(平均执行时间)进行排序；（默认使用的方式）
   l  : 根据lock time(锁定时间)进行排序；
   al : 根据average lock time(平均锁定时间)进行排序；
   r  : 根据rows(扫描的行数)进行排序；
   ar : 根据average rows(扫描的平均行数)进行排序；
   c  : 根据日志中出现的总次数进行排序；
-t 指定输出的sql语句条数；
-a 不进行抽象显示(默认会将数字抽象为N，字符串抽象为S)；
-g 满足指定条件，与grep相似；
-h 用来指定主机名(指定打开文件，通常慢查询日志名称为“主机名-slow.log”，用-h exp则表示打开exp-slow.log文件)；
```

## 使用方式

`mysqldumpslow`常用的使用方式如下：

```
# mysqldumpslow -s c slow.log
```

如上一条命令，应该是mysqldumpslow最简单的一种形式，其中-s参数是以什么方式排序的意思，c指代的是以总数从大到小的方式排序。-s的常用子参数有：c: 相同查询以查询条数和从大到小排序。t: 以查询总时间的方式从大到小排序。l: 以查询锁的总时间的方式从大到小排序。at: 以查询平均时间的方式从大到小排序。al: 以查询锁平均时间的方式从大到小排序。

同样的，还可以增加其他参数，实际使用的时候，按照自己的情况来。

其他常用方式：

```
# 得到返回记录集最多的10 个SQL
mysqldumpslow -s r -t 10 /var/lib/mysql/atguigu-slow.log

# 得到访问次数最多的10 个SQL
mysqldumpslow -s c -t 10 /var/lib/mysql/atguigu-slow.log

# 得到按照时间排序的前10 条里面含有左连接的查询语句
mysqldumpslow -s t -t 10 -g "left join" /var/lib/mysql/atguigu-slow.log

# 另外建议在使用这些命令时结合| 和more 使用，否则有可能出现爆屏情况
mysqldumpslow -s r -t 10 /var/lib/mysql/atguigu-slow.log | more
```

接下，我们来个实际操作。

### 实操

```
root@yunzongjitest1:~# mysqldumpslow -s t -t 3

Reading mysql slow query log from /var/lib/mysql/exp-slow.log /var/lib/mysql/yunzongjitest1-slow.log
Count: 464  Time=18.35s (8515s)  Lock=0.01s (3s)  Rows=90884.0 (42170176), root[root]@localhost
  select ************

Count: 38  Time=11.22s (426s)  Lock=0.00s (0s)  Rows=1.0 (38), root[root]@localhost
  select *********** not like 'S'

Count: 48  Time=5.07s (243s)  Lock=0.02s (1s)  Rows=1.0 (48), root[root]@localhost
  select ********='S'
```

这其中的`SQL`语句因为涉及某些信息，所以我都用*号将主体替换了，如果希望得到具体的值，使用-a参数。

使用`mysqldumpslow`查询出来的摘要信息，包含了这些内容：

`Count`: 464 ：表示慢查询日志总共记录到这条sql语句执行的次数；

`Time=18.35s (8515s)`：18.35s表示平均执行时间（-s at)，8515s表示总的执行时间(-s t)；

`Lock=0.01s (3s)`：与上面的Time相同，第一个表示平均锁定时间(-s al)，括号内的表示总的锁定时间(-s l)（也有另一种说法，说是表示的等待锁释放的时间）；

`Rows=90884.0 (42170176)`: 第一个值表示扫描的平均行数(-s ar)，括号内的值表示扫描的总行数(-s r)。

是不是![图片](https://mmbiz.qpic.cn/mmbiz_png/07BicZywOVtmXoZHgNy7iaicsz04eTqgJT77K2wJjjzZ8ZTlliaLRQcveFjNp33gN6mcnsojruCe2sYzl0gzfFCoaw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1) `so easy!!!!`

### 参考

www.cnblogs.com/Yang-Sen/p/11384440.html

juejin.cn/post/6970550749528866852

juejin.cn/post/6942479516900163614

blog.csdn.net/ljl890705/article/details/77581260