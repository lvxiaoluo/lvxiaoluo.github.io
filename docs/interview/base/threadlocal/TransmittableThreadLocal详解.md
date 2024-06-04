# TransmittableThreadLocal详解

**ThreadLocal和InheritableThreadLocal学习资料**：[二刷Java多线程：ThreadLocal详解](https://blog.csdn.net/qq_40378034/article/details/101221008)

**线程池学习资料**：[二刷Java多线程：线程池详解](https://blog.csdn.net/qq_40378034/article/details/102209809)

### 1、InheritableThreadLocal+[线程池](https://so.csdn.net/so/search?q=线程池&spm=1001.2101.3001.7020)局限性

**InheritableThreadLocal支持子线程访问在父线程中设置的线程上下文环境，其实现原理是在创建子线程时将父线程中的本地变量值复制到子线程，即复制的时机为创建子线程时**

**当提交一个新任务到线程池时，线程池的处理流程如下**：

1. 线程池判断线程数是否**达到核心线程数且线程都处于工作状态**。如果不是，则创建一个新的工作线程来执行任务。否则进入下个流程
2. 线程池判断**工作队列是否已经满**。如果工作队列没有满，则将新提交的任务存储在这个工作队列里。否则进入下个流程
3. 线程池判断线程数是否**达到最大线程数且线程都处于工作状态**。如果没有，则创建一个新的工作线程来执行任务。否则按照策略处理无法执行的任务

如果使用InheritableThreadLocal+线程池，提交任务时导致线程池创建了新的工作线程，此时工作线程（子线程）能够访问到父线程（提交任务的线程）的本地变量；如果提交任务复用了已经创建的工作线程，此时工作线程（子线程）访问的本地变量来源于第一个提交任务给该工作线程的外部线程，造成线程本地变量混乱

```java
public class InheritableThreadLocalDemo {
    /**
     * 模拟tomcat线程池
     */
    private static ExecutorService tomcatExecutors = Executors.newFixedThreadPool(10);

    /**
     * 业务线程池,默认Control中异步任务执行线程池
     */
    private static ExecutorService businessExecutors = Executors.newFixedThreadPool(5);

    /**
     * 线程上下文环境,模拟在Control这一层,设置环境变量,然后在这里提交一个异步任务,模拟在子线程中,是否可以访问到刚设置的环境变量值
     */
    private static InheritableThreadLocal<Integer> requestIdThreadLocal = new InheritableThreadLocal<>();

    /**
     * 模式10个请求,每个请求执行ControlThread的逻辑,其具体实现就是,先输出父线程的名称,
     * 然后设置本地环境变量,并将父线程名称传入到子线程中,在子线程中尝试获取在父线程中的设置的环境变量
     *
     * @param args
     * @throws InterruptedException
     */
    public static void main(String[] args) throws InterruptedException {
        for (int i = 0; i < 10; ++i) {
            tomcatExecutors.submit(new ControlThread(i));
        }

        TimeUnit.SECONDS.sleep(10);
        businessExecutors.shutdown();
        tomcatExecutors.shutdown();
    }

    /**
     * 模拟Control任务
     */
    static class ControlThread implements Runnable {
        private int i;

        public ControlThread(int i) {
            this.i = i;
        }

        @Override
        public void run() {
            System.out.println(Thread.currentThread().getName() + ":" + i);
            requestIdThreadLocal.set(i);
            //使用线程池异步处理任务
            businessExecutors.submit(new BusinessTask(Thread.currentThread().getName()));
        }
    }

    /**
     * 业务任务,主要是模拟在Control控制层,提交任务到线程池执行
     */
    static class BusinessTask implements Runnable {
        private String parentThreadName;

        public BusinessTask(String parentThreadName) {
            this.parentThreadName = parentThreadName;
        }

        @Override
        public void run() {
            //如果与上面的能对应上来,则说明正确,否则失败
            System.out.println("parentThreadName:" + parentThreadName + ":" + requestIdThreadLocal.get());
        }
    }
}
123456789101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657585960616263646566676869
```

其中一次执行结果如下：

```
pool-1-thread-1:0
pool-1-thread-4:3
pool-1-thread-3:2
pool-1-thread-2:1
pool-1-thread-6:5
pool-1-thread-5:4
pool-1-thread-7:6
pool-1-thread-8:7
pool-1-thread-9:8
pool-1-thread-10:9
parentThreadName:pool-1-thread-1:0
parentThreadName:pool-1-thread-4:3
parentThreadName:pool-1-thread-8:3
parentThreadName:pool-1-thread-7:6
parentThreadName:pool-1-thread-10:0
parentThreadName:pool-1-thread-3:3
parentThreadName:pool-1-thread-5:4
parentThreadName:pool-1-thread-2:1
parentThreadName:pool-1-thread-9:6
parentThreadName:pool-1-thread-6:0
1234567891011121314151617181920
```

在子线程中出现出现了线程本地变量混乱的现象

### 2、TransmittableThreadLocal

#### 1）、TransmittableThreadLocal+线程池

引入ttl依赖：

```xml
        <dependency>
            <groupId>com.alibaba</groupId>
            <artifactId>transmittable-thread-local</artifactId>
            <version>2.12.1</version>
        </dependency>
12345
public class TransmittableThreadLocalDemo {
    /**
     * 模拟tomcat线程池
     */
    private static ExecutorService tomcatExecutors = Executors.newFixedThreadPool(10);

    /**
     * 业务线程池,默认Control中异步任务执行线程池 使用ttl线程池
     */
    private static ExecutorService businessExecutors = TtlExecutors.getTtlExecutorService(Executors.newFixedThreadPool(5));

    /**
     * 线程上下文环境,模拟在Control这一层,设置环境变量,然后在这里提交一个异步任务,模拟在子线程中,是否可以访问到刚设置的环境变量值
     */
    private static TransmittableThreadLocal<Integer> requestIdThreadLocal = new TransmittableThreadLocal<>();

    /**
     * 模式10个请求,每个请求执行ControlThread的逻辑,其具体实现就是,先输出父线程的名称,
     * 然后设置本地环境变量,并将父线程名称传入到子线程中,在子线程中尝试获取在父线程中的设置的环境变量
     *
     * @param args
     * @throws InterruptedException
     */
    public static void main(String[] args) throws InterruptedException {
        for (int i = 0; i < 10; ++i) {
            tomcatExecutors.submit(new ControlThread(i));
        }

        TimeUnit.SECONDS.sleep(10);
        businessExecutors.shutdown();
        tomcatExecutors.shutdown();
    }

    /**
     * 模拟Control任务
     */
    static class ControlThread implements Runnable {
        private int i;

        public ControlThread(int i) {
            this.i = i;
        }

        @Override
        public void run() {
            System.out.println(Thread.currentThread().getName() + ":" + i);
            requestIdThreadLocal.set(i);
            //使用线程池异步处理任务
            businessExecutors.submit(new BusinessTask(Thread.currentThread().getName()));
        }
    }

    /**
     * 业务任务,主要是模拟在Control控制层,提交任务到线程池执行
     */
    static class BusinessTask implements Runnable {
        private String parentThreadName;

        public BusinessTask(String parentThreadName) {
            this.parentThreadName = parentThreadName;
        }

        @Override
        public void run() {
            //如果与上面的能对应上来,则说明正确,否则失败
            System.out.println("parentThreadName:" + parentThreadName + ":" + requestIdThreadLocal.get());
        }
    }
}
123456789101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657585960616263646566676869
```

执行结果如下：

```
pool-1-thread-3:2
pool-1-thread-6:5
pool-1-thread-5:4
pool-1-thread-1:0
pool-1-thread-4:3
pool-1-thread-2:1
pool-1-thread-8:7
pool-1-thread-7:6
pool-1-thread-9:8
pool-1-thread-10:9
parentThreadName:pool-1-thread-3:2
parentThreadName:pool-1-thread-1:0
parentThreadName:pool-1-thread-2:1
parentThreadName:pool-1-thread-4:3
parentThreadName:pool-1-thread-10:9
parentThreadName:pool-1-thread-8:7
parentThreadName:pool-1-thread-7:6
parentThreadName:pool-1-thread-9:8
parentThreadName:pool-1-thread-6:5
parentThreadName:pool-1-thread-5:4
1234567891011121314151617181920
```

执行结果符合预期

#### 2）、TransmittableThreadLocal实现原理

InheritableThreadLocal不支持线程池的根本原因是**InheritableThreadLocal是在父线程创建子线程时复制的**，由于线程池的复用机制，子线程只会复制一次。要支持线程池中能访问提交任务线程的本地变量，其实只需要**在父线程向线程池提交任务时复制父线程的上下环境**，那在子线程中就能够如愿访问到父线程中的本地变量，实现本地环境变量在线程池调用中的透传，这也是TransmittableThreadLocal最本质的实现原理

##### 1）TransmittableThreadLocal

![img](https://img-blog.csdnimg.cn/20210327215103179.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQwMzc4MDM0,size_16,color_FFFFFF,t_70#pic_center)

TransmittableThreadLocal继承自InheritableThreadLocal

在TransmittableThreadLocal中定义了一个全局静态变量holder，该对象缓存了线程执行过程中所有的TransmittableThreadLocal对象

```java
public class TransmittableThreadLocal<T> extends InheritableThreadLocal<T> implements TtlCopier<T> {
  
    private static final InheritableThreadLocal<WeakHashMap<TransmittableThreadLocal<Object>, ?>> holder =
            new InheritableThreadLocal<WeakHashMap<TransmittableThreadLocal<Object>, ?>>() {
                @Override
                protected WeakHashMap<TransmittableThreadLocal<Object>, ?> initialValue() {
                    return new WeakHashMap<TransmittableThreadLocal<Object>, Object>();
                }

                @Override
                protected WeakHashMap<TransmittableThreadLocal<Object>, ?> childValue(WeakHashMap<TransmittableThreadLocal<Object>, ?> parentValue) {
                    return new WeakHashMap<TransmittableThreadLocal<Object>, Object>(parentValue);
                }
            };
1234567891011121314
```

`childValue()`方法会在创建子线程时，Thread调用`init()`方法，会调用`ThreadLocal.createInheritedMap()`，`createInheritedMap()`方法中会创建ThreadLocalMap，ThreadLocalMap的构造方法中会调用`childValue()`方法

在使用线程池时，需要使用TTL提供的TtlExecutors包装，如：

```java
TtlExecutors.getTtlExecutor(Executors.newCachedThreadPool());
1
```

`TtlExecutors.getTtlExecutorService()`方法：

```java
public final class TtlExecutors {
  
    public static Executor getTtlExecutor(@Nullable Executor executor) {
        if (TtlAgent.isTtlAgentLoaded() || null == executor || executor instanceof TtlEnhanced) {
            return executor;
        }
        return new ExecutorTtlWrapper(executor, true);
    }
12345678
```

使用ExecutorTtlWrapper包装Executor

```java
class ExecutorTtlWrapper implements Executor, TtlWrapper<Executor>, TtlEnhanced {
    private final Executor executor;
    protected final boolean idempotent;

    ExecutorTtlWrapper(@NonNull Executor executor, boolean idempotent) {
        this.executor = executor;
        this.idempotent = idempotent;
    }

    @Override
    public void execute(@NonNull Runnable command) {
        executor.execute(TtlRunnable.get(command, false, idempotent));
    }
12345678910111213
```

ExecutorTtlWrapper在执行`execute()`方法的时候，使用TtlRunnable做了线程上下文的处理，再执行真正的Runnable `run()`方法

##### 2）TtlRunnable

```java
public final class TtlRunnable implements Runnable, TtlWrapper<Runnable>, TtlEnhanced, TtlAttachments {
  
    private final AtomicReference<Object> capturedRef;
    private final Runnable runnable;
    private final boolean releaseTtlValueReferenceAfterRun;

    private TtlRunnable(@NonNull Runnable runnable, boolean releaseTtlValueReferenceAfterRun) {
      	//1)Snapshot对象用于父线程的本地线程变量
        this.capturedRef = new AtomicReference<Object>(capture());
        this.runnable = runnable;
        this.releaseTtlValueReferenceAfterRun = releaseTtlValueReferenceAfterRun;
    }
123456789101112
    public static class Transmitter {
      
        public static Object capture() {
          	//Snapshot中包含HashMap<TransmittableThreadLocal<Object>, Object> ttl2Value和HashMap<ThreadLocal<Object>, Object> threadLocal2Value
            return new Snapshot(captureTtlValues(), captureThreadLocalValues());
        }
      
        private static HashMap<TransmittableThreadLocal<Object>, Object> captureTtlValues() {
            HashMap<TransmittableThreadLocal<Object>, Object> ttl2Value = new HashMap<TransmittableThreadLocal<Object>, Object>();
            for (TransmittableThreadLocal<Object> threadLocal : holder.get().keySet()) {
              	//默认是浅拷贝
                ttl2Value.put(threadLocal, threadLocal.copyValue());
            }
            return ttl2Value;
        }

        private static HashMap<ThreadLocal<Object>, Object> captureThreadLocalValues() {
            final HashMap<ThreadLocal<Object>, Object> threadLocal2Value = new HashMap<ThreadLocal<Object>, Object>();
            for (Map.Entry<ThreadLocal<Object>, TtlCopier<Object>> entry : threadLocalHolder.entrySet()) {
                final ThreadLocal<Object> threadLocal = entry.getKey();
                final TtlCopier<Object> copier = entry.getValue();
                threadLocal2Value.put(threadLocal, copier.copy(threadLocal.get()));
            }
            return threadLocal2Value;
        }      
      
        private static class Snapshot {
            final HashMap<TransmittableThreadLocal<Object>, Object> ttl2Value;
            final HashMap<ThreadLocal<Object>, Object> threadLocal2Value;

            private Snapshot(HashMap<TransmittableThreadLocal<Object>, Object> ttl2Value, HashMap<ThreadLocal<Object>, Object> threadLocal2Value) {
                this.ttl2Value = ttl2Value;
                this.threadLocal2Value = threadLocal2Value;
            }
        }      
123456789101112131415161718192021222324252627282930313233343536
```

在向线程池提交任务时，会先捕获父线程（提交任务到线程池的线程）中的本地环境变量，接下来重点来看一下其`run()`方法

```java
public final class TtlRunnable implements Runnable, TtlWrapper<Runnable>, TtlEnhanced, TtlAttachments {

    @Override
    public void run() {
        final Object captured = capturedRef.get();
        if (captured == null || releaseTtlValueReferenceAfterRun && !capturedRef.compareAndSet(captured, null)) {
            throw new IllegalStateException("TTL value reference is released after run!");
        }
				
      	//1)重放父线程的本地环境变量,即使用从父线程中捕获过来的上下文环境,在子线程中重新执行一遍,并返回原先存在与子线程中的上下文环境变量
        final Object backup = replay(captured);
        try {
          	//2)执行业务逻辑
            runnable.run();
        } finally {
          	//3)恢复线程池中当前执行任务的线程的上下文环境,即代码1),会直接继承父线程中的上下文环境,但会将原先存在该线程的线程上下文环境进行备份,在任务执行完后通过执行restore方法进行恢复
            restore(backup);
        }
    }
12345678910111213141516171819
```

`replay()`方法：

```java
    public static class Transmitter {
      
		public static Object replay(@NonNull Object captured) {
            final Snapshot capturedSnapshot = (Snapshot) captured;
            return new Snapshot(replayTtlValues(capturedSnapshot.ttl2Value), replayThreadLocalValues(capturedSnapshot.threadLocal2Value));
        }
      
        @NonNull
        private static HashMap<TransmittableThreadLocal<Object>, Object> replayTtlValues(@NonNull HashMap<TransmittableThreadLocal<Object>, Object> captured) {
          	//capturedMap:子线程从父线程捕获的线程本地变量 backup:线程池中处理本次任务的线程中原先存在的本地线程变量
            HashMap<TransmittableThreadLocal<Object>, Object> backup = new HashMap<TransmittableThreadLocal<Object>, Object>();
						
          	//holder.get()是子线程中原先存在的本地线程变量(即线程池中分配来执行本次任务的线程),然后遍历它,将其存储在backUp
            for (final Iterator<TransmittableThreadLocal<Object>> iterator = holder.get().keySet().iterator(); iterator.hasNext(); ) {
                TransmittableThreadLocal<Object> threadLocal = iterator.next();

                // backup
                backup.put(threadLocal, threadLocal.get());

                //根据父线程的本地变量来重放当前线程,如果父线程中不包含的threadlocal对象,将从本地线程变量中移除
                if (!captured.containsKey(threadLocal)) {
                    iterator.remove();
                    threadLocal.superRemove();
                }
            }

            //遍历父线程中的本地线程变量,在子线程中重新执行一次threadlocal.set方法
            setTtlValuesTo(captured);

            //执行beforeExecute()钩子函数
            doExecuteCallback(true);
						
          	//返回线程池原线程的本地线程变量，供本次调用后恢复上下文环境
            return backup;
        }    
1234567891011121314151617181920212223242526272829303132333435
```

`restore()`方法：

恢复线程中子线程原先的本地线程变量，即恢复线程，本次执行并不会污染线程池中线程原先的上下文环境

```java
    public static class Transmitter {        

		public static void restore(@NonNull Object backup) {
            final Snapshot backupSnapshot = (Snapshot) backup;
            restoreTtlValues(backupSnapshot.ttl2Value);
            restoreThreadLocalValues(backupSnapshot.threadLocal2Value);
        }
      
        private static void restoreTtlValues(@NonNull HashMap<TransmittableThreadLocal<Object>, Object> backup) {
            //执行afterExecute()钩子函数
            doExecuteCallback(false);

            for (final Iterator<TransmittableThreadLocal<Object>> iterator = holder.get().keySet().iterator(); iterator.hasNext(); ) {
                TransmittableThreadLocal<Object> threadLocal = iterator.next();

                //遍历本地线程变量,将不属于backUpMap中存在的线程本地上下文移除
                if (!backup.containsKey(threadLocal)) {
                    iterator.remove();
                    threadLocal.superRemove();
                }
            }

            //遍历备份的本地线程变量,在本地线程中重新执行threadlocal.set方法,实现线程本地变量的还原
            setTtlValuesTo(backup);
        }      
12345678910111213141516171819202122232425
```

**参考**：

https://github.com/alibaba/transmittable-thread-local

https://github.com/alibaba/transmittable-thread-local/issues/123

https://mp.weixin.qq.com/s/a6IGrOtn1mi0r05355L5Ng