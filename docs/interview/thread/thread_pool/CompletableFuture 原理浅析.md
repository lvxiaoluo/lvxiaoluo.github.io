# CompletableFuture 原理浅析

Java8新增了`CompletableFuture` 提供对异步计算的支持，可以通过回调的方式处理计算结果，CompletableFuture 类实现了`CompletionStage`和`Future`接口，所以还可以像之前使用Future那样使用CompletableFuture ，尽管已不再推荐这样用了。

> 试想下这个场景：要执行一个任务逻辑（交给另一个线程处理），并针对任务结果转换，最后执行打印操作，那么该如完成呢？一种是使用Future.get获取任务结果并执行转换逻辑，最后执行打印操作，有没有像stream那样的处理方式呢？借助CompletableFuture的话，实现代码如下：

```java
CompletableFuture
        .supplyAsync(() -> "000")
        .thenApply(s -> s.length()) // Function
        .whenComplete((integer, throwable) -> System.out.println(integer));
```

从上述的示例代码，我们可以大致分析下`CompletableFuture`的执行流程，首先`CompletableFuture`会异步执行supply任务，当supply任务执行结束时会自动执行对应的计算s.length()逻辑，这里问题来了？

当前调用thenApply方法的线程（这里是main线程）会对CompletableFuture提交Function（对应的是计算s.length()逻辑），那么到底是哪个线程执行的计算s.length()逻辑呢？由于supply任务是由其他线程来执行的（这里对应的是ForkJoin线程），当main线程调用thenApply方法时，不能确定supply任务是否执行完毕的！因此这时就要分2种情况：

- 如果supply任务已经执行完毕，那么就需要当前main线程来执行s.length()逻辑；
- 如果supply任务还未执行完毕，显然这时候main线程需要将Function记录到CompletableFuture中，这样当ForkJoin线程执行完supply任务时可以执行s.length()逻辑，这时就是 ForkJoin线程 来执行的。

对于上述的两种情况测试代码如下：

```java
CompletableFuture
        .completedFuture("000")
        .thenApply(r -> r)
        .whenComplete((r, e) -> System.out.println(format(r)));

CompletableFuture
        .supplyAsync(() -> {
            LockSupport.parkNanos(TimeUnit.MILLISECONDS.toNanos(10));
            return "111";
        })
        .thenApply(r->r)
        .whenComplete((r, e) -> System.out.println(format(r))); 

private static String format(String msg) {
    return String.format("[%s] %s", Thread.currentThread().getName(), msg);
}
```

输出结果如下：

![img](https://pic4.zhimg.com/80/v2-4382539edc884074a024bb7ebff6312b_1440w.jpg)

最后到了whenComplete的逻辑，其实仔细思考下，不管是thenApply还是whenComplete都是接下来要执行的动作，那么它们的执行逻辑应该是类似的，这里不再赘述。

在上述分析完毕后，我们来实际看下CompletableFuture源码，来一探究竟其执行流程，为了方便查看源码debug，使用如下示例代码：

```java
CompletableFuture
  .supplyAsync(() -> {
    // random n millisecond
    int ms = new Random().nextInt(100);
    LockSupport.parkNanos(TimeUnit.MILLISECONDS.toNanos(ms));

    String msg = String.format("supplyAsync %s ms", ms);
    System.out.println(format(msg));
    return msg;
}).thenApply(new Function<String, Integer>() {
    @Override
    public Integer apply(String s) {
        System.out.println(format("thenApply apply s.length()"));
        return s.length();
    }
}).whenComplete(new BiConsumer<Integer, Throwable>() {
    @Override
    public void accept(Integer s, Throwable throwable) {
        System.out.println(format("done " + s));
    }
});
```

输出结果为：

![img](https://pic2.zhimg.com/80/v2-c4b34cd3051b6be6519489f917050185_1440w.png)

下面就按照示例代码照`提交supplyAsync`、`提交thenApply`、`执行whenComplete`流程来进行分析，注意 CompletableFuture 的方法大都是返回新的CompletableFuture对象。

提交supplyAsync时，如果外部未传递线程池那么就会使用默认的ForkJoin线程池，然后线程池中提交AsyncSupply任务，AsyncSupply类继承ForkJoinTask并实现了Runnable，源码如下：

```java
static <U> CompletableFuture<U> asyncSupplyStage(Executor e, Supplier<U> f) {
    CompletableFuture<U> d = new CompletableFuture<U>();
    e.execute(new AsyncSupply<U>(d, f));
    return d;
}

static final class AsyncSupply<T> extends ForkJoinTask<Void> implements Runnable, AsynchronousCompletionTask {
    CompletableFuture<T> dep; Supplier<T> fn;
    AsyncSupply(CompletableFuture<T> dep, Supplier<T> fn) {
        this.dep = dep; this.fn = fn;
    }

    public void run() {
        CompletableFuture<T> d; Supplier<T> f;
        if ((d = dep) != null && (f = fn) != null) {
            dep = null; fn = null;
            if (d.result == null) {
                try {
                    // 执行Supplier方法并设置result
                    d.completeValue(f.get());
                } catch (Throwable ex) {
                    // 异常result
                    d.completeThrowable(ex);
                }
            }
            // 正常执行执行回调
            d.postComplete();
        }
    }
}
```

注意：CompletableFuture 中设置结果和是否执行回调是基于CAS思路来做的。这里正常result和异常result没什么太多好说的，重点关注下postComplete()回调。这里的回调也就是执行 thenApply或者whenComplete添加上的执行回调。

```java
final void postComplete() {
    CompletableFuture<?> f = this; Completion h;
    while ((h = f.stack) != null ||
           (f != this && (h = (f = this).stack) != null)) {
        CompletableFuture<?> d; Completion t;
        if (f.casStack(h, t = h.next)) { // 提取stack第一个元素后cas重置stack
            if (t != null) {
                if (f != this) {
                    // f不等于this表示h.tryFire返回了另一个f
                    pushStack(h);
                    continue;
                }
                h.next = null;    // detach
            }
            // 执行Completion.tryFire回调
            f = (d = h.tryFire(NESTED)) == null ? this : d;
        }
    }
}
```

**注意stack属性，它是一个使用上是栈思路的属性，但实际数据结构是链表，只不过使用上是头插入头读取的**。执行tryFire就是执行对应 thenApply或者whenComplete添加上的执行回调逻辑了。

![img](https://pic4.zhimg.com/80/v2-52154cc7fc88dcb8091143eda21a0793_1440w.jpg)

回到最初的示例代码 thenApply或者whenComplete都往CompletableFuture 中提交的是什么Completion呢？从源码中可以得知thenApply最后提交的是UniApply，whenComplete最后提交的是UniWhenComplete，二者的动作都是将各自对应的Completion提交到当前的CompletableFuture.stack中，其中提交UniWhenComplete的源码如下：

```java
private CompletableFuture<T> uniWhenCompleteStage(Executor e, BiConsumer<? super T, ? super Throwable> f) {
    CompletableFuture<T> d = new CompletableFuture<T>();
    if (e != null || !d.uniWhenComplete(this, f, null)) {
        UniWhenComplete<T> c = new UniWhenComplete<T>(e, d, this, f);
        push(c);
        c.tryFire(SYNC);
    }
    return d;
}
```

注意这里的c.tryFire(SYNC)内部会判断上一个CompletableFuture（src字段）是否已存在结果，如果不存在其内部不会做什么逻辑的。从上图结合 thenApply或者whenComplete 提交的Completion，可以看出每种类型方法都对应了一种Completion来处理，多个Completion会被存放到CompletableFuture.stack数据结构中，这样等到执行回调时就能按照顺序执行了。

CompletableFuture都会对应有一个stack数据结构，也就说针对同一个CompletableFuture对象添加多个Completion，执行Completion回调是按照其逆序进行执行的；针对多个CompletableFuture的添加Completion，是按照CompletableFuture的添加次序来顺序执行的，对应的测试代码如下：

![img](https://pic2.zhimg.com/80/v2-a281d5a0de8d547fbfe5dde226e2c009_1440w.jpg)

### **小结**

CompletableFuture的多个操作，也就是多个CompletableFuture之间，如果上一个CompletableFuture未完成，则会将当前CompletableFuture动作添加到上一个CompletableFuture的stack数据结构中，在任务执行完毕之后，回执行对应stack中的Completion回调方法，每个操作基本上都对应有Completion处理类。

看完文章示例代码，是不是还不太清楚多个CompletableFuture之间的执行流程呢，说实话笔者第一次看的时候也是这样的 :(，下面我们换个例子并给出图示来看：

```java
CompletableFuture<String> f1 = CompletableFuture.supplyAsync(() -> {
    System.out.println("hello world f1");
    sleep(1); // TimeUnit.SECONDS.sleep(1)
    return "result f1";
});
CompletableFuture<String> f2 = f1.thenApply(r -> {
    System.out.println(r);
    sleep(1);
    return "f2";
});
CompletableFuture<String> f3 = f2.thenApply(r -> {
    System.out.println(r);
    sleep(1);
    return "f2";
});

CompletableFuture<String> f4 = f1.thenApply(r -> {
    System.out.println(r);
    sleep(1);
    return "f2";
});
CompletableFuture<String> f5 = f4.thenApply(r -> {
    System.out.println(r);
    sleep(1);
    return "f2";
});
CompletableFuture<String> f6 = f5.thenApply(r -> {
    System.out.println(r);
    sleep(1);
    return "f2";
});
```

上面代码对应的CompletableFuture及其Completion关系如下图：

![img](https://pic2.zhimg.com/80/v2-b828f50d611aa88248f22784836c5921_1440w.jpg)

结合上图和postComplete流程，可以看出执行回调的顺序是：f1 -> f4 -> f5 -> f6 -> f2 -> f3。（如果这里没看懂，可以回过头再看下postComplete方法的源码~）



***推荐阅读***

[CompletableFuture 应用实践](https://link.zhihu.com/?target=http%3A//mp.weixin.qq.com/s%3F__biz%3DMzIwNTI2ODY5OA%3D%3D%26mid%3D2649939209%26idx%3D1%26sn%3D3f290441820d34b6099791193b6b6e4c%26chksm%3D8f350ebcb84287aa01ec21c77d36677085c340e3d0b27621712c0d825e85ee269237ac79cf5a%26scene%3D21%23wechat_redirect)

[Java线程池实现原理](https://link.zhihu.com/?target=http%3A//mp.weixin.qq.com/s%3F__biz%3DMzIwNTI2ODY5OA%3D%3D%26mid%3D2649939199%26idx%3D1%26sn%3Da4fec8eaa89811fd0d56f2ba540769b3%26chksm%3D8f350f4ab842865cc4a08e43f39644b6b53705dc0c3778a2d8d89828a690605aeb33a9cb07cf%26scene%3D21%23wechat_redirect)

[深入理解Java线程池](https://link.zhihu.com/?target=http%3A//mp.weixin.qq.com/s%3F__biz%3DMzIwNTI2ODY5OA%3D%3D%26mid%3D2649939190%26idx%3D1%26sn%3D944594fb73c4a780cbe9d093cbfe119a%26chksm%3D8f350f43b8428655e8a38ebe5530a6293d937d7cbfed245a2a81d515b59cdf1e163e1ae50904%26scene%3D21%23wechat_redirect)

[JMM Java内存模型](https://link.zhihu.com/?target=http%3A//mp.weixin.qq.com/s%3F__biz%3DMzIwNTI2ODY5OA%3D%3D%26mid%3D2649939179%26idx%3D1%26sn%3D5868587f841bfa8b792cc686311c758c%26chksm%3D8f350f5eb8428648de1c2a1a50a43f01350c53922492bcda9677ffed4e1eb153cd5c79a7817f%26scene%3D21%23wechat_redirect)

[happens-before那些事儿](https://link.zhihu.com/?target=http%3A//mp.weixin.qq.com/s%3F__biz%3DMzIwNTI2ODY5OA%3D%3D%26mid%3D2649939170%26idx%3D1%26sn%3D68ce8cb33e5c710e1ecfae782b7692f9%26chksm%3D8f350f57b8428641684dd38070793646e415355cfcc0e777799bdf5575f4dd6f5b0f96f41275%26scene%3D21%23wechat_redirect)

[为什么说LockSupport是Java并发的基石?](https://link.zhihu.com/?target=http%3A//mp.weixin.qq.com/s%3F__biz%3DMzIwNTI2ODY5OA%3D%3D%26mid%3D2649939162%26idx%3D1%26sn%3Dc4425d174656adcf5b6959cfff7fe815%26chksm%3D8f350f6fb84286794bf4fb19394534d00c8f47a2caf3c14c8720f4d45e2f3de0a26111faf0e4%26scene%3D21%23wechat_redirect)

