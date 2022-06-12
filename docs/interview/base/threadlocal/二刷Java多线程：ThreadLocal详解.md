# 二刷Java多线程：ThreadLocal详解

### 1、[ThreadLocal](https://so.csdn.net/so/search?q=ThreadLocal&spm=1001.2101.3001.7020)简介

ThreadLocal是一个**以ThreadLocal对象为键、任意对象为值**的[存储结构](https://so.csdn.net/so/search?q=存储结构&spm=1001.2101.3001.7020)，提供了线程本地变量，也就是如果创建了一个ThreadLocal变量，那么访问这个变量的每个线程都会有这个变量的一个本地副本。当多个线程操作这个变量时，实际操作的是自己本地内存里面的变量，从而避免了线程安全问题。创建一个ThreadLocal变量后，每个线程都会复制一个变量到自己的本地内存
![在这里插入图片描述](https://img-blog.csdnimg.cn/20190922152347884.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQwMzc4MDM0,size_16,color_FFFFFF,t_70)
**ThreadLocal的内部结构图如下**：
![在这里插入图片描述](https://img-blog.csdnimg.cn/20190922152359267.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQwMzc4MDM0,size_16,color_FFFFFF,t_70)

### 2、ThreadLocal使用示例

```java
public class ThreadLocalTest {
    static void print(String str) {
        System.out.println(str + ":" + localVariable.get());
        localVariable.remove();
    }

    static ThreadLocal<String> localVariable = new ThreadLocal<String>();

    public static void main(String[] args) {
        new Thread(new Runnable() {
            public void run() {
                localVariable.set("threadOne local variable");
                print("threadOne");
                System.out.println("threadOne remove after :" + localVariable.get());
            }
        }).start();

        new Thread(new Runnable() {
            public void run() {
                localVariable.set("threadTwo local variable");
                print("threadTwo");
                System.out.println("threadTwo remove after :" + localVariable.get());
            }
        }).start();
    }
}
1234567891011121314151617181920212223242526
```

运行结果：

```
threadOne:threadOne local variable
threadOne remove after :null
threadTwo:threadTwo local variable
threadTwo remove after :null
1234
```

### 3、ThreadLocal的实现原理

![在这里插入图片描述](https://img-blog.csdnimg.cn/20190922152409943.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQwMzc4MDM0,size_16,color_FFFFFF,t_70)
Thread类中有一个threadLocals和一个inheritableThreadLocals，它们都是ThreadLocalMap类型的变量，而ThreadLocalMap是一个定制化的HashMap。在默认情况下，每个线程中的这两个变量都为null，只有当前线程第一次调用ThreadLocal的set()或者get()方法时才会创建它们。其实每个线程的本地变量不是存放在ThreadLocal实例里面，而是存放在调用线程的threadLocals变量里面。也就是说，ThreadLocal类型的本地变量存放在具体的线程内存空间中。ThreadLocal就是一个工具壳，它通过set()方法把value值放入调用线程的threadLocals里面并存放起来，当调用线程调用它的get()方法时，再从当前线程的threadLocals变量里面将其拿出来使用。如果调用线程一直不终止，那么这个本地变量会一直存放在调用线程的threadLocals变量里面，所以当不需要使用本地变量时可以通过调用ThreadLocal变量的remove()方法，从当前线程的threadLocals里面删除该本地变量

#### 1）、void set(T value)

```java
    public void set(T value) {
        //获取当前线程
        Thread t = Thread.currentThread();
        //找到当前线程对应的threadLocals变量
        ThreadLocalMap map = getMap(t);
        if (map != null)
            map.set(this, value);
        else
            //第一次调用就创建当前线程对应的threadLocals变量
            createMap(t, value);
    }

    ThreadLocalMap getMap(Thread t) {
        //获取线程自己的变量threadLocals,threadLocals变量被绑定到了线程的成员变量上
        return t.threadLocals;
    }

    void createMap(Thread t, T firstValue) {
        //创建当前线程的threadLocals变量
        t.threadLocals = new ThreadLocalMap(this, firstValue);
    }
123456789101112131415161718192021
```

#### 2）、T get()

```java
    public T get() {
        //获取当前线程
        Thread t = Thread.currentThread();
        //获取当前线程的threadLocals变量
        ThreadLocalMap map = getMap(t);
        if (map != null) {
            //如果threadLocals不为null,则返回对应本地变量的值
            ThreadLocalMap.Entry e = map.getEntry(this);
            if (e != null) {
                @SuppressWarnings("unchecked")
                T result = (T)e.value;
                return result;
            }
        }
        //threadLocals为空则初始化当前线程的threadLocals成员变量
        return setInitialValue();
    }

    private T setInitialValue() {
        //初始化为null
        T value = initialValue();
        Thread t = Thread.currentThread();
        ThreadLocalMap map = getMap(t);
        //如果当前线程的threadLocals变量不为null
        if (map != null)
            map.set(this, value);
        //如果当前线程的threadLocals变量为null
        else
            createMap(t, value);
        return value;
    }

    protected T initialValue() {
        return null;
    }
1234567891011121314151617181920212223242526272829303132333435
```

#### 3）、void remove()

```java
     public void remove() {
         ThreadLocalMap m = getMap(Thread.currentThread());
         if (m != null)
             m.remove(this);
     }
12345
```

如果当前线程的threadLocals变量不为空，则删除当前线程中指定ThreadLocal实例的本地变量

#### 4）、ThreadLocalMap

ThreadLocalMap是ThreadLocal的内部类，没有实现Map接口，用独立的方式实现了Map的功能，其内部的Entry也独立实现的
![在这里插入图片描述](https://img-blog.csdnimg.cn/20190922152419855.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQwMzc4MDM0,size_16,color_FFFFFF,t_70)
在ThreadLocalMap中，也是用Entry来保存K-V结构数据的，但是Entry中key只能是ThreadLocal对象

```java
        static class Entry extends WeakReference<ThreadLocal<?>> {
            Object value;

            Entry(ThreadLocal<?> k, Object v) {
                super(k);
                value = v;
            }
        }
12345678
```

**Entry继承自WeakReference（弱引用，生命周期只能存活到下次GC前），但只有key是弱引用类型的，value并非弱引用**

```java
        private static final int INITIAL_CAPACITY = 16;

		ThreadLocalMap(ThreadLocal<?> firstKey, Object firstValue) {
            table = new Entry[INITIAL_CAPACITY];
            int i = firstKey.threadLocalHashCode & (INITIAL_CAPACITY - 1);
            table[i] = new Entry(firstKey, firstValue);
            size = 1;
            setThreshold(INITIAL_CAPACITY);
        }

        private void setThreshold(int len) {
            threshold = len * 2 / 3;
        }
12345678910111213
```

从ThreadLocalMap的构造函数可以得知，**ThreadLocalMap初始化容量为16，负载因子为2/3**

和HashMap的最大的不同在于，ThreadLocalMap结构非常简单，没有next引用，也就是说ThreadLocalMap中解决Hash冲突的方式并非链表的方式，而是采用线性探测的方式。所谓线性探测，就是根据初始key的hashcode值确定元素在table数组中的位置，如果发现这个位置上已经有其他key值的元素被占用，则利用固定的算法寻找一定步长的下个位置，依次判断，直至找到能够存放的位置

```java
        private void set(ThreadLocal<?> key, Object value) {
            Entry[] tab = table;
            int len = tab.length;
            int i = key.threadLocalHashCode & (len-1);

            for (Entry e = tab[i];
                 e != null;
                 e = tab[i = nextIndex(i, len)]) {
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

		private static int nextIndex(int i, int len) {
            return ((i + 1 < len) ? i + 1 : 0);
        }
123456789101112131415161718192021222324252627282930
```

在插入过程中，根据ThreadLocal对象的hash值，定位到table中的位置i，过程如下

- 如果当前位置是空的，那么正好，就初始化一个Entry对象放在位置i上
- 位置i已有对象，如果这个Entry对象的key正好是即将设置的key，那么覆盖value
- 位置i的对象，和即将设置的key没关系，那么只能找下一个空位置

#### 5）、ThreadLocalMap内存泄露问题

![在这里插入图片描述](https://img-blog.csdnimg.cn/20190923192952167.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQwMzc4MDM0,size_16,color_FFFFFF,t_70)
上图中，实线代表强引用，虚线代表的是弱引用，如果threadLocal外部强引用被置为null（`threadLocalInstance==null`）的话，threadLocal实例就没有一条引用链路可达，很显然在GC（垃圾回收）的时候势必会被回收，因此entry就存在key为null的情况，无法通过一个Key为null去访问到该entry的value。同时，就存在了这样一条引用链：`threadRef->currentThread->threadLocalMap->entry->valueRef->valueMemory`，导致在垃圾回收的时候进行可达性分析的时候，value可达从而不会被回收掉，但是该value永远不能被访问到，这样就存在了**内存泄漏**。当然，如果线程执行结束后，threadLocal和threadRef会断掉，因此threadLocal、threadLocalMap、entry都会被回收掉。可是，在实际使用中我们都是会用线程池去维护我们的线程，比如在`Executors.newFixedThreadPool()`时创建线程的时候，为了复用线程是不会结束的，所以threadLocal内存泄漏就值得我们关注

**ThreadLocalMap的设计中已经做出了哪些改进？**

ThreadLocalMap中的get()和set()方法都针对内存泄露问题做了相应的处理，下文为了叙述，针对key为null的entry，源码注释为stale entry，就称之为“脏entry”

**ThreadLocalMap的set()方法**：

```java
        private void set(ThreadLocal<?> key, Object value) {

            Entry[] tab = table;
            int len = tab.length;
            int i = key.threadLocalHashCode & (len-1);

            for (Entry e = tab[i];
                 e != null;
                 e = tab[i = nextIndex(i, len)]) {
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
123456789101112131415161718192021222324252627
```

在该方法中针对脏entry做了这样的处理：

- 如果当前table[i]不为空的话说明hash冲突就需要向后环形查找，若在查找过程中遇到脏entry就通过replaceStaleEntry()进行处理
- 如果当前table[i]为空的话说明新的entry可以直接插入，但是插入后会调用cleanSomeSlots()方法检测并清除脏entry

**当我们调用threadLocal的get()方法**时，当table[i]不是和所要找的key相同的话，会继续通过threadLocalMap的getEntryAfterMiss()方法向后环形去找

```java
        private Entry getEntry(ThreadLocal<?> key) {
            int i = key.threadLocalHashCode & (table.length - 1);
            Entry e = table[i];
            if (e != null && e.get() == key)
                return e;
            else
                return getEntryAfterMiss(key, i, e);
        }

        private Entry getEntryAfterMiss(ThreadLocal<?> key, int i, Entry e) {
            Entry[] tab = table;
            int len = tab.length;

            while (e != null) {
                ThreadLocal<?> k = e.get();
                if (k == key)
                    return e;
                if (k == null)
                    expungeStaleEntry(i);
                else
                    i = nextIndex(i, len);
                e = tab[i];
            }
            return null;
        }
12345678910111213141516171819202122232425
```

当key为null的时候，即遇到脏entry也会调用expungeStleEntry()对脏entry进行清理

**当我们调用threadLocal.remove()方法时候**，实际上会调用threadLocalMap的remove方法

```java
        private void remove(ThreadLocal<?> key) {
            Entry[] tab = table;
            int len = tab.length;
            int i = key.threadLocalHashCode & (len-1);
            for (Entry e = tab[i];
                 e != null;
                 e = tab[i = nextIndex(i, len)]) {
                if (e.get() == key) {
                    e.clear();
                    expungeStaleEntry(i);
                    return;
                }
            }
        }
1234567891011121314
```

同样的可以看出，当遇到了key为null的脏entry的时候，也会调用expungeStaleEntry()清理掉脏entry

从以上set()、get()、remove()方法看出，**在ThreadLocal的生命周期里，针对ThreadLocal存在的内存泄漏的问题，都会通过expungeStaleEntry()、cleanSomeSlots()、replaceStaleEntry()这三个方法清理掉key为null的脏entry**

想要更加深入学习ThreadLocal内存泄漏问题可以查看[这篇文章](https://www.jianshu.com/p/dde92ec37bd1)

**小结**：

![img](https://img-blog.csdnimg.cn/20190922152752818.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQwMzc4MDM0,size_16,color_FFFFFF,t_70)
在每个线程内部都有一个名为threadLocals的成员变量，该变量的类型为HashMap，其中key为我们定义的ThreadLocal变量的this引用，value则为我们使用set方法设置的值。每个线程的本地变量存放在线程自己的内存变量threadLocals中，如果当前线程一直不消亡，那么这些本地变量会一直存在，所以可能会造成内存溢岀，因 此使用完毕后要记得调用ThreadLocal的remove()方法删除对应线程的threadLocals中的本地变量

### 4、InheritableThreadLocal类

**同一个ThreadLocal变量在父线程中被设置值后，在子线程中是获取不到的。而子类InheritableThreadLocal提供了一个特性，就是让子线程可以访问在父线程中设置的本地变量**

```java
public class InheritableThreadLocal<T> extends ThreadLocal<T> {
    //(1)
    protected T childValue(T parentValue) {
        return parentValue;
    }

    //(2)
    ThreadLocalMap getMap(Thread t) {
       return t.inheritableThreadLocals;
    }
    
	//(3)
    void createMap(Thread t, T firstValue) {
        t.inheritableThreadLocals = new ThreadLocalMap(this, firstValue);
    }
}
12345678910111213141516
```

从上面InheritableThreadLocal的源码中可知，InheritableThreadLocal继承了ThreadLocal，并重写了三个方法。由代码(3)可知，InheritableThreadLocal重写了createMap()方法，那么现在当第一次调用set()方法时，创建的是当前线程的inheritableThreadLocals变量的实例而不再是threadLocals。由代码(2)可知，当调用get()方法获取当前线程内部的map变量时，获取的是inheritableThreadLocals而不再是threadLocals

综上可知，在InheritableThreadLocal的世界里，变量inheritableThreadLocals替代了threadLocals

下面我们看一下重写的代码(1)何时执行，以及如何让子线程可以访问父线程的本地变量。这要从创建Thread的代码说起，打开Thread类的默认构造函数

```java
    public Thread(Runnable target) {
        init(null, target, "Thread-" + nextThreadNum(), 0);
    }

    private void init(ThreadGroup g, Runnable target, String name,
                      long stackSize) {
        init(g, target, name, stackSize, null, true);
    }

    private void init(ThreadGroup g, Runnable target, String name,
                      long stackSize, AccessControlContext acc,
                      boolean inheritThreadLocals) {
        if (name == null) {
            throw new NullPointerException("name cannot be null");
        }

        this.name = name;

        //获取当前线程,也就是父线程
        Thread parent = currentThread();
        SecurityManager security = System.getSecurityManager();
        if (g == null) {
            
            if (security != null) {
                g = security.getThreadGroup();
            }

            if (g == null) {
                g = parent.getThreadGroup();
            }
        }

        g.checkAccess();

        if (security != null) {
            if (isCCLOverridden(getClass())) {
                security.checkPermission(SUBCLASS_IMPLEMENTATION_PERMISSION);
            }
        }

        g.addUnstarted();

        this.group = g;
        this.daemon = parent.isDaemon();
        this.priority = parent.getPriority();
        if (security == null || isCCLOverridden(parent.getClass()))
            this.contextClassLoader = parent.getContextClassLoader();
        else
            this.contextClassLoader = parent.contextClassLoader;
        this.inheritedAccessControlContext =
                acc != null ? acc : AccessController.getContext();
        this.target = target;
        setPriority(priority);
        //如果父线程的inheritableThreadLocals变量不为null
        if (inheritThreadLocals && parent.inheritableThreadLocals != null)
			//设置子线程中的inheritableThreadLocals变量
            this.inheritableThreadLocals =
                ThreadLocal.createInheritedMap(parent.inheritableThreadLocals);
        
        this.stackSize = stackSize;

        tid = nextThreadID();
    }

    static ThreadLocalMap createInheritedMap(ThreadLocalMap parentMap) {
        return new ThreadLocalMap(parentMap);
    }
12345678910111213141516171819202122232425262728293031323334353637383940414243444546474849505152535455565758596061626364656667
```

在createlnheritedMap内部使用父线程的inheritableThreadLocals变量作为构造函数创建了一个新的ThreadLocalMap变量，然后赋值给了子线程的inheritableThreadLocals变量

**小结**：

InheritableThreadLocal类通过重写代码(2)和(3)让本地变量保存到了具体线程的inheritableThreadLocals变量里面，那么线程在通过InheritableThreadLocal类实例的set()或者get()方法设置变量时，就会创建当前线程的inheritableThreadLocals变量。当父线程创建子线程时，构造函数会把父线程中inheritableThreadLocals变量里面的本地变量复制一份保存到子线程的inheritableThreadLocals变量里面

参考：

https://www.jianshu.com/p/98b68c97df9b

https://blog.csdn.net/wsm0712syb/article/details/51025111

https://www.jianshu.com/p/dde92ec37bd1