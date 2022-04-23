## JDK 线程池如何保证核心线程不被销毁

## 前言

很早之前那个时候练习线程池, 就是感觉线程池类似于 ArrayList 这种集合类结构, 将 Thread 类存储, 来任务了就进行消费, 然鹅…

## 线程包装类

线程池并不是对 Thread 直接存储, 而是对 Thread 进行了一层包装, 包装类叫做 Worker

线程在线程池中的存储结构如下:

```java
private final HashSet<Worker> workers = new HashSet<Worker>();
1
```

先看一下 Worker 类中的变量及方法

```java
private final class Worker
        extends AbstractQueuedSynchronizer
        implements Runnable {

    /**
     * 此线程为线程池中的工作线程
     */
    final Thread thread;

    /**
     * 指定线程运行的第一项任务
     * 第一项任务没有则为空
     */
    Worker(Runnable firstTask) {
        ...
        this.firstTask = firstTask;
        this.thread = getThreadFactory().newThread(this);
    }

    /**
     * 运行传入的 Runnable 任务
     */
    @Override
    public void run() {
        runWorker(this);
    }
}
123456789101112131415161718192021222324252627
```

通过 Worker 的构造方法和重写的 run 得知:

> **线程池提交的任务, 会由 Worker 中的 thread 进行执行调用**

## ADDWORKER

这里还是要先放一下线程池的执行流程代码, 具体流程如下:

```java
public void execute(Runnable command) {
    ...
    int c = ctl.get();
    if (workerCountOf(c) < corePoolSize) {
      	// 🌟【重点】关注方法
        if (addWorker(command, true))
            return;
        c = ctl.get();
    }
    if (isRunning(c) && workQueue.offer(command)) {
        int recheck = ctl.get();
        if (!isRunning(recheck) && remove(command))
            reject(command);
        else if (workerCountOf(recheck) == 0)
            addWorker(null, false);
    } else if (!addWorker(command, false))
        reject(command);
}
123456789101112131415161718
```

我们具体看一下 **ThreadPoolExecutor#addWorker**

> 和大纲没关系的代码和知识点不作讲解

```java
private boolean addWorker(Runnable firstTask, boolean core) {
    ...
    // worker运行标识
    boolean workerStarted = false;  
  	// worker添加标识
    boolean workerAdded = false;  
    Worker w = null;
    try {
      	// 调用Worker构造方法
        w = new Worker(firstTask);
      	// 获取Worker中工作线程
        final Thread t = w.thread;
        if (t != null) {
            final ReentrantLock mainLock = this.mainLock;
            mainLock.lock();
            try {
                int rs = runStateOf(ctl.get());

                if (rs < SHUTDOWN ||
                        (rs == SHUTDOWN && firstTask == null)) {
                    if (t.isAlive())
                        throw new IllegalThreadStateException();
                  	// 如无异常, 将w添加至workers
                    workers.add(w);
                    int s = workers.size();
                    if (s > largestPoolSize)
                      	// 更新池内最大线程
                        largestPoolSize = s;
                    workerAdded = true;
                }
            } finally {
                mainLock.unlock();
            }

            if (workerAdded) {
              	// 启动Woker中thread工作线程
                t.start();
              	// 设置启动成功标识成功
                workerStarted = true;
            }
        }
    } finally {
      	// 如果启动失败抛出异常终止, 将Worker从workers中移除
        if (!workerStarted)
            addWorkerFailed(w);
    }
    return workerStarted;
}
123456789101112131415161718192021222324252627282930313233343536373839404142434445464748
```

这里需要着重关心下 **t.start()**, t 是我们 Worker 中的工作线程

上文说到 Worker 实现了 Runnable 接口, 并重写了 run 方法, 所以 t.start()

**最终还是会调用 Worker 中的 run()**

```java
@Override
public void run() {
    runWorker(this);
}
1234
```

## RUNWORKER

**ThreadPoolExecutor#runWorker** 是具体执行线程池提交任务的方法, 大致思路如下：

1、获取 Worker 中的第一个任务

2、如果第一个任务不为空则执行具体流程

3、第一个任务为空则从阻塞队列中获取任务, 这一点也是核心线程不被回收的关键

runWorker() 中有两个扩展方法, **beforeExecute、afterExecute**, 在任务执行前后输出一些重要信息, 可用作与监控等…

```java
final void runWorker(Worker w) {
    Thread wt = Thread.currentThread();
    Runnable task = w.firstTask;
    w.firstTask = null;
    w.unlock(); // allow interrupts
    boolean completedAbruptly = true;
    try {
      	// 🌟【重点】getTask() 是核心线程不被回收的精髓
        while (task != null || (task = getTask()) != null) {
            w.lock();
            ...
            try {
                beforeExecute(wt, task);
                Throwable thrown = null;
                try {
                    task.run();
                } ...
                } finally {
                    afterExecute(task, thrown);
                }
            } finally {
          			// 🌟【重点】执行完任务后, 将Task置空
                task = null;
                w.completedTasks++;
                w.unlock();
            }
        }
        completedAbruptly = false;
    } finally {
  			// 退出Worker
        processWorkerExit(w, completedAbruptly);
    }
}
123456789101112131415161718192021222324252627282930313233
```

关键关注下 while 循环, 内部会在执行完流程后将 task 设置为空, 这样就会跳出循环

可以看到 **processWorkerExit** 是在 finally 语句块中, 相当于 **获取不到阻塞队列任务就会去关闭 Worker**

线程池是如何保证核心线程获取不到任务时不被销毁呢？

我们继续看一下 getTask() 中是如何获取任务

## GETTASK

**ThreadPoolExecutor#getTask** 只做了一件事情, 就是从线程池的阻塞队列中获取任务返回

```java
private Runnable getTask() {
    boolean timedOut = false; // Did the last poll() time out?

    for (; ; ) {
        int c = ctl.get();
        int rs = runStateOf(c);

        // Check if queue empty only if necessary.
        if (rs >= SHUTDOWN && (rs >= STOP || workQueue.isEmpty())) {
            decrementWorkerCount();
            return null;
        }

        int wc = workerCountOf(c);

        boolean timed = allowCoreThreadTimeOut || wc > corePoolSize;

        if ((wc > maximumPoolSize || (timed && timedOut))
                && (wc > 1 || workQueue.isEmpty())) {
            if (compareAndDecrementWorkerCount(c))
                return null;
            continue;
        }

        try {
            Runnable r = timed ?
                    workQueue.poll(keepAliveTime, TimeUnit.NANOSECONDS) :
                    workQueue.take();
            if (r != null)
                return r;
            timedOut = true;
        } catch (InterruptedException retry) {
            timedOut = false;
        }
    }
}
123456789101112131415161718192021222324252627282930313233343536
```

### TIMED

重点代码从上面截出来, 首先是判断是否需要获取阻塞队列任务时在规定时间返回

```java
/**
 * 【重点】判断线程是否超时, 这里会针对两种情况判断
 * 1. 设置allowCoreThreadTimeOut参数默认false
 *    如果为true表示核心线程也会进行超时回收
 * 2. 判断当前线程池的数量是否大于核心线程数
 * 
 * 这里参与了或运算符, 只要其中一个判断符合即为True
 */
boolean timed = allowCoreThreadTimeOut || wc > corePoolSize;
123456789
```

根据 timed 属性, 判断获取阻塞队列中任务的方式

```java
/**
 * 【重点】根据timed判断两种不同方式的任务获取
 * 1. 如果为True, 表示线程会根据规定时间调用阻塞队列任务
 * 2. 如果为False, 表示线程会进行阻塞调用
 */
Runnable r = timed ? 
		workQueue.poll(keepAliveTime, TimeUnit.NANOSECONDS) : 
		workQueue.take();
12345678
```

这里就比较清楚了, 如果 timed 为 True, 线程经过 **非核心线程过期时间后还没有获取到任务**, 则方法结束, 后续会将 Worker 进行回收

如果没有设置 allowCoreThreadTimeOut 为 True, 以及当前线程池内线程数量不大于核心线程

那么从阻塞队列获取的话是 take(), take() 会 **一直阻塞, 等待任务的添加返回**

这样也就间接达到了核心线程数不会被回收的效果

![getTask流程](https://www.freesion.com/images/654/92662d752a271ddf678dad26d7774f76.png)

> 图片本来是要放上面的, 但是画的实在有点不忍直视 🙃️

## 核心线程与非核心线程区别

核心线程只是一个叫法, 核心线程与非核心线程的区别是:

**创建核心线程时会携带一个任务, 而非核心线程没有**

如果核心线程执行完第一个任务, 线程池内线程无区别

**线程池是期望达到 corePoolSize 的并发状态**, 不关心最先添加到线程池的核心线程是否会被销毁