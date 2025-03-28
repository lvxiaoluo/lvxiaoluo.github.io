# JVM面试八股文第三弹（完结）



**推荐阅读：**

- **[Java虚拟机面试八股文第二弹](http://mp.weixin.qq.com/s?__biz=MzA4NjU1MzA2MQ==&mid=2647725995&idx=1&sn=64401e5de17bb9491bdd91c9da87cd3a&chksm=87e34f21b094c6372722cce2a606697387110204301700b8d2e8a004e8a676056cc39390fbda&scene=21#wechat_redirect)**
- **[Redis高频面试题完整版](http://mp.weixin.qq.com/s?__biz=MzA4NjU1MzA2MQ==&mid=2647726102&idx=1&sn=21617ecac89bdc0989b12db32658785d&chksm=87e3409cb094c98ad14ba73a1b9878faf6e8044aa31267d262e66b0352ca4775d4aa0dcb5a5b&scene=21#wechat_redirect)**
- **[面试八股文系列](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=MzA4NjU1MzA2MQ==&action=getalbum&album_id=1966226418825035778#wechat_redirect)**
- **[程序人生系列](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=MzA4NjU1MzA2MQ==&action=getalbum&album_id=1816486914183512067#wechat_redirect)
  **

**文章目录：**

- 垃圾收集器

- - Serial收集器
  - ParNew收集器
  - Parallel Scavenge收集器
  - Serial Old收集器
  - Parallel Old收集器
  - CMS收集器
  - G1收集器

- 关于类加载

- - 简述类的生命周期
  - 简述类加载过程
  - 类加载器有哪些
  - 什么是双亲委派机制
  - 有哪些打破双亲委派机制的例子



## 垃圾收集器

垃圾回收算法是内存回收的方法论，垃圾收集器则是内存回收的具体实现。Java规范中并没有对垃圾收集器的实现有任何规范，所以不用的厂商、不同的版本的虚拟机提供的垃圾收集器是不同的，这里主要讨论的是HotSpot虚拟机所包含的虚拟机，按照年代划分如下：

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/cBnxLn7axryo3pNHHChc8ImCbtfaFcsRuQeAeJ6r8jx7nV6VBssOqXQZYXQdHG8l25wn3QVND5aE3XwQdWtNgA/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

其中新生代收集器有Serial、ParNew、Parallel，老年代收集器有CMS、Serial Old、Parallel Ol，G1则既可以在新生代收集，又能在老年代收集。两个垃圾收集器之间如果存在连线，则说明它们可以搭配使用。

那哪个收集器的性能最好呢，其实这里**并不存在最好的收集器，只有在对应场景中最合适的垃圾收集器**

### Serial收集器

Serial收集器是最基本的收集器，并且是单线程的收集器，这里的单线程不仅仅说明它只会使用一个CPU或一条收集线程去完成垃圾收集工作，在它进行垃圾收集时，必须暂停其他所有的线程工作，直到它收集结束。不难想象，这对很多应用来说都是难以接受的，如下图

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/cBnxLn7axryo3pNHHChc8ImCbtfaFcsRvlCGZg4chrYfcx0qDaibrCx3j4afcWiaVbIibZESxSkCjZV8ddJLUqLRQ/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

除了上面写到的缺点，Serial收集器也有着优于其他收集器的地方，简单而高效（与其他收集器的单线程相比），对于限定单个CPU的环境来说，Serial收集器由于没有线程交互的开销，专心做垃圾回收自然可以获得最高的单线程的收集效率。

### ParNew收集器

ParNew收集器是Serial收集器的多线程版本，除了使用多条线程进行垃圾回收外，其他地方与Serial一样，从下图中也可以看出，除了多了几个GC线程，和Serial收集器并没有什么区别

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/cBnxLn7axryo3pNHHChc8ImCbtfaFcsRI1n0MO7iabMShRbUxVhv5HVRLMEKKHGhp7iapRclWickPAa0M6kia2nUMw/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

### Parallel Scavenge收集器

Parallel Scavenge 是一个使用标记-复制算法的多线程收集器，看起来和ParNew很像，Parallel Scavenge收集器的关注点和与其他收集器不同，CMS等收集器的关注点是尽可能地缩短垃圾收集时用户线程的停顿时间（用户体验），而Parallel Scavenge收集器的关注点是达到一个可控制的吞吐量（提高CPU的效率），这里的吞吐量指的是CPU用于运行代码的时间和CPU总消耗时间的比值。

那更短的停顿时间和更高的吞吐量有什么好处呢？

停顿时间越短越适合需要与用户交互的程序，良好的响应速度可以提升用户体验。更高的吞吐量适合在后台运算而不需要太多交互的程序，高吞吐量可以提高CPU的利用率，尽快地完成程序的运算任务。

### Serial Old收集器

Serial Old是Serial收集器的老年代版本，同样是单线程收集器，采用标记-整理算法，主要有两大用途：一是在JDK1.5以及之前的版本中与Parallel Scavenge收集器搭配使用，二是作为CMS收集器的后备预案。

### Parallel Old收集器

Parallel Old是Parallel Scavenge收集器的老年代版本，采用多线程和标记-整理算法。该收集器是在JDK1.6才开始提供的，因为当新生代选择了Parallel Scavenge收集器，老年代只能选择Serial Old（Parallel Scavenge无法与CMS搭配使用），这时Serial Old收集器会影响整体的吞吐量，所以提供了Parallel Old收集器和Parallel Scavenge搭配使用

### CMS收集器

CMS（Concurrent Mark Sweep）收集器是一种以获取最短回收停顿时间为目标的收集器，采用标记-清除算法，其运作过程可以分为**初始标记**、**并发标记**、**重新标记**、**并发清除**四个步骤。

- 初始标记：暂停其他线程，标记GC Roots能直接关联的对象，速度很快
- 并发标记：同时开启GC线程和用户线程，跟踪记录发生引用更新的地方
- 重新标记：修正并发标记期间因用户线程继续运作而导致标记产生变动的那一部分对象的标记记录
- 并发清除：GC线程对未标记的区域进行清除

上述四个步骤中，初始标记和重新标记两个步骤会“Stop The Word”，也就是会暂停用户线程，如下图

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/cBnxLn7axryo3pNHHChc8ImCbtfaFcsRtWUo3ibPkm7FMs8x9Dg0zWtMQFXj8uX03A6cQy9ORqmYkLArhGvOFhg/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

这里解释下在垃圾收集器的语境中，并行和并发的概念：

- 并行：指多条垃圾收集器线程并行工作，此时用户线程仍处于等待状态
- 并发：指用户线程与垃圾收集线程同时执行（也可以交替执行）

CMS的优点是**并发收集**，**停顿时间短**，缺点主要有以下三个：

- CMS收集器对CPU资源非常敏感
- CMS收集器无法处理浮动垃圾，浮动垃圾指在CMS并发清理阶段用户线程运行时不断产生的垃圾，CMS无法在当次集中收集处理它们，只能在下一次GC时清理
- 所采用的标记-清除算法会导致收集结束时产生大量的空间碎片。

### G1收集器

G1收集器是面向服务端应用的垃圾收集器，回收范围包括**新生代和老年代**，主要有以下特点：

- 并行与并发：G1充分利用多CPU、多核环境下的硬件优势，使用多个CPU来缩短Stop The World停顿时间，部分其他收集器需要停顿Java线程执行的GC动作，G1收集器可以通过并发的方式让Java程序继续执行
- 分代收集：分代概念在G1中依然保留，G1可以不需要其他收集器配合就能独自管理整个GC堆
- 空间整合：G1从整体上看是基于标记-整理算法实现的，从局部上看是基于标记-复制算法实现的，这意味着G1运作期间不会产生内存碎片
- 可预测的停顿：G1除了追求停顿外，还能建立可预测的停顿时间模型

G1收集器的运作步骤如下：

- 初始标记
- 并发标记
- 最终标记
- 筛选回收

看起来和CMS很像，如下图

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/cBnxLn7axryo3pNHHChc8ImCbtfaFcsRMsYj04HoHed8lqAE4XvmP66nDTZGN6QlJWMDdKYibqhfDpwcLp1flDQ/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

## 关于类加载

先解释下什么是类加载机制，虚拟机把描述类的数据从Class文件加载到内存，并对数据进行校验、转换解析和初始化，最终形成可以被虚拟机直接使用的Java类型。其实在看类加载之前最好了解下类文件结构，因为面试中这部分问的不多就不介绍了。

### 简述类的生命周期

类从被加载到虚拟机内存中开始，到卸载出内存为止，生命周期包括：**加载**、**验证**、**准备**、**解析**、**初始化**、**使用**和**卸载**等7个部分，其中验证、准备、解析统称为连接。

### 简述类加载过程

类的加载过程也就是类的生命周期的前五部分，**加载**、**验证**、**准备**、**解析**、**初始化**

#### 加载

在加载部分，虚拟机需要完成以下三件事：

- 通过一个类的全限定名来获取定义此类的二进制字节流
- 将这个字节流所代表的静态存储结构转化为方法区的运行时数据结构
- 在内存中生成一个代表这个类的java.lang.Class对象，作为方法区这个类的各种数据的访问入口

#### 验证

验证的目的是为了确保Classw文件的字节流中包含的信息符合当前虚拟机的要求，并且不会危害虚拟机的自身安全。验证主要分为四个阶段：**文件格式验证**、**元数据验证**、**字节码验证**、**符号引用验证**

- 文件格式验证：验证字节流是否符合Class文件格式的规范，并且能被当前版本虚拟机处理，例如主、次版本号是否在当前虚拟机处理范围之内
- 元数据验证：对字节码描述的信息进行语义分析，以保证其描述的信息符合Java语言规范的要求，例如这个类是否有父类，这个类的父类是否继承了不允许被继承的类等
- 字节码验证：通过数据流的控制流分析，确定程序语义是合法的、符合逻辑的。在对元数据信息中的数据类型做完校验后，字节码验证是对类的方法体进行校验分析，保证被校验类的方法在运行时不会做出危害虚拟机安全的事件，例如保证跳转指令不会跳转到方法体以外的字节码指令上
- 符号引用验证：符号引用验证可以看做是对类自身以外（常量池中的各种符号引用）的信息进行匹配性校验，例如符号引用中通过字符串描述的全限定名是否可以找到对应的类

#### 准备

准备阶段是正式为**类变量**分配内存并设置类变量初始值的阶段，这些变量所使用的内存都将在方法区分配。注意：这时候进行内存分配的只有类变量，**不包括实例变量**，其次，这里指的初始值一般是数据类型的零值，`public static int x = 1;`，变量`x`在准备阶段被设置的初始值是0而不是1，而程序被编译之后，`x`的值才为1。

#### 解析

解析阶段是虚拟机将常量池内的符号引用替换为直接引用的过程，符号引用是指以一组符号来描述所引用的目标，符号可以是任何形式的字面量，只要使用时可以无歧义定位到目标即可。直接引用是指直接指向目标的指针、相对偏移量或是一个可以直接定位到目标的句柄。

看了上面符号引用和直接引用的概念，相信很多人还是一头雾水，那符号引用转为直接引用有什么用呢？

其实符号引用就是通过一组符号来描述所引用的目标，符号引用与虚拟机实现的内存布局无关，引用的目标并不一定加载内存中，这时虚拟机并不知道对象的内存地址，所以光有符号引用是不够的。而直接引用是可以指向目标的指针，是和虚拟机实现的内存布局相关的，也就是可以确定对象在内存中的位置的。

简单来说就是在编译的时候，类会编译成一个class文件，但在编译的时候虚拟机并不直到知道所引用类的地址，这时就用符号引用来替代了，在解析时将符号引用转为直接引用就是因为直接引用可以找到类在内存中的地址。

#### 初始化

初始化是类加载的最后一步，也是类加载的最后一步，从这开始JVM开始真正执行类中定义的Java代码

### 类加载器有哪些

前面介绍了类的加载过程，类加载器的意义很容易理解，作用就是将类加载到虚拟机的内存中。

这里再提个挺重要的知识点，任何类都需要加载它的类和加载器和这个类本身确定其在Java虚拟机中的唯一性，也就是说要比较两个类是否相等，只有两个类由同一个类加载器加载的前提下才有意义，如果两个类不是由同一个类加载器加载，那么它一定不相等。

JVM主要提供三个类加载器:

- 启动类加载器（Bootstrap ClassLoader）：由C++语言实现，是虚拟机自身的一部分，负责加载存放在`<JAVA_HOME>\lib`（比如rt.jar、resources.jar、charsets.jar和class等），或被`-Xbootclasspath`参数所指定路径中的并且被虚拟机识别的类库。
- 扩展类加载器（Extension ClassLoader）：由Java语言实现，独立于虚拟机外部，负责加载`<JAVA_HOME>\lib\ext`目录中的类库。
- 应用程序类加载器（Application ClassLoader）：由Java语言实现，独立于虚拟机外部，负责加载用户路径上所指定的类库，如果程序中没有自己定义过的类加载器，一般情况这个是程序中的默认类加载器

### 什么是双亲委派机制

> 双亲委派机制是面试中非常高频的一个知识点，需要牢牢掌握

双亲委派机制：如果一个类加载器收到了类加载的请求，它首先不会自己去尝试加载这个类，而是把这个请求委派给父类加载器去完成，每一层次的类加载器都是这样，所以所有的加载请求最终都应该传送到顶层的启动类加载容器，只有当父类加载器无法完成加载时，子加载器才会尝试自己去加载，如下图

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/cBnxLn7axryo3pNHHChc8ImCbtfaFcsRQj8ht12vrLmVb1QdIibEGicVgSJc22rKPcG1xibia4tLw2H63YnlEDT2zw/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

#### **这里有个问题，类加载器中的父类加载器和子类加载器是继承关系吗？**

既然问了，那肯定就不是了，在双亲委派模型中，类加载器之间的父子关系一般不是以继承关系实现的，而是**组合**的关系来复用父加载器的代码的

#### **介绍完双亲委派的概念，那双亲委派机制有什么好处呢？**

双亲委派的保证了Java程序稳定地运行，可以**避免类地重复加载**（父类加载器加载过，子加载器不会再进行加载），**保证Java的核心API不被篡改**，例如，你自己编写了一个java.lang.Object类，也不会被加载，因为根据双亲委派机制，会由启动类加载器进行加载，会先加载位于rt.jar中的java.lang.Object类，并且其他子类加载器不会再去加载ava.lang.Object类。

#### **那双亲委派机制的弊端是什么呢？**

从上面的介绍可以看到父类加载器的优先级是大于子类加载器的，只有父类加载器无法加载，子类加载器才会去尝试加载，这在大多数情况是没有问题的，因为越上层加载的类通常是基础类（像Object类），一般情况这些基础类都是被用户代码所调用的API，但基础类要是想调用用户的代码，那就会出问题了，因为第三方的类不能被启动类加载器加载。

举个很经典的例子，JDBC服务在Java开发中非常常见（操作数据库），

```
Connection c = DriverManager.getConnection("jdbc:mysql://localhost:3306/mysql", "lurenzhang", "666");
```

DriverManager类是在java.sql包中，java.sql包的位置是jdk\jre\lib\rt.jar，也就是DriverManager类会先被启动类加载器加载，类在加载时其中有这样一段代码

```
ServiceLoader<Driver> loadedDrivers = ServiceLoader.load(Driver.class);
```

这会尝试加载classpath下面的所有实现了Driver接口的实现类，而实现了Driver接口的第三方类库应由应用类加载器加载，这样一来启动类加载器加载的类使用了启动类加载器加载的类，违背双亲委派机制的原理。

#### 如何破坏双亲委派机制

这个需要先去了解双亲委派是怎么实现的，看下**java.lang.ClassLoader的loadClass()源码**就知道了，这里就不展开写了，想破环双亲委派自定义一个类加载器，重写其中的loadClass()方法即可。

### 有哪些打破双亲委派机制的例子

- 在双亲委派出现之前，双亲委派模型是在JDK1.2引入的，在此之前就有自定义类加载器了，这些自然是没遵循双亲委派机制的
- JIDI服务及前面提到的JDBC服务，如何解决这个问题呢？Java设计团队引入了上下文类加载器，通过上下文类加载器可以使得父类加载器请求子类加载器去完成类的加载动作。
- 用户对程序动态性的追求导致的，比如代码热替换、模块热部署等，已经成为Java模块化标准的OSGi实现模块化热部署的关键是它自定义的类加载，没和程序模块都有自己的类加载器，当需要更换一个程序模块时，会把程序模块和类加载器一起替换掉实现代码的热替换
- tomcat等web服务器，因为一个web容器可以部署多个应用程序，不同的应用程序可能会依赖同一个第三方类库的不同版本，但不同版本的类库中的全限定名很可能是一样的，如果采取双亲委派机制，这里就无法加载多个相同的类，解决方法就是，破坏双亲委派原则，提供隔离的机制，为每个web容器提供一个单独的类加载器

**参考：**《深入理解Java虚拟机》