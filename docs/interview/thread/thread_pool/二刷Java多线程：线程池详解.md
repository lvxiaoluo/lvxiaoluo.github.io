# 二刷Java多线程：线程池详解

## 一、使用线程池的好处

- **降低资源消耗**：通过重复利用已创建的线程降低线程创建和销毁造成的消耗
- **提高响应速度**：当任务到达时，任务可以不需要等到线程创建就能立即执行
- **提高线程的可管理性**：使用线程池可以统一分配、调优和监控

## 二、线程池实现原理

**当提交一个新任务到线程池时，线程池的处理流程如下**：

1）、线程池判断核心线程池里的线程是否已满且线程都在执行任务。如果不是，则创建一个新的工作线程来执行任务。否则进入下个流程

2）、线程池判断工作队列是否已经满。如果工作队列没有满，则将新提交的任务存储在这个工作队列里。否则进入下个流程

3）、线程池判断线程池的线程数是否达到最大线程数且线程都处于工作状态。如果没有，则创建一个新的工作线程来执行任务。否则进入下个流程

![在这里插入图片描述](https://img-blog.csdnimg.cn/2019100608421354.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQwMzc4MDM0,size_16,color_FFFFFF,t_70) 
![在这里插入图片描述](https://img-blog.csdnimg.cn/20191006084235624.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQwMzc4MDM0,size_16,color_FFFFFF,t_70)

**ThreadPoolExecutor执行execute方法分下面4种情况**：

1）、如果当前运行的线程少于corePoolSize，则创建新线程来执行任务（这一步需要获取全局锁）

2）、如果运行的线程等于或多于corePoolSize，则将任务加入BlockingQueue

3）、如果无法将任务加入BlockingQueue（队列已满），则创建新的线程来处理任务（这一步需要获取全局锁）

4）、如果创建新线程将使当前运行的线程超出maximumPoolSize，任务将被拒绝，并调用RejectedExecutionHandler.rejectedExecution()方法

ThreadPoolExecutor采取上述步骤的总体设计思路，是为了在执行execute()方法时，尽可能地避免获取全局锁。在ThreadPoolExecutor完成预热之后（当前运行的线程数大于等于corePoolSize），几乎所有的execute()方法调用都是执行步骤2，而步骤2不需要获取全局锁

## 三、线程池使用

### 1、线程池的创建

```java
    public ThreadPoolExecutor(int corePoolSize,
                              int maximumPoolSize,
                              long keepAliveTime,
                              TimeUnit unit,
                              BlockingQueue<Runnable> workQueue,
                              ThreadFactory threadFactory,
                              RejectedExecutionHandler handler)
```

1）、**corePoolSize（核心线程池大小）**：当提交一个任务到线程池时，线程池会创建一个线程来执行任务，即使其他空闲的基本线程能够执行新任务也会创建线程，等到需要执行的任务数大于线程池基本大小时就不再创建。如果调用了线程池的prestartAllCoreThreads()方法，线程池会提前创建并启动所有基本线程

2）、**maximumPoolSize（线程池最大数量）**：线程池允许创建的最大线程数。如果队列满了，并且已创建的线程数小于最大线程数，则线程池会再创建新的线程执行任务。如果使用了无界的任务队列这个参数无效

3）、**keepAliveTime（线程活动保持时间）&unit（线程活动保持时间的单位）**：如果一个线程空闲了keepAliveTime&unit这么久，而且线程池的线程池数大于corePoolSize，那么这个空闲的线程就要被回收了

4）、**workQueue（任务队列）**：用于保存等待执行的任务的阻塞队列

- ArrayBlockingQueue：是一个基于数组结构的有界阻塞队列，此队列按FIFO（先进先出）原则对元素进行排序
- LinkedBlockingQueue：一个基于链表结构的阻塞队列，此队列按FIFIO排序元素，吞吐量通常要高于ArrayBlockingQueue。静态工厂方法Executors.newFixedThreadPool()使用了这个队列
- SynchronousQueue：一个不存储元素的阻塞队列。每个插入操作必须等到另一个线程调用移除操作，否则插入操作一直处于阻塞状态，吞吐量通常要高于LinkedBlockingQueue，静态工厂方法Executors.newCachedThreadPool()使用了这个队列
- PriorityBlockingQueue：一个具有优先级的无限阻塞队列

5）、**ThreadFactory**：用于设置创建线程的工厂，可以通过线程工厂给每个创建出来的线程设置名字

6）、**RejectedExecutionHandler（饱和策略）**：当队列和线程池都满了，说明线程池处于饱和状态，那么必须采取一种策略处理提交的新任务。**这个策略默认情况下是AbortPolicy，表示无法处理新任务时抛出异常**

- AbortPolicy：直接抛出异常
- CallerRunsPolicy：只用调用者所在线程来运行任务
- DiscardOldestPolicy：丢弃队列里最近的一个任务，并执行当前任务
- DiscardPolicy：不处理，丢弃掉

### 2、向线程池提交任务

execute()方法用于提交不需要返回值的任务，所以无法判断任务是否被线程池执行成功

```java
        threadPool.execute(new Runnable() {
            @Override
            public void run() {

            }
        });
123456
```

submit()方法用于提交需要返回值的任务。线程池会返回一个future类型的对象，通过这个future对象可以判断任务是否执行成功，并且可以通过future的get()方法来获取返回值，get()方法会阻塞当前线程直到任务完成，而使用get(long timeout, TimeUnit unit)方法会阻塞当前线程一段时间后立即返回，这时候有可能任务没有执行完

```java
        Future<Boolean> future = threadPool.submit(new Callable<Boolean>() {
            @Override
            public Boolean call() throws Exception {
                return true;
            }
        });
        try {
            Boolean flag = future.get();
        } catch (InterruptedException e) {
            //处理中断异常
            e.printStackTrace();
        } catch (ExecutionException e) {
            //处理无法执行任务异常
            e.printStackTrace();
        } finally {
            //关闭线程池
            threadPool.shutdown();
        }
123456789101112131415161718
```

### 3、关闭线程池

可以通过调用线程池的shutdown或shutdownNow方法来关闭线程池。它们的原理是遍历线程池中的工作线程，然后逐个调用线程的interrupt方法来中断线程，所以无法响应中断的任务可能永远无法终止。但是它们存在一定的区别，shutdownNow首先将线程池的状态设置为STOP，然后尝试停止所有的正在执行或暂停任务的线程，并返回等待执行任务的列表，而shutdown只是将线程池的状态设置成SHUTDOWN状态，然后中断所有没有正在执行任务的线程

只要调用了这两个关闭方法中的任意一个，isShutdown方法就会返回true。当所有的任务都已关闭后，才表示线程池关闭成功，这时调用isTerminaed方法会返回true

### 4、合理地配置线程池

1）、不建议使用静态工厂类Executors：Executors提供的很多方法默认使用的都是无界的LinkedBlockingQueue，高负载情境下，无界队列很容易导致OOM，而OOM会导致所有请求都无法处理，**所以强烈建议使用有界队列**

如果想要学习Executors相关知识可以参考之前的博客：https://blog.csdn.net/qq_40378034/article/details/87344164

2）、使用有界队列，当任务过多时，线程池会触发执行拒绝策略，线程池默认的拒绝策略会throw RejectedExecutionException这是个运行时异常，对于运行时异常编译器并不强制catch它，所以开发人员很容易忽略。因此**默认拒绝策略要慎重使用**。如果线程池处理的任务非常重要，建议自定义自己的拒绝策略

3）、使用线程池，还需要注意异常处理的问题，例如通过ThreadPoolExecutor对象的execute()方法提交任务时，如果任务在执行的过程中出现运行时异常，会导致执行任务的线程终止；不过，最致命的是任务虽然异常了，但是却获取不到任何通知，这会让人误以为任务都执行得很正常。虽然线程池提供了很多用于异常处理的方法，但是最稳妥和简单的方案还是捕获所有异常并按需处理，可以参考下面的示例代码：

```java
        try {
            // 业务逻辑
        } catch (RuntimeException runtimeException) {
            // 按需处理
        } catch (Throwable throwable) {
            // 按需处理
        }
1234567
```

4）、性质不同的任务（CPU密集型任务、IO密集型任务和混合型任务）可以用不同规模的线程池分开处理

**创建多少线程合适可以参考之前的博客**：https://blog.csdn.net/qq_40378034/article/details/100556161

### 5、其他API

**1）、prestartAllCoreThreads()和prestartCoreThread()方法**：线程池预热，提前创建等于核心线程数的线程数量

**2）、allowsCoreThreadTimeOut()方法**：线程池包括核心线程在内，没有任务分配的所有线程，在等待keepAliveTime&unit时间后全部回收掉

## 四、ThreadPoolExecutor源码分析

ThreadPoolExecutor中的成员变量ctl是一个32位二进制的Integer原子变量，用来记录线程池状态和线程池中线程个数，其中高3位用来表示线程池状态，后面29位用来记录线程池线程个数

```java
    //(高3位)用来标识线程池状态,(低29位)用来表示线程个数
    private final AtomicInteger ctl = new AtomicInteger(ctlOf(RUNNING, 0));
	//线程个数掩码位数
    private static final int COUNT_BITS = Integer.SIZE - 3;
	//线程最大个数(低29位) 00011111111111111111111111111111
    private static final int CAPACITY   = (1 << COUNT_BITS) - 1;

    //(高3位)11100000000000000000000000000000
    private static final int RUNNING    = -1 << COUNT_BITS;
	//(高3位)00000000000000000000000000000000
    private static final int SHUTDOWN   =  0 << COUNT_BITS;
	//(高3位)00100000000000000000000000000000
    private static final int STOP       =  1 << COUNT_BITS;
	//(高3位)01000000000000000000000000000000
    private static final int TIDYING    =  2 << COUNT_BITS;
	//(高3位)01100000000000000000000000000000
    private static final int TERMINATED =  3 << COUNT_BITS;

    //取高3位(运行状态)
    private static int runStateOf(int c)     { return c & ~CAPACITY; }
	//获取低29位(线程个数)
    private static int workerCountOf(int c)  { return c & CAPACITY; }
	//计算ctl新值(线程状态与线程个数)
    private static int ctlOf(int rs, int wc) { return rs | wc; }
```

**线程池状态含义如下：**

- **RUNNING**：接受新任务并且处理阻塞队列里的任务
- **SHUTDOWN**：拒绝新任务但是处理阻塞队列里的任务
- **STOP**：拒绝新任务并且抛弃阻塞队列里的任务，同时会中断正在处理的任务
- **TIDYING**：所有任务都执行完后当前线程池活动线程数为0，将要调用terminated方法
- **TERMINATED**：终止状态。terminated方法调用完以后的状态


**线程池状态转换图：**

![在这里插入图片描述](https://img-blog.csdnimg.cn/20191006084254922.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQwMzc4MDM0,size_16,color_FFFFFF,t_70)

**execute()方法：**

```java
    public void execute(Runnable command) {
        if (command == null)
            throw new NullPointerException();
        
        //获取当前线程池的状态+线程个数变啦的组合值
        int c = ctl.get();
        //当前线程池中线程个数小于corePoolSize则开启新线程(core线程)运行
        if (workerCountOf(c) < corePoolSize) {
            if (addWorker(command, true))
                return;
            c = ctl.get();
        }
        //如果线程池处于Running状态,则添加任务到阻塞队列
        if (isRunning(c) && workQueue.offer(command)) {
            //二次检查,因为添加任务到任务队列后,可能线程池的状态已经变化了
            int recheck = ctl.get();
            //如果当前线程池状态不是Running则从队列中删除任务,并执行拒绝策略
            if (! isRunning(recheck) && remove(command))
                reject(command);
            //否则如果当前线程池为空,则添加一个线程
            else if (workerCountOf(recheck) == 0)
                addWorker(null, false);
        }
        //如果队列满,则新增线程,新增失败则执行拒绝策略
        else if (!addWorker(command, false))
            reject(command);
    }

```

**addWorker()方法：**

```java
    private boolean addWorker(Runnable firstTask, boolean core) {
        retry:
        for (;;) {
            int c = ctl.get();
            int rs = runStateOf(c);

            //检查队列是否只在必要时为空
            if (rs >= SHUTDOWN &&
                ! (rs == SHUTDOWN &&
                   firstTask == null &&
                   ! workQueue.isEmpty()))
                return false;

            //循环CAS增加线程个数
            for (;;) {
                int wc = workerCountOf(c);
                //如果线程个数超限则返回false
                if (wc >= CAPACITY ||
                    wc >= (core ? corePoolSize : maximumPoolSize))
                    return false;
                //CAS增加线程个数,同时只有一个线程成功
                if (compareAndIncrementWorkerCount(c))
                    break retry;
                c = ctl.get(); 
                //CAS失败了,则看线程状态是否变化了,变化则调到外层(retry处)循环重新尝试获取线程池状态,否则内层重新CAS
                if (runStateOf(c) != rs)
                    continue retry;
            }
        }

        //此时说明CAS成功
        boolean workerStarted = false;
        boolean workerAdded = false;
        Worker w = null;
        try {
            //创建worker
            w = new Worker(firstTask);
            final Thread t = w.thread;
            if (t != null) {
                final ReentrantLock mainLock = this.mainLock;
                //加独占锁,为了实现workers同步,因为可能多个线程调用了线程池的execute方法
                mainLock.lock();
                try {
                    //重新检查线程池状态,以避免在获取锁前调用了shutdown接口
                    int rs = runStateOf(ctl.get());

                    if (rs < SHUTDOWN ||
                        (rs == SHUTDOWN && firstTask == null)) {
                        if (t.isAlive()) // precheck that t is startable
                            throw new IllegalThreadStateException();
                        //添加任务
                        workers.add(w);
                        int s = workers.size();
                        if (s > largestPoolSize)
                            largestPoolSize = s;
                        workerAdded = true;
                    }
                } finally {
                    mainLock.unlock();
                }
                //添加成功后则启动任务
                if (workerAdded) {
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

```

> break retry：跳到retry处，且不再进入循环
> continue retry：跳到retry处，且再次进入循环

## 五、线程池实战

### 1、submit()提交任务，批量处理返回结果（异步转同步）

```java
    public class ThreadPoolDemo {
    
        public static void main(String[] args) throws ExecutionException, InterruptedException {
            ExecutorService executorService = Executors.newFixedThreadPool(4);
            List<Future<String>> resultList = new ArrayList<>();
            for (int i = 0; i < 6; i++) {
                //使用ExecutorService执行Callable类型的任务,并将结果保存在future变量中
                Future<String> future = executorService.submit(() -> {
                    long start = System.currentTimeMillis();
                    System.out.println(Thread.currentThread().getName() + "任务开始");
                    TimeUnit.SECONDS.sleep(10);
                    System.out.println(Thread.currentThread().getName() + "任务结束");
                    return Thread.currentThread().getName() + "任务耗时" + (System.currentTimeMillis() - start) + "ms";
                });
                //将任务执行结果存储到List中
                resultList.add(future);
            }
            executorService.shutdown();
            Iterator<Future<String>> iterator = resultList.iterator();
            while (iterator.hasNext()) {
                System.out.println(iterator.next().get());
            }
        }
    }
123456789101112131415161718192021222324
```

### 2、SpringBoot使用线程池

参考：https://mp.weixin.qq.com/s/SCbZueYmODmCXUhn6y3q5A

### 3、多线程实现Excel批量快速导入

参考：https://blog.csdn.net/System_out_print_Boy/article/details/86700865