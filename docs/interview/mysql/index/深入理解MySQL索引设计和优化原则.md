# 深入理解MySQL索引设计和优化原则

-  索引类型 

探讨索引设计和优化原则之前，先给大家熟悉一下索引类型：

1. 主键索引`PRIMARY KEY`：它是一种特殊的唯一索引，不允许有空值。一般是在建表的时候同时创建主键索引。
2. 唯一索引`UNIQUE`：唯一索引列的值必须唯一，但允许有空值。如果是组合索引，则列值的组合必须唯一。 创建命令：`ALTER TABLE table_name ADD UNIQUE (column);`
3. 普通索引`INDEX`：最基本的索引，它没有任何限制。 创建命令：`ALTER TABLE table_name ADD INDEX index_name (column);`
4. 组合索引 `INDEX`：组合索引，即一个索引包含多个列。多用于避免回表查询。 创建命令：`ALTER TABLE table_name ADD INDEX index_name(column1, column2, column3);`
5. 全文索引 `FULLTEXT`：全文索引（也称全文检索）是目前搜索引擎使用的一种关键技术。 创建命令：`ALTER TABLE table_name ADD FULLTEXT (column);` 读到就是赚到，溪源这里再赠送一条删除索引命令：索引一经创建不能修改，如果要修改索引，只能删除重建。 删除索引命令：`DROP INDEX index_name ON table_name；`

-  设计原则 

为了使索引的使用效率更高，在创建索引时，必须考虑在哪些字段上创建索引；溪源给大家整理了以下基本原则：

1. **搜索条件、排序、分组和联合操作字段：** 出现在`where`关键词后面的字段适合设置为索引列，或者`连接子句`中指定的列也是可以设置为索引列；
2. **唯一性字段（字段值基数越小）：** 对于`唯一性的列`，设置索引效果是最佳的；而对于`具有多个重复值`的列，其索引效果是最差的。 因此设置索引时，大家需要考虑该列中值的分布情况；（大家注意：此处说的字段值的基数越小【即**接近于**除自身之外无其他重复值】，越适合做索引列，但这里不是指唯一性索引，不要陷入深深的误解哦~） **扩展点**：`区分度的公式是count(distinct col)/count(*)，表示字段不重复的比例，比例越大我们扫描的记录数越少，唯一键的区分度是1；` 简单举例说明： 如果将存放年龄字段列设置为索引列，由于各个年龄的值不同，值的`区分度较高`，可以考虑作为索引列； 而对于性别列而言：即男，女，未知；数据量基本上没有很大差别，便不适合作为索引列；
3. **短索引原则：** 对于长字符串字段列设置索引，最好遵循短索引原则即指定前缀长度，节省大量索引空间。 例如： `备注`列字段VARCHAR(200),如果该列设置为索引列，查询效率不很高，因为索引字段长度过大，索引节点树高增加，I/O次数也会增加。因此，对于长子字符考虑使用前缀索引。将`备注`字段值得前10个字符设置为索引，就会节省索引空间，提高效率。
4. ** 适度设置索引列：** 设置索引时要考虑设置合适的列，不要造成“过多的索引列”。因为每个索引需要额外的磁盘空间，并降低写操作的性能。并且在修改表内容的时候，索引会进行更新，更有甚至需要重构，索引列越多，所花费的时间就会越长。所以只保持需要的索引有利于查询即可。如果想要给已存在索引列的表再添加索引，则需要考虑一下要增加的索引是否能够使用现有多列索引的最左索引，如果是，则无须增加该索引。`对于长时间不再使用或者很少使用的索引要进行删除操作。`

-  优化原则 

上面说完索引的设计原则，那么我们下面探讨一下索引的优化原则吧！

1. 联合索引，遵循最左前缀匹配原则： 另外需要注意大家特别容易误解的点：`最左匹配原则并不是指查询条件的顺序，而是指查询条件中是否包含索引最左列字段；`
2. 隐式转换： 数据类型出现隐式转换的时候不会命中索引，特别是当列类型是字符串，一定要将字符常量值用引号引起来。
3. 索引列不能参与计算，保持列“干净”： 比如from_unixtime(create_time) = ’2014-05-29’就不能使用到索引，原因很简单，b+树中存的都是数据表中的字段值，但进行检索时，需要把所有元素都应用函数才能比较，显然成本太大。所以语句应该写成create_time = unix_timestamp(’2014-05-29’)；
4. 范围条件存在多个索引时，查询可以命中索引： 范围条件有：<、<=、>、>=、between等。 
   - 范围列可以用到索引（联合索引必须是最左前缀），但是范围列后面的列无法用到索引，并且索引最多用于一个范围列，如果查询条件中有两个范围列则无法全用到索引；
   - 如果是范围查询和等值查询同时存在，优先匹配等值查询列的索引；
5. 利用覆盖索引进行查询，避免回表： 被查询的列，数据能从索引中取得，而不用通过行定位符row-locator再到row上获取，即“被查询列要被所建的索引覆盖”，这能够加速查询速度。就是平时我们谈论是否select *

-  实战 
-  创建member表 创建一张会员表，用于实践操作设置索引和验证索引是否有效； 

```javascript
CREATE TABLE `member` (
  `member_id` INT NOT NULL AUTO_INCREMENT COMMENT '会员ID',
  `member_name` VARCHAR(45) NOT NULL COMMENT '会员名字',
  `age` INT(3) NULL,
  `sex` VARCHAR(3) NULL,
  `address` VARCHAR(45) NULL COMMENT '地址',
  `status` VARCHAR(3) NULL COMMENT '状态：0(失效)，1(有效)',
  `remark` VARCHAR(45) NULL COMMENT '备注',
  PRIMARY KEY (`member_id`),
  UNIQUE INDEX `member_name_UNIQUE` (`member_name` ASC) VISIBLE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COMMENT = '会员表';
```

复制

上面我们成功建立会员表，使用`show index from member;`命令查看当前表的索引列； 

![img](https://ask.qcloudimg.com/http-save/yehe-2681158/pcqozq74g5.png?imageView2/2/w/1620)

-  姓名索引列模糊匹配是否命中： 

![img](https://ask.qcloudimg.com/http-save/yehe-2681158/c8yjts5jmx.png?imageView2/2/w/1620)

![img](https://ask.qcloudimg.com/http-save/yehe-2681158/1ps5mfeg2n.png?imageView2/2/w/1620)

-  设置sex字段为普通索引 下面我们将`性别`字段设置为索引列，验证是否能够命中索引； 

```javascript
-- 性别列设置普通索引
ALTER TABLE member ADD INDEX sex_index (sex);
```

复制

验证是否设置成功： 

![img](https://ask.qcloudimg.com/http-save/yehe-2681158/oyl7rvv3xr.png?imageView2/2/w/1620)

溪源此时表中仅有6条数据时，设置性别作为索引列，查询会命中索引； 

![img](https://ask.qcloudimg.com/http-save/yehe-2681158/mvoakpo0oc.png?imageView2/2/w/1620)

可以从结果中看到已经命中索引列 

![img](https://ask.qcloudimg.com/http-save/yehe-2681158/u8sysd04se.png?imageView2/2/w/1620)

- 索引计算、隐式转换问题： 为了验证隐式转换导致索引失效，因此我们需要将之前建立的`sex_index`删除，重新建立`age_index`索引

```javascript
-- 删除性别索引列
DROP INDEX sex_index ON member;
-- 年龄列设置普通索引
ALTER TABLE member ADD INDEX age_index (age);
show index from member;
```

复制

![img](https://ask.qcloudimg.com/http-save/yehe-2681158/wk08nx89jq.png?imageView2/2/w/1620)

以下这条SQL会命中索引吗？？？ 

![img](https://ask.qcloudimg.com/http-save/yehe-2681158/p5xt2z0abw.png?imageView2/2/w/1620)

 答案肯定是：不会 解密时刻： 

![img](https://ask.qcloudimg.com/http-save/yehe-2681158/v9dd0hxg3o.png?imageView2/2/w/1620)

 细心的伙伴可能会发现，溪源故意将`status`字段设置成VARCHAR类型，到了显露目的的时候啦，这里会将age索引列一起谈论是目的的，哈哈~ 首先使用命令将status字段设置成普通索引`ALTER TABLE member ADD INDEX status_index (status);` 

![img](https://ask.qcloudimg.com/http-save/yehe-2681158/ua7p6pr7ym.png?imageView2/2/w/1620)

 那么反过来，如果我们将status字段，查询时设置成非VARCAHR类型，会命中索引吗？？？ 

![img](https://ask.qcloudimg.com/http-save/yehe-2681158/cozwno7ao0.png?imageView2/2/w/1620)

 对比结果很明显啦，为了加深大家的理解和好奇心，溪源这里暂时不抛出答案，有兴趣的小伙伴百度一下哦，欢迎评论去留言哦~

相信到这里大家已经捞到了不少东西，趁着大家高涨的热情，继续分享联合索引~

- 联合索引问题：

为了避免索引数量过多，下面溪源将上面建立的`age_index\status_index`全部删除后，我们建立三个字段的联合索引； `ALTER TABLE member ADD INDEX age_sex_status_index (age,sex,status);`

1. 查询顺序按照索引顺序，与乱序是否命中： 

![img](https://ask.qcloudimg.com/http-save/yehe-2681158/d57r2og46i.png?imageView2/2/w/1620)

`explain select * from member where age=21 and sex='男' and status = 1; explain select * from member where age=21 and status = 1 and sex='男'; explain select * from member where status = 1 and age=21 and sex='男'; explain select * from member where age=21 and status = 1;` 以上SQL语句均会命中索引，因为底层[MySQL](https://cloud.tencent.com/product/cdb?from=10680)提供语句优化器，优先使用索引。

下面再验证一条语句： 

![img](https://ask.qcloudimg.com/http-save/yehe-2681158/fsk52nvf66.png?imageView2/2/w/1620)

 通过以上SQL语句验证溪源上面所整理的原则，**保证查询条件中存在最左索引即可**，实践是检验真理的唯一标准，只有动手实践后，才能够存在话语权，空谈理论不行啊。

### 总结

最后，溪源总结一下本篇文章没有涉及到的SQL优化原则，后面溪源有时间会持续更新此文章；

1. union、in、or都能够命中索引，建议使用in。
2. 用or分割开的条件，如果or前的条件中列有索引，而后面的列中没有索引，那么涉及到的索引都不会被用到。
3. 负向条件查询不能使用索引，可以优化为in查询。负向条件有：!=、<>、not in、not exists、not like等 。。。 各位大佬阅览之中，若发现错误之处，请及时指正，溪源抓紧时间改正，不要误人子弟！！！ 周六时光整理此文不易，若大家有所学到，请积极点赞、关注、转发ha~

参考资料： [MySQL索引优化原则](https://www.cnblogs.com/hepingqingfeng/p/7553428.html)

本文