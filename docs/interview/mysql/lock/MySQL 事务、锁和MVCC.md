#  MySQL 事务、锁和MVCC



**面试官**：**你是怎么理解InnoDB引擎中的事务的？**

**候选者**：在我的理解下，事务可以使「一组操作」要么全部成功，要么全部失败

**候选者**：事务其目的是为了「保证数据最终的一致性」。

**候选者**：举个例子，我给你发支付宝转了888块红包。那自然我的支付宝余额会扣减888块，你的支付宝余额会增加888块。

**候选者**：而事务就是保证我的余额扣减跟你的余额增添是同时成功或者同时失败的，这样这次转账就正常了

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/E44aHibktsKa23y7eBdg7ZkHNEoIDMgVkAKxJTaBtVe32xiaymVw7CicBdluWTibIas5LQJBLTygC7Js99TQ5Ot40w/640?wx_fmt=jpeg&wxfrom=5&wx_lazy=1&wx_co=1)

**面试官**：**嗯，那你了解事务的几大特性吗？**

**候选者**：嗯，就是ACID嘛，分别是原子性（Atomicity）、一致性（Consistency）、隔离性（Isolation）、持久性（Durability）。

**候选者**：原子性指的是：当前事务的操作要么同时成功，要么同时失败。原子性由undo log日志来保证，因为undo log记载着数据修改前的信息。

**候选者**：比如我们要 insert 一条数据了，那undo log 会记录的一条对应的 delete 日志。我们要 update 一条记录时，那undo log会记录之前的「旧值」的update记录。

**候选者**：如果执行事务过程中出现异常的情况，那执行「回滚」。InnoDB引擎就是利用undo log记录下的数据，来将数据「恢复」到事务开始之前

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/E44aHibktsKa23y7eBdg7ZkHNEoIDMgVkE8pqn1s3E9Nqboh0Xib3JiaPzgKgC2Ixsasvgfr23DTxF4QbLld1iaNrg/640?wx_fmt=jpeg&wxfrom=5&wx_lazy=1&wx_co=1)

**候选者**：一致性我稍稍往后讲，我先来说下隔离性

**面试官**：嗯…

**候选者**：隔离性指的是：在事务「并发」执行时，他们内部的操作不能互相干扰。如果多个事务可以同时操作一个数据，那么就会产生脏读、重复读、幻读的问题。

**候选者**：于是，事务与事务之间需要存在「一定」的隔离。在InnoDB引擎中，定义了四种隔离级别供我们使用：

**候选者**：分别是：read uncommit(读未提交)、read commit (读已提交)、repeatable read (可重复复读)、serializable (串行)

**候选者**：不同的隔离级别对事务之间的隔离性是不一样的（级别越高事务隔离性越好，但性能就越低），而隔离性是由MySQL的各种锁来实现的，只是它屏蔽了加锁的细节。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/E44aHibktsKa23y7eBdg7ZkHNEoIDMgVkIG6KWgbuVZbp7natNMTI3cqVtZL81micdZsJDBANGgCtaJniaRS8kzpA/640?wx_fmt=jpeg&wxfrom=5&wx_lazy=1&wx_co=1)

**候选者**：持久性指的就是：一旦提交了事务，它对数据库的改变就应该是永久性的。说白了就是，会将数据持久化在硬盘上。

**候选者**：而持久性由redo log 日志来保证，当我们要修改数据时，MySQL是先把这条记录所在的「页」找到，然后把该页加载到内存中，将对应记录进行修改。

**候选者**：为了防止内存修改完了，MySQL就挂掉了（如果内存改完，直接挂掉，那这次的修改相当于就丢失了）。

**候选者**：MySQL引入了redo log，内存写完了，然后会写一份redo log，这份redo log记载着这次在某个页上做了什么修改。

**候选者**：即便MySQL在中途挂了，我们还可以根据redo log来对数据进行恢复。

**候选者**：redo log 是顺序写的，写入速度很快。并且它记录的是物理修改（xxxx页做了xxx修改），文件的体积很小，恢复速度也很快。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/E44aHibktsKa23y7eBdg7ZkHNEoIDMgVkAnSl1ahVTEJY1DficWiay2jZlunDPBUPaNwpuwq5dNico1X1IyjIMvlTg/640?wx_fmt=jpeg&wxfrom=5&wx_lazy=1&wx_co=1)

**候选者**：回头再来讲一致性，「一致性」可以理解为我们使用事务的「目的」，而「隔离性」「原子性」「持久性」均是为了保障「一致性」的手段，保证一致性需要由应用程序代码来保证

**候选者**：比如，如果事务在发生的过程中，出现了异常情况，此时你就得回滚事务，而不是强行提交事务来导致数据不一致。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/E44aHibktsKa23y7eBdg7ZkHNEoIDMgVkABXmN47ySQxgF0ReESdl5KuQE4GRreYRebJqoOVzKibrvPlAtvBicia5A/640?wx_fmt=jpeg&wxfrom=5&wx_lazy=1&wx_co=1)

**面试官**：嗯，挺好的，讲了蛮多的

**面试官**：刚才你也提到了隔离性嘛，**然后你说在MySQL中有四种隔离级别，能分别来介绍下吗？**

**候选者**：嗯，为了讲清楚隔离级别，我顺带来说下MySQL锁相关的知识吧。

**候选者**：在InnoDB引擎下，按锁的粒度分类，可以简单分为行锁和表锁。

**候选者**：行锁实际上是作用在索引之上的（索引上次已经说过了，这里就不赘述了）。当我们的SQL命中了索引，那锁住的就是命中条件内的索引节点（这种就是行锁），如果没有命中索引，那我们锁的就是整个索引树（表锁）。

**候选者**：简单来说就是：锁住的是整棵树还是某几个节点，完全取决于SQL条件是否有命中到对应的索引节点。

**候选者**：而行锁又可以简单分为读锁（共享锁、S锁）和写锁（排它锁、X锁）。

**候选者**：读锁是共享的，多个事务可以同时读取同一个资源，但不允许其他事务修改。写锁是排他的，写锁会阻塞其他的写锁和读锁。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/E44aHibktsKa23y7eBdg7ZkHNEoIDMgVkHcnHuT3go1n2Dvs3KmPHUUx5sxwHgULpeIZvob8K9Rhdy27XtmSRtA/640?wx_fmt=jpeg&wxfrom=5&wx_lazy=1&wx_co=1)

**候选者**：我现在就再回到隔离级别上吧，就直接以例子来说明啦。

**面试官**：嗯…

**候选者**：首先来说下read uncommit(读未提交)。比如说：A向B转账，A执行了转账语句，但A还没有提交事务，B读取数据，发现自己账户钱变多了！B跟A说，我已经收到钱了。A回滚事务【rollback】，等B再查看账户的钱时，发现钱并没有多。

**候选者**：简单的定义就是：事务B读取到了事务A还没提交的数据，这种用专业术语来说叫做「脏读」。

**候选者**：对于锁的维度而言，其实就是在read uncommit隔离级别下，读不会加任何锁，而写会加排他锁。读什么锁都不加，这就让排他锁无法排它了。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/E44aHibktsKa23y7eBdg7ZkHNEoIDMgVkdaMujEgBNL1IuqNwaBBNazBxV91cu0ZqSBVOz7Ea87RNa5ywfCcEvA/640?wx_fmt=jpeg&wxfrom=5&wx_lazy=1&wx_co=1)

**候选者**：而我们又知道，对于更新操作而言，InnoDB是肯定会加写锁的（数据库是不可能允许在同一时间，更新同一条记录的）。而读操作，如果不加任何锁，那就会造成上面的脏读。

**候选者**：脏读在生产环境下肯定是无法接受的，那如果读加锁的话，那意味着：当更新数据的时，就没办法读取了，这会极大地降低数据库性能。

**候选者**：在MySQL InnoDB引擎层面，又有新的解决方案（解决加锁后读写性能问题），叫做MVCC(Multi-Version Concurrency Control)多版本并发控制

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/E44aHibktsKa23y7eBdg7ZkHNEoIDMgVkMxJcNgibZnuFibEHo4FeGPNvTHyZWmrCXgvKMo39VY5ZlSibQqTVEhKTQ/640?wx_fmt=jpeg&wxfrom=5&wx_lazy=1&wx_co=1)

**候选者**：在MVCC下，就可以做到读写不阻塞，且避免了类似脏读这样的问题。那MVCC是怎么做的呢？

**候选者**：MVCC通过生成数据快照（Snapshot)，并用这个快照来提供一定级别（语句级或事务级）的一致性读取

**候选者**：回到事务隔离级别下，针对于 read commit (读已提交) 隔离级别，它生成的就是语句级快照，而针对于repeatable read (可重复读)，它生成的就是事务级的快照。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/E44aHibktsKa23y7eBdg7ZkHNEoIDMgVkhUaj9HkfofHuvuRMJtMIqVBickM84E7jL3McmTDYnCYbOyK85LJhV5g/640?wx_fmt=jpeg&wxfrom=5&wx_lazy=1&wx_co=1)

**候选者**：前面提到过read uncommit隔离级别下会产生脏读，而read commit (读已提交) 隔离级别解决了脏读。思想其实很简单：在读取的时候生成一个”版本号”，等到其他事务commit了之后，才会读取最新已commit的”版本号”数据。

**候选者**：比如说：事务A读取了记录(生成版本号)，事务B修改了记录(此时加了写锁)，事务A再读取的时候，是依据最新的版本号来读取的(当事务B执行commit了之后，会生成一个新的版本号)，如果事务B还没有commit，那事务A读取的还是之前版本号的数据。

**候选者**：通过「版本」的概念，这样就解决了脏读的问题，而「版本」其实就是对应快照的数据。

**候选者**：read commit (读已提交) 解决了脏读，但也会有其他并发的问题。「不可重复读」：一个事务读取到另外一个事务已经提交的数据，也就是说一个事务可以看到其他事务所做的修改。

**候选者**：不可重复读的例子：A查询数据库得到数据，B去修改数据库的数据，导致A多次查询数据库的结果都不一样【危害：A每次查询的结果都是受B的影响的】

**候选者**：了解MVCC基础之后，就很容易想到repeatable read (可重复复读)隔离级别是怎么避免不可重复读的问题了（前面也提到了）。

**候选者**：repeatable read (可重复复读)隔离级别是「事务级别」的快照！每次读取的都是「当前事务的版本」，即使当前数据被其他事务修改了(commit)，也只会读取当前事务版本的数据。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/E44aHibktsKa23y7eBdg7ZkHNEoIDMgVkGek0TdDYQVwBNo1F7LdqKMTvfXjAVbRSyib2MBM6xsic6E0fDeV7JOPA/640?wx_fmt=jpeg&wxfrom=5&wx_lazy=1&wx_co=1)

**候选者**：而repeatable read (可重复复读)隔离级别会存在幻读的问题，「幻读」指的是指在一个事务内读取到了别的事务插入的数据，导致前后读取不一致。

**候****选者**：在InnoDB引擎下的的repeatable read (可重复复读)隔离级别下，快照读MVCC影响下，已经解决了幻读的问题（因为它是读历史版本的数据）

**候选者**：而如果是当前读（指的是 select * from table for update），则需要配合间隙锁来解决幻读的问题。

**候选者**：剩下的就是serializable (串行)隔离级别了，它的最高的隔离级别，相当于不允许事务的并发，事务与事务之间执行是串行的，它的效率最低，但同时也是最安全的。

**面试官**：嗯，可以的。**我看你提到了MVCC了，不妨来说下他的原理？**

**候选者**：MVCC的主要是通过read view和undo log来实现的

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/E44aHibktsKa23y7eBdg7ZkHNEoIDMgVkcZbr7670ibA1w8icW2bjgpcjyewAD2a5a7yWhK2F50RNicnSNvGOnahvA/640?wx_fmt=jpeg&wxfrom=5&wx_lazy=1&wx_co=1)

**候选者**：undo log前面也提到了，它会记录修改数据之前的信息，事务中的原子性就是通过undo log来实现的。所以，有undo log可以帮我们找到「版本」的数据

**候选者**：而read view 实际上就是在查询时，InnoDB会生成一个read view，read view 有几个重要的字段，分别是：trx_ids（尚未提交commit的事务版本号集合），up_limit_id（下一次要生成的事务ID值），low_limit_id（尚未提交版本号的事务ID最小值）以及creator_trx_id（当前的事务版本号）

**候选者**：在每行数据有两列隐藏的字段，分别是DB_TRX_ID（记录着当前ID）以及DB_ROLL_PTR（指向上一个版本数据在undo log 里的位置指针）

**候选者**：铺垫到这了，很容易就发现，MVCC其实就是靠「比对版本」来实现读写不阻塞，而版本的数据存在于undo log中。

**候选者**：而针对于不同的隔离级别（read commit和repeatable read），无非就是read commit隔离级别下，每次都获取一个新的read view，repeatable read隔离级别则每次事务只获取一个read view

**面试官**：嗯，OK的。细节就不考究了，今天就到这里吧。

**本文总结**：

- 事务为了保证数据的最终一致性

- 事务有四大特性，分别是原子性、一致性、隔离性、持久性

- - 原子性由undo log保证
  - 持久性由redo log 保证
  - 隔离性由数据库隔离级别供我们选择，分别有read uncommit,read commit,repeatable read,serializable
  - 一致性是事务的目的，一致性由应用程序来保证

- 事务并发会存在各种问题，分别有脏读、重复读、幻读问题。上面的不同隔离级别可以解决掉由于并发事务所造成的问题，而隔离级别实际上就是由MySQL锁来实现的

- 频繁加锁会导致数据库性能低下，引入了MVCC多版本控制来实现读写不阻塞，提高数据库性能

- MVCC原理即通过read view 以及undo log来实现