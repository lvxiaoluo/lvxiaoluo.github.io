**美团技术一面20分钟**

**1、自我介绍** 

说了很多遍了，很流畅捡重点介绍完。 

**2、问我数据结构算法好不好** 

挺好的（其实心还是有点虚，不过最近刷了很多题也只能壮着胆子充胖子了） 

**3、找到单链表的三等分点，如果单链表是有环的呢** 

用快慢指针，一个走一步，一个走三步。如果有环，先判断环在哪，找最后一个节点，然后用之前的无环的做法 

**4、讲一下项目的架构** 

我重点讲了MVC 

**5、说一下你熟悉的设计模式** 

我重点讲了单例、工厂方法、代理 

**6、有没有配置过服务器啥啥啥** 

这个我真不知道，都没听过呢，只能诚实说没有，毕竟都没法扯。 

**一面挺匆忙的，我估计面试官刚开完会还没吃饭呢。他说让我等，可能再找一个同事面我，可能就直接告诉我结果了。从一面面试官的声音和口吻，我判断他一定是个部门老大，问的设计偏多，后面hr告诉我他就是我要去的部门的老大。哈哈。**

**美团技术二面60分钟，详细问答**

面完一面正准备出去打羽毛球，北京的电话又来了。（注定这周五参加不了球队活动了！） 

二面：跟一面比起来，二面面试官的声音听起来就像是搞技术开发的，果不其然，一个小时的纯技术电话面试！面的特别全面！

1、Spring：有没有用过Spring，Spring IOC、AOP机制与实现，Spring MVC

2、多线程：怎么实现线程安全，各个实现方法有什么区别，volatile关键字的使用，可重入锁的理解，Synchronized是不是可重入锁

3、集合： HashMap底层实现，怎么实现HashMap线程安全 

4、JVM内存管理，GC算法，HotSpot里面的垃圾回收器、类加载 

5、进程和线程的区别

6、HTTP有没有状态，我说无状态，怎么解决HTTP无状态 

7、Java IO，NIO，Java中有没有实现异步IO

8、前端会不会，Ajax是什么，Ajax实现原理 

9、让我设计一个线程池 

10、讲几个设计模式，哪些地方用到了，为什么要用

11、Mysql优化、索引的实现

12、事务的隔离级别

13、有没有用过Hibernate、mybatis、git

14、Linux 

15、算法题

- 从10万个数中找最小的10个，时间复杂度分析（最大堆，考虑内存）
- 从一个有正有负数组中找连续子数组的最大和，时间复杂度分析（动态规划）
- 满二叉树第i层有多少个节点，n层的满二叉树共有多少个节点

**终于到我提问环节了**

- 1、你们是什么部门（他说是核心部门，大数据研发）
- 2、我对高并发和负载均衡挺有兴趣的，但是我平时在学校也没有这个环境让我在这方面有所体验，那你建议我目前可以怎么学呢（他说这确实是不太好学，只能看些理论和别人的博客，以后工作中才能慢慢学） 
- 3、中间件具体是做什么的，是解决高并发和负载均衡吗（他说差不多是的，然后他说我们这个部门不是中间件，是大数据部门啊，我说恩我知道） 
- 最后没啥问题了，他让我保持电话畅通。

**这一面面完，口干舌燥，我一度怀疑他可能不知道我是在应聘实习生的岗位。有太多要总结的了，放在总结的地方一起讲吧。**

**美团技术三面25分钟**

面试官说是他是另外一个部门的，需要进行交叉面试。

- 1、MySql优化 
- 2、说下项目做了些什么，架构之类的 
- 3、在collabedit上在线写代码，题目很简单是编程之美上的原题，一个有序的整数数组，输出两个数，使它们的和为某个给定的值。之前做过很快写好，然后给他讲思路。他继续问如果数组无序怎么办，先排序。 
- 4、两个文件，每个文件中都有若干个url，找出两个文件中相同的url（用HashMap） 

**这一面挺简单的，只是增加之前面试没有过的在线写代码环节，collabedit后来我才了解，像facebook一些互联网公司远程面试都会用这个在线编辑器写代码，就是文本文档写，没有提示，不能编译运行，跟白板写一样。平时练练手就好。**

**美团技术HR四面30分钟**

三面面试官说他那就是终面，说我过了等hr联系我。万万没想到半小时后的hr面居然也是技术。 

- 1、自我介绍，都四面了还自我介绍？！我还以为是单纯的hr面，所以介绍的都是我的性格和生活方面的，结果并不是。 
- 2、问项目，问的特别特别细，技术细节，还有遇到什么问题，怎么解决的，做项目有没有人带，怎么跟别人沟通的。 
- 3、数据库优化，如果数据库一个表特别大怎么办 数据库优化我就讲了之前讲过很多遍的点，他问一个表特别大怎么办：大表分小表，怎么实现：使用分区表 。
