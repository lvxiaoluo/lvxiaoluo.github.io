```java
public class Singleton{
  private Singleton(){}	//构造器私有
  private static Singleton instance = null;	//初始化对象为null
  public static Singleton getInstance(){// A.B 同时进入存在线程安全，导致实例化多次
    if（instance == null){
      instance = new Singleton();
    }
    return instance;
  }
}
```

1.懒加载，真正需要使用才调用

2.线程安全，如果直接在getInstance方法添加synchronized ，导致每次调用线程都添加了锁，性能下降

另一种方式 编译器构建 ，但不是懒加载的

```java
public class Singleton(){
 	private static Singleton instance = new Singleton();
  private Singleton(){}
  public static Singleton getInstance(){
    return instance;
  }
}
```

java -jar JrebelBrainsLicenseServerforJava-1.0-SNAPSHOT-jar-with-dependencies.jar -p 1010
java -jar eureka-service-0.0.3-SNAPSHOT.jar
```java
public class Singleton{
  private static Singleton instance = null;	//初始化对象为null
  public static Singleton getInstance(){//1
    if（instance == null){//2
      synchroinzed(Singleton.class){//3
        instance = new Singleton();//4
      }
    }
    return instance;
  }
}
```

在多个线程执行语句2后，虽然只有一个线程执行锁抢到3，但可能已经有线程进入2 if代码块，一旦线程A执行完成，线程B获取锁进行对象创建，这样导致对象被创建多次



使用双重锁检查 如下：

```java
public class Singleton{
  private static Singleton instance = null;	//初始化对象为null
  public static Singleton getInstance(){//1
    if（instance == null){//2
      synchroinzed(Singleton.class){//3
        if(instance == null){//4
           instance = new Singleton();//5
        }
      }
    }
    return instance;
  }
}
```

指令重排 happen-before



```java
public class Singleton{
  private volatile static Singleton instance = null;	//初始化对象为null
  public static Singleton getInstance(){//1
    if（instance == null){//2
      synchroinzed(Singleton.class){//3
        if(instance == null){//4
           instance = new Singleton();//5
        }
      }
    }
    return instance;
  }
}
```

使用静态内部类：

```java
public class Singleton(){
  private static class SingletonHolder{
    	private static final Singleton INSTANCE = new Singleton();
  }
  private Singleton(){}
  public static final Singleton getInstance(){
    return SingletonHolder.INSTANCE;
  }
}
```
静态内部类在程序启动时不会加载，只用在第一次调用时才加载，巧妙的使用了JDK类加载机制的特性来实现了懒加载