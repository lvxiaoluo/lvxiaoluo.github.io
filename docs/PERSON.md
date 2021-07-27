### 美团
     * 自我介绍
     * 双写一致性，binlog
     * validate 作用
     * spring 循环依赖
     * redis 数据结构 zset底层数据结构
     * kafka 死信队列 消息顺序性
     * mysql 聚集索引 非聚集索引 区别
     *     MVCC 间隙锁 
     * Autowired 和 @Resource 区别
     * synchronized reentrantLock区别
     * hashmap 为什么是2的n次方  concurrenthashmap 1.7 1.8
     * cpu飙升 内存泄漏问题排除
     * 分库分表有过吗？
     * 设计模式 责任链模式
     * jvm cms过程  stw那几个阶段
     * 怎么判断链表有环？
     * 有什么问题？
     * 问了垃圾回收。注意下cms和g1区别，和适用场景。
     * 算法提也是线程打印。我好像join没有用对 。 也没了下文
     
     
## 去哪儿
     * synchronized reentrantLock 原理
     * 线程顺序执行 A-B-C
     * 内存溢出问题排查
     * MySQL隔离级别
     * MySQL可重复读 MVCC
     * 幻读如何解决
     * 多线程实现生产者消费者
     * join 作用 
     * 项目难点，遇到遇到什么问题    


## 字节
    1.重入锁加锁过程，公平非公平如何实现的
    2.mysql主从复制原理，出现延迟的原因，如何避免
    3.线程池一个任务加进去的过程 及非核心工作线程如何被回收
    4.redis 主从复制原理及高并发下有什么局限。如何解决     
    5.还有个kafka选举过程。 如何保证消息不丢失。
    
    
    出了道算法题：有n个学生，每个学生考的分不同，要对学生进行糖块奖励，原则是当学生知道左右比他分低的同学分得了多于或等于的糖就会不开心。求最少糖让每个学生都开新的数量




    
## 美团面经（4轮面试，一波三折）
#### 1. 美团第一面：轻松
自我介绍、过往工作经历
说之前的项目（关于并发量）
介绍一下项目流程，介绍一下系统框架是怎么设计的？用到哪些技术？遇到过哪些问题？是怎样去解决的？
如何承载高并发？
RocketMQ的运行模型
zookeeper是如何保证一致性的，协议叫什么？
乐观锁和悲观锁，应用场景有哪些？
什么情况下会发生死锁，怎么处理死锁？
hashMap的原理，由此延伸问红黑树是什么，hash冲突怎么解决？
排序算法记得多少？
写代码：两个stack实现一个queue
美团第二面：紧张
#### 2. 自我介绍，介绍一下项目流程
网页输入 url 之后会有什么过程？
讲讲三次握手，为什么是三次？两次不行吗？
做过 socket 编程吗？讲讲 socket 中的状态？

进程和线程的区别
Synchronized与Lock的区别
事务隔离级别和实现原理，mysql发生锁死怎么办？
Java的垃圾回收机制
线程池了解多少，线程池的参数有哪些？
HashMap原理（感觉是个必问题）
有100只瓶液体，其中一瓶是毒药，一只小白鼠喝到毒药一周后会死亡。请问给一周时间，至少需要多少只小白鼠能确定哪瓶是毒药？（把瓶子序号变成二进制）
代码实现链表的反转
一个整数数组先升序后降序，给一个整数k，返回它在数组中的index，找不到的话返回-1
算法题：连续子数组最大和 / 乘积
#### 3. 美团第三面：融洽
问oracle里面的函数有什么用？
面向对象都有哪些特性以及你对这些特性的理解
访问权限修饰符都有哪些？以及他们的区别
抽象的(abstract)方法是否可同时是静态的(static), 是否可同时是本地方法(native)，是否可同时被 synchronized？
    都不能。
    抽象方法需要子类重写，而静态的方法是无法被重写的，因此二者是矛盾的。
    本地方法是由本地代码（如 C 代码）实现的方法，而抽象方法是没有实现的，也是矛盾的。
    synchronized 和方法的实现细节有关，抽象方法不涉及实现细节（抽象方法没有方法体），因此也是相互矛盾的。
    为什么静态方法不能被重写：
    静态方法可以被继承，但是，不能被覆盖，即重写。如果父类中定义的静态方法在子类中被重新定义，那么在父类中定义的静态方法将被隐藏。可以使用语法：父类名.静态方法调用隐藏的静态方法。
    如果父类中含有一个静态方法，且在子类中也含有一个返回类型、方法名、参数列表均与之相同的静态方法，那么该子类实际上只是将父类中的该同名方法进行了隐藏，而非重写。换句话说，父类和子类中含有的其实是两个没有关系的方法，它们的行为也并不具有多态性
    因此，通过一个指向子类对象的父类引用变量来调用父子同名的静态方法时，只会调用父类的静态方法。
    本地方法
    一个Native Method就是一个java调用非java代码的接口。一个Native Method是这样一个java的方法：该方法的实现由非java语言实现。有些时候java语言不能实现某些功能，就需要调用其他语言的方法，即本地方法。
    使用本地方法是有开销的，谨慎使用。
#### 4. 聊我应聘的部门在做什么，谈谈我对项目的理解，怎么开展一个项目？
美团HR面试：稳了
自我介绍
为什么想来美团，对美团了解多少？
心中的互联网公司排序（送命题）
工作中遇见暂时无法解决的问题，你怎么来应对？
自己的优点和缺点
未来的职业规划是什么？
还面了哪些公司？结果怎么样？
薪资要求


## 阿里四面技术 + 一面HR


垃圾回收器 gc机制 ，对象分配过程（stab 栈上分配 eden old 动态年龄计算等）。
分布式缓存原理如何实现的？
分布式锁细节，可重入，失效时间，父子线程串改，结合项目问
AQS详细过程，加锁、解锁，入队，出队 抢占锁释放锁等过程。
zookeeper原理 说下zab算法。
jvm的空间分配担保策略描述下？
mq如何保证顺序消费的？从rocketMQ集群架构和kafka说起。
jdk8新特性，为什么要引进时间类，函数式编程本质？
分库分表原理知道吗？sequence和分表键关系是什么？
innodb引擎 优化细节，数据页，bufferBool 机制，索引下推等
redis cluster保证高可用吗？，节点党机，从机器数据失效
LinkedHashMap、treeMap 源码和实现过程？
如果碰到烦心事，压力大，一般怎么进行解压呀？
在公司的绩效如何？对标阿里的绩效是怎样的呢？
说说有没有什么让你印象很深刻无法忘记的事情。


## 网易三面技术 + 一面HR
介绍一下JVM内存模型。
MySQL索引优化原则，知道多少说多少。
BufferPool原理聊聊。
解释一下什么是负载均衡，Dubbo的负载均衡说一下？
当MySQL单表记录数过大时，数据库如何优化？
一个4库的怎么拆分成8库的在表数量不变的情况下？
举举例子业务中DDD的设计。
函数式编程的本质是什么，为什么需要了解过吗？
知道流的原理吗 Foreach函数碰到报错后面的执行吗？为什么？
kafka消息怎么保证不丢失的？
为什么跳槽？
对不是互联网电商方向，其他方向感兴趣吗？
今后有什么职场规划或者学习计划。
你认为你的个人性格是怎样的呢。


## 字节两面技术
介绍一下JVM内存模型。
MySQL索引优化原则，知道多少说多少。
BufferPool原理聊聊。
解释一下什么是负载均衡，Dubbo的负载均衡说一下。
当MySQL单表记录数过大时，数据库如何优化？
一个4库的怎么拆分成8库的在表数量不变的情况下。
hot么要分为新生代和老年代？
介绍一下CMS,G1收集器。