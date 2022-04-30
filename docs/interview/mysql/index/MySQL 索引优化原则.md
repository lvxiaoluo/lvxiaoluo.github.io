## [MySQL 索引优化原则](https://www.cnblogs.com/hepingqingfeng/p/7553428.html)

一、索引优化原则

1、最左前缀匹配原则，联合索引，mysql会从做向右匹配直到遇到范围查询(>、<、between、like)就停止匹配，比如a = 1 and b = 2 and c > 3 and d = 4 如果建立(a,b,c,d)顺序的索引，d是用不到索引的，如果建立(a,b,d,c)的索引则都可以用到，a,b,d的顺序可以任意调整。

 

2、=和in可以乱序，比如a = 1 and b = 2 and c = 3 建立(a,b,c)索引可以任意顺序，mysql的查询优化器会帮你优化成索引可以识别的形式

 

3、索引列不能参与计算，保持列“干净”，比如**from_unixtime(create_time) = ’2014-05-29’**就不能使用到索引，原因很简单，b+树中存的都是数据表中的字段值，但进行检索时，需要把所有元素都应用函数才能比较，显然成本太大。所以语句应该写成**create_time = unix_timestamp(’2014-05-29’)**

 

4、使用索引时，索引字段最好小而且唯一，避免select * 的情况

 

5、尽量的扩展索引，不要新建索引。比如表中已经有a的索引，现在要加(a,b)的索引，那么只需要修改原来的索引即可，建立不必要索引会增加MySQL空间

 

6、如果确定有多少条数据，使用 limit 限制一下，MySQL在查找到对应条数的数据的时候，会停止继续查找

 

7、利用查询缓存，很多时候MySQL会对查询结果进行cache，但是对应“动态”的数据会不cache，例如：

 

1 SELECT username FROM user WHERE signup_date >= CURDATE() 无法使用cache

2 SELECT username FROM user WHERE signup_date >= '2017-05-06' 可以cache 

 

当使用了MySQL的一写函数之后，MySQL无法确定结果是易变的，所以不会cache，还有now(),rand()

也一样不开启cache

 

8、join 语法，尽量将小的表放在前面，在需要on的字段上，数据类型保持一致，并设置对应的索引，否则MySQL无法使用索引来join查询

 

9、在大表上做大量更新时，如果会锁全表，则需要拆分执行，避免长时间锁住表，导致其他请求积累太多（InnoDB 支持行锁，但前提是Where子句需要建立索引，没有索引也一样是锁全表）

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
 1 while (1) {
 2     //每次只做1000条
 3    mysql_query("DELETE FROM logs WHERE log_date <= '2009-11-01' LIMIT 1000");
 4    if (mysql_affected_rows() == 0) {
 5         // 没得可删了，退出！
 6         break;
 7     }
 8     // 每次都要休息一会儿
 9     usleep(50000);
10 }
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)