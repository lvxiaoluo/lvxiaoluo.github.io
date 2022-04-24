## JAVA线程池是如何保证核心线程不被销毁的

> 对于Java中 Thread 对象，同一个线程对象调用 start 方法后，会在执行完run 后走向终止（TERMINATED）状态，也就是说一个线程对象是不可以通过多次调用 start 方法重复执行 run 方法内容的。

详情可通过该链接了解：[Java同一个线程对象能否多次调用start方法](https://blog.csdn.net/smile_from_2015/article/details/105233224)

> 问题：那 Java 线程池中是如何保证核心线程不会终止的呢？

接下来将通过源码分析线程池是如何保证核心线程不被终止的，在分析前需要了解 `ThreadPoolExecutor`中几个重要成员变量和方法，便于下面源码阅读：

## THREADPOOLEXECUTOR 成员变量和方法介绍

1. ctl 原子整型变量

```java
private final AtomicInteger ctl = new AtomicInteger(ctlOf(RUNNING, 0));
1
```

- ctl 包含两个字段
  - workerCount：表示线程池中实际生效的线程数；
  - runState：表示线程池运行状态（注意和线程状态进行区分），线程池状态包括以下几种：
    - RUNNING：可以接收新任务并可执行队列中的任务；
    - SHUTDOWN：不接收新任务，但可执行队列中的任务；
    - STOP：不接收新任务，不执行队列任务并且中断正在执行的任务；
    - TIDYING：所有任务已终止，workerCount 为0，将会运行钩子方法 terminated；
    - TERMINATED：terminated 方法调用完成的状态。

1. 线程池中实际生效线程的最大容量

```java
//Integer.SIZE等于32
private static final int COUNT_BITS = Integer.SIZE - 3;
//实际有效线程的最大容量
private static final int CAPACITY   = (1 << COUNT_BITS) - 1;
1234
```

- 实际生效最大线程数为
  2^{29} - 1229−1
- 为何使用int类型是因为相对于long运行的更快一点，如果将来int不够用，可以使用AtomicLong代替。

1. 线程池运行状态

```java
// runState is stored in the high-order bits
private static final int RUNNING    = -1 << COUNT_BITS;
private static final int SHUTDOWN   =  0 << COUNT_BITS;
private static final int STOP       =  1 << COUNT_BITS;
private static final int TIDYING    =  2 << COUNT_BITS;
private static final int TERMINATED =  3 << COUNT_BITS;
123456
```

这里我们仅需要知道只有运行（RUNNING）状态是小于0的，其他状态下都是大于等于0的。
\4. 获取线程池运行状态

```java
private static int runStateOf(int c)     { return c & ~CAPACITY; }
1
```

方法入参 c 即为 ctl，通过该方法位运算可以得到线程池的状态值，并与 3 中的状态进行比较来进行逻辑处理。
\5. 获取线程池中当前实际有效的线程数量

```java
private static int workerCountOf(int c)  { return c & CAPACITY; }
1
```

同上，方法入参 c 为 ctl 原子整形变量，通过位运算得到线程池中实际的线程数 workCount。
\6. 工作线程集合

```java
private final HashSet<Worker> workers = new HashSet<Worker>();
1
```

线程池中每一个有效线程都会被包装为 Worker 对象。
\7. Worker 内部类

```java
private final class Worker extends AbstractQueuedSynchronizer implements Runnable
1
```

- 类 Worker 主要用于维护运行任务线程的中断控制状态；
- 继承 AQS 实现了一个简单的不可重入互斥锁，而不是使用可重入锁，因为不希望工作任务在调用setCorePoolSize之类的池控制方法时能够重新获取锁;
- 为了在线程真正开始运行任务之前禁止中断，将锁状态初始化为负值，并在启动时清除它（runWorker中）。

1. 其他如 corePoolSize、maximumPoolSize、threadFactory、workQueue等就不做赘述了。

## 案例分析

该案例不执行 shutdown 方法，这样可以保证线程池一直处于运行状态(RUNNING)

```java
public static void main(String[] args) {
    ThreadPoolExecutor threadPoolExecutor = new ThreadPoolExecutor(2, 2,
            0, TimeUnit.MILLISECONDS, new LinkedBlockingQueue<>(6),
            Executors.defaultThreadFactory(), new ThreadPoolExecutor.AbortPolicy());
    for (int i = 0; i < 8; i++) {
        int num = i;
        threadPoolExecutor.execute(() -> {
            String threadName = Thread.currentThread().getName();
            System.out.println(threadName + " - " + num);
            System.out.println(threadName + " 开始睡眠...");
            try {
                //暂缓线程执行
                TimeUnit.MILLISECONDS.sleep(5000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            System.out.println(threadName +" 结束睡眠...");
        });
    }

    //threadPoolExecutor.shutdown();
}
12345678910111213141516171819202122
```

跟踪 execute 方法源码，查看核心线程是如何被加添到池中的：

```java
public void execute(Runnable command) {
    if (command == null)
        throw new NullPointerException();
    //获取线程池控制状态
    int c = ctl.get();
    //通过workerCountOf计算出实际线程数
    if (workerCountOf(c) < corePoolSize) {
        //未超过核心线程数，则新增 Worker 对象，true表示核心线程
        if (addWorker(command, true))
            return;
        c = ctl.get();
    }

    //核心线程满了，如果线程池处于运行状态则往队列中添加任务
    if (isRunning(c) && workQueue.offer(command)) {
        int recheck = ctl.get();
        //双重检测池是否处于运行状态
        if (! isRunning(recheck) && remove(command))
            reject(command);
        else if (workerCountOf(recheck) == 0)
            addWorker(null, false);
    } else if (!addWorker(command, false))//添加非核心线程
        reject(command);
}
123456789101112131415161718192021222324
```

根据方法内容和断点跟踪可以得出以下结论：

1. 核心线程数未超过 corePoolSize，每添加新的任务（command），都会创建新的线程（Worker中创建），即使有空闲线程存在；
2. 核心线程数等于corePoolSize后，如果继续添加新的任务（command），会将任务添加到阻塞队列 workQueue 中，等待调度；
3. 如果添加到队列失败，则检查 corePoolSize 是否小于 maximumPoolSize，如果小于则创建新的线程执行任务，直到线程总数 等于 maximumPoolSize；
4. 当线程数等于 maximumPoolSize 并且队列已满了，后续新增任务将会触发线程饱和策略。

上面代码中我们关心 addWorker 方法，它有两个参数，第一个是 Runnable 对象，第二参数是标记是否核心线程，true为核心线程，接下来看下源码：

```java
private boolean addWorker(Runnable firstTask, boolean core) {
    retry:
    for (;;) {
        int c = ctl.get();
        // 省略部分代码
        ......
        
        for (;;) {
            //core主要用于判断是否继续创建新线程
            int wc = workerCountOf(c);
            //workCount 大于总容量或者workCount大于核心线程或最大线程将直接返回
            if (wc >= CAPACITY ||
                wc >= (core ? corePoolSize : maximumPoolSize))
                return false;
            //通过CAS将c加1，也就是将workCount加1    
            if (compareAndIncrementWorkerCount(c))
                break retry;
            c = ctl.get();  // Re-read ctl
            if (runStateOf(c) != rs)
                continue retry;
             retry inner loop
        }
    }

    boolean workerStarted = false;
    boolean workerAdded = false;
    Worker w = null;
    try {
        //创建新线程
        w = new Worker(firstTask);
        final Thread t = w.thread;
        if (t != null) {
            final ReentrantLock mainLock = this.mainLock;
            mainLock.lock();
            //省略部分代码
            ......
            workers.add(w);
            int s = workers.size();
            if (s > largestPoolSize)
                largestPoolSize = s;
            workerAdded = true;
            ......
            
            if (workerAdded) {
                //启动线程
                t.start();
                workerStarted = true;
            }
        }
    } finally {
        if (! workerStarted)
            addWorkerFailed(w);
    }
    return workerStarted;
}
12345678910111213141516171819202122232425262728293031323334353637383940414243444546474849505152535455
```

从 addWorker 方法中，可以看到从 Worker 对象中获取到线程对象 t ，并调用 start 方法启动线程，那这个 t 线程是如何来的呢？
扩展：[java retry:详解](https://www.cnblogs.com/captainad/p/10931314.html)

接下来要看下 Worker 是如何创建线程的：

```java
private final class Worker extends AbstractQueuedSynchronizer implements Runnable {
    final Thread thread;
    /**初始执行任务，有可能为空*/
    Runnable firstTask;
    
    /**使用firstTask和来自线程工厂中的线程创建了 Worker 对象*/
    Worker(Runnable firstTask) {
        setState(-1); // inhibit interrupts until runWorker
        this.firstTask = firstTask;
        this.thread = getThreadFactory().newThread(this);
    }

    /**将run方法委托给runWorker执行*/
    public void run() {
        runWorker(this);
    }
}
1234567891011121314151617
```

Worker 类实现 Runnable 接口， Worker 类的构造方法中 `this.thread = getThreadFactory().newThread(this)`比较关键，**这行代码的意思是说使用当前 Worker 对象创建了一个线程，那其实也就是说 thread 对象和 当前 Worker 对象中调用的 run 方法是一样的**。**到这一步我们可以得出上一步 addWorker 方法中的 t.start 调用的其实就是 Worker 类中的 run方法**。

那 runWorker 又是如何运行的呢？

```java
final void runWorker(Worker w) {
    Thread wt = Thread.currentThread();
    //获取要执行的任务
    Runnable task = w.firstTask;
    w.firstTask = null;
    w.unlock(); // allow interrupts
    boolean completedAbruptly = true;
    
    //轮询调用 getTask 用于获取任务
    while (task != null || (task = getTask()) != null) {
        w.lock();
        //省略部分代码
            ......
        //执行run方法
        task.run();
        //省略部分代码
            ......
    }
}
12345678910111213141516171819
```

runWorker 中使用 while 循环，不断调用 getTask 去获取新任务。

最后看下 getTask 方法做了哪些事：

```java
private Runnable getTask() {
    boolean timedOut = false; 
    //无限循环
    for (;;) {
        int c = ctl.get();
        int rs = runStateOf(c);
        // 检查队列是否为空
        if (rs >= SHUTDOWN && (rs >= STOP || workQueue.isEmpty())) {
            decrementWorkerCount();
            return null;
        }
        
        //获取运行线程数，根据allowCoreThreadTimeOut决定是否允许定时等待
        int wc = workerCountOf(c);
        boolean timed = allowCoreThreadTimeOut || wc > corePoolSize;
        //线程超时并且队列为空时通过CAS将实际运行线程数减1
        if ((wc > maximumPoolSize || (timed && timedOut))
                && (wc > 1 || workQueue.isEmpty())) {
            if (compareAndDecrementWorkerCount(c))
                return null;
            continue;
        }

        try {
            //允许超时则调用队列的poll方法定时等待
            //否则调用take获取任务
            Runnable r = timed ?
                    workQueue.poll(keepAliveTime, TimeUnit.NANOSECONDS) :
                    workQueue.take();
            //获取任务，返回结果
            if (r != null)
                return r;
            //继续循环，并且置超时标识为true
            timedOut = true;
        } catch (InterruptedException retry) {
            timedOut = false;
        }
    }
}
123456789101112131415161718192021222324252627282930313233343536373839
```

通过以上源码可以看出：

1. 在for无限循环中，通过不断的检查线程池状态和队列容量，来获取可执行任务；

2. 在

    

   ```
   Runnable r = timed ? workQueue.poll(keepAliveTime, TimeUnit.NANOSECONDS) : workQueue.take();
   ```

   代码中，分为两种情况

   - timed 为 true，允许淘汰 Worker，即实际运行的线程，则通过
     workQueue.poll的方式定时等待拉取任务，如果在指定keepAliveTime时间内获取任务则返回，如果没有任务则继续for循环并直到timed等于false；
   - timed 为 false，则会调用 workQueue.take 方法，**队列中 take 方法的含义是当队列有任务时，立即返回队首任务，没有任务时则一直阻塞当前线程，直到有新任务才返回**。

下面简单画了一下核心线程的序列图：
![核心线程序列图](https://www.freesion.com/images/659/09fb052d7a55ab20babba72703a4e743.png)

> 1.客户端创建线程池对象后，调用execute方法提交一个Runnable任务

> 2.execute方法内会调用addWorker方法创建一个worker对象        

> 3.addWorker方法内会调用Worker.thread.start方法，这时候实际调用的是Worker对象的run方法

> 4.Worker中的run方法委托给runWorker方法执行

> 5.runWorker方法中有while循环体，不断的调用getTask获取新任务
 
> 6.getTask方法中通过blockQueue的take方法来获取队列的线程，如果队列为空，则一直阻塞当前线程

> **因此，线程池是通过队列的take方法来阻塞核心线程Worker的run方法，保证核心线程不会因执行完run方法而被系统终止**

## 结论

线程池当未调用 shutdown 方法时，是通过队列的 take 方法阻塞核心线程（Worker）的 run 方法从而保证核心线程不被销毁的。