# 「动图」 秒懂 Kafka 时间轮（TimingWheel）



大家好，我是悟空呀。



时间轮在 Kafka，Netty 中都用到了，必须学它一波，这篇动图讲解时间轮的，可以快速帮助大家理解~

通过本文你将了解到时间轮算法思想，层级时间轮，时间轮的升级和降级。













时间轮，是一种实现延迟功能（定时器）的巧妙算法，在 Netty，Zookeeper，Kafka 等各种框架中，甚至 Linux 内核中都有用到。



本文将参考Kafka的时间轮作为例子讲解。



0

设计源于生活

开始之前给大家看块宝珀中华年历表。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/rYPAT7RhHkOV6fbKr4vm6LB6O1aLXSGJTIOLgbrdmG81ich3lZZ2iagR8lQ8t4oVvQibbqEk5E8xxAWj8G8GLxVRQ/640?wx_fmt=jpeg&wxfrom=5&wx_lazy=1&wx_co=1)

图片来自宝珀官网



这款手表的表盘融合了中华历法中各种博大精深的计时元素。



上方位置的小表盘显示时辰数字及字符,24小时一周期;年份视窗显示当年所属生肖,12年一周期;



左边位置显示农历月,12个月一周期; 农历日, 30天一周期;



右边位置显示五行元素和十天干,10年一周期;



下方的表盘显示月相盈亏。



至于价格.....这个话题略过。



而时间轮，其设计正是来源于生活中的时钟。



1

时间轮

如图就是一个简单的时间轮：



![图片](https://mmbiz.qpic.cn/mmbiz_gif/rYPAT7RhHkOV6fbKr4vm6LB6O1aLXSGJr1E3tibHiaricBWlNQzzeLcmKIEhr29ImHBWyL0ib22xicq8icfKRbJbRPCw/640?wx_fmt=gif&wxfrom=5&wx_lazy=1)

图中大圆的圆心位置表示的是当前的时间，随着时间推移, 圆心处的时间也会不断跳动。



下面我们对着这个图，来说说Kafka的时间轮TimingWheel。



Kafka时间轮的底层就是一个环形数组，而数组中每个元素都存放一个双向链表TimerTaskList，链表中封装了很多延时任务。



Kafka中一个时间轮TimingWheel是由20个时间格组成，wheelSize = 20；每格的时间跨度是1ms，tickMs = 1ms。参照Kafka，上图中也用了20个灰边小圆表示时间格，为了动画演示可以看得清楚，我们这里每个小圆的时间跨度是1s。



所以现在整个时间轮的时间跨度就是 tickMs * wheelSize ，也就是 20s。从0s到19s，我们都分别有一个灰边小圆来承载。



Kafka的时间轮还有一个表盘指针 currentTime，表示时间轮当前所处的时间。也就是图中用黑色粗线表示的圆，随着时间推移, 这个指针也会不断前进;

![图片](https://mmbiz.qpic.cn/mmbiz_png/rYPAT7RhHkOteibQFNwbdLNcVvbzdiaWoJk5zUibTbE3nDCZL7Kn4wAshDiaK9cxzS9EJ1ARNAR3HkTPDjOvUCNJeA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)







添加定时任务

有了时间轮，现在可以往里面添加定时任务了。我们用一个粉红色的小圆来表示一个定时任务。

![图片](https://mmbiz.qpic.cn/mmbiz_png/rYPAT7RhHkOV6fbKr4vm6LB6O1aLXSGJcGDsredcibJibGGz18Vb5Z2ia4BfCiadUojYr7v2d0bDDeHdiaVkWV6Tycw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)



这里先讲一下设定，每一个定时任务都有延时时间**delayTime**，和过期时间**ExpiredTime**。

比如当前时间是10s，我们添加了个延时时间为2s的任务，那么这个任务的过期时间就是12s，也就是当前时间10s再走两秒，变成了12s的时候，就到了触发这个定时任务的时间。



而时间轮上代表时间格的灰边小圆上显示的数字，可以理解为任务的过期时间。

![图片](https://mmbiz.qpic.cn/mmbiz_png/rYPAT7RhHkOV6fbKr4vm6LB6O1aLXSGJmEibUC6pokiadT72pAdRibC0ImprIfSywmSorh1j23tibmOtiaUzWibm51lw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)



讲清楚这些设定后，我们就开始添加定时任务吧。



初始的时候, 时间轮的指针定格在0。此时添加一个超时时间为2s的任务, 那么这个任务将会插入到第二个时间格中。

![图片](https://mmbiz.qpic.cn/mmbiz_gif/rYPAT7RhHkOV6fbKr4vm6LB6O1aLXSGJ4VDuicwsn6upOfMbib8na0XrhAXKyTs2ciblfAIQVEXCeN8HhKcQOe5yQ/640?wx_fmt=gif&wxfrom=5&wx_lazy=1)





当时间轮的指针到达第二个时间格时, 会处理该时间格上对应的任务。在动画上就是让红色的小圆消失!

![图片](https://mmbiz.qpic.cn/mmbiz_gif/rYPAT7RhHkOV6fbKr4vm6LB6O1aLXSGJzZp2LGhe809EgBEjgwHbkoDqicPgae5ktouOZ5GQ0uFZXJTXHnpicyAA/640?wx_fmt=gif&wxfrom=5&wx_lazy=1)



如果这个时候又插入一个延时时间为8s的任务进来, 这个任务的过期时间就是在当前时间2s的基础上加8s, 也就是10s, 那么这个任务将会插入到过期时间为10s的时间格中。

![图片](https://mmbiz.qpic.cn/mmbiz_gif/rYPAT7RhHkOV6fbKr4vm6LB6O1aLXSGJmic5BWgMEq8ianT2sJgBELk7mTttF0hS4NzvcjFBf3pb52dV5KYgxibug/640?wx_fmt=gif&wxfrom=5&wx_lazy=1)







2

"动态"时间轮

到目前为止，一切都很好理解。



那么如果在当前时间是2s的时候, 插入一个延时时间为19s的任务时, 这个任务的过期时间就是在当前时间2s的基础上加19s, 也就是21s。



请看下图，当前的时间轮是没有过期时间为21s的时间格。这个任务将会插入到过期时间为1s的时间格中，这是怎么回事呢？

![图片](https://mmbiz.qpic.cn/mmbiz_png/rYPAT7RhHkOV6fbKr4vm6LB6O1aLXSGJYTibC942oia86zfwS3CDDpXtyGtNcxEBnBwlBD7OtDTtK3YpFSU6fjpw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

复用时间格



为了解答上面的问题，我们先来点魔法， 让时间轮上的时间都动起来！

![图片](https://mmbiz.qpic.cn/mmbiz_gif/rYPAT7RhHkOV6fbKr4vm6LB6O1aLXSGJXp50icFeIRwoA6PV2ic6jJBhvicibbOxdicshMLIRUxbKtFRRlVFt5ibJzng/640?wx_fmt=gif&wxfrom=5&wx_lazy=1)

其实呢，当指针定格在2s的位置时, 时间格0s, 1s和2s就已经是过期的时间格。



也就是说指针可以用来划分过期的时间格[0,2]和未来的时间格 [3,19]。而过期的时间格可以继续复用。比如过期的时间格0s就变成了20s, 存放过期时间为20s的任务。



理解了时间格的复用之后，再看回刚刚的例子，当前时间是2s时，添加延时时间为19s的任务，那么这个任务就会插入到过期时间为21s的时间格中。

![图片](https://mmbiz.qpic.cn/mmbiz_png/rYPAT7RhHkOV6fbKr4vm6LB6O1aLXSGJw3YJ9VoWOq7kRW9kBqtrn7dlRjsEX1Cg4c70icef4p8zf9Y4ib0h2Z9w/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

3

时间轮升级

下面，新的问题来了，请坐好扶稳。



如果在当前时间是2s的时候, 插入一个延时时间为22s的任务, 这个任务的过期时间就是在2s的基础上加22s，也就是24s。

![图片](https://mmbiz.qpic.cn/mmbiz_png/rYPAT7RhHkOV6fbKr4vm6LB6O1aLXSGJVRTrZbVMtmFYXQS8hRugnmVkKXtGWTNym73XBA7JkDC3JZ1wR3nTRQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)



显然当前时间轮是无法找到过期时间格为24秒的时间格，因为当前过期时间最大的时间格才到21s。而且我们也没办法像前面那样再复用时间格，因为除了过期时间为2s的时间格，其他的时间格都还没过期呢。当前时间轮无法承载这个定时任务, 那么应该怎么办呢?



当然我们可以选择扩展时间轮上的时间格, 但是这样一来，时间轮就失去了意义。



是时候要升级时间轮了！



我们先来理解下多层时间轮之间的联系。



4

层级时间轮

如图是一个两层的时间轮:

![图片](https://mmbiz.qpic.cn/mmbiz_png/rYPAT7RhHkOV6fbKr4vm6LB6O1aLXSGJFiblvEzFyLeial3eBwwFS3vIkA89iatmelIFjmFwB79iajJjYnm1CpTN8A/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

第二层时间轮也是由20个时间格组成, 每个时间格的跨度是20s。





图中展示了每个时间格对应的过期时间范围, 我们可以清晰地看到, 第二层时间轮的第0个时间格的过期时间范围是 [0,19]。也就是说, 第二层时间轮的一个时间格就可以表示第一层时间轮的所有(20个)时间格;



为了进一步理清第一层时间轮和第二层时间轮的关系, 我们拉着时间的小手, 一起观看下面的动图:

![图片](https://mmbiz.qpic.cn/mmbiz_gif/rYPAT7RhHkOV6fbKr4vm6LB6O1aLXSGJib1mZdlvTdjHEpG6fDtbbVyaSc77a9T6ia5H83kibCKlwkgPficmg4fo0Q/640?wx_fmt=gif&wxfrom=5&wx_lazy=1)

可以看到，第二层时间轮同样也有自己的指针, 每当第一层时间轮走完一个周期，第二层时间轮的指针就会推进一格。

添加定时任务

回到一开始的问题，在当前时间是2s的时候, 插入一个延时时间为22s的任务，该任务过期时间为24s。

![图片](https://mmbiz.qpic.cn/mmbiz_gif/rYPAT7RhHkOV6fbKr4vm6LB6O1aLXSGJsctbcYh9fGMWjjlyDmicbSqcf7HVZUKPAygDYfvlybcfnaic6NROz9NQ/640?wx_fmt=gif&wxfrom=5&wx_lazy=1)

当第一层时间轮容纳不下时，进入第二层时间轮，并插入到过期时间为[20,39]的时间格中。



我们再来个例子，如果在当前时间是2s的时候, 插入一个延时时间为350s的任务, 这个任务的过期时间就是在2s的基础上加350s，也就是352s。

![图片](https://mmbiz.qpic.cn/mmbiz_gif/rYPAT7RhHkOV6fbKr4vm6LB6O1aLXSGJuia3ibb9hyDR6cDBgaCIbsgNSwMB7Xbx9zx56icIzY3GQtRkwicxcY6RBg/640?wx_fmt=gif&wxfrom=5&wx_lazy=1)



从图中可以看到，该任务插入到第二层时间轮过期时间为[340,359]s的时间格中，也就是第17格的位置。





5

"动态"层级时间轮

通常来说, 第二层时间轮的第0个时间格是用来表示第一层时间轮的, 这一格是存放不了任务的, 因为超时时间0-20s的任务, 第一层时间轮就可以处理了。



但是! 事情往往没这么简单, 我们时间轮上的时间格都是可以复用的! 那么这在第二层时间轮上又是怎么体现的呢? 



下面是魔法时间， 我们让时间轮上的过期时间都动起来！

![图片](https://mmbiz.qpic.cn/mmbiz_gif/rYPAT7RhHkOV6fbKr4vm6LB6O1aLXSGJ8gicBt6AQAKichaL5XANpRRvuMvICuhfvV13ovHnG6UIdAUIGrnQTq9Q/640?wx_fmt=gif&wxfrom=5&wx_lazy=1)



从图中可以看到，当第一层时间轮的指针定格在1s时，超时时间0s的时间格就过期了。而这个时候，第二层时间轮第0个时间格的时间范围就从[0,19]分为了过期的[0],和未过期的[1,19]。而过期的[0]就会被新的过期时间[400]复用。



第二层时间轮第0个时间格的过期时间范围演变如下：

[0-19]

[400][1,19]

[400,401][2,19]

......

[400,419]



所以，如果在当前时间是2s的时候, 插入一个延时时间为399s的任务, 这个任务的过期时间就是在2s的基础上加399s，也就是401s。如图，这个任务还是会插到第二层时间轮第0个时间格中去。

![图片](https://mmbiz.qpic.cn/mmbiz_png/rYPAT7RhHkOV6fbKr4vm6LB6O1aLXSGJXN9CI8XKGPAa53qE5klNwNxmh6JeFllOfmdGVaQicJV5AYCOFEfgbpw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)



6

时间轮降级

还是用回这个大家都已经耳熟能详的例子，在当前时间是2s的时候, 插入一个延时时间为22s的任务，该任务过期时间为24s。最后进入第二层时间轮，并插入到过期时间为[20,39]的时间格中。



当二层时间轮上的定时任务到期后，时间轮是怎么做的呢？



![图片](https://mmbiz.qpic.cn/mmbiz_gif/rYPAT7RhHkOV6fbKr4vm6LB6O1aLXSGJsk2HkrJ8chwhnvbePX1jahItaE3cibhklgI4Nf098Dpacas3NwtMLOA/640?wx_fmt=gif&wxfrom=5&wx_lazy=1)

从图中可以看到，随着当前时间从2s继续往前推进，一直到20s的时候，总共经过了18s。此时第二层时间轮中，超时时间为[20-39s]的时间格上的任务到期。



原本超时时间为24s的任务会被取出来，重新加入时间轮。此时该定时任务的延时时间从原本的22s，到现在还剩下4s（22s-18s）。最后停留在第一层时间轮超时时间为24s的时间格，也就是第4个时间格。



随着当前时间继续推进，再经过4s后，该定时任务到期被执行。





从这里可以看出时间轮的巧妙之处，两层时间轮只用了40个数组元素，却可以承载[0-399s]的定时任务。而三层时间轮用60个数组元素，就可以承载[0-7999s]的定时任务！



![图片](https://mmbiz.qpic.cn/mmbiz_png/rYPAT7RhHkOV6fbKr4vm6LB6O1aLXSGJf5P1ZkjY4aKEIVXdNEQXmF1gU2aMu36Aap01ylvZ7LQO3ZJk8gpFhw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)



7

时间轮的推进

从动画中可以注意到, 随着时间推进, 时间轮的指针循环往复地定格在每一个时间格上, 每一次都要判断当前定格的时间格里是不是有任务存在;



其中有很多时间格都是没有任务的, 指针定格在这种空的时间格中, 就是一次"空推进";



比如说, 插入一个延时时间400s的任务, 指针就要执行399次"空推进", 这是一种浪费!



那么Kafka是怎么解决这个问题的呢？这就要从延迟队列DelayQueue开始讲起了！

