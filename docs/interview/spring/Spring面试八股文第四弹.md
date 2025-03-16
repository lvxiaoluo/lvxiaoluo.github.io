# Spring面试八股文第四弹



**推荐阅读：**

- **[Spring面试八股文第三弹](http://mp.weixin.qq.com/s?__biz=MzA4NjU1MzA2MQ==&mid=2647726420&idx=1&sn=2e7e47e0e50db8b161f92886865e591e&chksm=87e341deb094c8c89dc90d1b70ac89337f29a0b48d44a4476caebd7da35f1dc90d2db24303e9&scene=21#wechat_redirect)**
- ***\*[JVM面试八股文第三弹（完结）](http://mp.weixin.qq.com/s?__biz=MzA4NjU1MzA2MQ==&mid=2647726128&idx=1&sn=64b1f854ad6aa2ae62bddd5343e495a6&chksm=87e340bab094c9ac51f046e2b8ad1cca46b661fc2d74b3ed398ed003f66c384a8dc4b7bf82c9&scene=21#wechat_redirect)\****
- **[面试八股文系列](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=MzA4NjU1MzA2MQ==&action=getalbum&album_id=1966226418825035778#wechat_redirect)**
- **[程序人生系列](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=MzA4NjU1MzA2MQ==&action=getalbum&album_id=1816486914183512067#wechat_redirect)
  **

### 什么是Spring AOP

AOP是Aspect Oriented Programing的简称，中文为面向切面编程。那AOP解决了什么问题呢？

在编写代码过程中，经常出现重复的代码，一般情况下会将重复的代码抽象成方法，在需要的地方来调用这个方法，这样就可以减少大量的重复代码，但还是会存在一些问题，比如很多地方都调用了这个方法，突然因业务需求又要删掉，但这个方法已经和业务代码混在了一起，修改所有调用这个方法的地方也是一个不小的工作量，这种情况就可以用AOP来解决，比如下图中操作数据库的场景

![图片](https://mmbiz.qpic.cn/mmbiz_png/cBnxLn7axrxQCnaZfzaLtaG0quk3NEBdib2GCIsyQibwbUfxgias3aUxy5OpSg7xf0gu6Uf7PoUqV0Q5zkdNkiam7A/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

从图片中可以看出，除了执行SQL这部分业务代码，其他都是重复性质的非核心业务代码，AOP的作用就是将这部分非核心代码与核心业务代码分离

如果了解代理模式的同学可能马上可以想到，通过动态代理就可以实现这个功能，Spring AOP也是通过动态代理来实现的。

#### AOP的一些名词

- 连接点（Joinpoint），连接点可以理解为程序执行的某个特定位置，比如某个方法执行前或执行后，类的初始化前或初始化后，Spring AOP仅支持方法的连接点，即在方法调用前后、方法抛出异常时这些连接点织入增强
- 切点（Pointcut），表示可以插入增强处理的连接点，程序中会有很多连接点，AOP会通过切点来定位到连接点，进行增强处理
- 增强（Advice），增强时织入目标类连接点的程序
- 目标（Target），将增强织入的目标类
- 织入（Weaving），织入是将增强添加到目标类的具体连接点上的过程
- 切面（Aspect），切面是由切点和增强组成的，Spring AOP将切面定义的横切面逻辑织入切面所指定的连接点中
- 引介（Introduction），引介是一种特殊的增强，它为类添加了一些属性和方法

可能很多人看了这些名词也没理解是啥意思，其实简单来说就是想在程序特定的位置插入执行一段其他程序，想要找到某程序特定的位置，就涉及到了**连接点、切点、目标**等名词，插入就是织入的过程，其他程序就是增强

这些名词之间的关系，如下图（图片来源于见水印）

![图片](https://mmbiz.qpic.cn/mmbiz_png/cBnxLn7axrxQCnaZfzaLtaG0quk3NEBdUL4mFRkV5rL2ibXHEialyN1msqMX6do5JkEibwsR4Nyg64Bl22vwMRTEQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

除了上述名词，还有需要掌握增强类型，就是什么时候执行增强，如下

- 前置增强，表示在目标方法执行前执行增强
- 后置增强，表示在目标方法执行后执行增强
- 环绕增强，表示在目标方法执行前后执行增强
- 异常增强，表示在目标方法抛出异常后执行增强
- 引介增强，表示在目标类中添加一些新的方法和属性

下面举个简单的例子

#### Spring AOP实例

Spring AOP可以通过注解和xml的方式进行配置，下面以使用注解的方式为例

首先导入spring aop的jar包

```
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-aspects</artifactId>
            <version>4.3.7.RELEASE</version>
        </dependency>
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-aop</artifactId>
            <version>5.0.2.RELEASE</version>
        </dependency>
```

在配置文件中开启aop注解

```
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xmlns:aop="http://www.springframework.org/schema/aop"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
       http://www.springframework.org/schema/beans/spring-beans.xsd
       http://www.springframework.org/schema/aop
       http://www.springframework.org/schema/aop/spring-aop-4.3.xsd
       http://www.springframework.org/schema/context
       http://www.springframework.org/schema/context/spring-context-3.0.xsd">
    
    <context:component-scan base-package="aopdemo"/>
    <aop:aspectj-autoproxy/>

</beans>
```

目标类

```
package aopdemo;

import org.springframework.stereotype.Component;

@Component
public class Interview {
    public void interview(){
        System.out.println("面试中..（切点方法）");
    }
}
```

切面类

```
package aopdemo;

import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.*;
import org.springframework.stereotype.Component;

@Component
@Aspect
public class aoptest {
    @Pointcut("execution(* *.interview(..))")
    public void interview(){}

 //前置通知
    @Before("interview()")
    public void beforeInterview(){
        System.out.println("面试前关注路人zhang");
    }
    //后置通知
    @After("interview()")
    public void afterInterview(){
        System.out.println("面试后收到offer");
    }
}
```

测试

```
public class SpringTest {

    @Test
    public void demo(){
        //初始化Spring容器ApplicationContext，加载配置文件
        ApplicationContext application = new ClassPathXmlApplicationContext("applicationContext.xml");
        Interview i = (Interview) application.getBean("interview");
        i.interview();
    }

}
```

输出

```
面试前关注路人zhang
面试中..（切点方法）
面试后收到offer
```

其实就是在打印面试中这个方法的前后织入了增强

### Spring AOP and AspectJ AOP 有什么区别？

Spring AOP and AspectJ AOP的主要区别如下：

| Spring AOP       | AspectJ                        |
| :--------------- | :----------------------------- |
| 属于运行时增强   | 属于编译时增强                 |
| 基于代理         | 基于字节码                     |
| 仅支持方法级织入 | 支持字段、方法、构造函数等织入 |
| 比AspectJ慢      | 比Spring AOP快                 |
| 简单             | 复杂                           |

### JDK动态代理和CGLIB动态代理的区别

> 动态代理也是面试的高频问题，需要掌握

JDK动态代理和CGLIB动态代理是Spring AOP中用到两种动态代理方式，如果目标对象实现了接口，默认情况下会采用JDK的动态代理实现AOP ，如果目标对象没有实现接口，则会采用CGLIB动态代理，它们的区别如下

- JDK动态代理是通过反射机制生成一个实现代理接口的匿名类，在调用具体方法前调用nvokeHandler来处理。而cglib动态代理是利用asm开源包，对代理对象类的class文件加载进来，通过修改其字节码生成子类来处理。
- JDK动态代理的核心是实现InvocationHandler接口，使用invoke()方法进行面向切面的处理，调用相应的通知。cglib动态代理核心是实现MethodInterceptor接口，使用intercept()方法进行面向切面的处理，调用相应的通知。
- JDK动态代理只能代理实现实现接口的类，不能代理没有实现接口的类。CGLIB动态代理是针对类来实现代理的，对指定的目标类生成一个子类，并覆盖其中方法实现增强，不能对final修饰的类进行代理。
- 在JDK1.6之前，CGLIB动态代理的效率比JDK动态代理要高，JDK1.6开始对JDK动态代理优化后，JDK动态代理的效率比CGLIB动态代理要高，但当大量调用的时候，JDK1.6和JDK1.7的效率比CGLIB动态代理效率低一些，到JDK1.8，JDK动态代理的效率比CGLIB动态代理高