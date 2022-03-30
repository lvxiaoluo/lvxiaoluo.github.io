# 子线程如何获取父线程 ThreadLocal 的值

```
京东一面」子线程如何获取父线程ThreadLocal的值
```

## 子线程如何获取父线程ThreadLocal的值

![图片](https://mmbiz.qpic.cn/mmbiz_png/TLH3CicPVibrf0AfEb0fyaP4ftXnwqAIiaOLQCye6QMzpFlKjwFFk6vQwMncibymoIKT1DfYgmCsXIfu1qfXbmdO2g/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

想要子线程获取父线程中 ThreadLocal 中的值，需要其子类 InheritableThreadLocal 实现。

测试代码如下：

```
public static void main(String[] args) throws InterruptedException {
    Thread parentParent = new Thread(() -> {
        ThreadLocal<Integer> threadLocal = new ThreadLocal<>();
        threadLocal.set(1);
        InheritableThreadLocal<Integer> inheritableThreadLocal = new InheritableThreadLocal<>();
        inheritableThreadLocal.set(2);

        new Thread(() -> {
            System.out.println("threadLocal=" + threadLocal.get());
            System.out.println("inheritableThreadLocal=" + inheritableThreadLocal.get());
        }).start();
    }, "父线程");
    parentParent.start();
}
```

运行结果如下：

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)子线程获取父线程中 ThreadLocal 中的值

原理如下：

首先我们要知道 Thread类维护了两个ThreadLocalMap

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)

跟进 new Thread() 方法

其构造方法调用了init方法, init方法把inheritThreadLocals值设置为了true

![图片](https://mmbiz.qpic.cn/mmbiz_png/TLH3CicPVibrf0AfEb0fyaP4ftXnwqAIiaO3PeIj5C4ke73ooo6rDl9Zfxkrd4PZxCEtkgENSHb4HhpPDgK4OaoOg/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

继续跟进。

当inheritThreadLocals的值为true并且其父线程的inheritableThreadLocals不为null时, 把其父线程inheritableThreadLocals 赋值给当前线程的inheritableThreadLocals

![图片](https://mmbiz.qpic.cn/mmbiz_png/TLH3CicPVibrf0AfEb0fyaP4ftXnwqAIiaOsSKaJ8fyHsK69FnKiaN6DHKS5D7aMqtM79yAKXAeX5b8Ez9V9O8rGeQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

这就是子线程可以获取到父线程ThreadLocal值的关键。

继续跟进 看看 InheritableThreadLocal 的get() 方法

get()方法没什么好看的，就是ThreadLocal的get()方法。

![图片](https://mmbiz.qpic.cn/mmbiz_png/TLH3CicPVibrf0AfEb0fyaP4ftXnwqAIiaOicFfBBpJAyj126PK3Ds2Qtnic2J7BevsvxsPXovVahuictj3eS7RHO1hA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

注意：InheritableThreadLocal 对ThreadLocal 的getMap()方法进行重写

```
ThreadLocalMap getMap(Thread t) {
 //获取线程自己的变量threadLocals，并绑定到当前调用线程的成员变量threadLocals上
    return t.threadLocals; 
}

void createMap(Thread t, T firstValue) {
    t.threadLocals = new ThreadLocalMap(this, firstValue);
    //创建给ThreadLocalMap的table属性赋值，并且将firstValue放在数组首位。
}
```

createMap方法不仅创建了threadLocals，同时也将要添加的本地变量值添加到了threadLocals中。

InheritableThreadLocal类继承了ThreadLocal类，并重写了childValue、getMap、createMap方法。

其中createMap方法在被调用的时候，创建的是inheritableThreadLocal而不是threadLocals。

同理，getMap方法在当前调用者线程调用get方法的时候返回的也不是threadLocals而是inheritableThreadLocal。