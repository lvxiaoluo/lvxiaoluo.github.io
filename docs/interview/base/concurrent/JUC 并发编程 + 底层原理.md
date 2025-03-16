# JUC 并发编程 + 底层原理



> 注意，一定要是JDK1.8、IDE 一定要设置

## 1、什么是JUC（重要）

![image-20200207201418258](https://shidongxu0312.github.io/assets/JUC/image-20200207201418258.png)

java.util.concurrent;

## 2、进程和线程回顾

> 进程 / 线程是什么？

技术：不能使用一句话说出来，你不会！

进程：QQ.exe 、 Music.exe . 程序

线程：一个进程中可能包含多个线程，至少包含一个。JAVA

main 、 GC 线程

> 并发 / 并行是什么？

并发编程？ 并发。并行；

并发：多线程、 多个线程操作一个资源类，快速交替过程。

并行：多核多CPU；

你吃饭，吃到一半，电话来了，3种情况

1、吃完再去接电话 （单线程）

2、先接电话再吃（交替、并发）

3、边吃边接电话（并行）

一个CPU 的电脑，能不能并行执行任务？

==**所以说，并发编程的主要目的，充分利用CPU的资源，提高性能；**==

> 线程的状态

线程的状态 6 种 （学习的方式：看源码+官方文档）

```
public enum State {
 
    NEW,

    RUNNABLE,

    BLOCKED,

    WAITING, // 等待

    TIMED_WAITING, // 延时等待 

    TERMINATED; //
}
```

> wait / sleep 的区别

**1、类**

wait Object

sleep Thread ， 谁调用的谁睡觉！

A 调用了 B 的sleep方法，实际上是谁睡觉？

**2、是否释放锁**

sleep抱着锁睡觉。

wait 会释放锁！

**3、使用范围不同**

wait、notify、notifyAll 只能用在同步方法中或者同步代码块中；

Sleep 可以再任意地方使用；

**4、异常**

sleep, 必须捕获异常！

wait ， 不需要捕获异常！

## 3、Lock锁

> 传统的 synchronized

```
package com.coding.demo01;

import java.util.TimerTask;

/**
 * 卖票   自己会写     3个售票员卖出30张票
 * 企业中禁止这样写，Coding：企业级开发！
 *
 * 多线程编程的固定套路：
 *     1、高内聚，低耦合  （前提）
 *     2、线程  操作(调用对外暴露的方法)   资源类  (要点)
 */
public class SaleTicketTest1 {
    public static void main(String[] args) {

        // 资源类
        final SaleTicket saleTicket = new SaleTicket();

        new Thread(new Runnable() {
            public void run() {
                for (int i = 1; i < 40; i++) {
                    saleTicket.saleTicket();
                }
            }
        }, "A").start();

        new Thread(new Runnable() {
            public void run() {
                for (int i = 1; i < 40; i++) {
                    saleTicket.saleTicket();
                }
            }
        }, "B").start();

        new Thread(new Runnable() {
            public void run() {
                for (int i = 1; i < 40; i++) {
                    saleTicket.saleTicket();
                }
            }
        }, "C").start();

    }
}

// 属性，和方法  高内聚
class SaleTicket{ //资源类
    private int number = 30;

    // 卖票方法
    public synchronized void saleTicket(){
        if (number>0){
            System.out.println(Thread.currentThread().getName()+"卖出第"+ (number--) +"还剩下："+number+"张票");
        }
    }

}
```

> 使用 juc.locks 包下的类操作 Lock 锁 + Lambda 表达式

![image-20200207204516043](https://shidongxu0312.github.io/assets/JUC/image-20200207204516043.png)

![image-20200207205455735](https://shidongxu0312.github.io/assets/JUC/image-20200207205455735.png)

```
package com.coding.demo01;

import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

/**
 * 卖票   自己会写     3个售票员卖出30张票
 * 企业中禁止这样写，Coding：企业级开发！
 * <p>
 * 多线程编程的固定套路：
 * 1、高内聚，低耦合  （前提）
 * 2、线程  操作(调用对外暴露的方法)   资源类  (要点)
 */
public class SaleTicketTest2 {
    public static void main(String[] args) {

        // 并发： 多线线程操作同一个资源类
        // 资源类
        SaleTicket2 saleTicket = new SaleTicket2();

        // lambda表达式、链式编程、流式计算！
        //  lambda表达式，() -> {} 自动推断类型

        // IDEA 一定要设置 JDK 版本为 1.8 版本
        new Thread(() -> {
            for (int i = 1; i < 40; i++) saleTicket.saleTicket();
        }, "A").start();

        new Thread(() -> {
            for (int i = 1; i < 40; i++) saleTicket.saleTicket();
        }, "B").start();

        new Thread(() -> {
            for (int i = 1; i < 40; i++) saleTicket.saleTicket();
        }, "C").start();

    }
}

// 属性，和方法  高内聚
class SaleTicket2 { //资源类
    private int number = 30;

    // 锁LOCK
    private Lock lock = new ReentrantLock(); // 可重入

    // 卖票方法
    public void saleTicket() {
        lock.lock(); // 加锁
        try {
            // 业务代码
            if (number > 0) {
                System.out.println(Thread.currentThread().getName() + "卖出第" + (number--) + "还剩下：" + number + "张票");
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            lock.unlock(); // 解锁
        }

    }

}
```

> synchronized 和 lock 区别 （自动挡 手动挡）

1、synchronized 关键字，Java内置的。lock 是一个Java 类

2、synchronized 无法判断是否获取锁、lock 可以判断是否获得锁

3、synchronized 锁会自动释放！ lock 需要手动在 finally 释放锁，如果不释放锁，就会死锁

4、synchronized 线程1阻塞 线程2永久等待下去。 lock可以 lock.tryLock(); // 尝试获取锁，如果尝试获取不到锁，可以结束等待

5、synchronized 可重入，不可中断，非公平的，Lock锁，可重入、可以判断、可以公平！

## 4、生产者和消费者（高频）

线程间的通信、无法通信，调度线程

> 生产者和消费者 synchroinzed 版

```
package com.coding.demo02;

/**
 * 题目：现在两个线程，操作一个初始值为0的变量
 *       一个线程 + 1， 一个线程 -1。判断什么时候+1，什么时候-1
 *       交替10 次
 *
 * 方法论：
 *
 * 多线程编程的固定套路：
 * 1、高内聚，低耦合  （前提）
 * 2、线程  操作(调用对外暴露的方法)   资源类  (要点)
 *
 * 生产者消费者模型： 判断、干活、通知
 */
public class A {

    public static void main(String[] args) {
        Data data = new Data();

        new Thread(()->{
            for (int i = 1; i <= 10; i++) {
                try {
                    data.increment();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        },"A").start();

        new Thread(()->{
            for (int i = 1; i <= 10; i++) {
                try {
                    data.decrement();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        },"B").start();

    }

}


// 资源类  属性，方法
class Data{
    private int num = 0;

    // +1
    public synchronized void increment() throws Exception{
        //判断
        if (num!=0){
            this.wait();
        }
        // 干活
        num++;
        System.out.println(Thread.currentThread().getName()+"\t"+num);
        // 通知
        this.notifyAll();
    }

    // -1
    public synchronized void decrement() throws Exception{
        // 判断
        if (num==0){
            this.wait();
        }
        // 干活
        num--;
        System.out.println(Thread.currentThread().getName()+"\t"+num);
        // 通知
        this.notifyAll();
    }

}
```

> 问题升级：防止虚假唤醒，4个线程，两个加，两个减

![image-20200207212135581](https://shidongxu0312.github.io/assets/JUC/image-20200207212135581.png)

```
package com.coding.demo02;

/**
 * 题目：现在两个线程，操作一个初始值为0的变量
 *       一个线程 + 1， 一个线程 -1。判断什么时候+1，什么时候-1
 *       交替10 次
 *
 * 方法论：
 *
 * 多线程编程的固定套路：
 * 1、高内聚，低耦合  （前提）
 * 2、线程  操作(调用对外暴露的方法)   资源类  (要点)
 *
 * 生产者消费者模型： 判断、干活、通知
 */
public class A {

    public static void main(String[] args) {
        Data data = new Data();

        new Thread(()->{
            for (int i = 1; i <= 10; i++) {
                try {
                    data.increment();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        },"A").start();

        new Thread(()->{
            for (int i = 1; i <= 10; i++) {
                try {
                    data.decrement();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        },"B").start();

        new Thread(()->{
            for (int i = 1; i <= 10; i++) {
                try {
                    data.increment();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        },"C").start();

        new Thread(()->{
            for (int i = 1; i <= 10; i++) {
                try {
                    data.decrement();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        },"D").start();

    }

}


// 资源类  属性，方法
class Data{
    private int num = 0;

    // +1
    public synchronized void increment() throws Exception{
        //判断  if 只判断了一次，  0  1  0   1   
        while (num!=0){    
            this.wait();
        }
        // 干活
        num++; 
        System.out.println(Thread.currentThread().getName()+"\t"+num);
        // 通知
        this.notifyAll();
    }

    // -1
    public synchronized void decrement() throws Exception{
        // 判断
        while (num==0){
            this.wait(); //0
        }
        // 干活
        num--;
        System.out.println(Thread.currentThread().getName()+"\t"+num);
        // 通知
        this.notifyAll();
    }

}
```

传统的，JUC！

> 新版生产者和消费者写法

![image-20200207212651991](https://shidongxu0312.github.io/assets/JUC/image-20200207212651991.png)

**任何一个新技术的出现，一定不仅仅是换了个马甲**

![image-20200207212751361](https://shidongxu0312.github.io/assets/JUC/image-20200207212751361.png)

手写生产者消费者问题：100 加分项目！

```
package com.coding.demo02;

import sun.awt.SunHints;

import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

// lock版生产者消费者
public class B {


    public static void main(String[] args) {
        // 新版
        Data2 data = new Data2();

        new Thread(()->{
            for (int i = 1; i <= 10; i++) {
                try {
                    data.increment();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        },"A").start();

        new Thread(()->{
            for (int i = 1; i <= 10; i++) {
                try {
                    data.decrement();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        },"B").start();

        new Thread(()->{
            for (int i = 1; i <= 10; i++) {
                try {
                    data.increment();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        },"C").start();

        new Thread(()->{
            for (int i = 1; i <= 10; i++) {
                try {
                    data.decrement();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        },"D").start();

    }

}

// 资源类  属性，方法
class Data2{
    private int num = 0;
    // 定义锁
    Lock lock = new ReentrantLock();
    private Condition condition = lock.newCondition();

    // +1
    public void increment() throws Exception{

        // 加锁
        lock.lock();

        try {
            //判断
            while (num!=0){
                condition.await(); //等待
            }
            // 干活
            num++;
            System.out.println(Thread.currentThread().getName()+"\t"+num);
            // 通知
            condition.signalAll();

        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            // 解锁
            lock.unlock();
        }
    }

    // -1
    public void decrement() throws Exception{


        // 加锁
        lock.lock();
        try {
            // 判断
            while (num==0){
                condition.await(); //等待
            }
            // 干活
            num--;
            System.out.println(Thread.currentThread().getName()+"\t"+num);
            // 通知
            condition.signalAll();
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            // 解锁
            lock.unlock();
        }
    }

}
```

如何精确通知访问！

> 精确通知顺序访问 Condition

![image-20200207214628875](https://shidongxu0312.github.io/assets/JUC/image-20200207214628875.png)

```
package com.coding.demo02;

import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

/**
 *  多个线程启动  A -- B -- C
 *  三个线程依次打印
 *  A  5次
 *  B  10次
 *  C  15次
 *  依次循环
 *
 *  精确通知线程消费
 */
public class C {

    public static void main(String[] args) {
        Data3 data = new Data3();

        // 线程操作资源类
        new Thread(()->{
            for (int i = 1; i <= 10; i++) {
                data.print5();
            }
        },"A").start();

        new Thread(()->{
            for (int i = 1; i <= 10; i++) {
                data.print10();
            }
        },"B").start();

        new Thread(()->{
            for (int i = 1; i <= 10; i++) {
                data.print15();
            }
        },"C").start();

    }

}


// 资源类  属性，方法
class Data3{
    private int num = 1; // A1   B2   C3
    // 定义锁
    Lock lock = new ReentrantLock();
    private Condition condition1 = lock.newCondition(); //3个判断，交替执行 A--B--C--A
    private Condition condition2 = lock.newCondition(); //3个判断，交替执行 A--B--C--A
    private Condition condition3 = lock.newCondition(); //3个判断，交替执行 A--B--C--A

    // 3个方法、作业，合3为1
    // +1
    public void print5(){
        // 加锁
        lock.lock();
        try {
            //判断
            while (num!=1){
                condition1.await(); //等待
            }
            // 干活
            for (int i = 1; i <=5 ; i++) {
                System.out.println(Thread.currentThread().getName()+"\t"+i);
            }

            // 第一个线程通知第二个线程，第二个线程通知第三个....  计数器
            num=2;
            // 通知第二个线程干活,指定谁干活
            condition2.signal();

        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            // 解锁
            lock.unlock();
        }
    }

    public void print10() {
        // 加锁
        lock.lock();
        try {
            //判断
            while (num!=2){
                condition2.await(); //等待
            }
            // 干活
            for (int i = 1; i <=10 ; i++) {
                System.out.println(Thread.currentThread().getName()+"\t"+i);
            }
            // 第一个线程通知第二个线程，第二个线程通知第三个....  计数器
            num=3;
            // 通知第二个线程干活,指定谁干活
            condition3.signal();

        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            // 解锁
            lock.unlock();
        }
    }

    public void print15() {
        // 加锁
        lock.lock();
        try {
            //判断
            while (num!=3){
                condition3.await(); //等待
            }
            // 干活 = 业务代码
            for (int i = 1; i <=15 ; i++) {
                System.out.println(Thread.currentThread().getName()+"\t"+i);
            }

            num=1;
            condition1.signal();

        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            // 解锁
            lock.unlock();
        }
    }


}
```

大家懂锁的吗？锁的谁！

## 5、8锁的现象（深入理解锁）

**1、标准访问，请问先打印邮件还是短信？**

```
package com.coding.lock8;

import java.util.concurrent.TimeUnit;

/**
 * **1、标准访问，请问先打印邮件1还是短信2？**
 * 
 * 
 */
public class Test1 {
    public static void main(String[] args) {
        
        Phone phone = new Phone();

        // 我们这里两个线程使用的是同一个对象。两个线程是一把锁！先调用的先执行！
        new Thread(() -> {
            phone.sendEmail();
        }, "A").start();

        // 干扰
        try {
            TimeUnit.SECONDS.sleep(1);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        new Thread(() -> {
            phone.sendMS();
        }, "B").start();

    }
}

// 手机，发短信，发邮件
class Phone {
    // 被 synchronized 修饰的方法、锁的对象是方法的调用者、
    public synchronized void sendEmail() {
        System.out.println("sendEmail");
    }

    public synchronized void sendMS() {
        System.out.println("sendMS");
    }
}
```

**2、邮件方法暂停4秒钟，请问先打印邮件还是短信？**

```
package com.coding.lock8;

import java.util.concurrent.TimeUnit;

/**
 * **2、邮件方法暂停4秒钟，请问先打印邮件还是短信？**
 */
public class Test2 {
    public static void main(String[] args) {

        Phone2 phone = new Phone2();

        // 我们这里两个线程使用的是同一个对象。两个线程是一把锁！先调用的先执行！
        new Thread(() -> {
            phone.sendEmail();
        }, "A").start();

        // 干扰
        try {
            TimeUnit.SECONDS.sleep(1);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        new Thread(() -> {
            phone.sendMS();
        }, "B").start();

    }
}


// 手机，发短信，发邮件
class Phone2 {
    // 被 synchronized 修饰的方法、锁的对象是方法的调用者、
    public synchronized void sendEmail() {
        try {
            TimeUnit.SECONDS.sleep(4);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println("sendEmail");
    }

    public synchronized void sendMS() {
        System.out.println("sendMS");
    }
}
```

**3、新增一个普通方法hello()没有同步,请问先打印邮件还是hello？**

```
package com.coding.lock8;

import java.util.concurrent.TimeUnit;

/**
 * 3、新增一个普通方法hello()没有同步,请问先打印邮件还是hello？
 */
public class Test3 {

    // 回家  卧室(锁)   厕所
    public static void main(String[] args) {

        Phone3 phone = new Phone3();

        // 我们这里两个线程使用的是同一个对象。两个线程是一把锁！先调用的先执行！
        new Thread(() -> { // 一开始就执行了
            phone.sendEmail();
        }, "A").start();

        // 干扰
        try {
            TimeUnit.SECONDS.sleep(1);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        new Thread(() -> { // 一秒后执行
            phone.hello();
        }, "B").start();

    }
}

// 锁：竞争机制

// 手机，发短信，发邮件
class Phone3 {
    // 被 synchronized 修饰的方法、锁的对象是方法的调用者、
    public synchronized void sendEmail() {
        try {
            TimeUnit.SECONDS.sleep(4);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println("sendEmail");
    }

    public synchronized void sendMS() {
        System.out.println("sendMS");
    }

    // 新增的方法没有被 synchronized 修饰，不是同步方法，所以不需要等待，其他线程用了一个把锁
    public void hello() {
        System.out.println("hello");
    }

}
```

**4、两部手机、请问先打印邮件还是短信？**

```
package com.coding.lock8;

import java.util.concurrent.TimeUnit;

/**
 * **4、两部手机、请问先打印邮件还是短信？**
 */
public class Test4 {

    // 回家  卧室(锁)   厕所
    public static void main(String[] args) {
        // 两个对象，互不干预
        Phone4 phone1 = new Phone4();
        Phone4 phone2 = new Phone4();

        // 我们这里两个线程使用的是同一个对象。两个线程是一把锁！先调用的先执行！
        new Thread(() -> { // 一开始就执行了
            phone1.sendEmail();
        }, "A").start();

        // 干扰
        try {
            TimeUnit.SECONDS.sleep(1);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        new Thread(() -> { // 一秒后执行
            phone2.sendMS();
        }, "B").start();

    }

}

// 手机，发短信，发邮件
class Phone4 {
    // 被 synchronized 修饰的方法、锁的对象是方法的调用者、调用者不同，没有关系，量个方法用得不是同一个锁！
    public synchronized void sendEmail() {
        // 善意的延迟
        try {
            TimeUnit.SECONDS.sleep(4);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println("sendEmail");
    }

    public synchronized void sendMS() {
        System.out.println("sendMS");
    }

}
```

**5、两个静态同步方法，同一部手机，请问先打印邮件还是短信？**

```
package com.coding.lock8;

import java.util.concurrent.TimeUnit;

/*
 **5、两个静态同步方法，同一部手机，请问先打印邮件还是短信？**
 */
public class Test5 {
    // 回家  卧室(锁)   厕所
    public static void main(String[] args) {
        // 两个对象，互不干预
        Phone5 phone = new Phone5();

        // 我们这里两个线程使用的是同一个对象。两个线程是一把锁！先调用的先执行！
        new Thread(() -> { // 一开始就执行了
            phone.sendEmail();
        }, "A").start();

        // 干扰
        try {
            TimeUnit.SECONDS.sleep(1);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        new Thread(() -> { // 一秒后执行
            phone.sendMS();
        }, "B").start();

    }

}


// 手机，发短信，发邮件
class Phone5 {

    // 对象    类模板可以new 多个对象！
    // Class   类模版，只有一个

    // 被 synchronized 修饰 和 static 修饰的方法，锁的对象是类的 class 对象！唯一的
    // 同一把锁

    public static synchronized void sendEmail() {
        // 善意的延迟
        try {
            TimeUnit.SECONDS.sleep(4);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println("sendEmail");
    }

    public static synchronized void sendMS() {
        System.out.println("sendMS");
    }

}
```

**6、两个静态同步方法，2部手机，请问先打印邮件还是短信？**

```
package com.coding.lock8;

import java.util.concurrent.TimeUnit;

/** 第一次听可能不会，第二次也可能不会，但是不要放弃，你可以！
 **6、两个静态同步方法，2部手机，请问先打印邮件还是短信？**
 */
public class Test6 {

    // 回家  卧室(锁)   厕所
    public static void main(String[] args) {
        // 两个对象，互不干预
        Phone5 phone = new Phone5();
        Phone5 phone2 = new Phone5();

        // 我们这里两个线程使用的是同一个对象。两个线程是一把锁！先调用的先执行！
        new Thread(() -> { // 一开始就执行了
            phone.sendEmail();
        }, "A").start();

        // 干扰
        try {
            TimeUnit.SECONDS.sleep(1);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        new Thread(() -> { // 一秒后执行
            phone2.sendMS();
        }, "B").start();

    }

}

// 手机，发短信，发邮件
class Phone6 {

    // 对象    类模板可以new 多个对象！
    // Class   类模版，只有一个

    // 被 synchronized 修饰 和 static 修饰的方法，锁的对象是类的 class 对象！唯一的
    // 同一把锁

    public static synchronized void sendEmail() {
        // 善意的延迟
        try {
            TimeUnit.SECONDS.sleep(4);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println("sendEmail");
    }

    public static synchronized void sendMS() {
        System.out.println("sendMS");
    }

}
```

**7、一个普通同步方法，一个静态同步方法，同一部手机，请问先打印邮件还是短信？**

```
package com.coding.lock8;

import java.util.concurrent.TimeUnit;

/**
 * 7、一个普通同步方法，一个静态同步方法，同一部手机，请问先打印邮件还是短信？**
 */
public class Test7 {
    // 回家  卧室(锁)   厕所
    public static void main(String[] args) {
        // 两个对象，互不干预
        Phone7 phone = new Phone7();

        // 我们这里两个线程使用的是同一个对象。两个线程是一把锁！先调用的先执行！
        new Thread(() -> { // 一开始就执行了
            phone.sendEmail();
        }, "A").start();

        // 干扰
        try {
            TimeUnit.SECONDS.sleep(1);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        new Thread(() -> { // 一秒后执行
            phone.sendMS();
        }, "B").start();

    }
}


class Phone7{
    // CLASS
    public static synchronized void sendEmail() {
        // 善意的延迟
        try {
            TimeUnit.SECONDS.sleep(4);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println("sendEmail");
    }

    // 对象
    // 普通同步方法
    public synchronized void sendMS() {
        System.out.println("sendMS");
    }

}
```

**8、一个普通同步方法，一个静态同步方法，2部手机，请问先打印邮件还是短信？**

```
package com.coding.lock8;

import java.util.concurrent.TimeUnit;

/**
 * **8、一个普通同步方法，一个静态同步方法，2部手机，请问先打印邮件还是短信？**
 */
public class Test8 {

    public static void main(String[] args) {
        // 两个对象，互不干预
        Phone8 phone = new Phone8();
        Phone8 phone2 = new Phone8();

        // 我们这里两个线程使用的是同一个对象。两个线程是一把锁！先调用的先执行！
        new Thread(() -> { // 一开始就执行了
            phone.sendEmail();
        }, "A").start();

        // 干扰
        try {
            TimeUnit.SECONDS.sleep(1);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        new Thread(() -> { // 一秒后执行
            phone2.sendMS();
        }, "B").start();

    }

}



class Phone8{

    // CLASS
    public static synchronized void sendEmail() {
        // 善意的延迟
        try {
            TimeUnit.SECONDS.sleep(4);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println("sendEmail");
    }

    // 对象
    // 普通同步方法
    public synchronized void sendMS() {
        System.out.println("sendMS");
    }

}
```

coding: 魔鬼教练，难受

> 小结

**new this 本身的这个对象，调用者**

**static class 类模板，保证唯一！**

一个对象中有多个 synchronized 方法，某个时刻内只要有一个线程去访问 synchronized 方法了就会被加锁，独立公共厕所！其他线程就会阻塞！

加了一个普通方法后 ，两个对象，无关先后，一个有锁，一个没锁！情况会变化！

换成静态同步方法，情况会变化！ CLASS ，所有静态同步方法的锁唯一 对象实例class 本身！

## 6、集合类不安全

> list 不安全

单线程：安全

```
package com.coding.collunsafe;

import java.util.Arrays;
import java.util.List;

public class UnsafeList1 {
    public static void main(String[] args) {
        List<String> list = Arrays.asList("a", "b", "c");
        list.forEach(System.out::println);
    }
    
}
```

多线程：不安全

```
package com.coding.collunsafe;

import java.util.ArrayList;
import java.util.Random;
import java.util.UUID;

public class UnsafeList2 {
    public static void main(String[] args) {
        // 代码实现
        ArrayList<Object> list = new ArrayList<>();

        // 测试多线程下是否安全List，3条线程都不安全了
        // 多线程下记住一个异常，并发修改异常 java.util.ConcurrentModificationException
        
        // Exception  ConcurrentModificationException
        for (int i = 1; i <= 30; i++) {
            new Thread(()->{
                // 3个结果
                list.add(UUID.randomUUID().toString().substring(0,5));
                System.out.println(list);
            },String.valueOf(i)).start();
        }

    }
}
```

不安全怎么解决：

```
package com.coding.collunsafe;

import java.util.*;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * 善于总结：
 * 1、 故障现象： ConcurrentModificationException
 * 2、 导致原因： 多线程操作集合类不安全
 * 3、 解决方案：
 *      List<String> list = new Vector<>(); // Vector 是一个线程安全的类,效率低下  50
 *      List<String> list = Collections.synchronizedList(new ArrayList<>()); // 60
 *      List<String> list = new CopyOnWriteArrayList<>(); // JUC 100 推荐使用
 */
public class UnsafeList2 {
    public static void main(String[] args) {
        // 代码实现
        // ArrayList<Object> list = new ArrayList<>(); // 效率高，不支持并发！
        // List<String> list = new Vector<>(); // Vector 是一个线程安全的类,效率低下  50
        // List<String> list = Collections.synchronizedList(new ArrayList<>()); // 60

        // 多线程高并发程序中，一致性最为重要

        // 写入时复制；  COW 思想，计算机设计领域。优化策略
        //  思想： 多个调用者，想调用相同的资源； 指针
        // 只是去读，就不会产生锁！
        // 假如你是去写，就需要拷贝一份都自己哪里，修改完毕后，在替换指针！

        List<String> list = new CopyOnWriteArrayList<>(); // JUC 100

        // 测试多线程下是否安全List，3条线程都不安全了
        // 多线程下记住一个异常，并发修改异常 java.util.ConcurrentModificationException

        // Exception  ConcurrentModificationException
        for (int i = 1; i <= 30; i++) {
            new Thread(()->{
                // 3个结果
                list.add(UUID.randomUUID().toString().substring(0,5));
                System.out.println(list);
            },String.valueOf(i)).start();
        }

    }
}
```

思想原理：指针，复制指向的问题

![image-20200207224610877](https://shidongxu0312.github.io/assets/JUC/image-20200207224610877.png)

> set 不安全

```
package com.coding.collunsafe;

import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.CopyOnWriteArraySet;

/**
 * 善于总结：
 * 1、 故障现象： ConcurrentModificationException 并发修改异常！
 * 2、 导致原因： 并发下 HashSet 存在安全的问题
 * 3、 解决方案：
 *     Set<String> set = Collections.synchronizedSet(new HashSet<>());  60
 *     Set<String> set =new CopyOnWriteArraySet<>();  // 100
 *
 */
public class UnsafeSet1 {
    public static void main(String[] args) {
        // Set<String> set = new HashSet<>(); // 底层是什么
        Set<String> set =new CopyOnWriteArraySet<>();

        for (int i = 1; i <=30 ; i++) {
            new Thread(()->{
                set.add(UUID.randomUUID().toString().substring(0,5));
                System.out.println(set);
            },String.valueOf(i)).start();
        }

    }
}
```

> map 不安全

![image-20200207230013664](https://shidongxu0312.github.io/assets/JUC/image-20200207230013664.png)

```
package com.coding.collunsafe;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

// 任何存在想修改JDK源码都是不可取的

// ConcurrentModificationException
// 并发下 HashMap 不安全
// 解决方案：Map<String, String> map = new ConcurrentHashMap<>();

public class UnSafeMap {
    public static void main(String[] args) {
        // 在开发中会这样使用 HashMap 吗？ 不会  一开始就知道 100大小的容量
        // 根据实际的业务设置初始值

        // 人生如程序，不是选择，就是循环，学习和总结十分重要！
        //Map<String, String> map = new HashMap<>();
        Map<String, String> map = new ConcurrentHashMap<>();

        // 加载因子，初始值
        // Map<String, String> map = new HashMap<>(100，0.75);

        for (int i = 1; i <= 30; i++) {
            new Thread(()->{
                map.put(Thread.currentThread().getName(),UUID.randomUUID().toString().substring(0,5));
                System.out.println(map);
            },String.valueOf(i)).start();
        }

    }
}
```

## 7、Callable

线程创建方式 Thread、Runnable、Callable区别：

- 是否有返回值
- 是否跑出异常
- 方法不同， run（），call（）

> 基础入门

![image-20200207230738176](https://shidongxu0312.github.io/assets/JUC/image-20200207230738176.png)

![image-20200207231056635](https://shidongxu0312.github.io/assets/JUC/image-20200207231056635.png)

![image-20200207231157684](https://shidongxu0312.github.io/assets/JUC/image-20200207231157684.png)

![image-20200207231429129](https://shidongxu0312.github.io/assets/JUC/image-20200207231429129.png)

![image-20200207231442409](https://shidongxu0312.github.io/assets/JUC/image-20200207231442409.png)

```
package com.coding.callabledemo;

import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.FutureTask;

// 练武不练功，到老一场空
// API 工程师，只会用，不会分析~
public class Test1 {
    public static void main(String[] args) throws ExecutionException, InterruptedException {
        // Thread（Runnable）
        // Thread（RunnableFuture）
        // Thread（FutureTask）

        MyThread myThread = new MyThread();
        FutureTask task = new FutureTask(myThread); // 适配类

        new Thread(task,"A").start(); // 执行线程

        System.out.println(task.get());// 获取返回值， get()


    }
}



class MyThread implements Callable<Integer> {

    @Override
    public Integer call() throws Exception {
        System.out.println("end");
        return 1024;
    }

}
```

> Callable 细节

缓存

结果获取会阻塞

```
package com.coding.callabledemo;

import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.FutureTask;
import java.util.concurrent.TimeUnit;

// 练武不练功，到老一场空
// API 工程师，只会用，不会分析~
public class Test1 {
    public static void main(String[] args) throws ExecutionException, InterruptedException {
        // Thread（Runnable）
        // Thread（RunnableFuture）
        // Thread（FutureTask）

        MyThread myThread = new MyThread();
        FutureTask task = new FutureTask(myThread); // 适配类

        // 会打印几次 end
        new Thread(task,"A").start(); // 执行线程
        new Thread(task,"B").start(); // 执行线程。细节1：结果缓存！效率提高N倍

        System.out.println(task.get());// 获取返回值， get()

        // 细节2：task.get() 获取值的方法一般放到最后，保证程序平稳运行的效率，因为他会阻塞等待结果产生！
        // 线程是一个耗时的线程，不重要！

    }
}


class MyThread implements Callable<Integer> {

    @Override
    public Integer call() throws Exception {
        System.out.println("end");

        TimeUnit.SECONDS.sleep(3);

        return 1024;
    }

}
```

## 8、常用辅助类

### 8.1、CountDownLatch

![image-20200207232744659](https://shidongxu0312.github.io/assets/JUC/image-20200207232744659.png)

```
package com.coding.demo03;

import java.util.concurrent.CountDownLatch;

// 程序如果不加以生活的理解再加上代码的测试，你就算不会
public class CountDownLatchDemo {

    // 有些任务是不得不阻塞的  减法计数器
    public static void main(String[] args) throws InterruptedException {

        CountDownLatch countDownLatch = new CountDownLatch(6); // 初始值

        for (int i = 1; i <=6 ; i++) {
            new Thread(()->{
                System.out.println(Thread.currentThread().getName()+"Start");
                // 出去一个人计数器就 -1
                countDownLatch.countDown();
            },String.valueOf(i)).start();
        }

        countDownLatch.await(); // 阻塞等待计数器归零
        // 阻塞的操作 ： 计数器  num++
        System.out.println(Thread.currentThread().getName()+"===END");

    }

    // 结果诡异的吗，达不到预期的 Main end 在最后一个
    public static void test1(){
        for (int i = 1; i <=6 ; i++) {
            new Thread(()->{
                System.out.println(Thread.currentThread().getName()+"Start");
            },String.valueOf(i)).start();
        }
        System.out.println(Thread.currentThread().getName()+"End");
    }


}
CountDownLatch countDownLatch = new CountDownLatch(6); 
```

`countDownLatch.countDown(); ` 出去一个人计数器就 -1

` countDownLatch.await(); ` 阻塞等待计数器归零

### 8.2、CyclicBarrier

```
package com.coding.demo03;

import java.util.concurrent.BrokenBarrierException;
import java.util.concurrent.CyclicBarrier;

// CyclicBarrier 栅栏 加法计数器
public class CyclicBarrierDemo {
    public static void main(String[] args) {
        // 集齐7个龙珠召唤神龙 ++ 1

        //  public CyclicBarrier(int parties, Runnable barrierAction)
        // 等待cyclicBarrier计数器满，就执行后面的Runnable，不满就阻塞
        CyclicBarrier cyclicBarrier = new CyclicBarrier(8, new Runnable() {
            @Override
            public void run() {
                System.out.println("神龙召唤成功！");
            }
        });

        for (int i = 1; i <= 7; i++) {
            final int temp = i;
            new Thread(()->{
                System.out.println(Thread.currentThread().getName()+"收集了第"+temp+"颗龙珠");

                try {
                    cyclicBarrier.await(); // 等待 阻塞
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } catch (BrokenBarrierException e) {
                    e.printStackTrace();
                }

            }, String.valueOf(i)).start();

        }


    }
}
```

### 8.3、Semaphore

Semaphore： 信号灯。 抢位置

```
package com.coding.demo03;

import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

// 抢车位
public class SemaphoreDemo {
    public static void main(String[] args) {
        // 模拟6个车，只有3个车位
        Semaphore semaphore = new Semaphore(3); // 3个位置

        for (int i = 1; i <= 6; i++) {
            new Thread(()->{
                // 得到车位
                try {
                    semaphore.acquire(); // 得到
                    System.out.println(Thread.currentThread().getName()+"抢到了车位");
                    TimeUnit.SECONDS.sleep(3);
                    System.out.println(Thread.currentThread().getName()+"离开了车位");
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } finally {
                    semaphore.release(); // 释放位置
                }


            },String.valueOf(i)).start();
        }

    }
}
```

## 9、读写锁

![image-20200208200836727](https://shidongxu0312.github.io/assets/JUC/image-20200208200836727.png)

![image-20200208200939230](https://shidongxu0312.github.io/assets/JUC/image-20200208200939230.png)

读锁（共享锁）： 这个锁可以被多个线程持有！

写锁（独占锁）：这个锁一次只能被一个线程占用！

> 代码

```
package com.coding.rwdemo;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.ReentrantLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

public class ReadWriteDemo {
    public static void main(String[] args) {

        MyCache2 myCache = new MyCache2();

        // 多个线程同时进行读写
        // 五个线程在写  线程是CPU调度的
        for (int i = 1; i < 5; i++) {
            final int temp = i;
            new Thread(()->{
                myCache.put(temp+"",temp+"");
            },String.valueOf(i)).start();
        }

        // 五个线程在读
        for (int i = 1; i < 5; i++) {
            final int temp = i;
            new Thread(()->{
                myCache.get(temp+"");
            },String.valueOf(i)).start();
        }


    }
}

// 线程操作资源类，存在问题的
class MyCache{

    private volatile Map<String,Object> map = new HashMap<>();

    // 没有加读写锁的时候，第一个线程还没有写入完成，可能会存在其他写入~

    // 写。独占
    public void put(String key,String value){
        System.out.println(Thread.currentThread().getName()+"写入"+key);
        map.put(key,value);
        // 存在别的线程插队
        System.out.println(Thread.currentThread().getName()+"写入完成");
    }

    // 读
    public void get(String key){
        System.out.println(Thread.currentThread().getName()+"读取"+key);
        Object result = map.get(key);
        System.out.println(Thread.currentThread().getName()+"读取结果："+result);
    }

}


// 线程操作资源类，存在问题的
class MyCache2{

    private volatile Map<String,Object> map = new HashMap<>();
    
    // ReadWriteLock --> ReentrantReadWriteLock   lock不能区分读和写 
    // ReentrantReadWriteLock 可以区分读和写，实现更加精确的控制
    // 读写锁
    private ReentrantReadWriteLock readWriteLock = new ReentrantReadWriteLock();

    // 写。独占
    public void put(String key,String value){
        // lock.lock 加锁
        readWriteLock.writeLock().lock();
        try {
            System.out.println(Thread.currentThread().getName()+"写入"+key);
            map.put(key,value);
            // 存在别的线程插队
            System.out.println(Thread.currentThread().getName()+"写入完成");
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            readWriteLock.writeLock().unlock(); // lck.unlock();
        }
    }

    // 多线程下尽量加锁！
    
    // 读
    public void get(String key){
        readWriteLock.readLock().lock();
        try {
            System.out.println(Thread.currentThread().getName()+"读取"+key);
            Object result = map.get(key);
            System.out.println(Thread.currentThread().getName()+"读取结果："+result);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            readWriteLock.readLock().unlock();
        }
    }

}
```

读写分离，提高效率~ 判断业务中那些代码是只读的业务，不要去锁这些业务~

## 10、阻塞队列

> 阻塞队列

队列：排队 FIFO

阻塞：必须要阻塞、不得不阻塞~

![image-20200208203613123](https://shidongxu0312.github.io/assets/JUC/image-20200208203613123.png)

> 接口架构图

![image-20200208204116377](https://shidongxu0312.github.io/assets/JUC/image-20200208204116377.png)

![image-20200208203822806](https://shidongxu0312.github.io/assets/JUC/image-20200208203822806.png)

> API 的使用

四组API：任何一个方法存在，就一定有对应的业务场景，应为都是在生活中或者编码中遇到了困难，才写的

| 方法     | 抛出异常 | 返回特殊值 | 一直阻塞 | 超时退出      |
| -------- | -------- | ---------- | -------- | ------------- |
| 插入 存  | add      | offer      | put ()   | offer(e,time) |
| 移除 取  | remove   | poll       | take()   | poll(e,time)  |
| 检查队首 | element  | peek       | -        | -             |

**第一组：抛出异常**

```
package com.coding.blocking;

import java.util.ArrayList;
import java.util.concurrent.ArrayBlockingQueue;

public class Test1 {
    public static void main(String[] args) {
        // 队列的大小
        ArrayBlockingQueue blockingQueue = new ArrayBlockingQueue<>(3); // 阻塞队列

        // add返回布尔值
        System.out.println(blockingQueue.add("a"));
        System.out.println(blockingQueue.add("b"));
        System.out.println(blockingQueue.add("c"));
        // System.out.println(blockingQueue.add("d")); // java.lang.IllegalStateException: Queue full

        System.out.println(blockingQueue.element());

        System.out.println(blockingQueue.remove()); // a

        System.out.println(blockingQueue.element());

        blockingQueue.remove();

        System.out.println(blockingQueue.element());

        System.out.println(blockingQueue.remove()); // b
        System.out.println(blockingQueue.remove()); // c
        System.out.println(blockingQueue.remove()); // java.util.NoSuchElementException


    }
}
```

第二组：没有异常

```
package com.coding.blocking;

import java.util.concurrent.ArrayBlockingQueue;

// 通常！
public class Test2 {

    public static void main(String[] args) {

        // 队列的大小
        ArrayBlockingQueue blockingQueue = new ArrayBlockingQueue<>(3); // 阻塞队列

        System.out.println(blockingQueue.offer("a"));
        System.out.println(blockingQueue.offer("b"));
        System.out.println(blockingQueue.offer("c"));
        // 等待（一直等待，超时就不等你）
        // System.out.println(blockingQueue.offer("d")); // false 我们通常不希望代码报错！这时候就使用offer

        System.out.println(blockingQueue.peek()); // 查看队首

        System.out.println(blockingQueue.poll());
        System.out.println(blockingQueue.poll());
        System.out.println(blockingQueue.poll());
        System.out.println(blockingQueue.poll()); // null

        // System.out.println(blockingQueue.peek()); // 查看队首 null

    }



}
```

第三组：一直阻塞

```
package com.coding.blocking;

import java.util.concurrent.ArrayBlockingQueue;

public class Test3 {

    public static void main(String[] args) throws InterruptedException {

        // 队列的大小
        ArrayBlockingQueue blockingQueue = new ArrayBlockingQueue<>(3); // 阻塞队列

        // 一直阻塞。超过3秒我就不等了, 业务必须要做！
        blockingQueue.put("a");
        blockingQueue.put("b");
        blockingQueue.put("c");
        // blockingQueue.put("d");

        System.out.println(blockingQueue.take());
        System.out.println(blockingQueue.take());
        System.out.println(blockingQueue.take());
        System.out.println(blockingQueue.take()); // 阻塞等待拿出元素
    }
}
```

超时就退出：

```
package com.coding.blocking;

import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.TimeUnit;

public class Test4 {
    public static void main(String[] args) throws InterruptedException {
        // 队列的大小
        ArrayBlockingQueue blockingQueue = new ArrayBlockingQueue<>(3); // 阻塞队列

        // 设置超时的时间
        blockingQueue.offer("a");
        blockingQueue.offer("b");
        blockingQueue.offer("c");
        // 超过3秒就不等待了
        blockingQueue.offer("d",3L,TimeUnit.SECONDS); // 不让他一直等待，然后也不想返回false，设置等待时间

        System.out.println(blockingQueue.poll()); // a
        System.out.println(blockingQueue.poll()); // b
        System.out.println(blockingQueue.poll()); // c
        System.out.println(blockingQueue.poll(3L,TimeUnit.SECONDS)); // 阻塞
    }
}
```

> SynchronousQueue 同步队列

不存储元素、队列空的

每一个 put 操作。必须等待一个take。否则无法继续添加元素！

```
package com.coding.blocking;

import java.util.concurrent.SynchronousQueue;
import java.util.concurrent.TimeUnit;

// 同步队列
// 每一个 put 操作。必须等待一个take。否则无法继续添加元素！
public class Test5 {
    public static void main(String[] args) {
        // 不用写参数！
        SynchronousQueue<String> queue = new SynchronousQueue<>();

        new Thread(()->{
            try {
                System.out.println(Thread.currentThread().getName()+"put 1");
                queue.put("1");
                System.out.println(Thread.currentThread().getName()+"put 2");
                queue.put("2");
                System.out.println(Thread.currentThread().getName()+"put 3");
                queue.put("3");
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        },"A").start();


        new Thread(()->{
            try {
                TimeUnit.SECONDS.sleep(3);
                System.out.println(Thread.currentThread().getName()+queue.take());
                TimeUnit.SECONDS.sleep(3);
                System.out.println(Thread.currentThread().getName()+queue.take());
                TimeUnit.SECONDS.sleep(3);
                System.out.println(Thread.currentThread().getName()+queue.take());
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        },"B").start();


    }
}
```

## 11、线程池(重点)

三大方法、7大参数、拒绝策略、优化配置

> 池化技术

程序运行的本质：占用系统资源，CPU/磁盘网络进行使用！我们希望可以高效的使用！池化技术就是演进出来的。

白话：提前准备一些资源、以供使用！

线程池、连接池、内存池、对象池………

线程的创建和销毁，数据库的连接和断开都十分浪费资源。

\-

minSize

maxSize

弹性访问！保证系统运行的效率

![image-20200208212211735](https://shidongxu0312.github.io/assets/JUC/image-20200208212211735.png)

> 为什么使用线程池

10年单核电脑，假的多线程！ 交替速度块 ，现在是多核多CPU，各自的线程跑在独立的CPU上，不用切换，效率会高~

CPU密集型，IO 密集型；

**线程池的优势：**

控制运行的线程的数量，处理的时候可以把一些任务放入队列 ；

特点：实现线程的复用！控制最大并发数！

> 线程池的三大方法

![image-20200208212720052](https://shidongxu0312.github.io/assets/JUC/image-20200208212720052.png)

![image-20200208213140559](https://shidongxu0312.github.io/assets/JUC/image-20200208213140559.png)

```
package com.coding.pool;

import java.util.Arrays;
import java.util.Collections;
import java.util.concurrent.Executor;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Executors.
 * ExecutorService.execute
 */
public class Test1 {
    public static void main(String[] args) {
        // 平时我们创建一些类使用工具类操作 s
        // 总数可以管理

        // 线程池  Executors原生三大方法
        // ExecutorService threadpool1 = Executors.newFixedThreadPool(5); // 固定大小
        // ExecutorService threadpool2 = Executors.newCachedThreadPool(); //可以弹性伸缩的线程池，遇强则强
        ExecutorService threadpool3 = Executors.newSingleThreadExecutor(); // 只有一个


        try {
            // 10个线程，会显示几个线程~
            for (int i = 1; i <= 100; i++) {
                // 线程池，执行线程
                threadpool3.execute(()->{
                    System.out.println(Thread.currentThread().getName()+" running...");
                });
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            // 线程池关闭
            threadpool3.shutdown();
        }


    }
}
```

> ThreadPoolExecutor 七大参数

分析三个方法的源码

```
public static ExecutorService newFixedThreadPool(int nThreads) {
    return new ThreadPoolExecutor(5, 5,
                                  0L, TimeUnit.MILLISECONDS,
                                  new LinkedBlockingQueue<Runnable>());
}

public static ExecutorService newCachedThreadPool() {
    return new ThreadPoolExecutor(0, Integer.MAX_VALUE,
                                  60L, TimeUnit.SECONDS,
                                  new SynchronousQueue<Runnable>());
}

public static ExecutorService newSingleThreadExecutor() {
    return new FinalizableDelegatedExecutorService
        (new ThreadPoolExecutor(1, 1,
                                0L, TimeUnit.MILLISECONDS,
                                new LinkedBlockingQueue<Runnable>()));
}
```

ThreadPoolExecutor核心方法：

```
public ThreadPoolExecutor(int corePoolSize,  // 核心池子的大小
                          int maximumPoolSize,  // 池子的最大大小
                          long keepAliveTime,  // 空闲线程的保留时间
                          TimeUnit unit,  // 时间单位
                          BlockingQueue<Runnable> workQueue, // 队列
                          ThreadFactory threadFactory, // 线程工厂，不修改！用来创建线程
                          RejectedExecutionHandler handler // 拒绝策略) {
    if (corePoolSize < 0 ||
        maximumPoolSize <= 0 ||
        maximumPoolSize < corePoolSize ||
        keepAliveTime < 0)
        throw new IllegalArgumentException();
    if (workQueue == null || threadFactory == null || handler == null)
        throw new NullPointerException();
    this.acc = System.getSecurityManager() == null ?
            null :
            AccessController.getContext();
    this.corePoolSize = corePoolSize;
    this.maximumPoolSize = maximumPoolSize;
    this.workQueue = workQueue;
    this.keepAliveTime = unit.toNanos(keepAliveTime);
    this.threadFactory = threadFactory;
    this.handler = handler;
}
```

思考：工作中怎么使用线程池？只能够自己根据业务情况去自定义线程池的大小策略，禁止使用Executors。

![image-20200208214359791](https://shidongxu0312.github.io/assets/JUC/image-20200208214359791.png)

> ThreadPoolExecutor 底层工作原理

![image-20200208220455114](https://shidongxu0312.github.io/assets/JUC/image-20200208220455114.png)

```
package com.coding.pool;

import java.util.concurrent.*;

public class Test2 {
    public static void main(String[] args) {
        ExecutorService threadPool = new ThreadPoolExecutor(
                2,
                5, // 线程池最大大小5
                2L,
                TimeUnit.SECONDS, // 超时回收空闲的线程
                new LinkedBlockingDeque<>(3), // 根据业务设置队列大小，队列大小一定要设置
                Executors.defaultThreadFactory(), // 不用变
                new ThreadPoolExecutor.CallerRunsPolicy() //拒绝策略
        );

        // 拒绝策略说明：
        // 1. AbortPolicy （默认的：队列满了，就丢弃任务抛出异常！）
        // 2. CallerRunsPolicy（哪来的回哪去？ 谁叫你来的，你就去哪里处理）
        // 3. DiscardOldestPolicy (尝试将最早进入对立与的人任务删除,尝试加入队列)
        // 4. DiscardPolicy (队列满了任务也会丢弃,不抛出异常)

        try {
            // 队列  RejectedExecutionException 拒绝策略
            for (int i = 1; i <= 10; i++) {
                // 默认在处理
                threadPool.execute(()->{
                    System.out.println(Thread.currentThread().getName()+" running....");
                });
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            threadPool.shutdown();
        }


    }

}
```

四种拒绝策略：

![image-20200208215353631](https://shidongxu0312.github.io/assets/JUC/image-20200208215353631.png)

流程图：

![image-20200208220704628](https://shidongxu0312.github.io/assets/JUC/image-20200208220704628.png)

> 线程池用哪个？生产中如何设置合理参数

在工作中，我们不会使用Executors，自定根据业务来定义线程池！

原因：

1、OOM. 默认大小 integer最大值

2、阿里巴巴开发手册说的

==**注意点：最大参数该如何设置？讲究？**==

CPU 密集型：CPU设置，每一次都要去写吗？

IO 密集型：磁盘读写、 一个线程在IO操作的时候、另外一个线程在CPU中跑，造成CPU空闲。

最大线程数应该设置为 IO任务数！ 大文件读写耗时！单独的线程让他慢慢跑。

```
package com.coding.pool;

import java.util.concurrent.*;

public class Test2 {
    public static void main(String[] args) {

        // 代码级别的
        System.out.println(Runtime.getRuntime().availableProcessors());

        ExecutorService threadPool = new ThreadPoolExecutor(
                2,
                Runtime.getRuntime().availableProcessors(), // 线程池最大大小5
                2L,
                TimeUnit.SECONDS, // 超时回收空闲的线程，假设超过了指定的时间，这个最大的线程就不被
                new LinkedBlockingDeque<>(3), // 根据业务设置队列大小，队列大小一定要设置
                Executors.defaultThreadFactory(), // 不用变
                new ThreadPoolExecutor.CallerRunsPolicy() //拒绝策略
        );

        // 拒绝策略说明：
        // 1. AbortPolicy （默认的：队列满了，就丢弃任务抛出异常！）
        // 2. CallerRunsPolicy（哪来的回哪去？ 谁叫你来的，你就去哪里处理）
        // 3. DiscardOldestPolicy (尝试将最早进入对立与的人任务删除,尝试加入队列)
        // 4. DiscardPolicy (队列满了任务也会丢弃,不抛出异常)

        try {
            // 队列  RejectedExecutionException 拒绝策略
            for (int i = 1; i <= 10; i++) {
                // 默认在处理
                threadPool.execute(()->{
                    System.out.println(Thread.currentThread().getName()+" running....");
                });
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            threadPool.shutdown();
        }


    }

}
```

## 12、四大函数式接口

![image-20200208221814601](https://shidongxu0312.github.io/assets/JUC/image-20200208221814601.png)

![image-20200208221920931](https://shidongxu0312.github.io/assets/JUC/image-20200208221920931.png)

> 函数型接口，有一个输入，有一个输出

![image-20200208222123471](https://shidongxu0312.github.io/assets/JUC/image-20200208222123471.png)

```
package com.coding.function4;

import java.util.function.Function;

public class Demo01 {
    public static void main(String[] args) {
        // new Runnable(); ()-> {}
//
//        Function<String,Integer> function = new Function<String,Integer>() {
//            @Override // 传入一个参数，返回一个结果
//            public Integer apply(String o) {
//                System.out.println("into");
//                return 1024;
//            }
//        };

        // 链式编程、流式计算、lambda表达式
        Function<String,Integer> function = s->{return s.length();};
        System.out.println(function.apply("abc"));
        
    }
}
```

> 断定型接口，有一个输入参数，返回只有布尔值。

![image-20200208222701392](https://shidongxu0312.github.io/assets/JUC/image-20200208222701392.png)

```
package com.coding.function4;

import java.util.function.Predicate;

public class Demo02 {
    public static void main(String[] args) {
//        Predicate<String> predicate = new Predicate<String>(){
//            @Override
//            public boolean test(String o) {
//                if (o.equals("abc")){
//                    return true;
//                }
//                return false;
//            }
//
//        };

        Predicate<String> predicate = s->{return s.isEmpty();};
        System.out.println(predicate.test("abced"));
    }
}
```

> 消费型接口，有一个输入参数，没有返回值

![image-20200208223008099](https://shidongxu0312.github.io/assets/JUC/image-20200208223008099.png)

```
package com.coding.function4;

import java.util.function.Consumer;

public class Demo03 {
    public static void main(String[] args) {
        // 没有返回值，只能传递参数  消费者
//        Consumer<String> consumer = new Consumer<String> () {
//            @Override
//            public void accept(String o) {
//                System.out.println(o);
//            }
//        };

        Consumer<String> consumer =s->{System.out.println(s);};
        consumer.accept("123");

        // 供给型接口  只有返回值，没有参数  生产者

    }
}
```

> 供给型接口，没有输入参数，只有返回参数

![image-20200208223333323](https://shidongxu0312.github.io/assets/JUC/image-20200208223333323.png)

```
package com.coding.function4;

import java.util.function.Supplier;

public class Demo04 {
    public static void main(String[] args) {
//        Supplier<String> supplier =  new Supplier<String>() {
//            @Override
//            public String get() {
//                return "aaa";
//            }
//        };

        Supplier<String> supplier = ()->{return "aaa";};
        System.out.println(supplier.get());
    }
}
```

## 13、Stream流式计算

效率！

> 流（Stream）到底是什么呢？

数据库：保存数据 + SQL操作

数据就是数据，计算交给Stream！

==**集合就是数据，Stream管理计算**==

> 代码验证

```
package com.coding.stream;

import java.util.Arrays;
import java.util.List;

/**
 * 一下数据，进行操作筛选用户：要求：一行代码做出此题，时长1分钟！
 * 1、全部满足偶数ID
 * 2、年龄都大于24
 * 3、用户名转为大写
 * 4、用户名字母倒排序
 * 5、只能输出一个名字
 */
public class StreamDemo {
    public static void main(String[] args) {
        User u1 = new User(11, "a", 23);
        User u2 = new User(12, "b", 24);
        User u3 = new User(13, "c", 22);
        User u4 = new User(14, "d", 28);
        User u5 = new User(16, "e", 26);

        // 集合管理数据
        List<User> list = Arrays.asList(u1, u2, u3, u4, u5);
        // 计算交给Stream
        // 过滤  filter
        // 映射 map
        // 排序， sort
        // 分页   limit
        list.stream()
                .filter(u->{return u.getId()%2==0;})
                .filter(u->{return u.getAge()>24;})
                .map(u->{return u.getUsername().toUpperCase();})
                .sorted((o1,o2)->{return o2.compareTo(o1);})
                .limit(1)
                .forEach(System.out::println);

        // 泛型、注解、反射
        // 链式编程 + 流式计算 + lambda表达式

    }
}
```

## 14、分支合并

> 什么是ForkJoin

大数据：mapreduce

任务切分，结果合并

![image-20200208225359946](https://shidongxu0312.github.io/assets/JUC/image-20200208225359946.png)

> 工作窃取

A 任务1 –> 任务2 –> 任务3 –> 任务4 A领先执行完成 ，帮B执行任务！

B 任务1 –> 任务2 任务3 任务4

工作开始从头，窃取从尾，有效提高速度，双端队列

![image-20200208225613111](https://shidongxu0312.github.io/assets/JUC/image-20200208225613111.png)

> 核心类

ForkJoinPool 对列来执行，找到实现接口的类

WorkQueue 是ForkJoinPool 的 一个内部类。

每一个线程都有一个 WorkQueue ！

**ForkJoinTask** 代表正在 ForkJoinPool 中运行的 任务

![image-20200208230015022](https://shidongxu0312.github.io/assets/JUC/image-20200208230015022.png)

fork： 安排任务异步执行，白话：创建一个子任务

join：当任务完成后互殴去返回的计算结果！

invoke：开始执行！如果计算没有完毕，就会等待！

**子类：**递归 RecursiveTask

![image-20200208230403313](https://shidongxu0312.github.io/assets/JUC/image-20200208230403313.png)

> 代码验证

![image-20200208230619373](https://shidongxu0312.github.io/assets/JUC/image-20200208230619373.png)

```
package com.coding.stream;

import java.util.concurrent.ForkJoinPool;
import java.util.stream.LongStream;

// 裁员就是机会！ 你要加工资的机会来了
public class ForkJoinTest {
    public static void main(String[] args) {
        // test1();  // 10582 ms    60
        // test2();  // 9965 ms    90
        // test3();  // 158 ms   101
    }

    // 正常测试
    public static void test1(){
        long start =  System.currentTimeMillis();

        Long sum = 0L;
        for (Long i = 0L; i <= 10_0000__0000 ; i++) {
            sum +=i;
        }
        long end =  System.currentTimeMillis();
        System.out.println("time:"+(end-start)+" sum:"+sum);
    }


    // ForkJoin测试
    public static void test2(){
        long start =  System.currentTimeMillis();

        ForkJoinPool forkJoinPool = new ForkJoinPool();
        ForkJoinDemo forkJoinDemo = new ForkJoinDemo(0L,10_0000__0000L);
        Long sum = forkJoinPool.invoke(forkJoinDemo);

        long end =  System.currentTimeMillis();
        System.out.println("time:"+(end-start)+" sum:"+sum);
    }

    // Stream并行流测试
    public static void test3(){
        long start =  System.currentTimeMillis();

        long sum = LongStream.rangeClosed(0, 10_0000__0000).parallel().reduce(0, Long::sum);

        long end =  System.currentTimeMillis();
        System.out.println("time:"+(end-start)+" sum:"+sum);
    }

}
```

## 15、异步回调

> 概述

![image-20200208232702042](https://shidongxu0312.github.io/assets/JUC/image-20200208232702042.png)

Futrue 设计初衷： 对将来会发生的结果进行建模~

程序的性能要高，要异步处理！同步并阻塞！

A 线程做完了返回一个结果告诉main我做完了！

Futrue！ ajax

![image-20200208233219875](https://shidongxu0312.github.io/assets/JUC/image-20200208233219875.png)

分布式思想！

![image-20200208233420155](https://shidongxu0312.github.io/assets/JUC/image-20200208233420155.png)

> 实例

```
package com.coding.stream;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;

// CompletableFuture 异步回调, 对将来的结果进行结果，ajax就是一种异步回调！
public class CompletableFutureDemo {
    public static void main(String[] args) throws Exception {
        // 多线程也可以异步回调
//
//        // 没有返回结果,任务执行完了就完毕了！ 新增~
//        CompletableFuture<Void> voidCompletableFuture = CompletableFuture.runAsync(() -> {
//            // 插入数据，修改数据
//            System.out.println(Thread.currentThread().getName() + " 没有返回值！");
//        });
//
//        System.out.println(voidCompletableFuture.get());

        // 有返回结果  ajax。 成功或者失败！
        CompletableFuture<Integer> uCompletableFuture = CompletableFuture.supplyAsync(() -> {
            System.out.println(Thread.currentThread().getName() + " 有返回值！");
            // int i = 10/0;
            return 1024;
        });
        
        // 有一些任务不紧急，但是可以给时间做！占用主线程！假设这个任务需要返回结果！

        System.out.println(uCompletableFuture.whenComplete((t, u) -> { // 正常编译完成！
            System.out.println("=t==" + t); // 正常结果
            System.out.println("=u==" + u); // 信息错误！
        }).exceptionally(e -> { // 异常！
            System.out.println("getMessage=>" + e.getMessage());
            return 555; // 异常返回结果
        }).get());
        
    }
}
```

## 16、JMM

> 问题：请你谈谈你对volatile的理解

volatile 是 轻量级的 同步机制：

1、保证可见性

2、==不保证原子性==

3、禁止指令重排！

> 什么是JMM

JMM 是一个抽象的概念！并不真实存在！一组规范！

Java内存模型：

1、线程解锁前，必须要把共享的变量值刷新会主内存；

2、线程加锁前，必须读取主内存的最新值到自己的工作内存；

3、必须是一把锁！

在你的电脑上运行完好！

主内存 工作内存

> JMM的内存模型

Java 内存模型对主内存与工作内存之间的具体交互协议定义了八种操作，具体如下：

- lock（锁定）：作用于主内存变量，把一个变量标识为一条线程独占状态。
- unlock（解锁）：作用于主内存变量，把一个处于锁定状态的变量释放出来，释放后的变量才可以被其他线程锁定。
- read（读取）：作用于主内存变量，把一个变量从主内存传输到线程的工作内存中，以便随后的 load 动作使用。
- load（载入）：作用于工作内存变量，把 read 操作从主内存中得到的变量值放入工作内存的变量副本中。
- use（使用）：作用于工作内存变量，把工作内存中的一个变量值传递给执行引擎，每当虚拟机遇到一个需要使用变量值的字节码指令时执行此操作。
- assign（赋值）：作用于工作内存变量，把一个从执行引擎接收的值赋值给工作内存的变量，每当虚拟机遇到一个需要给变量进行赋值的字节码指令时执行此操作。
- store（存储）：作用于工作内存变量，把工作内存中一个变量的值传递到主内存中，以便后续 write 操作。
- write（写入）：作用于主内存变量，把 store 操作从工作内存中得到的值放入主内存变量中。

## 17、volatile

**volatile是不错的机制，但是也不能保证原子性。**

> 代码验证可见性

![image-20200208235138783](https://shidongxu0312.github.io/assets/JUC/image-20200208235138783.png)

```
package com.coding.jmm;

import java.util.concurrent.TimeUnit;

public class Test1 {
    // volatile 读取的时候去主内存中读取在最新值！
    private volatile static int num = 0;

    public static void main(String[] args) throws InterruptedException { // Main线程

        new Thread(()->{ // 线程A 一秒后会停止！  0
            while (num==0){

            }
        }).start();

        TimeUnit.SECONDS.sleep(1);

        num = 1;
        System.out.println(num);

    }

}
```

> 验证 volatile 不保证原子性

原子性：ACID 不可分割！完整，要么同时失败，要么同时成功！

```
package com.coding.jmm;

public class Test2 {

    private volatile static  int num = 0;

    public static void  add(){
        num++;
    }

    public static void main(String[] args) {
        for (int i = 1; i <= 20; i++) {
            new Thread(()->{
                for (int j = 1; j <= 1000; j++) {
                    add();  // 20 * 1000 = 20000
                }
            },String.valueOf(i)).start();
        }

        // main线程等待上面执行完成，判断线程存活数   2
        while (Thread.activeCount()>2){ // main  gc
            Thread.yield();
        }

        System.out.println(Thread.currentThread().getName()+" "+num);

    }
}
```

不加 synchronize的能否解决？ 前方高能！

![image-20200209000830477](https://shidongxu0312.github.io/assets/JUC/image-20200209000830477.png)

![image-20200209000901376](https://shidongxu0312.github.io/assets/JUC/image-20200209000901376.png)

```
package com.coding.jmm;

import java.util.concurrent.atomic.AtomicInteger;

// 遇到问题不要着急，要思考如何去做！
public class Test2 {

    private volatile static AtomicInteger num = new AtomicInteger();

    public static void  add(){
        num.getAndIncrement(); // 等价于 num++
    }

    public static void main(String[] args) {
        for (int i = 1; i <= 20; i++) {
            new Thread(()->{
                for (int j = 1; j <= 1000; j++) {
                    add();  // 20 * 1000 = 20000
                }
            },String.valueOf(i)).start();
        }

        // main线程等待上面执行完成，判断线程存活数   2
        while (Thread.activeCount()>2){ // main  gc
            Thread.yield();
        }

        System.out.println(Thread.currentThread().getName()+" "+num);

    }
}
```

> 指令重排讲解

计算及在执行程序的之后，为了提高性能，编译器和处理器会进行指令重排！

处理在指令重排的时候必须要考虑==数据之间的依赖性！==

**指令重排：程序最终执行的代码，不一定是按照你写的顺序来的！**

```
int x = 11;  // 语句1
int y = 12;  // 语句2
x = y + 5;   // 语句3
y = x*x ;    // 语句4

//怎么执行
1234
2134
1324
    
// 请问语句4 能先执行吗？
```

加深 : int x,y,a,b = 0;

| 线程1        | 线程2  |
| ------------ | ------ |
| x = a;       | y = b; |
| b = 1;       | a = 2; |
|              |        |
| x = 0, y = 0 |        |

假设编译器进行了指令重排！

| 线程1     | 线程2  |
| --------- | ------ |
| b = 1;    | a = 2; |
| x = a;    | y =b； |
|           |        |
| x =2，y=1 |        |

```j
package com.coding.jmm;

// 两个线程交替执行的！
public class Test3 {

    int a = 0;
    boolean flag = false;

    public void m1(){  // A
        flag = true;   // 语句2
        a = 1;         // 语句1

    }

    public void m2(){  // B
        if (flag){ 
            a = a + 5;  // 语句3
            System.out.println("m2=>"+a);
        }
    }

}
```

由于有指令重排的问题！

volatite： 实现禁止指令重排！

刨根问底：

**内存屏障**： CPU的指令，作用两个：

1、 保证特定的操作执行顺序

2、保证某些变量的内存可见性

![image-20200209002810362](https://shidongxu0312.github.io/assets/JUC/image-20200209002810362.png)

**线程安全可以获得保证性**

可能存在 指令重排，有序性的问题的时候 volitile ！

volitile ！

## 18、深入单例模式

1、饿汉式

```
package com.coding.single;

public class Hungry {

    private byte[] data1 = new  byte[10240];
    private byte[] data2 = new  byte[10240];
    private byte[] data3 = new  byte[10240];
    private byte[] data4 = new  byte[10240];

    // 单例模式核心思想，构造器私有！
    private Hungry(){

    }

    private final static Hungry HUNGRY = new Hungry();

    public static Hungry getInstance(){
        return HUNGRY;
    }
}
```

2、懒汉式 DCL 双重检测锁

```
package com.coding.single;

public class LazyMan {
    private LazyMan(){
        System.out.println(Thread.currentThread().getName()+"Start");
    }

    private volatile static LazyMan lazyMan;

    public static  LazyMan getInstance(){
        if (lazyMan==null){
            synchronized (LazyMan.class){
                if (lazyMan==null){
                    lazyMan = new LazyMan(); // 可能存在指令重排！
                    /*
                    A：  1    3    2
                    B：  lazyMan = null ；
                    1. 分配对象的内存空间
                    2. 执行构造方法初始化对象
                    3. 设置实例对象指向刚分配的内存的地址， instance = 0xfffff;
                     */
                }
            }
        }
        return lazyMan;
    }

    public static void main(String[] args) {
        for (int i = 0; i < 10; i++) {
            new Thread(()->{
                LazyMan.getInstance();
            }).start();
        }
    }

}
```

3、静态内部类

```
package com.coding.single;

import java.util.concurrent.RecursiveTask;

public class Holder {
    private Holder(){
        
    }
    
    public static Holder getInstance(){
        return InnerClass.HOLDER;
    }
    
    private static class InnerClass {
        private static final Holder HOLDER = new Holder();
    }
}
```

反射：

```Java
package com.coding.single;

import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;

public class LazyMan {

    private static boolean flag = false;

    private LazyMan(){
        synchronized (LazyMan.class){
            if (flag==false){
                flag = true;
            }else {
                throw new RuntimeException("不要试图使用反射破坏单例模式");
            }
        }
    }

    private volatile static LazyMan lazyMan;

    public static  LazyMan getInstance(){
        if (lazyMan==null){
            synchronized (LazyMan.class){
                if (lazyMan==null){
                    lazyMan = new LazyMan(); // 可能存在指令重排！
                    /*
                    A：  1    3    2
                    B：  lazyMan = null ；
                    1. 分配对象的内存空间
                    2. 执行构造方法初始化对象
                    3. 设置实例对象指向刚分配的内存的地址， instance = 0xfffff;
                     */
                }
            }
        }
        return lazyMan;
    }

    public static void main(String[] args) throws NoSuchMethodException, IllegalAccessException, InvocationTargetException, InstantiationException, NoSuchFieldException {

        //LazyMan instance1 = LazyMan.getInstance();
        Constructor<LazyMan> declaredConstructors = LazyMan.class.getDeclaredConstructor(null);
        declaredConstructors.setAccessible(true); // 无视 private 关键字

        Field flag = LazyMan.class.getDeclaredField("flag");
        flag.setAccessible(true);

        LazyMan instance1 = declaredConstructors.newInstance();

        flag.set(instance1,false);


        LazyMan instance2 = declaredConstructors.newInstance();

        System.out.println(instance1);
        System.out.println(instance2);

    }

}
```

4、枚举 （最安全的）

```
package com.coding.single;

import java.lang.reflect.Constructor;

// 枚举是一个类！  EnumSingle.class
public enum EnumSingle {

    INSTANCE;

    public EnumSingle getInstance(){
        return INSTANCE;
    }

    public static void main(String[] args) throws Exception {
        EnumSingle enumSingle2 = EnumSingle.INSTANCE;

        Constructor<EnumSingle> declaredConstructor = EnumSingle.class.getDeclaredConstructor(null);
        declaredConstructor.setAccessible(true);
        // 期望的异常 throw new IllegalArgumentException("Cannot reflectively create enum objects");

        //  java.lang.NoSuchMethodException: com.coding.single.EnumSingle.<init>()
        declaredConstructor.newInstance();
    }

}
```

![image-20200209005338315](https://shidongxu0312.github.io/assets/JUC/image-20200209005338315.png)

jad 反编译工具！

找到万恶之源

```
// Decompiled by Jad v1.5.8g. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3) 
// Source File Name:   EnumSingle.java

package com.coding.single;

import java.lang.reflect.Constructor;

public final class EnumSingle extends Enum
{

    public static EnumSingle[] values()
    {
        return (EnumSingle[])$VALUES.clone();
    }

    public static EnumSingle valueOf(String name)
    {
        return (EnumSingle)Enum.valueOf(com/coding/single/EnumSingle, name);
    }

    private EnumSingle(String s, int i)
    {
        super(s, i);
    }

    public EnumSingle getInstance()
    {
        return INSTANCE;
    }

    public static void main(String args[])
        throws Exception
    {
        EnumSingle enumSingle2 = INSTANCE;
        Constructor declaredConstructor = com/coding/single/EnumSingle.getDeclaredConstructor(null);
        declaredConstructor.setAccessible(true);
        declaredConstructor.newInstance(null);
    }

    public static final EnumSingle INSTANCE;
    private static final EnumSingle $VALUES[];

    static 
    {
        INSTANCE = new EnumSingle("INSTANCE", 0);
        $VALUES = (new EnumSingle[] {
            INSTANCE
        });
    }
}
```

再次测试

```
package com.coding.single;

import java.lang.reflect.Constructor;

// 枚举是一个类！  EnumSingle.class
public enum EnumSingle {

    INSTANCE;

    public EnumSingle getInstance(){
        return INSTANCE;
    }

    public static void main(String[] args) throws Exception {
        EnumSingle enumSingle2 = EnumSingle.INSTANCE;

        Constructor<EnumSingle> declaredConstructor = EnumSingle.class.getDeclaredConstructor(String.class,int.class);
        declaredConstructor.setAccessible(true);
        // 期望的异常 throw new IllegalArgumentException("Cannot reflectively create enum objects");
        // Exception in thread "main" java.lang.IllegalArgumentException: Cannot reflectively create enum objects
        // java.lang.NoSuchMethodException: com.coding.single.EnumSingle.<init>()
        declaredConstructor.newInstance();
    }

}
```

## 19、深入理解CAS

在互联网缩招的情下，初级程序员大量过剩，高级程序员重金难求！

> CAS : 比较并交换

```
package com.coding.cas;

import java.util.concurrent.atomic.AtomicInteger;

public class CASDemo {
    public static void main(String[] args) {
        AtomicInteger atomicInteger = new AtomicInteger(5);

        // compareAndSet  简称 CAS 比较并交换！
        // compareAndSet(int expect, int update)  我期望原来的值是什么，如果是，就更新

        System.out.println(atomicInteger.compareAndSet(5, 2020)+"=>"+atomicInteger.get());

        // 2020
        System.out.println(atomicInteger.compareAndSet(2020, 1024)+"=>"+atomicInteger.get());

    }
}
```

> CAS 底层原理？如果知道，谈谈你对UnSafe的理解？

`getAndIncrement` 分析这个+1是怎么实现的

```
public final int getAndIncrement() {
    return unsafe.getAndAddInt(this, valueOffset, 1);
}
```

java出生就自带的

![image-20200209010408930](https://shidongxu0312.github.io/assets/JUC/image-20200209010408930.png)

![image-20200209010518266](https://shidongxu0312.github.io/assets/JUC/image-20200209010518266.png)

```
public final int getAndAddInt(Object var1, long var2, int var4) {
    int var5;
    do {
        var5 = this.getIntVolatile(var1, var2);
    } while(!this.compareAndSwapInt(var1, var2, var5, var5 + var4));

    return var5;
}
```

Unsafe 就是CAS 的核心类 ！

JAVA 无法直接操作系统的底层！ native

Unsafe 后门！操作特定内存中的数据！ 里面的所有的所有方法 ，都可以像C的指针一样直接操作内存！

native

> 最后解释CAS 是什么

CAS 就是 他是一个 CPU的 并发原语！

它的功能就是判断内存中的某个位置的值，是否是预期值，如果是更新为自己指定的新值，原子性的！内存级别的，连续的

**==本身就不存在了数据不一致的问题！根治！==**

![image-20200209010955717](https://shidongxu0312.github.io/assets/JUC/image-20200209010955717.png)

> 汇编层面理解

Unsafe 类中的 compareAndSwapint，是一个本地方法，该方法的实现位于 unsafe.cpp 中；

![image-20200206193735516](c:/Users/Administrator/Desktop/%E4%BC%98%E8%B4%A8%E8%AF%BE%E9%A2%98%E5%A4%87%E8%AF%BE/JUC%E7%B2%BE%E8%AE%B2/1%E3%80%81%E6%95%99%E6%A1%88/\assets\JUC/image-20200206193735516.png)

> 总结

CAS : 比较当前工作内存的中值和主内存的中值，如果相同，则执行操作，否则就一直比较知道值一致为止！

CAS:

内存值A： 旧的预期值 B ， 想修改为 V！

**CAS的缺点：**

1、循环时间长，开销大！

2、只能保证一个共享变量的原子操作！

3、ABA 问题！？ 狸猫换太子！

## 20、原子引用

> 原子类 AtomicInteger 的ABA问题谈谈？原子更新引用知道吗？

```
package com.coding.cas;

import com.coding.demo02.A;

import java.util.concurrent.atomic.AtomicInteger;

public class CASDemo {
    public static void main(String[] args) {
        AtomicInteger atomicInteger = new AtomicInteger(5);

        // compareAndSet  简称 CAS 比较并交换！
        // compareAndSet(int expect, int update)  我期望原来的值是什么，如果是，就更新

        //  a
        System.out.println(atomicInteger.compareAndSet(5, 2020)+"=>"+atomicInteger.get());

        // c  偷偷的改动
        System.out.println(atomicInteger.compareAndSet(2020, 2021)+"=>"+atomicInteger.get());
        System.out.println(atomicInteger.compareAndSet(2021, 5)+"=>"+atomicInteger.get());


        //  b
        System.out.println(atomicInteger.compareAndSet(5, 1024)+"=>"+atomicInteger.get());

    }
}
```

CAS 会导致 ABA的问题！

CAS算法的前提是：取出内存中某个时刻的数据，并且比较并交换！ 在这个时间差内有可能数据被修改！

**==尽管CAS操作成功！但是不不代表这个过程就是没有问题的！==**

![image-20200209012108317](https://shidongxu0312.github.io/assets/JUC/image-20200209012108317.png)

乐观锁！

> 原子引用 AtomicReference

版本号，时间戳！

![image-20200209012159898](https://shidongxu0312.github.io/assets/JUC/image-20200209012159898.png)

> 版本号原子引用，类似乐观锁

```
package com.coding.cas;

import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;
import java.util.concurrent.atomic.AtomicStampedReference;

/**
 * AtomicReference 原子引用
 * AtomicStampedReference 加了时间戳  类似于乐观锁！ 通过版本号
 */
public class CASDemo2 {
    static AtomicStampedReference<Integer> atomicStampedReference = new AtomicStampedReference<>(100,1);

    public static void main(String[] args) {
        new Thread(()->{
            //1 、 获得版本号
            int stamp = atomicStampedReference.getStamp();
            System.out.println("T1 stamp 01=>"+stamp);

            try {
                TimeUnit.SECONDS.sleep(2);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            atomicStampedReference.compareAndSet(100,101,
                    atomicStampedReference.getStamp(),atomicStampedReference.getStamp()+1);

            System.out.println("T1 stamp 02=>"+atomicStampedReference.getStamp());

            atomicStampedReference.compareAndSet(101,100,
                    atomicStampedReference.getStamp(),atomicStampedReference.getStamp()+1);

            System.out.println("T1 stamp 03=>"+atomicStampedReference.getStamp());

        },"T1").start();

        new Thread(()->{
            // GIT  看到数据被动过了！

            //1 、 获得版本号
            int stamp = atomicStampedReference.getStamp();
            System.out.println("T1 stamp 01=>"+stamp);

            // 保证上面的线程先执行完毕！
            try {
                TimeUnit.SECONDS.sleep(3);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            boolean b = atomicStampedReference.compareAndSet(100, 2019,
                    stamp, stamp + 1);
            System.out.println("T2 是否修改成功："+b);
            System.out.println("T2 最新的stamp："+stamp);
            System.out.println("T2 当前的最新值："+atomicStampedReference.getReference());
        },"T2").start();

    }


}
```

解决ABA 问题： AtomicStampedReference

## 21、Java锁

### 1、公平锁非公平锁

> 是什么

公平锁：就是非常公平，先来后到

非公平锁：就是非常不公平，可以插队！但是有时候插队可以提高效率 3个小时

```
public ReentrantLock() {
    sync = new NonfairSync(); // 默认是非公平锁，随机
}

public ReentrantLock(boolean fair) { // 公平锁
    sync = fair ? new FairSync() : new NonfairSync();
}
```

> 两者区别

公平锁：并发环境下，每个线程在获取到锁的时候都要先看一下这个锁的等待队列！如果为空，那就可以占有锁！否则就要等待！

非公平锁：上来就直接尝试占有该锁！如果失败就会采用类似公平锁的方式！

synchronized ：默认就是非公平锁，改不了

ReentrantLock ：默认就是非公平锁，可以通过参数修改！

### 2、可重入锁

递归锁就是可重入锁！

大门 卧室A 卧室B 厕所

白话：线程可以进入任何一个他已经拥有锁的，锁所同步的代码块！

**==最大的好处：就是避免死锁！==**

![image-20200209014202757](https://shidongxu0312.github.io/assets/JUC/image-20200209014202757.png)

练武不练功，到老一场空！

```
package com.coding.lock;

import java.util.function.Predicate;

public class RTLock {

    public static void main(String[] args) {
        Phone phone = new Phone();

        new Thread(()->{
            phone.sendSMS();
        },"T1").start();

        new Thread(()->{
            phone.sendMail();
        },"T2").start();
    }

}

class Phone {
    public synchronized void sendSMS(){ // 外面的锁
        System.out.println(Thread.currentThread().getName()+" sendSMS");
        sendMail();  // 这个方法本来也是被锁的，但是由于获得了外面的锁，所以这个锁也获得了！
    }
    public synchronized void sendMail(){
        System.out.println(Thread.currentThread().getName()+" sendMail");
    }
}
```

ReentrantLock

```
package com.coding.lock;

import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class RTLock2 {
    public static void main(String[] args) {
        Phone2 phone2 = new Phone2();

        // T1 线程在获得外面锁的时候，也会拿到里面的锁！
        new Thread(phone2,"T1").start();

        new Thread(phone2,"T2").start();

    }
}


class Phone2 implements Runnable{

    Lock lock = new ReentrantLock();

    public void get(){
        lock.lock(); // A  // lock 锁必须匹配！
        // lock.lock(); // A  // lock 锁必须匹配！
        try {
            System.out.println(Thread.currentThread().getName()+"=>get");
            set();
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            lock.unlock(); // A
        }
    }

    public void set(){
        lock.lock(); // B
        try {
            System.out.println(Thread.currentThread().getName()+"=>set");
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            lock.unlock(); // B
        }
    }

    @Override
    public void run() {
        get();
    }
}
```

### 3、自旋锁

自旋锁 spinlock

尝试获取锁的线程不会立即阻塞，采用循环的方式尝试获取锁！减少上下文的切换！缺点会消耗CPU

```
public final int getAndAddInt(Object var1, long var2, int var4) {
    int var5;
    do {
        var5 = this.getIntVolatile(var1, var2);
    } while(!this.compareAndSwapInt(var1, var2, var5, var5 + var4));

    return var5;
}
```

我们手动编写一个锁来测试！

```
package com.coding.lock;

import com.sun.org.apache.bcel.internal.generic.NEW;

import java.util.concurrent.atomic.AtomicReference;

// coding自己定义的艾编程的锁！
public class MyLock {

    // 原子引用 CAS
    AtomicReference<Thread> atomicReference = new AtomicReference<>();


    // 加锁
    public void myLock(){
        Thread thread = Thread.currentThread();
        System.out.println(Thread.currentThread().getName()+"==mylock");

        // 期望是空的没有加锁， thread         // 自旋，（循环！）
        while (atomicReference.compareAndSet(null,thread)){// cas

        }

    }

    // 解锁
    public void myUnlock(){
        Thread thread = Thread.currentThread();
        atomicReference.compareAndSet(thread,null);
        System.out.println(Thread.currentThread().getName()+"==myUnlock");
    }


}
package com.coding.lock;

import java.util.concurrent.TimeUnit;

public class SpinLockDemo {

    public static void main(String[] args) {
        MyLock myLock = new MyLock();

        new Thread(()->{
            myLock.myLock();

            try {
                TimeUnit.SECONDS.sleep(5);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            myLock.myUnlock();

        },"T1").start();


        try {
            TimeUnit.SECONDS.sleep(1);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        new Thread(()->{
            myLock.myLock();

            try {
                TimeUnit.SECONDS.sleep(1);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            myLock.myUnlock();

        },"T2").start();



    }

}
```

### 4、死锁

可重入锁：可以避免死锁！

什么是死锁！

![image-20200209020540430](https://shidongxu0312.github.io/assets/JUC/image-20200209020540430.png)

产生死锁的原因：

1、系统资源不足

2、进程运行顺序不当！

3、资源分配不当！

```JAVA
package com.coding.lock;

import java.util.concurrent.TimeUnit;

public class DeadLock {
    public static void main(String[] args) {
        String lockA = "lockA";
        String lockB = "lockB";

        new Thread(new HoldLockThread(lockA,lockB),"T1").start();
        new Thread(new HoldLockThread(lockB,lockA),"T2").start();
    }
}


class HoldLockThread implements  Runnable{

    private String lockA;
    private String lockB;

    public HoldLockThread(String lockA, String lockB) {
        this.lockA = lockA;
        this.lockB = lockB;
    }

    @Override
    public void run() {
        // A 想要拿B
        synchronized (lockA){
            System.out.println(Thread.currentThread().getName()+"lock:"+lockA+"=>get" + lockB);
            try {
                TimeUnit.SECONDS.sleep(2);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            // B想要拿到A
            synchronized (lockB){
                System.out.println(Thread.currentThread().getName()+"lock:"+lockB+"=>get" + lockA);
            }
        }
    }
}
```

![image-20200209021035948](https://shidongxu0312.github.io/assets/JUC/image-20200209021035948.png)

解决：

```
jps -l
```

![image-20200209021134877](https://shidongxu0312.github.io/assets/JUC/image-20200209021134877.png)

查看死锁现象：`jstack 进程号`

![image-20200209021301528](https://shidongxu0312.github.io/assets/JUC/image-20200209021301528.png)

死锁：看日志 9 10 我分析堆栈！

**==每一个理论，背后一定要去实践！不仅仅是看一遍，还要自己过一遍==**