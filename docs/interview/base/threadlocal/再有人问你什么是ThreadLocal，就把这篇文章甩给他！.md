# [再有人问你什么是ThreadLocal，就把这篇文章甩给他！](https://www.hollischuang.com/archives/4859)

> ThreadLocal是JDK1.2提供的一个工具，它为解决多线程程序的并发问题提供了一种新的思路。使用这个工具类可以很简洁地编写出优美的多线程程序，解决共享参数的频繁传递与线程安全等问题。如果开发者掌握了ThreadLocal用法与原理，那么使用起来将得心应手，那么请跟随本文的节奏，拨开迷雾，探究本质吧！

本文将带领读者深入理解ThreadLocal，为了保证阅读质量，我们可以先一起来简单理解一下什么是ThreadLocal？

如果你从字面上来理解，很容易将ThreadLocal理解为『`本地线程`』，那么你就大错特错了。

首先，ThreadLocal不是线程，更不是本地线程，而是Thread的局部变量，也许把它命名为`ThreadLocalVariable`更容易让人理解一些。

它是每个线程独享的本地变量，每个线程都有自己的ThreadLocal，它们是线程隔离的。接下来，我们通过一个生活案例来开始理解ThreadLocal。

#### 一、问题场景引入

假如语文老师有一本书，但是班上有30名学生，老师将这本书送给学生们去阅读，30名学生都想阅读这本书。

为保证每个学生都能阅读到书籍，那么基本可以有两种方案，一是按照某种排序（例如姓名首字母排序），让每个学生依次阅读。

二是让30名学生同时争抢，谁抢到谁就去阅读，读完放回原处，剩下的29名学生再次争抢。

显然第一种方案，基本表现为串行阅读，时间成本较大，第二种方案为多个学生争抢，容易发生安全问题（学生发生冲突或者书籍在争抢过程中被毁坏）。

为了解决这两个问题，那么有没有更加好的方案呢？当然有，老师可以将书籍复印30本，每个学生都发一本，这样既大大提高了阅读效率，节约了阅读时间，还能保证每个学生都能有自己的书籍，这样就不会发生争抢，避免了安全问题。

其实阅读到这里，读者应该有点感觉了，因为生动的例子能帮助读者迅速理解关键点，在本例中，书籍作为共享变量，那么很多学生去争抢，学生可以理解为线程，同时去争抢（并发执行）有很大可能会引起安全问题（线程安全问题），这往往是老师不愿意看到的后果。

我们在结合Java Demo来演示类似的案例。假如我们有一个需求，那就是在多线程环境下，去格式化时间为指定格式`yyyy-MM-dd HH:mm:ss`，假设一开始只有两个线程需要这么做，代码如下：

```
public class ThreadLocalUsage01 {

    public static void main(String[] args) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                String date = new ThreadLocalUsage01().date(10);
                System.out.println(date);
            }
        }).start();

        new Thread(new Runnable() {
            @Override
            public void run() {
                String date = new ThreadLocalUsage01().date(1000);
                System.out.println(date);
            }
        }).start();
    }

    private String date(int seconds) {
        // 参数的单位是毫秒，从1970.1.1 00:00:00 GMT计时
        Date date = new Date(1000 * seconds);
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        return dateFormat.format(date);
    }

}
```

在线程少的情况下是没有问题的，我们在每个线程里调用date方法，也就是在每个线程里都执行了创建SimpleDateFormat对象，每个对象在各自的线程里面执行格式化时间

但是我们是否会思考到，假如有1000个线程需要格式化时间，那么需要调用1000次date方法，也就是需要创建1000个作用一样的SimpleDateFormat对象，这样是不是太浪费内存了？也给GC带来压力？

于是我们联想到，1000个线程来共享一个SimpleDateFormat对象，这样SimpleDateFormat对象只需要创建一次即可，代码如下：

```
public class ThreadLocalUsage02 {

    public static ExecutorService THREAD_POOL = Executors.newFixedThreadPool(10);
    static SimpleDateFormat DATE_FORMAT = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

    public static void main(String[] args) throws InterruptedException {
        for (int i = 0; i < 1000; i++) {
            int finalI = i;
            THREAD_POOL.submit(new Runnable() {
                @Override
                public void run() {
                    String date = new ThreadLocalUsage02().date(finalI);
                    System.out.println(date);
                }
            });
        }
        // 关闭线程池，此种关闭方式不再接受新的任务提交，等待现有队列中的任务全部执行完毕之后关闭
        THREAD_POOL.shutdown();
    }

    private String date(int seconds) {
        // 参数的单位是毫秒，从1970.1.1 00:00:00 GMT计时
        Date date = new Date(1000 * seconds);
        return DATE_FORMAT.format(date);
    }

}
```

上述代码我们使用到了固定线程数的线程池来执行时间格式化任务，我们来执行一下，看看结果：

![在这里插入图片描述](http://www.hollischuang.com/wp-content/uploads/2020/05/0.png)

截取了部分执行结果，发现执行结果中有很多重复的时间格式化内容，这是为什么呢？

这是因为SimpleDateFormat是一个线程不安全的类，其实例对象在多线程环境下作为共享数据，会发生线程不安全问题。

说到这里，很多读者肯定会说，我们可以尝试一下使用锁机制，我们将date方法内的格式化代码使用`synchronized`关键字概括起来，保证同一时刻只能有一个线程来访问SimpleDateFormat的format方法，代码如下所示：

```
private String date(int seconds) {
    // 参数的单位是毫秒，从1970.1.1 00:00:00 GMT计时
    Date date = new Date(1000 * seconds);
    String format;
    synchronized (ThreadLocalUsage02.class) {
        format = DATE_FORMAT.format(date);
    }
    return format;
}
```

有了锁的保证，那么这次执行后就不会再出现重复的时间格式化结果了，这也就保证了线程安全。

使用锁机制确实可以解决问题，但是多数情况下，我们不大愿意使用锁，因为锁的使用会带来性能的下降（比如10个线程重复排队执行`DATE_FORMAT.format(date)`代码），那么有没有其他方法来解决这个问题呢？答案当然是有，那就是本文的主角——ThreadLocal。

#### 二、理解ThreadLocal的用法

这里还是使用固定线程数的线程池来执行格式化时间的任务。

我们的基本思想是，使用ThreadLocal来给线程池中每个线程赋予一个SimpleDateFormat对象副本，该副本只能被当前线程使用，是当前线程独享的成员变量，当SimpleDateFormat对象不存在多线程共同访问的时候，也就不会产生线程安全问题了，基本原理图如下所示：

![在这里插入图片描述](http://www.hollischuang.com/wp-content/uploads/2020/05/1.png)

我们使用ThreadLocal的目的是为了避免创建1000个SimpleDateFormat对象，且在不使用锁的情况下保证线程安全，那么如何实现只创建一个SimpleDateFormat对象且能被多个线程同时使用呢？改造后的案例代码如下所示：

```
public class ThreadLocalUsage04 {

    public static ExecutorService THREAD_POOL = Executors.newFixedThreadPool(10);

    public static void main(String[] args) throws InterruptedException {
        for (int i = 0; i < 1000; i++) {
            int finalI = i;
            THREAD_POOL.submit(new Runnable() {
                @Override
                public void run() {
                    String date = new ThreadLocalUsage04().date(finalI);
                    System.out.println(date);
                }
            });
        }
        THREAD_POOL.shutdown();
    }

    private String date(int seconds) {
        // 参数的单位是毫秒，从1970.1.1 00:00:00 GMT计时
        Date date = new Date(1000 * seconds);
        SimpleDateFormat simpleDateFormat = ThreadSafeDateFormatter.dateFormatThreadLocal.get();
        return simpleDateFormat.format(date);
    }

}

class ThreadSafeDateFormatter {

    public static ThreadLocal<SimpleDateFormat> dateFormatThreadLocal = new ThreadLocal<SimpleDateFormat>() {
        @Override
        protected SimpleDateFormat initialValue() {
            return new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        }
    };

}
```

上面的代码使用到了ThreadLocal，将SimpleDateFormat对象用ThreadLocal包装了一层，使得多个线程内部都有一个SimpleDateFormat对象副本，每个线程使用自己的SimpleDateFormat，这样就不会产生线程安全问题了。

那么以上介绍的是ThreadLocal的第一大场景的使用，也就是利用到了ThreadLocal的`initialValue()`方法，使得每个线程内都具备了一个SimpleDateFormat副本。

接下来我们一起来看看ThreadLocal的第二大使用场景，在使用之前，我们先把两个场景总结如下：

- 场景1：每个线程需要一个独享的对象，通常是工具类，比如典型的SimpleDateFormat和Random等。
- 场景2：每个线程内需要保存线程内的全局变量，这样线程在执行多个方法的时候，可以在多个方法中获取这个线程内的全局变量，避免了过度参数传递的问题。

那么如何理解第二个问题呢？我们还是使用一个Demo来理解：假设有一个学生类，类成员变量包括姓名，性别，成绩，我们需要定义三个方法来分别获取学生的姓名、性别和成绩，那么我们传统的做法是：

```
public class ThreadLocalUsage05 {

    public static void main(String[] args) {
        Student student = init();
        new NameService().getName(student);
        new SexService().getSex(student);
        new ScoreService().getScore(student);
    }

    private static Student init() {
        Student student = new Student();
        student.name = "Lemon";
        student.sex = "female";
        student.score = "100";
        return student;
    }

}

class Student {

    /**
     * 姓名、性别、成绩
     */
    String name;
    String sex;
    String score;

}

class NameService {

    public void getName(Student student) {
        System.out.println(student.name);
    }

}

class SexService {

    public void getSex(Student student) {
        System.out.println(student.sex);
    }

}

class ScoreService {

    public void getScore(Student student) {
        System.out.println(student.score);
    }

}
```

从上面的代码中可以看出，每个类的方法都需要传递学生的信息才可以获取到正确的信息，这样做能达到目的

但是每个方法都需要学生信息作为入参，这样未免有点繁琐，且在实际使用中通常在每个方法里面还需要对每个学生信息进行判空，这样的代码显得十分冗余，不利于维护。

也许有人会说，我们可以将学生信息存入到一个共享的Map中，需要学生信息的时候直接去Map中取，如下图所示：

![在这里插入图片描述](http://www.hollischuang.com/wp-content/uploads/2020/05/2.png)

其实这也是一种思路，但是在并发环境下，如果要使用Map，那么就需要使用同步的Map，比如ConcurrentHashMap或者Collections.SynchronizedMap()，前者底层用的是CAS和锁机制，后者直接使用的是synchronized，性能也不尽人意。

其实，我们可以将学生信息存入到ThreadLocal中，在同一个线程中，那么直接从ThreadLocal中获取需要的信息即可！案例代码如下所示：

```
public class ThreadLocalUsage05 {

    public static void main(String[] args) {
        init();
        new NameService().getName();
        new SexService().getSex();
        new ScoreService().getScore();
    }

    private static void init() {
        Student student = new Student();
        student.name = "Lemon";
        student.sex = "female";
        student.score = "100";
        ThreadLocalProcessor.studentThreadLocal.set(student);
    }

}

class ThreadLocalProcessor {

    public static ThreadLocal<Student> studentThreadLocal = new ThreadLocal<>();

}

class Student {

    /**
     * 姓名、性别、成绩
     */
    String name;
    String sex;
    String score;

}

class NameService {

    public void getName() {
        System.out.println(ThreadLocalProcessor.studentThreadLocal.get().name);
    }

}

class SexService {

    public void getSex() {
        System.out.println(ThreadLocalProcessor.studentThreadLocal.get().sex);
    }

}

class ScoreService {

    public void getScore() {
        System.out.println(ThreadLocalProcessor.studentThreadLocal.get().score);
    }

}
```

上面的代码就省去了频繁的传递参数，也没有使用到锁机制，同样满足了需求，思想其实和上面将学生信息存储到Map中的思想差不多，只不过这里不是将学生信息存储到Map中，而是存储到了ThreadLocal中，原理图如下所示：

![在这里插入图片描述](http://www.hollischuang.com/wp-content/uploads/2020/05/3.png)

那么总结这两种用法，通常分别用在不同的场景里：

- 场景一：通常多线程之间需要拥有同一个对象的副本，那么通常就采用initialValue()方法进行初始化，直接将需要拥有的对象存储到ThreadLocal中。
- 场景二：如果多个线程中存储不同的信息，为了方便在其他方法里面获取到信息，那么这种场景适合使用set()方法。例如，在拦截器生成的用户信息，用ThreadLocal.set直接放入到ThreadLocal中去，以便在后续的方法中取出来使用。

#### 三、理解ThreadLocal原理

##### 3.1 理解ThreadLocalMap数据结构

通过本文的第二小节的介绍，相信大家基本上可以掌握ThreadLocal的基本使用方法，接下来，我们来一起阅读ThreadLocal源码，从源码角度来真正理解ThreadLocal。

在阅读源码之前，我们一起来看看一张图片：

![在这里插入图片描述](http://www.hollischuang.com/wp-content/uploads/2020/05/4.png)

上图中基本描述出了Thread、ThreadLocalMap以及ThreadLocal三者之间的包含关系。Thread类对象中维护了ThreadLocalMap成员变量，而ThreadLocalMap维护了以ThreadLocal为key，需要存储的数据为value的Entry数组。这是它们三者之间的基本包含关系，我们需要进一步到源码中寻找踪迹。

查看Thread类，内部维护了两个变量，threadLocals和inheritableThreadLocals，它们的默认值是null，它们的类型是`ThreadLocal.ThreadLocalMap`，也就是ThreadLocal类的一个静态内部类ThreadLocalMap。

在静态内部类ThreadLocalMap维护一个数据结构类型为Entry的数组，节点类型如下代码所示：

```
static class Entry extends WeakReference<ThreadLocal<?>> {
    /** The value associated with this ThreadLocal. */
    Object value;

    Entry(ThreadLocal<?> k, Object v) {
        super(k);
        value = v;
    }
}
```

从源码中我们可以看到，Entry结构实际上是继承了一个ThreadLocal类型的弱引用并将其作为key，value为Object类型。这里使用弱引用是否会产生问题，我们这里暂时不讨论，在文章结束的时候一起讨论一下，暂且可以理解key就是ThreadLocal对象。对于ThreadLocalMap，我们一起来了解一下其内部的变量：

```
// 默认的数组初始化容量
private static final int INITIAL_CAPACITY = 16;
// Entry数组，大小必须为2的幂
private Entry[] table;
// 数组内部元素个数
private int size = 0;
// 数组扩容阈值，默认为0，创建了ThreadLocalMap对象后会被重新设置
private int threshold;
```

这几个变量和HashMap中的变量十分类似，功能也类似。

ThreadLocalMap的构造方法如下所示：

```
/**
 * Construct a new map initially containing (firstKey, firstValue).
 * ThreadLocalMaps are constructed lazily, so we only create
 * one when we have at least one entry to put in it.
 */
ThreadLocalMap(ThreadLocal<?> firstKey, Object firstValue) {
    // 初始化Entry数组，大小 16
    table = new Entry[INITIAL_CAPACITY];
    // 用第一个键的哈希值对初始大小取模得到索引，和HashMap的位运算代替取模原理一样
    int i = firstKey.threadLocalHashCode & (INITIAL_CAPACITY - 1);
    // 将Entry对象存入数组指定位置
    table[i] = new Entry(firstKey, firstValue);
    size = 1;
    // 初始化扩容阈值，第一次设置为10
    setThreshold(INITIAL_CAPACITY);
}
```

从构造方法的注释中可以了解到，该构造方法是懒加载的，只有当我们创建一个Entry对象并需要放入到Entry数组的时候才会去初始化Entry数组。

分析到这里，也许我们都有一个疑问，平常使用ThreadLocal功能都是借助ThreadLocal对象来操作的，比如set、get、remove等，使用上都屏蔽了ThreadLocalMap的API，那么到底是如何做到的呢？我们一起继续看下面的代码。

##### 3.2 理解ThreadLocal类set方法

试想我们一个请求对应一个线程，我们可能需要在请求到达拦截器之后，可能需要校验当前请求的用户信息，那么校验通过的用户信息通常都放入到ThreadLocalMap中，以方便在后续的方法中直接从ThreadLocalMap中获取

但是我们并没有直接操作ThreadLocalMap来存取数据，而是通过一个静态的ThreadLocal变量来操作，我们从上面的图可以看出，ThreadLocalMap中存储的键其实就是ThreadLocal的弱引用所关联的对象，那么键是如何操作类似HashMap的值的呢？我们一起来分析一下set方法：

```
public void set(T value) {
    // 首先获取调用此方法的线程
    Thread t = Thread.currentThread();
    // 将线程传递到getMap方法中来获取ThreadLocalMap，其实就是获取到当前线程的成员变量threadLocals所指向的ThreadLocalMap对象
    ThreadLocalMap map = getMap(t);
    // 判断Map是否为空
    if (map != null)
        // 如果Map为不空，说明当前线程内部已经有ThreadLocalMap对象了，那么直接将本ThreadLocal对象作为键，存入的value作为值存储到ThreadLocalMap中
        map.set(this, value);
    else
        // 创建一个ThreadLocalMap对象并将值存入到该对象中，并赋值给当前线程的threadLocals成员变量
        createMap(t, value);
}

// 获取到当前线程的成员变量threadLocals所指向的ThreadLocalMap对象
ThreadLocalMap getMap(Thread t) {
    return t.threadLocals;
}

// 创建一个ThreadLocalMap对象并将值存入到该对象中，并赋值给当前线程的threadLocals成员变量
void createMap(Thread t, T firstValue) {
    t.threadLocals = new ThreadLocalMap(this, firstValue);
}
```

上面的set方法是ThreadLocal的set方法，就是为了将指定的值存入到指定线程的threadLocals成员变量所指向的ThreadLocalMap对象中，那么具体是如何存取的，其实调用的还是ThreadLocalMap的set方法，源码分析如下所示：

```
private void set(ThreadLocal<?> key, Object value) {

    // We don't use a fast path as with get() because it is at
    // least as common to use set() to create new entries as
    // it is to replace existing ones, in which case, a fast
    // path would fail more often than not.

    Entry[] tab = table;
    int len = tab.length;
    // 计算当前ThreadLocal对象作为键在Entry数组中的下标索引
    int i = key.threadLocalHashCode & (len-1);

    // 线性遍历，首先获取到指定下标的Entry对象，如果不为空，则进入到for循环体内，
    // 判断当前的ThreadLocal对象是否是同一个对象，如果是，那么直接进行值替换，并结束方法，
    // 如果不是，再判断当前Entry的key是否失效，如果失效，则直接将失效的key和值进行替换。
    // 这两点都不满足的话，那么就调用nextIndex方法进行搜寻下一个合适的位置，进行同样的操作，
    // 直到找到某个位置，内部数据为空，也就是Entry为null，那么就直接将键值对设置到这个位置上。
    // 最后判断是否达到了扩容的条件，如果达到了，那么就进行扩容。
    for (Entry e = tab[i]; e != null; e = tab[i = nextIndex(i, len)]) {
        ThreadLocal<?> k = e.get();

        if (k == key) {
            e.value = value;
            return;
        }

        if (k == null) {
            replaceStaleEntry(key, value, i);
            return;
        }
    }

    tab[i] = new Entry(key, value);
    int sz = ++size;
    if (!cleanSomeSlots(i, sz) && sz >= threshold)
        rehash();
}
```

这里的代码核心的地方就是for循环这一块，代码上面加了详细的注释，这里在复述一遍：

线性遍历，首先获取到指定下标的Entry对象，如果不为空，则进入到for循环体内，判断当前的ThreadLocal对象是否是同一个对象

如果是，那么直接进行值替换，并结束方法。如果不是，再判断当前Entry的key是否失效，如果失效，则直接将失效的key和值进行替换。

这两点都不满足的话，那么就调用nextIndex方法进行搜寻下一个合适的位置，进行同样的操作，直到找到某个位置，内部数据为空，也就是Entry为null，那么就直接将键值对设置到这个位置上。最后判断是否达到了扩容的条件，如果达到了，那么就进行扩容。

这里有两点需要注意：一是nextIndex方法，二是key失效，这里先解释第一个注意点，第二个注意点涉及到弱引用JVM GC问题，文章最后做出解释。

nextIndex方法的具体代码如下所示：

```
private static int nextIndex(int i, int len) {
    return ((i + 1 < len) ? i + 1 : 0);
}
```

其实就是寻找下一个合适位置，找到最后一个后还不合适的话，那么从数组头部重新开始找，且一定可以找到，因为存在扩容阈值，数组必定有冗余的位置存放当前键值对所对应的Entry对象。其实nextIndex方法就是大名鼎鼎的『`开放寻址法`』的应用。

这一点和HashMap不一样，HashMap存储HashEntry对象发生哈希冲突的时候采用的是链表方式进行存储，而这里是去寻找下一个合适的位置，思想就是『`开放寻址法`』。

##### 3.3 理解ThreadLocal类get方法

在实际的开发中，我们往往需要在代码中调用ThreadLocal对象的get方法来获取存储在ThreadLocalMap中的数据，具体的源码如下所示：

```
public T get() {
    // 获取当前线程的ThreadLocalMap对象
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    if (map != null) {
        // 如果map不为空，那么尝试获取Entry数组中以当前ThreadLocal对象为键的Entry对象
        ThreadLocalMap.Entry e = map.getEntry(this);
        if (e != null) {
            // 如果找到，那么直接返回value
            @SuppressWarnings("unchecked")
            T result = (T)e.value;
            return result;
        }
    }
    // 如果Map为空或者在Entry数组中没有找到以当前ThreadLocal对象为键的Entry对象，
    // 那么就在这里进行值初始化，值初始化的过程是将null作为值，当前ThreadLocal对象作为键，
    // 存入到当前线程的ThreadLocalMap对象中
    return setInitialValue();
}

// 值初始化过程
private T setInitialValue() {
    T value = initialValue();
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    if (map != null)
        map.set(this, value);
    else
        createMap(t, value);
    return value;
}
```

值初始化过程是这样的一个过程，如果调用新的ThreadLocal对象的get方法，那么在当前线程的成员变量threadLocals中必定不存在key为当前ThreadLocal对象的Entry对象，那么这里值初始话就将此ThreadLocal对象作为key，null作为值存储到ThreadLocalMap的Entry数组中。

##### 3.4 理解ThreadLocal的remove方法

使用ThreadLocal这个工具的时候，一般提倡使用完后及时清理存储在ThreadLocalMap中的值，防止内存泄露。这里一起来看下ThreadLocal的remove方法。

```
public void remove() {
    ThreadLocalMap m = getMap(Thread.currentThread());
    if (m != null)
        m.remove(this);
}

// 具体的删除指定的值，也是通过遍历寻找，找到就删除，找不到就算了
private void remove(ThreadLocal<?> key) {
    Entry[] tab = table;
    int len = tab.length;
    int i = key.threadLocalHashCode & (len-1);
    for (Entry e = tab[i]; e != null; e = tab[i = nextIndex(i, len)]) {
        if (e.get() == key) {
            e.clear();
            expungeStaleEntry(i);
            return;
        }
    }
}
```

看了这么多ThreadLocal的源码实现，其实原理还是很简单的，基本上可以说是一看就懂，理解ThreadLocal原理，其实就是需要理清Thread、ThreadLocal、ThreadLocalMap三者之间的关系

这里加以总结：线程类Thread内部持有ThreadLocalMap的成员变量，而ThreadLocalMap是ThreadLocal的内部类，ThreadLocal操作了ThreadLocalMap对象内部的数据，对外暴露的都是ThreadLocal的方法API，隐藏了ThreadLocalMap的具体实现，理清了这一点，ThreadLocal就很容易理解了。

#### 四、理解ThreadLocalMap内存泄露问题

这里所说的ThreadLocal的内存泄露问题，其实都是从ThreadLocalMap中的一段代码说起的，这段代码就是Entry的构造方法：

```
static class Entry extends WeakReference<ThreadLocal<?>> {
    /** The value associated with this ThreadLocal. */
    Object value;

    Entry(ThreadLocal<?> k, Object v) {
        super(k);
        value = v;
    }
}
```

这里简单介绍一下Java内的四大引用：

- 强引用：Java中默认的引用类型，一个对象如果具有强引用那么只要这种引用还存在就不会被回收。比如`String str = new String("Hello ThreadLocal");`，其中str就是一个强引用，当然，一旦强引用出了其作用域，那么强引用随着方法弹出线程栈，那么它所指向的对象将在合适的时机被JVM垃圾收集器回收。
- 软引用：如果一个对象具有软引用，在JVM发生内存溢出之前（即内存充足够使用），是不会GC这个对象的；只有到JVM内存不足的时候才会调用垃圾回收期回收掉这个对象。软引用和一个引用队列联合使用，如果软引用所引用的对象被回收之后，该引用就会加入到与之关联的引用队列中。
- 弱引用：这里讨论ThreadLocalMap中的Entry类的重点，如果一个对象只具有弱引用，那么这个对象就会被垃圾回收器回收掉（被弱引用所引用的对象只能生存到下一次GC之前，当发生GC时候，无论当前内存是否足够，弱引用所引用的对象都会被回收掉）。弱引用也是和一个引用队列联合使用，如果弱引用的对象被垃圾回收期回收掉，JVM会将这个引用加入到与之关联的引用队列中。若引用的对象可以通过弱引用的get方法得到，当引用的对象被回收掉之后，再调用get方法就会返回null。
- 虚引用：虚引用是所有引用中最弱的一种引用，其存在就是为了将关联虚引用的对象在被GC掉之后收到一个通知。

我们从ThreadLocal的内部静态类Entry的代码设计可知，ThreadLocal的引用k通过构造方法传递给了Entry类的父类WeakReference的构造方法，从这个层面来说，可以理解ThreadLocalMap中的键是ThreadLocal的所引用。

当一个线程调用ThreadLocal的set方法设置变量的时候，当前线程的ThreadLocalMap就会存放一个记录，这个记录的键为ThreadLocal的弱引用，value就是通过set设置的值，这个value值被强引用。

如果当前线程一直存在且没有调用该ThreadLocal的remove方法，如果这个时候别的地方还有对ThreadLocal的引用，那么当前线程中的ThreadLocalMap中会存在对ThreadLocal变量的引用和value对象的引用，是不会释放的，就会造成内存泄漏。

考虑这个ThreadLocal变量没有其他强依赖，如果当前线程还存在，由于线程的ThreadLocalMap里面的key是弱引用，所以当前线程的ThreadLocalMap里面的ThreadLocal变量的弱引用在垃圾回收的时候就被回收，但是对应的value还是存在的这就可能造成内存泄漏（因为这个时候ThreadLocalMap会存在key为null但是value不为null的entry项）。

总结：ThreadLocalMap中的Entry的key使用的是ThreadLocal对象的弱引用，在没有其他地方对ThreadLocal依赖，ThreadLocalMap中的ThreadLocal对象就会被回收掉，但是对应的值不会被回收，这个时候Map中就可能存在key为null但是值不为null的项，所以在使用ThreadLocal的时候要养成及时remove的习惯。

**(全文完)**