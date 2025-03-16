# Java虚拟机面试八股文第二弹



**推荐阅读：**

- **[JVM面试八股文第一弹](http://mp.weixin.qq.com/s?__biz=MzA4NjU1MzA2MQ==&mid=2647725980&idx=1&sn=04ec26389536027020edba68a4cd98a6&chksm=87e34f16b094c6000fab71eae6238e26c19c671423402ead2844e524fc385823a5ede8b018ff&scene=21#wechat_redirect)**
- **[面试八股文系列](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=MzA4NjU1MzA2MQ==&action=getalbum&album_id=1966226418825035778#wechat_redirect)**
- **[程序人生系列](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=MzA4NjU1MzA2MQ==&action=getalbum&album_id=1816486914183512067#wechat_redirect)**
- **[大厂面经系列](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=MzA4NjU1MzA2MQ==&action=getalbum&album_id=2105056235833131010#wechat_redirect)
  **

**文章目录**

- Java中垃圾回收是什么，为什么需要垃圾回收?

- Minor GC和Full GC有什么不同？什么情况下会触发Full GC和Minor FC？

- 为什么要减少Full GC的发生？

- JVM的内存分配与回收

- Java中都有哪些引用类型

- 如何判断对象是否可以回收

- - 引用计数法
  - 可达性分析法

- JVM中的永久代中会发生垃圾回收吗？元空间会发生垃圾回收吗？

- 有什么办法主动通知虚拟机进行垃圾回收？

- 垃圾回收算法

- - 标记-清除算法
  - 标记-复制算法
  - 标记-整理算法
  - 分代收集算法

- 垃圾收集器



# JVM垃圾回收

> Java和C++的一个明显区别就是Java具备内存动态分配和垃圾收集技术，而C++则需要程序员自己管理内存，这也使得一些初学者觉得C++比较难

## Java中垃圾回收是什么，为什么需要垃圾回收?

在Java中垃圾回收的目的是回收释放不再被引用的实例对象，这样做可以减少内存泄漏、内存溢出问题的出现

## Minor GC和Full GC有什么不同？什么情况下会触发Full GC和Minor FC？

- **Minor GC**（新生代GC）：指发生在新生代的垃圾收集动作，Java对象大多存活时间不长，所以Minor GC的发生会比较频繁，回收速度也比较快
- **Full GC/Major GC**（老年代GC）：指发生在老年代的GC，出现了Full GC，经常会伴随至少一次的Minor GC（不是必然的），Major GC的速度一般会比Minor GC慢10倍以上。

什么情况下会触发**Minor GC**：在新生代的Eedn区满了会触发

什么情况下会触发**Full GC**：

- **`System.gc()`方法的调用**，此方法会建议JVM进行Full GC，但JVM可能不接受这个建议，所以不一定会执行。
- **老年代空间不足**，创建的大对象的内存大于老年代空间，导致老年代空间不足，则会发生Full GC
- **JDK1.7及以前的永久代空间满了**，在JDK1.7以前，HotSpot虚拟机的方法区是永久代实现都得，在永久代中会存放一些Class的信息、常量、静态变量等数据，在永久代满了，并且没有配置CMS GC的情况下就会触发Full GC，在JDK1.8开始移除永久代也是为了减少Full GC的频率
- **空间分配担保失败**，通过Minor GC后进入老年代的平均大小大于老年代的可用空间，会触发Full GC

## 为什么要减少Full GC的发生？

Full GC发生过于频繁，会影响性能，因为Full GC会导致STW(Stop-The-World)，STW指的是用户线程在运行至安全点（safe point）或安全区域（safe region）之后，就自行挂起，进入暂停状态，对外的表现就是卡顿。所以应尽量减少Full GC的次数。不过不论是minor gc还是major gc都会STW，区别只在于STW的时间长短。

## JVM的内存分配与回收

Java的自动内存管理主要解决了**给对象分配内存**和**回收分配给对象的内存**两个问题，先来看下Java虚拟机是如何为对象分配内存的

Java对象的内存分配主要就是在堆上，Java堆的基本结构如下，大体上可以分为**新生代**和**老年代**。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/cBnxLn7axrzlsicXqrbNyqjmUzhwzTCYQLsl1UQFmibqribYcJBxRogriaVgTFXmtPUOSygT70yqPyFmOZiaWv6QibRA/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

新生代默认占1/3，老年代默认占2/3，新生代包含Eden区、From Survivor0区和From Survivor1区，默认比例是8：1：1，老年代就一个Old Memory区。

一般情况下是这样分配的

- 对象先在Eden区分配，当Eden区没有足够的空间去分配时，虚拟机会发起一次Minor GC，将存活的对象放到From Survivor区（对象年龄为1）
- 当再次发生Minor GC，会将Eden区和From Survivor区一起清理，存活的对象会被移动到To Survivor区（年龄加1）
- 这时From Survivor区会和To Survivor区进行交换，然后重复第一步，不过这次第一步中的From Survivor区其实是上一轮中的To Survivor区。

每次移动，对象的年龄就会加1，当年龄到达15时（默认是15，对象晋升老年代的年龄阈值可以通过参数`-XX: MaxTenuringThreshold`设置），会从新生代进入老年代。

下面介绍几种收集器的内存分配策略

- 对象优先在Eden区分配
- 大对象直接进入老年代（大对象指需要大量连续内存空间的Java对象）
- 长期存活的对象进入老年代

注：为了可以更好地适应不同程度的内存状况，虚拟机并不是必须要求对象的年龄达到MaxTenuringThreshold才进入老年代，如果在Survivor空间中相同年龄所有对象大小的总和大于Survivor空间的一半，年龄大于或等于该年龄的对象可以直接进入老年代，无需等到MaxTenuringThreshold

最后说下**空间分配担保机制**，在发生Minor GC之前，虚拟机会先检查老年代最大可用的连续空间是否大于新生代所有对象总空间，如果大于，则表明Minor GC可以安全进行。如果不大于，虚拟机会查看HandlePromotionFailure设置是否允许担保失败。如果允许，则会继续检查老年代的最大可利用连续空间是否大于历次晋升到老年代对象的平均大小，如果大于，则会尝试进行一次Minor GC（存在一定风险），如果小于或者HandlePromotionFailure设置不允许担保失败，则这一次会进行Full GC。

这里解释为什么会存在风险，因为在新生代使用的垃圾收集算法是复制算法，前面也提到了，只有一个Survivor空间作为轮换备份，如果这时出现大量对象在Minor GC后仍然存活，则需要老年代进行担保，Survivor无法容纳的对象会直接进入老年代，风险就是Survivor无法容纳的对象有多大很难确定，也就无法保证老年代的空间一定够用，一般是取之前每一次回收晋升到老年代对象的平均大小作为参考值。

说完了空间分配担保机制的概念，不知道大家看出来这玩意儿有什么用了吗？

其实很简单，就是怕Minor GC后需要进入到老年代的对象太多了，老年代没有那么大空间，先提前检查一下，如果检查结果显示老年代确实装不下，那么这次Minor GC就得改成Full GC，那Full GC完了老年代空间还是不够呢？那会OOM内存溢出的

## Java中都有哪些引用类型

在JDK1.2之后，Java对引用的概念进行了扩充，主要分为**强引用**、**软引用**、**弱引用**、**虚引用**

- 强引用：垃圾收集器永远不会回收掉被引用的对象
- 软引用：用来描述一些有用但非必需的对象，在内存发生溢出之前会被回收
- 弱引用：用来描述一些有用但非必需的对象，在下一次垃圾回收时被回收
- 虚引用：最弱的一种引用关系，无法通过虚引用来获取一个对象，虚引用的唯一目的就是能在这个对象被回收时收到一个系统通知

## 如何判断对象是否可以回收

判断对象是否死亡的常见方法主要有**引用计数法**和**可达性分析法**两种

### 引用计数法

给对象添加一个引用计数器，每当有一个地方引用它时，计数器就会加1；当引用失效时，计数器就减1，当计数器为0就是没有被使用的对象，但主流的Java虚拟机并没有选择用引用计数法来管理内存，**因为无法解决对象之间相互循环引用的问题**，就是两个对象相互引用，除此之外，两个对象并没有其他引用，这两个对象已经不可能被访问了，但他们的引用计数都不为0，所以无法被垃圾收集器回收。

### 可达性分析法

可达性分析法就是通过一系列被称为”GC Roots“的对象作为起点，从这些节点开始向下搜索，搜索所走过的路径被称为引用链，当一个对象到GC Roots没有任何引用链相连时，则证明该对象是不可用的，也就是可回收的，如下图，对象object 5、object 6、object 7虽然有关联，但他们到GC Roots是不可达的，所以也会判定是可以回收的，这样解决了对象之间相互引用导致不能回收的问题。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/cBnxLn7axrzlsicXqrbNyqjmUzhwzTCYQiaoM5JohUqIia2uia53Aicx90F2rPMG5aib6b6ibh4ozM4UkGAwdt9VM09mA/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

注：在Java语言中，可以作为GC Roots的对象主要有以下几种：

- 虚拟机栈中引用的对象
- 方法区中类静态属性引用的对象
- 方法区中常量引用的属性
- 本地方法栈中Native中引用的对象

## JVM中的永久代中会发生垃圾回收吗？元空间会发生垃圾回收吗？

首先，永久代这个概念是HotSpot虚拟机中独有的，其他Java虚拟机中并没有永久代的概念

在JDK1.8之前JVM存在永久代，在JDK1.8被元空间替代。那什么是永久代呢？永久代和元空间都是方法区的具体实现，方法区只是一种规范

在永久代中主要是存放类的信息（成员方法、构造器、类加载器等）及运行时常量池，所以当永久代满了也会进行回收。

在永久代发生的内存回收主要是**常量池的回收**和**类型的卸载**。常量池的回收相对容易，只要常量池中的常量没有被任何地方引用，就可以被回收。判断一个类型是否可以回收比较麻烦，主要看以下几个方面：

- 该类型所有实例都被回收
- 加载该类的类加载器已经被回收
- 该类对应的java.lang.Class对象没有在任何地方被引用，无法在任何地方通过反射访问该类的方法

为什么在JDK1.8会使用元空间取代永久代？

永久代使用的是设定好的虚拟机内存，无法动态扩展内存空间，当加载的类过多就可能发生OOM，并且永久代的内存大小设置也是难以确定的，所以对永久代调优也是比较困难的。

元空间的出现就解决了永久代的问题，因为元空间不再使用虚拟机的内存了，而是使用了本地内存，本地内存可以自动扩展调节，内存不足也不会触发Full GC。

## 有什么办法主动通知虚拟机进行垃圾回收？

可以通过调用`system.gc()`方法通知虚拟机进行垃圾回收，但Java虚拟机规范并不能保证一定会执行。

## 垃圾回收算法

> 垃圾收集算法主要有**标记-清除算法**、**标记-复制算法**、**标记-整理算法**、**分代收集算法**

### 标记-清除算法

标记-清除算法主要包含**标记**和**清除**两个阶段，首先标记出所有需要回收的对象，在标记完成后同一回收所有被标记的对象。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/cBnxLn7axrzlsicXqrbNyqjmUzhwzTCYQJ0nmCptYK1XIajsWJadmdTZgfCmMkUKIiaoaHJyQuGic3soyKFWINZnw/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

标记-清除算法有两个明显的缺点：第一就是效率低，标记和清除两个过程的效率都不高；第二是空间问题，标记清除后会产生大量不连续内存碎片，空间碎片太多会导致以后在程序运作过程中需要分配大对象时，无法找到足够的连续内存进而提前触发另一次垃圾收集动作。

### 标记-复制算法

为了解决标记-清除算法的效率问题，标记-复制算法出现了，它将可用内存按容量划分为大小相等的两块，每次只使用其中的一块，当这块的内存用完了，就将活着的对象复制到另一块上面，再将已使用过的内存一次清理掉，如下图

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/cBnxLn7axrzlsicXqrbNyqjmUzhwzTCYQTiav9FofGItKXFAXhMoRuzwvxuQbibKGBqZCQVJiccXD9no2ejbCIZdhg/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

标记-复制算法的好处显而易见，每次都是对半个区进行内存回收，内存分配时也不用考虑内存碎片等复杂情况，只需要移动堆顶指针，按顺序分配内存即可，实现简单，运行高效，缺点也是显而易见的，每次可以使用的内存只有原来的一半。

### 标记-整理算法

如果对象存活率比较高时使用标记-复制算法就要进行比较多的复制操作，效率会变低，针对这种场景，提出了一种标记-整理算法，和标记-清除算法不同的是，标记完后不直接对可回收对象进行清理，而是让所有存活的对象都向一端移动，然后直接清理掉其他地方的内存，如下图

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/cBnxLn7axrzlsicXqrbNyqjmUzhwzTCYQA8z0Nj4hdUZFIZ7DEK27aekGFgTYqeVGvSOoPibveI45Kw3pPhU5HlQ/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

### 分代收集算法

按照前面讲的，将Java堆分为新生代和老年代，根据每个年代的特点采用合适的收集算法。例如，在新生代每次垃圾回收时会有大量对象死亡，只有少量存活，所以在新生代选择用标记-复制算法，在老年代每次垃圾回收会有大量对象存活，考虑使用标记-清除或标记-整理算法。在商业虚拟机中一般都是采用分代收集算法。

## 垃圾收集器

垃圾回收算法是内存回收的方法论，垃圾收集器则是内存回收的具体实现。Java规范中并没有对垃圾收集器的实现有任何规范，所以不用的厂商、不同的版本的虚拟机提供的垃圾收集器是不同的，这里主要讨论的是HotSpot虚拟机所包含的虚拟机，按照年代划分如下：

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/cBnxLn7axrzlsicXqrbNyqjmUzhwzTCYQGb3hvdLSB6KkXiciahk2JKgmYOSnA4YayyfPMZibzm7PNceVgF67dVzgw/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

其中新生代收集器有Serial、ParNew、Parallel，老年代收集器有CMS、Serial Old、Parallel Ol，G1则既可以在新生代收集，又能在老年代收集。两个垃圾收集器之间如果存在连线，则说明它们可以搭配使用。

那哪个收集器的性能最好呢，其实这里**并不存在最好的收集器，只有在对应场景中最合适的垃圾收集器**

**参考：**《深入理解Java虚拟机》