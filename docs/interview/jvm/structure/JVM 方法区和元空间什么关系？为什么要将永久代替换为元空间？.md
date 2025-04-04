# JVM 方法区和元空间什么关系？为什么要将永久代替换为元空间？

昨天，我花了很长时间完善了一下 JavaGuide 上 JVM 部分方法区的相关介绍。

![图片](https://mmbiz.qpic.cn/mmbiz_png/iaIdQfEric9Tz6TdUN8mTdS0IEpLvicYE45iau2L3gOicypcQJeJgmbh4rG69epvBKUjvh1bXwQ6UPovPls8q8D8vGw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

多提一嘴，为了完善方法区这部分内容的介绍，我看了很多文档，还特意去扒了一下《深入理解 Java 虚拟机（第 3 版）》勘误的 issues，简直看到的脑壳疼。。。

![图片](https://mmbiz.qpic.cn/mmbiz_png/iaIdQfEric9Tz6TdUN8mTdS0IEpLvicYE45I8VXRhRgibAibkRD2BlyvajAick4cUBNRgvQZKicTgANVEh9kb70BZ4SaA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

讲真，深挖下来的话细节太多，也没太大意义（卷不动了）。

这个问题在 Java 面试中还是挺常见的（通常会在面试官问你 JVM 运行时内存的时候被提到），但是，面试的时候也不会问的特别细致，我下面讲到的这些基本就够面试使用了。

我前几天看好几个群友分享的面经里面就有方法区相关的面试题。

这篇文章我就从面试的角度，通过 7 个常见的知识点/面试题来带你了解方法区：

1. 什么是方法区
2. 方法区和永久代以及元空间有什么关系？
3. 方法区常用参数有哪些？
4. 为什么要将永久代 (PermGen) 替换为元空间 (MetaSpace) 呢?
5. 什么是运行时常量池？
6. 字符串常量池有什么作用？
7. JDK 1.7 为什么要将字符串常量池移动到堆中？

下面是正文。

## 什么是方法区？

方法区属于是 JVM 运行时数据区域的一块逻辑区域，是各个线程共享的内存区域。

《Java 虚拟机规范》只是规定了有方法区这么个概念和它的作用，方法区到底要如何实现那就是虚拟机自己要考虑的事情了。也就是说，在不同的虚拟机实现上，方法区的实现是不同的。

当虚拟机要使用一个类时，它需要读取并解析 Class 文件获取相关信息，再将信息存入到方法区。方法区会存储已被虚拟机加载的 **类信息、字段信息、方法信息、常量、静态变量、即时编译器编译后的代码缓存等数据**。

## 方法区和永久代以及元空间有什么关系？

方法区和永久代以及元空间的关系很像 Java 中接口和类的关系，类实现了接口，这里的类就可以看作是永久代和元空间，接口可以看作是方法区，也就是说永久代以及元空间是 HotSpot 虚拟机对虚拟机规范中方法区的两种实现方式。

并且，永久代是 JDK 1.8 之前的方法区实现，JDK 1.8 及以后方法区的实现便成为元空间。

![图片](https://mmbiz.qpic.cn/mmbiz_png/iaIdQfEric9Tz6TdUN8mTdS0IEpLvicYE45bDhXh6B2ZVGw81QC5Tu9Niac7PiaZKrEnTKu1czmZUSTO47F4qm3rricA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

## 方法区常用参数有哪些？

JDK 1.8 之前永久代还没被彻底移除的时候通常通过下面这些参数来调节方法区大小。

```
-XX:PermSize=N //方法区 (永久代) 初始大小
-XX:MaxPermSize=N //方法区 (永久代) 最大大小,超过这个值将会抛出 OutOfMemoryError 异常:java.lang.OutOfMemoryError: PermGen
```

相对而言，垃圾收集行为在这个区域是比较少出现的，但并非数据进入方法区后就“永久存在”了。

JDK 1.8 的时候，方法区（HotSpot 的永久代）被彻底移除了（JDK1.7 就已经开始了），取而代之是元空间，元空间使用的是直接内存。下面是一些常用参数：

```
-XX:MetaspaceSize=N //设置 Metaspace 的初始（和最小大小）
-XX:MaxMetaspaceSize=N //设置 Metaspace 的最大大小
```

与永久代很大的不同就是，如果不指定大小的话，随着更多类的创建，虚拟机会耗尽所有可用的系统内存。

## 为什么要将永久代 (PermGen) 替换为元空间 (MetaSpace) 呢?

下图来自《深入理解 Java 虚拟机》第 3 版 2.2.5

![图片](https://mmbiz.qpic.cn/mmbiz_png/iaIdQfEric9Tz6TdUN8mTdS0IEpLvicYE45NsiaaEicicU9ZdhqBTdh2Q4FiaUQHvatwSGfhF0DaDC27np0SwCcPl4hVw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

1、整个永久代有一个 JVM 本身设置的固定大小上限，无法进行调整，而元空间使用的是直接内存，受本机可用内存的限制，虽然元空间仍旧可能溢出，但是比原来出现的几率会更小。

> 当元空间溢出时会得到如下错误：`java.lang.OutOfMemoryError: MetaSpace`

你可以使用 `-XX：MaxMetaspaceSize` 标志设置最大元空间大小，默认值为 unlimited，这意味着它只受系统内存的限制。`-XX：MetaspaceSize` 调整标志定义元空间的初始大小如果未指定此标志，则 Metaspace 将根据运行时的应用程序需求动态地重新调整大小。

2、元空间里面存放的是类的元数据，这样加载多少类的元数据就不由 `MaxPermSize` 控制了, 而由系统的实际可用空间来控制，这样能加载的类就更多了。

3、在 JDK8，合并 HotSpot 和 JRockit 的代码时, JRockit 从来没有一个叫永久代的东西, 合并之后就没有必要额外的设置这么一个永久代的地方了。

## 什么是运行时常量池？

Class 文件中除了有类的版本、字段、方法、接口等描述信息外，还有用于存放编译期生成的各种字面量（Literal）和符号引用（Symbolic Reference）的常量池表(Constant Pool Table)。常量池表会在类加载后存放到方法区的运行时常量池中。

字面量是源代码中的固定值的表示法，即通过字面我们就能知道其值的含义。字面量包括整数、浮点数和字符串字面量，符号引用包括类符号引用、字段符号引用、方法符号引用和接口方法符号引用。

运行时常量池的功能类似于传统编程语言的符号表，尽管它包含了比典型符号表更广泛的数据。

既然运行时常量池是方法区的一部分，自然受到方法区内存的限制，当常量池无法再申请到内存时会抛出 `OutOfMemoryError` 错误。

**JDK1.7 及之后版本的 JVM 已经将运行时常量池从方法区中移了出来，在 Java 堆（Heap）中开辟了一块区域存放运行时常量池。**

> **🐛 修正（参见：issue747，reference）** ：
>
> 1. JDK1.7 之前，运行时常量池包含的字符串常量池和静态变量存放在方法区, 此时 HotSpot 虚拟机对方法区的实现为永久代。
> 2. JDK1.7 字符串常量池和静态变量被从方法区拿到了堆中, 这里没有提到运行时常量池,也就是说字符串常量池被单独拿到堆,运行时常量池剩下的东西还在方法区, 也就是 HotSpot 中的永久代 。
> 3. JDK1.8 HotSpot 移除了永久代用元空间(Metaspace)取而代之, 这时候字符串常量池和静态变量还在堆, 运行时常量池还在方法区, 只不过方法区的实现从永久代变成了元空间(Metaspace)

## 字符串常量池有什么作用？

**字符串常量池** 是 JVM 为了提升性能和减少内存消耗针对字符串（String 类）专门开辟的一块区域，主要目的是为了避免字符串的重复创建。

```
String aa = "ab"; // 放在常量池中
String bb = "ab"; // 从常量池中查找
System.out.println(aa==bb);// true
```

JDK1.7 之前运行时常量池逻辑包含字符串常量池存放在方法区。JDK1.7 的时候，字符串常量池被从方法区拿到了堆中。

这里的字符串其实就是我们前面提到的字符串字面量。在声明一个字符串字面量时，如果字符串常量池中能够找到该字符串字面量，则直接返回该引用。如果找不到的话，则在常量池中创建该字符串字面量的对象并返回其引用。

相关问题：JVM 常量池中存储的是对象还是引用呢？- RednaxelaFX - 知乎

## JDK 1.7 为什么要将字符串常量池移动到堆中？

主要是因为永久代（方法区实现）的 GC 回收效率太低，只有在整堆收集 (Full GC)的时候才会被执行 GC。Java 程序中通常会有大量的被创建的字符串等待回收，将字符串常量池放到堆中，能够更高效及时地回收字符串内存。

## 总结

一张图片带你看看 JDK1.6 到 JDK1.8 方法区的变化。

![图片](https://mmbiz.qpic.cn/mmbiz_png/iaIdQfEric9Tz6TdUN8mTdS0IEpLvicYE45b99CuTlTtiaccA4SMhU8iam6FIod5tOWhd4korZDibBcRibkdbrhtnNwfg/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

## 参考资料



[1]issue747: *https://github.com/Snailclimb/JavaGuide/issues/747*[2]reference: *https://blog.csdn.net/q5706503/article/details/84640762*[3]JVM 常量池中存储的是对象还是引用呢？- RednaxelaFX - 知乎: *https://www.zhihu.com/question/57109429/answer/151717241*