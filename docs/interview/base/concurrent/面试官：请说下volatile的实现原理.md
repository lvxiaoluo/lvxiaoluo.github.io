# 面试官：请说下volatile的实现原理

**文章目录：**

- volatile的作用是什么？

- volatile的特性有哪些？

- Java内存的可见性问题

- 为什么代码会重排序？

- 重排序会引发什么问题？

- as-if-serial规则和happens-before规则的区别？

- volatile的实现原理？

- - volatile实现内存可见性原理
  - volatile实现有序性原理
  - 编译器对内存屏障插入策略的优化

- volatile能使一个非原子操作变成一个原子操作吗？

- volatile、synchronized的区别？

推荐阅读：

- [面试官：请详细说下synchronized的实现原理](http://mp.weixin.qq.com/s?__biz=MzA4NjU1MzA2MQ==&mid=2647724827&idx=1&sn=47342db708c6dbaee0681bea71874c8c&chksm=87e34b91b094c2878c4fdf91222ffacf6b2feb341f4118d204c1b2fb0889b3cdc0d77cccd71e&scene=21#wechat_redirect)
- [Java八股文](http://mp.weixin.qq.com/s?__biz=MzA4NjU1MzA2MQ==&mid=2647724779&idx=1&sn=b46860b8f43d8d31712f987241f6df22&chksm=87e34a61b094c37745afed3b87c0ed382791ab494be35394ee5895c1f017ca29eeb58ebda994&scene=21#wechat_redirect)
- [面试官：请用五种方法来实现多线程交替打印问题](http://mp.weixin.qq.com/s?__biz=MzA4NjU1MzA2MQ==&mid=2647724685&idx=1&sn=0c4d54e897753b6ff2b67c4e214c28ba&chksm=87e34a07b094c311e5ed6d1d791d5d8e30ecd6c0975dbcdb1dfeab24b7c24614e6f6c119e365&scene=21#wechat_redirect)
- [并发编程高频面试题第一弹](http://mp.weixin.qq.com/s?__biz=MzA4NjU1MzA2MQ==&mid=2647724650&idx=1&sn=361a6102991e5123a5a94727143aaca3&chksm=87e34ae0b094c3f6ec01c245b38312163af096c2b019e1dd89961279980655f49eb890bb9307&scene=21#wechat_redirect)
- [技术岗面试中的一些常见问题](http://mp.weixin.qq.com/s?__biz=MzA4NjU1MzA2MQ==&mid=2647724575&idx=1&sn=1cb6f9974485a4fee9faaf6f12612132&chksm=87e34a95b094c383b055b18360f75df627aa2d8fa19678b2ae5386134af641ec5c2c06a49378&scene=21#wechat_redirect)

## volatile的作用是什么？

`volatile`是一个轻量级的`synchronized`，一般作用于**变量**，在多处理器开发的过程中保证了内存的可见性。相比于`synchronized`关键字，`volatile`关键字的执行成本更低，效率更高。

## volatile的特性有哪些？

> 并发编程的三大特性为可见性、有序性和原子性。通常来讲`volatile`可以保证可见性和有序性。

- 可见性：`volatile`可以保证不同线程对共享变量进行操作时的可见性。即当一个线程修改了共享变量时，另一个线程可以读取到共享变量被修改后的值。
- 有序性：`volatile`会通过禁止指令重排序进而保证有序性。
- 原子性：对于单个的`volatile`修饰的变量的读写是可以保证原子性的，但对于`i++`这种复合操作并不能保证原子性。这句话的意思基本上就是说`volatile`不具备原子性了。

## Java内存的可见性问题

Java的内存模型如下图所示。

![图片](https://mmbiz.qpic.cn/mmbiz_png/cBnxLn7axryO9PjY6xSoRe9DktPf9OnDicwjJDHWKkNFBs3Gnvibe6G0kQlkO6DfOrYuhaNEgSUhXO3attcnDdpw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

这里的本地内存并不是真实存在的，只是Java内存模型的一个抽象概念，它包含了控制器、运算器、缓存等。同时Java内存模型规定，线程对共享变量的操作必须在自己的本地内存中进行，不能直接在主内存中操作共享变量。这种内存模型会出现什么问题呢？，

1. 线程A获取到共享变量X的值，此时本地内存A中没有X的值，所以加载主内存中的X值并缓存到本地内存A中，线程A修改X的值为1，并将X的值刷新到主内存中，这时主内存及本地内存A中的X的值都为1。
2. 线程B需要获取共享变量X的值，此时本地内存B中没有X的值，加载主内存中的X值并缓存到本地内存B中，此时X的值为1。线程B修改X的值为2，并刷新到主内存中，此时主内存及本地内存B中的X值为2，本地内存A中的X值为1。
3. 线程A再次获取共享变量X的值，此时本地内存中存在X的值，所以直接从本地内存中A获取到了X为1的值，但此时主内存中X的值为2，到此出现了所谓内存不可见的问题。

该问题Java内存模型是通过`synchronized`关键字和`volatile`关键字就可以解决。

## 为什么代码会重排序？

计算机在执行程序的过程中，编译器和处理器通常会对指令进行重排序，这样做的目的是为了提高性能。具体可以看下面这个例子。

```
int a = 1;
int b = 2;
int a1 = a;
int b1 = b;
int a2 = a + a;
int b2 = b + b;
......
```

像这段代码，不断地交替读取a和b，会导致寄存器频繁交替存储a和b，使得代码性能下降，可对其进入如下重排序。

```
int a = 1;
int b = 2;
int a1 = a;
int a2 = a + a;
int b1 = b;
int b2 = b + b;
......
```

按照这样的顺序执行代码便可以避免交替读取a和b，这就是重排序的意义。

指令重排序一般分为编译器优化重排、指令并行重排和内存系统重排三种。

- 编译器优化重排：编译器在不改变单线程程序语义的情况下，可以对语句的执行顺序进行重新排序。
- 指令并行重排：现代处理器多采用指令级并行技术来将多条指令重叠执行。对于不存在**数据依赖**的程序，处理器可以对机器指令的执行顺序进行重新排列。
- 内存系统重排：因为处理器使用缓存和读/写缓冲区，使得加载（load）和存储（store）看上去像是在乱序执行。

注：简单解释下数据依赖性：如果两个操作访问了同一个变量，并且这两个操作有一个是写操作，这两个操作之间就会存在数据依赖性，例如：

```
a = 1;
b = a;
```

如果对这两个操作的执行顺序进行重排序的话，那么结果就会出现问题。

> 其实，这三种指令重排说明了一个问题，就是指令重排在单线程下可以提高代码的性能，但在多线程下可以会出现一些问题。

## 重排序会引发什么问题？

前面已经说过了，在单线程程序中，重排序并不会影响程序的运行结果，而在多线程场景下就不一定了。可以看下面这个经典的例子，该示例出自《Java并发编程的艺术》。

```
class ReorderExample{
    int a = 0;
    boolean flag = false;
    public void writer(){
        a = 1;              // 操作1
        flag = true;        // 操作2
    }
    public void reader(){
        if(flag){          // 操作3
            int i = a + a; // 操作4
        }
    }
}
```

假设线程1先执行`writer()`方法，随后线程2执行`reader()`方法，最后程序一定会得到正确的结果吗？

答案是不一定的，如果代码按照下图的执行顺序执行代码则会出现问题。

![图片](https://mmbiz.qpic.cn/mmbiz_png/cBnxLn7axryO9PjY6xSoRe9DktPf9OnD36z1Qic2VD7ic3mw1eOmUzQmWyZKUQn66hOOwlB9CQvcX2xDvB1tDfHQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

操作1和操作2进行了重排序，线程1先执行`flag=true`，然后线程2执行操作3和操作4，线程2执行操作4时不能正确读取到`a`的值，导致最终程序运行结果出问题。这也说明了在多线程代码中，重排序会破坏多线程程序的语义。

## as-if-serial规则和happens-before规则的区别？

区别：

- as-if-serial定义：无论编译器和处理器如何进行重排序，单线程程序的执行结果不会改变。
- happens-before定义：一个操作happens-before另一个操作，表示第一个的操作结果对第二个操作可见，并且第一个操作的执行顺序也在第二个操作之前。但这并不意味着Java虚拟机必须按照这个顺序来执行程序。如果重排序的后的执行结果与按happens-before关系执行的结果一致，Java虚拟机也会允许重排序的发生。
- happens-before关系保证了同步的多线程程序的执行结果不被改变，as-if-serial保证了单线程内程序的执行结果不被改变。

相同点：happens-before和as-if-serial的作用都是在不改变程序执行结果的前提下，提高程序执行的并行度。

## volatile的实现原理？

> 前面已经讲述`volatile`具备可见性和有序性两大特性，所以`volatile`的实现原理也是围绕如何实现可见性和有序性展开的。

### volatile实现内存可见性原理

> 导致内存不可见的主要原因就是Java内存模型中的本地内存和主内存之间的值不一致所导致，例如上面所说线程A访问自己本地内存A的X值时，但此时主内存的X值已经被线程B所修改，所以线程A所访问到的值是一个脏数据。那如何解决这种问题呢？

`volatile`可以保证内存可见性的关键是`volatile`的读/写实现了缓存一致性，缓存一致性的主要内容为：

- 每个处理器会通过嗅探总线上的数据来查看自己的数据是否过期，一旦处理器发现自己缓存对应的内存地址被修改，就会将当前处理器的缓存设为无效状态。此时，如果处理器需要获取这个数据需重新从主内存将其读取到本地内存。
- 当处理器写数据时，如果发现操作的是共享变量，会通知其他处理器将该变量的缓存设为无效状态。

那缓存一致性是如何实现的呢？可以发现通过`volatile`修饰的变量，生成汇编指令时会比普通的变量多出一个Lock指令，这个Lock指令就是`volatile`关键字可以保证内存可见性的关键，它主要有两个作用：

- 将当前处理器缓存的数据刷新到主内存。
- 刷新到主内存时会使得其他处理器缓存的该内存地址的数据无效。

### volatile实现有序性原理

> 前面提到重排序可以提高代码的执行效率，但在多线程程序中可以导致程序的运行结果不正确，那`volatile`是如何解决这一问题的呢？

为了实现`volatile`的内存语义，编译器在生成字节码时会通过插入内存屏障来禁止指令重排序。

内存屏障：内存屏障是一种CPU指令，它的作用是对该指令前和指令后的一些操作产生一定的约束，保证一些操作按顺序执行。

#### Java虚拟机插入内存屏障的策略

Java内存模型把内存屏障分为4类，如下表所示：

|      屏障类型       |         指令示例         |                             说明                             |
| :-----------------: | :----------------------: | :----------------------------------------------------------: |
|  LoadLoad Barriers  |   Load1;LoadLoad;Load2   |     保证Load1数据的读取先于Load2及后续所有读取指令的执行     |
| StoreStore Barriers | Store1;StoreStore;Store2 |    保证Store1数据刷新到主内存先于Store2及后续所有存储指令    |
| LoadStore Barriers  |  Load1;LoadStore;Store2  | 保证Load1数据的读取先于Store2及后续的所有存储指令刷新到主内存 |
| StoreLoad Barriers  |  Store1;StoreLoad;Load2  | 保证Store1数据刷新到主内存先于Load2及后续所有读取指令的执行  |

注：StoreLoad Barriers同时具备其他三个屏障的作用，它会使得该屏障之前的所有内存访问指令完成之后，才会执行该屏障之后的内存访问命令。

Java内存模型对编译器指定的`volatile`重排序规则为：

- 当第一个操作是`volatile`读时，无论第二个操作是什么都不能进行重排序。
- 当第二个操作是`volatile`写时，无论第一个操作是什么都不能进行重排序。
- 当第一个操作是`volatile`写，第二个操作为`volatile`读时，不能进行重排序。

根据`volatile`重排序规则，Java内存模型采取的是保守的屏障插入策略，`volatile`写是在前面和后面分别插入内存屏障，`volatile`读是在后面插入两个内存屏障，具体如下：

- `volatile`读：在每个`volatile`读后面分别插入LoadLoad屏障及LoadStore屏障（根据volatile重排序规则第一条），如下图所示

![图片](https://mmbiz.qpic.cn/mmbiz_png/cBnxLn7axryO9PjY6xSoRe9DktPf9OnDDkJxAhMQhXPRJibs3pk4WARHwWJDGwXs3RtCiaRjXhvuKIfa8gGicCovg/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

LoadLoad屏障的作用：禁止上面的所有普通读操作和上面的`volatile`读操作进行重排序。

LoadStore屏障的作用：禁止下面的普通写和上面的`volatile`读进行重排序。

- `volatile`写：在每个`volatile`写前面插入一个StoreStore屏障（为满足`volatile`重排序规则第二条），在每个`volatile`写后面插入一个StoreLoad屏障（为满足`voaltile`重排序规则第三条），如下图所示

  ![图片](https://mmbiz.qpic.cn/mmbiz_png/cBnxLn7axryO9PjY6xSoRe9DktPf9OnDJeqHick1k2eccyc6gjD6ZMs74H23PicmcedRTrQxFwUqNrx98wDiaibR4A/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

  StoreStore屏障的作用：禁止上面的普通写和下面的`volatile`写重排序

  StoreLoad屏障的作用：防止上面的`volatile`写与下面可能出现的`volatile`读/写重排序。

### 编译器对内存屏障插入策略的优化

> 因为Java内存模型所采用的屏障插入策略比较保守，所以在实际的执行过程中，只要不改变`volatile`读/写的内存语义，编译器通常会省略一些不必要的内存屏障。

代码如下：

```
public class VolatileBarrierDemo{
    int a;
    volatile int b = 1;
    volatile int c = 2;
    
    public void test(){
        int i = b;  //volatile读
        int j = c;  //volatile读
        a = i + j;  //普通写
        
    }
}
```

指令序列示意图如下：

![图片](https://mmbiz.qpic.cn/mmbiz_png/cBnxLn7axryO9PjY6xSoRe9DktPf9OnDLM7dCAyI9EHExVIPgYGD2Eh0pvHxzZa2yfIlmE36rYNNQ3fk41WEPw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

从上图可以看出，通过指令优化一共省略了两个内存屏障（虚线表示），省略第一个内存屏障LoadStore的原因是最后的普通写不可能越过第二个`volatile`读，省略第二个内存屏障LoadLoad的原因是下面没有涉及到普通读的操作。

## volatile能使一个非原子操作变成一个原子操作吗？

`volatile`只能保证可见性和有序性，但可以保证64位的`long`型和`double`型变量的原子性。

对于32位的虚拟机来说，每次原子读写都是32位的，会将`long`和`double`型变量拆分成两个32位的操作来执行，这样`long`和`double`型变量的读写就不能保证原子性了，而通过`volatile`修饰的`long`和`double`型变量则可以保证其原子性。

## volatile、synchronized的区别？

- `volatile`主要是保证内存的可见性，即变量在寄存器中的内存是不确定的，需要从主存中读取。`synchronized`主要是解决多个线程访问资源的同步性。
- `volatile`作用于变量，`synchronized`作用于代码块或者方法。
- `volatile`仅可以保证数据的可见性，不能保证数据的原子性。`synchronized`可以保证数据的可见性和原子性。
- `volatile`不会造成线程的阻塞，`synchronized`会造成线程的阻塞。



**参考：**

- 《Java并发编程的艺术》