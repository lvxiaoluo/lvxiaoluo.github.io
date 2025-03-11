### Java同一个线程对象能否多次调用start方法

> 同一个线程对象能否多次调用start方法，搞清楚这个问题，首先需要了解线程的生命周期

#### 一、线程生命周期
![image](https://img-blog.csdnimg.cn/20200331215217135.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3NtaWxlX2Zyb21fMjAxNQ==,size_16,color_FFFFFF,t_70)
更多线程状态细节描述可查看Thread内部枚举类：State
从上图线程状态转换图可以看出：
1. 新建（NEW）状态是无法通过其他状态转换而来的;
2. 终止（TERMINATED）状态无法转为其他状态。
为何新建状态和终止状态不可逆转，接下来将通过Thread源码来分析

#### 二、先通过一个正常程序来了解线程的执行过程：
```java
public static void main(String[] args) {
    //创建一个线程t1
    Thread t1 = new Thread(() -> {
        try {
            //睡眠10秒，防止run方法执行过快，线程组被销毁
            TimeUnit.SECONDS.sleep(10);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    });
    //第一次启动
    t1.start();
}
```
1. 当执行new Thread时，Thread构造方法会调用内部init方法做一些初始化工作，如设置线程组、目标方法、线程名称、堆栈大小、线程优先级等，线程状态是由volatile关键字修饰的threadStatus控制的，初始值为0，即0表示新建状态（NEW）；
2. 调用t1.start方法后，该方法会将调用本地方法start0，start0会创建一个新线程并修改Thread.threadStatus的值；

扩展：[了解Java线程的start方法如何回调run方法](https://blog.csdn.net/itmyhome1990/article/details/78471653)

下面看下start方法源码：
```java
/**线程成员变量，默认为0，volatile修饰可以保证线程间可见性*/
private volatile int threadStatus = 0;
/* 当前线程所属的线程组 */
private ThreadGroup group;
/**
 * 同步方法，同一时间，只能有一个线程可以调用此方法
 */
public synchronized void start() {
    //threadStatus
    if (threadStatus != 0)
        throw new IllegalThreadStateException();
    //线程组
    group.add(this);
    boolean started = false;
    try {
        //本地方法，该方法会实际调用run方法
        start0();
        started = true;
    } finally {
        try {
            if (!started) {
                //创建失败，则从线程组中删除该线程
                group.threadStartFailed(this);
            }
        } catch (Throwable ignore) {
            /* start0抛出的异常不用处理，将会在堆栈中传递 */
        }
    }
}
```
1. 通过断点跟踪，可以看到当线程对象第一次调用start方法时会进入同步方法，会判断threadStatus是否为0，如果为0，则进行往下走，否则抛出非法状态异常；
2. 将当前线程对象加入线程组；
3. 调用本地方法**start0**执行真正的创建线程工作，并调用run方法，可以看到在start0执行完后，**threadStatus**的值发生了改变，不再为0；
4. finally块用于捕捉**start0**方法调用发生的异常。

扩展：线程是如何根据**threadStatus**来判断线程的状态的呢？
通过查看Thread提供的public方法getState可以看到，调用的是sun.misc.VM.toThreadState(threadStatus)，根据位运算得出线程的不同状态：
```java
public static State toThreadState(int var0) {
        if ((var0 & 4) != 0) {
            return State.RUNNABLE;
        } else if ((var0 & 1024) != 0) {
            return State.BLOCKED;
        } else if ((var0 & 16) != 0) {
            return State.WAITING;
        } else if ((var0 & 32) != 0) {
            return State.TIMED_WAITING;
        } else if ((var0 & 2) != 0) {
            return State.TERMINATED;
        } else {
            return (var0 & 1) == 0 ? State.NEW : State.RUNNABLE;
        }
    }
```
继续回到原话题，当start调用后，并且run方法内容执行完后，线程是如何终止的呢？实际上是由虚拟机调用Thread中的exit方法来进行资源清理并终止线程的，看下exit方法源码：
```java
/**
 * 系统调用该方法用于在线程实际退出之前释放资源
 */
private void exit() {
    //释放线程组资源
    if (group != null) {
        group.threadTerminated(this);
        group = null;
    }
    //清理run方法实例对象
    target = null;
    /*加速资源释放。快速垃圾回收 */
    threadLocals = null;
    inheritableThreadLocals = null;
    inheritedAccessControlContext = null;
    blocker = null;
    uncaughtExceptionHandler = null;
}
```
1. 到这里，t1 线程经历了从新建（NEW），就绪（RUNNABLE），运行（RUNNING），定时等待（TIMED_WAITING），终止（TERMINATED）这样一个过程；
2. 由于在第一次 start 方法后，threadStatus 值被改变，因此第二次调用start时会抛出非法状态异常；
3. 在调用start0方法后，如果run方法体内容被快速执行完，那么系统会自动调用exit方法释放资源，销毁对象，所以第二次调用start方法时，有可能内部资源已经被释放。
初步结论：同一个线程对象不可以多次调用 start 方法。

#### 三、通过反射修改threadStatus来多次执行start方法
：
```java
public static void main(String[] args) throws Exception {
    //创建一个线程t1
    Thread t1 = new Thread(() -> {
        try {
            //睡眠10秒，防止run方法执行过快，
            //触发exit方法导致线程组被销毁
            TimeUnit.SECONDS.sleep(10);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    });

    //第一次启动
    t1.start();
    
    //修改threadStatus，重新设置为0，即 NEW 状态
    Field threadStatus = t1.getClass().getDeclaredField("threadStatus");
    threadStatus.setAccessible(true);
    //重新将线程状态设置为0，新建（NEW）状态
    threadStatus.set(t1, 0);
    
    //第二次启动
    t1.start();
}
```
截取start后半截源码：
```
boolean started = false;
try {
    //第二次执行start0会抛异常，这时started仍然为false
    start0();
    started = true;
} finally {
    try {
        if (!started) {
            //创建失败，则从线程组中删除该线程
            group.threadStartFailed(this);
        }
    } catch (Throwable ignore) {
        /* start0抛出的异常不用处理，将会在堆栈中传递 */
    }
}
```
1. 在上面代码中，在第一次调用start方法后，我通过反射修改threadStatus值，这样在第二次调用时可以跳过状态值判断语句，达到多次调用start方法；
2. 当我第二次调用t1.start时，需要设置run方法运行时间长一点，防止系统调用exit方法清理线程资源；
3. 经过以上两步，我成功绕开 threadStatus 判断和线程组增加方法，开始执行start0方法，但是在执行start0的时候抛出异常，并走到了finally块中，由于start为false，所以会执行group.threadStartFailed(this)操作，将该线程从线程组中移除；
4. 所以start0中还是会对当前线程状态进行了一个判断，不允许重复创建线程。

**最后结论：无论是直接二次调用还是通过反射二次调用，同一个线程对象都无法多次调用start方法，仅可调用一次。**