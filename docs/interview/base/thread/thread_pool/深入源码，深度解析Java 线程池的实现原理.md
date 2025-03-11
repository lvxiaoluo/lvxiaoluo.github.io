# [深入源码，深度解析Java 线程池的实现原理](https://www.hollischuang.com/archives/6338)



java 系统的运行归根到底是**程序**的运行，程序的运行归根到底是代码的执行，代码的执行归根到底是虚拟机的执行，虚拟机的执行其实就是操作系统的线程在执行，并且会占用一定的系统资源，如CPU、内存、磁盘、网络等等。所以，**如何高效的使用这些资源就是程序员在平时写代码时候的一个努力的方向**。本文要说的**线程池**就是一种对 **CPU** 利用的优化手段。

线程池，百度百科是这么解释的：

> 线程池是一种多线程处理形式，处理过程中将任务添加到队列，然后在创建线程后自动启动这些任务。线程池线程都是后台线程。每个线程都使用默认的堆栈大小，以默认的优先级运行，并处于多线程单元中。如果某个线程在托管代码中空闲（如正在等待某个事件）,则线程池将插入另一个辅助线程来使所有处理器保持繁忙。如果所有线程池线程都始终保持繁忙，但队列中包含挂起的工作，则线程池将在一段时间后创建另一个辅助线程但线程的数目永远不会超过最大值。超过最大值的线程可以排队，但他们要等到其他线程完成后才启动。

线程池，其实就是维护了很多线程的池子，类似这样的技术还有很多的，例如：HttpClient 连接池、数据库连接池、内存池等等。

## 线程池的优点

在 Java 并发编程框架中的线程池是运用场景最多的技术，几乎所有需要异步或并发执行任务的程序都可以使用线程池。在开发过程中，合理地使用线程池能够带来至少以下4个好处。

第一：**降低资源消耗**。通过重复利用已创建的线程降低线程创建和销毁造成的消耗；

第二：**提高响应速度**。当任务到达时，任务可以不需要等到线程创建就能立即执行；

第三：**提高线程的可管理性**。线程是稀缺资源，如果无限制地创建，不仅会消耗系统资源，还会降低系统的稳定性，使用线程池可以进行统一分配、调优和监控。

第四：**提供更强大的功能，比如延时定时线程池；**

## 线程池的实现原理

当向线程池提交一个任务之后，线程池是如何处理这个任务的呢？下面就先来看一下它的主要处理流程。先来看下面的这张图，然后我们一步一步的来解释。

![image-20210322132334799](https://blogs-1302490380.cos.ap-nanjing.myqcloud.com/20210322132334.png)

当使用者将一个任务提交到线程池以后，线程池是这么执行的：

①首先判断**核心的线程数**是否已满，如果没有满，那么就去创建一个线程去执行该任务；否则请看下一步

②如果线程池的核心线程数已满，那么就继续判断**任务队列**是否已满，如果没满，那么就将任务放到任务队列中；否则请看下一步

③如果任务队列已满，那么就判断**线程池是否已满**，如果没满，那么就创建线程去执行该任务；否则请看下一步；

④如果线程池已满，那么就根据**拒绝策略**来做出相应的处理；

上面的四步其实就已经将线程池的执行原理描述结束了。如果不明白没有关系，先一步一步往下看，上面涉及到的线程池的专有名词都会详细的介绍到。

我们在平时的开发中，线程池的使用基本都是基于`ThreadPoolExexutor`类，他的继承体系是这样子的：

![image-20210322133058425](https://blogs-1302490380.cos.ap-nanjing.myqcloud.com/20210322133058.png)

那既然说在使用中都是基于`ThreadPoolExecutor`的那么我们就重点分析这个类。

至于他构造体系中的其他的类或者是接口中的属性，这里就不去截图了，完全没有必要。小伙伴如果实在想看就自己去打开代码看一下就行了。

## ThreadPoolExecutor

在《阿里巴巴 java 开发手册》中指出了线程资源必须通过线程池提供，不允许在应用中自行显示的创建线程，这样一方面是线程的创建更加规范，可以合理控制开辟线程的数量；另一方面线程的细节管理交给线程池处理，优化了资源的开销。

其原文描述如下：

![img](https://www.hollischuang.com/wp-content/uploads/2021/05/Jietu20210525-235930-300x39.jpg)

在`ThreadPoolExecutor`类中提供了四个构造方法，但是他的四个构造器中，实际上最终都会调用同一个构造器，只不过是在另外三个构造器中，如果有些参数不传`ThreadPoolExecutor`会帮你使用默认的参数。所以，我们直接来看这个完整参数的构造器，来彻底剖析里面的参数。

```
public  class  ThreadPoolExecutor  extends  AbstractExecutorService {
    ......

    public ThreadPoolExecutor(int corePoolSize, int maximumPoolSize,long keepAliveTime,TimeUnit unit,
                                  BlockingQueue<Runnable> workQueue,ThreadFactory threadFactory,
                                  RejectedExecutionHandler handler) {
            if (corePoolSize < 0 || maximumPoolSize <= 0 || maximumPoolSize < corePoolSize || keepAliveTime < 0){
                throw new IllegalArgumentException();
            }
            if (workQueue == null || threadFactory == null || handler == null){
                throw new NullPointerException();
            }
            this.acc = System.getSecurityManager() == null ? null : AccessController.getContext();
            this.corePoolSize = corePoolSize;
            this.maximumPoolSize = maximumPoolSize;
            this.workQueue = workQueue;
            this.keepAliveTime = unit.toNanos(keepAliveTime);
            this.threadFactory = threadFactory;
            this.handler = handler;
        }
}
```

主要参数就是下面这几个：

- corePoolSize：线程池中的核心线程数，包括空闲线程，也就是核心线程数的大小；
- maximumPoolSize：线程池中允许的最多的线程数，也就是说线程池中的线程数是不可能超过该值的；
- keepAliveTime：当线程池中的线程数大于 corePoolSize 的时候，在超过指定的时间之后就会将多出 corePoolSize 的的空闲的线程从线程池中删除；
- unit：keepAliveTime 参数的单位（常用的秒为单位）；
- workQueue：用于保存任务的队列，此队列仅保持由 executor 方法提交的任务 Runnable 任务；
- threadFactory：线程池工厂，他主要是为了给线程起一个标识。也就是为线程起一个具有意义的名称；
- handler：拒绝策略

### 阻塞队列

workQueue 有多种选择，在 JDK 中一共提供了 7 中阻塞对列，分别为：

1. ArrayBlockingQueue ： 一个由数组结构组成的有界阻塞队列。 此队列按照先进先出（FIFO）的原则对元素进行排序。默认情况下不保证访问者公平地访问队列 ，所谓公平访问队列是指阻塞的线程，可按照阻塞的先后顺序访问队列。非公平性是对先等待的线程是不公平的，当队列可用时，阻塞的线程都可以竞争访问队列的资格。
2. LinkedBlockingQueue ： 一个由链表结构组成的有界阻塞队列。 此队列的默认和最大长度为Integer.MAX_VALUE。 此队列按照先进先出的原则对元素进行排序。
3. PriorityBlockingQueue ： 一个支持优先级排序的无界阻塞队列。 （虽然此队列逻辑上是无界的，但是资源被耗尽时试图执行 add 操作也将失败，导致 OutOfMemoryError）
4. DelayQueue： 一个使用优先级队列实现的无界阻塞队列。 元素的一个无界阻塞队列，只有在延迟期满时才能从中提取元素
5. SynchronousQueue： 一个不存储元素的阻塞队列。 一种阻塞队列，其中每个插入操作必须等待另一个线程的对应移除操作 ，反之亦然。（SynchronousQueue 该队列不保存元素）
6. LinkedTransferQueue： 一个由链表结构组成的无界阻塞队列。 相对于其他阻塞队列LinkedTransferQueue多了tryTransfer和transfer方法。
7. LinkedBlockingDeque： 一个由链表结构组成的双向阻塞队列。 是一个由链表结构组成的双向阻塞队列

在以上的7个队列中，线程池中常用的是`ArrayBlockingQueue、LinkedBlockingQueue、SynchronousQueue`，

队列中的常用的方法如下：

|         类型         |  方法   |          含义          |                    特点                     |
| :------------------: | :-----: | :--------------------: | :-----------------------------------------: |
|        抛异常        |   add   |      添加一个元素      | 如果队列满，抛出异常 IllegalStateException  |
|        抛异常        | remove  | 返回并删除队列的头节点 | 如果队列空，抛出异常 NoSuchElementException |
|        抛异常        | element |     返回队列头节点     | 如果队列空，抛出异常 NoSuchElementException |
| 不抛异常，但是不阻塞 |  offer  |      添加一个元素      |  添加成功，返回 true，添加失败，返回 false  |
| 不抛异常，但是不阻塞 |  poll   | 返回并删除队列的头节点 |            如果队列空，返回 null            |
| 不抛异常，但是不阻塞 |  peek   |     返回队列头节点     |            如果队列空，返回 null            |
|         阻塞         |   put   |      添加一个元素      |              如果队列满，阻塞               |
|         阻塞         |  take   | 返回并删除队列的头节点 |              如果队列空，阻塞               |

关于阻塞队列，介绍到这里也就基本差不多了。

### 线程池工厂

线程池工厂，就像上面已经介绍的，目的是为了给线程起一个有意义的名字。用起来也非常的简单，只需要实现`ThreadFactory`接口即可

```
public class CustomThreadFactory implements ThreadFactory {
    @Override
    public Thread newThread(Runnable r) {
        Thread thread = new Thread(r);
        thread.setName("我是你们自己定义的线程名称");
        return thread;
    }
}
```

具体的使用就不去废话了。

### 拒绝策略

线程池有四种默认的拒绝策略，分别为：

1. AbortPolicy：这是线程池默认的拒绝策略，在任务不能再提交的时候，抛出异常，及时反馈程序运行状态。如果是比较关键的业务，推荐使用此拒绝策略，这样子在系统不能承载更大的并发量的时候，能够及时的通过异常发现；
2. DiscardPolicy：丢弃任务，但是不抛出异常。如果线程队列已满，则后续提交的任务都会被丢弃，且是静默丢弃。这玩意不建议使用；
3. DiscardOldestPolicy：丢弃队列最前面的任务，然后重新提交被拒绝的任务。这玩意不建议使用；
4. CallerRunsPolicy：如果任务添加失败，那么主线程就会自己调用执行器中的 executor 方法来执行该任务。这玩意不建议使用；

也就是说关于线程池的拒绝策略，最好使用默认的。这样能够及时发现异常。如果上面的都不能满足你的需求，你也可以自定义拒绝策略，只需要实现 `RejectedExecutionHandler` 接口即可

```
public class CustomRejection implements RejectedExecutionHandler {
    @Override
    public void rejectedExecution(Runnable r, ThreadPoolExecutor executor) {
        System.out.println("你自己想怎么处理就怎么处理");
    }
}
```

看到这里，我们再来画一张图来总结和概括下线程池的执行示意图：

![image-20210322145600064](https://blogs-1302490380.cos.ap-nanjing.myqcloud.com/20210322145600.png)

详细的执行过程全部在图中说明了。

## 提交任务到线程池

在 java 中，有两个方法可以将任务提交到线程池，分别是`submit`和`execute`。

### execute 方法

execute()方法用于提交不需要返回值的任务，所以无法判断任务是否被线程池执行成功。

```
void execute(Runnable command);
```

通过以下代码可知 execute() 方法输入的任务是一个Runnable类的实例。

```
executorService.execute(()->{
            System.out.println("ThreadPoolDemo.execute");
        });
```

### submit 方法

submit()方法用于提交需要返回值的任务。

```
Future<?> submit(Runnable task);
```

线程池会返回一个future类型的对象，通过这个 future 对象可以判断任务是否执行成功，并且可以通过future的get()方法来获取返回值，get() 方法会阻塞当前线程直到任务完成，而使用get（long timeout，TimeUnit unit）方法则会阻塞当前线程一段时间后立即返回，这时候有可能任务没有执行完。

```
Future<?> submit = executorService.submit(() -> {
            System.out.println("ThreadPoolDemo.submit");
        });
```

## 关闭线程池

其实，如果优雅的关闭线程池是一个令人头疼的问题，线程开启是简单的，但是想要停止却不是那么容易的。通常而言， 大部分程序员都是使用 jdk 提供的两个方法来关闭线程池，他们分别是：`shutdown` 或 `shutdownNow`；

通过调用线程池的 `shutdown` 或 `shutdownNow` 方法来关闭线程池。它们的原理是遍历线程池中的工作线程，然后逐个调用线程的 interrupt 方法来中断线程（PS：**中断，仅仅是给线程打上一个标记，并不是代表这个线程停止了，如果线程不响应中断，那么这个标记将毫无作用**），所以无法响应中断的任务可能永远无法终止。

但是它们存在一定的区别，`shutdownNow`首先将线程池的状态设置成 STOP，然后尝试停止所有的正在执行或暂停任务的线程，并返回等待执行任务的列表，而 `shutdown` 只是将线程池的状态设置成`SHUTDOWN`状态，然后中断所有没有正在执行任务的线程。

只要调用了这两个关闭方法中的任意一个，`isShutdown` 方法就会返回 true。当所有的任务都已关闭后，才表示线程池关闭成功，这时调用`isTerminaed`方法会返回 true。至于应该调用哪一种方法来关闭线程池，应该由提交到线程池的任务特性决定，通常调用 `shutdown`方法来关闭线程池，如果任务不一定要执行完，则可以调用 `shutdownNow` 方法。

这里推荐使用稳妥的 `shutdownNow` 来关闭线程池，至于更优雅的方式我会在以后的**并发编程设计模式中的两阶段终止模式中**会再次详细介绍。

## 合理的参数

为什么叫合理的参数，那不合理的参数是什么样子的？在我们创建线程池的时候，里面的参数该如何设置才能称之为合理呢？其实这是有一定的依据的，我们先来看一下以下的创建的方式：

```
ExecutorService executorService = new ThreadPoolExecutor(5,
                5,
                5,
                TimeUnit.SECONDS,
                new ArrayBlockingQueue<>(5),
                r -> {
                    Thread thread = new Thread(r);
                    thread.setName("线程池原理讲解");
                    return thread;
                });
```

你说他合理不合理？我也不知道，因为我们没有参考的依据，在实际的开发中，我们需要根据任务的性质（IO是否频繁？）来决定我们创建的核心的线程数的大小，实际上可以从以下的一个角度来分析：

- 任务的性质：CPU密集型任务、IO密集型任务和混合型任务；
- 任务的优先级：高、中和低；
- 任务的执行时间：长、中和短；
- 任务的依赖性：是否依赖其他系统资源，如数据库连接；

性质不同的任务可以用不同规模的线程池分开处理。**分为CPU密集型和IO密集型**。

**CPU密集型任务**应配置尽可能小的线程，如配置 `Ncpu+1`个线程的线程池。(可以通过`Runtime.getRuntime().availableProcessors()`来获取CPU物理核数)

**IO密集型任务**线程并不是一直在执行任务，则应配置尽可能多的线程，如 `2*Ncpu`。

混合型的任务，如果可以拆分，将其拆分成一个**CPU密集型任务一个IO密集型任务**，只要这两个任务执行的时间相差不是太大，那么分解后执行的吞吐量将高于串行执行的吞吐量。

如果这两个任务执行时间相差太大，则没必要进行分解。可以通过 `Runtime.getRuntime().availableProcessors()` 方法获得当前设备的CPU个数。

优先级不同的任务可以使用优先级队列 `PriorityBlockingQueue`来处理。它可以让优先级高的任务先执行（注意：**如果一直有优先级高的任务提交到队列里，那么优先级低的任务可能永远不能执行**）

执行时间不同的任务可以交给不同规模的线程池来处理，或者可以使用优先级队列，让执行时间短的任务先执行。依赖数据库连接池的任务，因为线程提交SQL后需要等待数据库返回结果，等待的时间越长，则 CPU 空闲时间就越长，那么线程数应该设置得越大，这样才能更好地利用CPU。

建议使用有界队列。有界队列能增加系统的稳定性和预警能力，可以根据需要设大一点。方式因为提交的任务过多而导致 OOM；

## 7、本文小结

本文主要介绍的是线程池的实现原理以及一些使用技巧，在实际开发中，线程池可以说是稍微高级一点的程序员的必备技能。所以掌握好线程池这门技术也是重中之重！

**(全文完)**