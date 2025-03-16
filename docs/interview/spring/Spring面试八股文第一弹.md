# Spring面试八股文第一弹

**推荐阅读：**

- **[Spring面试八股文之IoC](http://mp.weixin.qq.com/s?__biz=MzA4NjU1MzA2MQ==&mid=2647726228&idx=1&sn=ae94e97054ac168083fd2dfa72b0b964&chksm=87e3401eb094c908f6b87ee6748bf2ebc59a1b41e92e2968c6508c4bc52a4e6c6be3079246af&scene=21#wechat_redirect)**
- **[JVM面试八股文第三弹（完结）](http://mp.weixin.qq.com/s?__biz=MzA4NjU1MzA2MQ==&mid=2647726128&idx=1&sn=64b1f854ad6aa2ae62bddd5343e495a6&chksm=87e340bab094c9ac51f046e2b8ad1cca46b661fc2d74b3ed398ed003f66c384a8dc4b7bf82c9&scene=21#wechat_redirect)**
- **[面试八股文系列](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=MzA4NjU1MzA2MQ==&action=getalbum&album_id=1966226418825035778#wechat_redirect)**
- **[程序人生系列](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=MzA4NjU1MzA2MQ==&action=getalbum&album_id=1816486914183512067#wechat_redirect)
  **

**文章目录：**

- Spring概述

- - 什么是Spring?
  - Spring的优缺点是什么？
  - Spring有哪些应用场景
  - Spring由哪些模块组成？
  - Spring 框架中都用到了哪些设计模式？

- Spring控制反转(IoC)

- - 什么是Spring IoC 容器？
  - 控制反转(IoC)的作用是什么？
  - Spring IoC 的实现机制
  - BeanFactory 和 ApplicationContext有什么区别？
  - 什么是依赖注入？
  - 依赖注入的方式有哪些？
  - 如何选择合适的依赖注入方式？



## Spring概述

### 什么是Spring?

Spring 是一款开源的轻量级 Java 开发框架，目的是提高开发人员的开发效率以及系统的可维护性，其核心功能是IoC和AOP，这两块也是Spring部分的面试重点内容

### Spring的优缺点是什么？

**优点：**

- 方便解耦，简化开发

通过Spring提供的IoC容器，我们可以将对象之间的依赖关系交由Spring进行控制，降低耦合

- AOP编程的支持

通过Spring提供的AOP功能，方便进行面向切面的编程，把应用业务逻辑和系统服务分开，例如权限校验、监控等功能

- 事务管理

Spring 提供一个持续的事务管理接口，可以扩展到上至本地事务下至全局事务

- 方便程序的测试

Spring对Junit4支持，可以通过注解方便的测试Spring程序

- 方便集成各种优秀框架

可以集成Struts、Hibernate、MyBatis等框架

- 降低JavaEE API的使用难度

Spring对JavaEE开发中非常难用的一些API（JDBC、JavaMail、远程调用等），都提供了封装，使这些API应用难度大大降低。

> 优点主要还是前两个，就是反复说的IoC和AOP，后面也会重点介绍

**缺点：**

- Spring依赖反射，反射影响性能
- 使用门槛较高，入门较慢（这个比较牵强，凑数的）

### Spring有哪些应用场景

主要是JavaEE企业应用的开发，比如之前用的比较多的SSH，近几年的SSM等

### Spring由哪些模块组成？

先看下官网的图，大致了解下

!![图片](https://mmbiz.qpic.cn/mmbiz_png/cBnxLn7axrw5iadxibkDvicFuyenZtCoNQ2jBibwzXqnU1liaibwzsspTvNHfnjD4ko8LkySWC6rOvuAV7Rmn2Bs4icow/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

从上图可以看大，大致有Data Access/Integration、Web、AOP、Aspects、Instrmentation、Messaging、Core Container、Test几个部分，简单介绍下比较重要的几个部分：

- Data Access/Integration，主要有JDBC、ORM、OXM、JMS、Transactions等几个部分组成，JDBC主要用于访问数据库，比如每个数据库都有不同的API，操作不同的数据库，就需要调用不同的API，而调用JDBC API操纵数据库就避免这种情况。Transactions是提供了对事务的支持。ORM表示提供了对ORM框架的支持。OXM表示对OXM框架的支持。JMS表示支持Java消息服务。（了解即可）
- Web，主要提供了一些针对web开发的集成特性
- AOP，支持面向切面编程
- Aspects，与Aspects集成并提供支持
- Core Container，包含Beans、Core、Context、SpEL，其中Beans提供了BeanFactory，其中beans是受到Spring管理的对象。Core是核心模块，Spring的基本功能都依赖于该库，包括控制反转和依赖注入等。Context提供了一种框架式的对象访问方法
- Test，主要提供测试支持，支持JUnit、TestNG、Mockito等对Spring组件进行单元测试和集成测试

### Spring 框架中都用到了哪些设计模式？

> 这是一个比较高频的面试题

- 工厂模式，Spring使用工厂模式可以通过 `BeanFactory` 或 `ApplicationContext` 创建 bean 对象
- 单例模式，Bean默认就是单例模式（面试时手写单例模式也是个高频面试题）
- 模板方法模式：主要用来减少代码重复，例如jdbcTemplate等
- 代理模式：主要体现在Spring的AOP模块功能实现
- 适配器模式：Spring AOP的 Advice中使用到了适配器模式，以及Spring MVC中适配 Controller时也用到了适配器模式
- 观察者模式：Spring 事件驱动模型
- 装饰者模式：当项目需要连接多个数据库，不同的客户根据需要去访问不同的数据库，装饰者模式可以根据客户的需求动态切换不同的数据源

## Spring控制反转(IoC)

> Spring IOC是一个面试高频点，在实际开发过程中也是非常的重要

### 什么是Spring IoC 容器？

简单来说就是将创建对象的控制权交给Spring框架，IoC是控制反转的意思，这里的**控制**就是指创建对象的控制权，**反转**是指将本来在程序中创建对象的权力交给Spring。

如果是初学者，看到IoC这种概念性的描述不是很容易理解这玩意到底是干什么的，又有什么用？

IoC并不是Spring独有的，而是一种思想，IoC主要的优点有两个，**降低代码之间的耦合度**和**集中资源同一管理，简化开发**

先举个比较容易理解的例子吧，先看不用IoC的写法，先确定一个简单的场景，学校、年级、班级（简单理解为学校由年级组成，年级由班级组成，班级由学生组成），大概需要三个Class，如下

```
class School{
    private Grade grade;
    School(){
        this.grade = new Grade();
    }

    public void printName(){
        System.out.println("路人大学");
    }

}

class Grade{
    private C c; //C表示班级
    Grade(){
        this.c = new C();
    }

}

class C{
    private int studentNum;
    C(){
        this.studentNum = 50;
    }
}
```

将代码运行起来，先new个大学，然后打印大学的名字

```
class test{
    public static void main(String[] args) {
        School school = new School();
        school.printName();
    }
}
```

输出

```
路人大学
```

这时，有人觉得班级的人数写死了，太不方便，要改成可动态修改的，这时需要修改三个类，如下

```
class School{
    private Grade grade;
    School(int studentNum){
        this.grade = new Grade(studentNum);
    }

    public void printName(){
        System.out.println("路人大学");
    }

}

class Grade{
    private C c; //C表示班级
    Grade(int studentNum){
        this.c = new C(studentNum);
    }

}

class C{
    private int studentNum;
    C(int studentNum){
        this.studentNum = 50;
    }
}
```

可以看到代码的整体改动还是比较大的，如果是采用IoC的思想写代码是怎样的呢？

```
class School{
    private Grade grade;
    School(Grade grade){
        this.grade = grade;
    }

    public void printName(){
        System.out.println("路人大学");
    }

}

class Grade{
    private C c; //C表示班级
    Grade(C c){
        this.c = c;
    }

}

class C{
    private int studentNum;
    C(){
        this.studentNum = 50;
    }
}
```

还是将代码运行起来，如下，和不采用IoC还是有些区别的，分别需要自己创建每个类的对象

```
class test{
    public static void main(String[] args) {
        C c = new C();
        Grade grade = new Grade(c);
        School school = new School(grade);
        school.printName();
    }
}
```

输出结果

```
路人大学
```

那这么做有什么好处呢？好像代码量还稍微变多了几行，还是上面的问题，如果要把每个班级的人数换成动态的呢？代码如下

```
class School{
    private Grade grade;
    School(Grade grade){
        this.grade = grade;
    }

    public void printName(){
        System.out.println("路人大学");
    }

}

class Grade{
    private C c; //C表示班级
    Grade(C c){
        this.c = c;
    }

}

class C{
    private int studentNum;
    C(int studentNum){
        this.studentNum = studentNum;
    }
}
```

写main方法，将代码运行起来

```
class test{
    public static void main(String[] args) {
        C c = new C(66);
        Grade grade = new Grade(c);
        School school = new School(grade);
        school.printName();
    }
}
```

可以看到只需要改C这个类就好了，而不是向之前每个类都要改，其实看到这里也很好理解，这是因为这种写法使得类与类之间的耦合性降低了。

在回想之前说的IoC的定义，控制反转，将创建对象的权力从程序中交给Spring，这里是将创建对象的权力从类中交到了main方法中，因为上面说的还没有Spring什么事，只是介绍IoC的思想。

在Spring框架中，mian方法中创建对象的活是由Spring做的，程序员只需要通过Xml或者注解的形式进行配置就行了。

IoC还有一种说法就是DI（Dependency Injection），依赖注入。至于IoC和DI的关系有一种说法是，IoC是一种思想，而DI是IoC的一种实现方式。那什么是依赖注入呢？其实很好理解，就是将你现在需要的对象给你注入进来，比如上述代码中，Grade类中需要C对象，就可以搞个注解或者Xml配置文件，告诉Spring需要C对象，让他创建好了注入进来。

下面就用Spring的Xml方式来配置下上面的代码，这里还需要搞清楚一个bean的概念，什么是bean呢，其实就是Java对象，上面main方法代码中的c、grade、school都可以看成是一个bean，而Spring就负责管理这些bean及它们之间的依赖关系，如下

```
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
       http://www.springframework.org/schema/beans/spring-beans.xsd
       http://www.springframework.org/schema/context
       http://www.springframework.org/schema/context/spring-context-3.0.xsd">
    
    <bean id="c" class="dao.C">
        <constructor-arg value="66"/>
    </bean>

    <bean id="grade" class="dao.Grade">
        <constructor-arg ref="c"/>
    </bean>

    <bean id="school" class="dao.School">
        <constructor-arg ref="grade"/>
    </bean>
```

可以看到每个类都在这里对应着一个bean，并且对每个类的有参构造方法传了相应的参数，这个bean的配置参数也决定了所创建对象的属性。其中bean的可以理解为对象名，class可以理解为该对象是实现的哪个类，constructor-arg可以理解为创建对象时构造函数传的值，可以看到c对象的人数是66，grade对象依赖c对象，school对象依赖grade对象。

其实它们就是对应着如下代码

```
 C c = new C(66);
 Grade grade = new Grade(c);
 School school = new School(grade);
```

然后在把main方法改下就可以运行了，主要时加载下上面的这个xml文件，然后直接从spring拿到school对象就可以了，因为都在xml文件中配置好了

```
class test{
    public static void main(String[] args) {
        //初始化Spring容器ApplicationContext，加载配置文件
        ApplicationContext application = new ClassPathXmlApplicationContext("applicationContext.xml");
        School school = application.getBean(dao.School.class);
        school.printName();
    }
}
```

输出

```
路人大学
```

上述介绍的依赖注入方法是构造方法注入，还有两种其他的依赖注入方法，后面还会介绍。

其实写到这里，我相信很多小伙伴可能是理解IoC的好处，但spring的好处却没有get到，因为好像配置xml文件也没比自己一个一个new对象省下多少事，其实还会有基于注解的配置方式，使用熟练会使得开发简化挺多，及springboot会更大程度上简化配置。

### 控制反转(IoC)的作用是什么？

前面介绍了Spring IoC的概念及使用方法已经提到过了，控制反转（IoC）的作用主要是降低代码之间的耦合度，Spring IoC除了降低代码之间的耦合度，还会管理对象的创建和依赖关系的维护。

### Spring IoC 的实现机制

前面介绍了Spring IoC的使用方法，肯定有人好奇了，怎么配置个xml文件就可以创建对象了呢？

其实这里主要涉及三块知识点，xml文件的配置及解析、工厂模式、反射，可能有些人对反射比较陌生，反射是指是 Java 在运行时（Run time）可以访问、检测和修改它本身状态或行为的一种能力，它允许运行中的 Java 程序获取自身的信息，并且可以操作类或对象的内部属性。

简单来说就是通过解析xml文件获取到对象信息，通过反射获取字节码文件，然后通过字节码文件创建对象，并且在创建对象的过程中使用了工厂模式。

至于Spring 框架是如何通过以上方法实现IoC的大家可以阅读下源码看看，也可以自己实现一个简易的Spring IoC试试，网上很多教程，不算太复杂。

### BeanFactory 和 ApplicationContext有什么区别？

BeanFactory和ApplicationContext是Spring的两大核心接口，都可以当做Spring的容器。至于它们之间的关系，可以打开idea，查看它们的UML类图，如下，从可以看出ApplicationContext是BeanFactory的子接口

![图片](https://mmbiz.qpic.cn/mmbiz_png/cBnxLn7axrw5iadxibkDvicFuyenZtCoNQ2C1PGvMaas0NeGTZZmdyzsxicB1xq9nBldnoolwTmloBhYtUz5TZAHng/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

**两者之间的区别**：

**作用**

BeanFactory接口作用：是Spring里面最底层的接口，包含了各种Bean的定义，读取bean配置文档，管理bean的加载、实例化，控制bean的生命周期，维护bean之间的依赖关系。

ApplicationContext接口作用：ApplicationContext接口作为BeanFactory的派生，除了提供BeanFactory所具有的功能外，还有额外的功能

- 提供在监听器中注册bean的事件
- 载入多个（有继承关系）上下文 ，使得每一个上下文都专注于一个特定的层次，比如应用的web层
- 同时加载多个配置文件
- 统一的资源文件访问方式
- 继承MessageSource，因此支持国际化

**加载方式**

BeanFactroy：采用的是延迟加载形式来注入Bean，也就是只有在使用到某个bean时，才会对该bean进行加载实例化，这样的弊端很明显，就是如果spring的配置存在问题，那么只有BeanFactory加载后，使用到这个bean时才可以发现问题。

ApplicationContext：ApplicationContext采用的是预加载机制，在容器启动时，一次性创建所有的bean。这种可以避免BeanFactory接口中出现的问题，容器启动时就可以发现Spring配置中存在的错误，但缺点是会占用内存空间，并且当配置的bean较多时，程序启动会变慢。

**创建方式**

BeanFactroy：采用编程的方式创建，如`BeanFactory factory = new XmlBeanFactory (new ClassPathResource("beans.xml"));`

ApplicationContext：除了采用编程的方式创建，还可以使用声明的方式创建，在web.xml文件添加如下代码

```
<!--指定Spring配置文件的位置，有多个配置文件时，以逗号分隔-->
<context-param>
    <param-name>contextConfigLocation</param-name>
    <!--spring将加载spring目录下的applicationContext.xml文件-->
    <param-value>
        classpath:spring/applicationContext.xml
    </param-value>
</context-param>
<!--指定以ContextLoaderListener方式启动Spring容器-->
<listener>
    <listener-class>
        org.springframework.web.context.ContextLoaderListener
    </listener-class>
</listener>
```

**注册方式**

BeanFactory和ApplicationContext都支持BeanPostProcessor、BeanFactoryPostProcessor的使用，但两者之间的区别是：BeanFactory需要手动注册，而ApplicationContext则是自动注册。

### 什么是依赖注入？

前面在介绍IoC时已经介绍过了依赖注入，依赖注入是指程序运行过程中，如果需要调用另一个对象协助时，无须在代码中创建被调用者，而是**依赖**于外部的**注入**

举个简单例子看看什么是依赖注入，先看原始的写法

```
public class Car {
    private wheel wheel;

    public Car() {
        wheel = new wheel();
    }
}
```

再看看依赖注入的写法

```
public class Car {
    private wheel wheel;

    public Car(wheel wheel) {
        this.wheel = wheel;
    }
}
```

看起来也没啥卵区别，代码都没多一行，其实这里最关键的部分是对象是在哪里创建的，原始的写法，哪里需要对象就在哪里创建，而依赖注入的写法是哪里需要对象就在哪里注入。

### 依赖注入的方式有哪些？

常用的依赖注入方法有构造函数注入和属性注入，除此之外，Spring还支持工厂方法注入。

在前面介绍Spring IoC时已经介绍过构造方法注入了，接下来简单介绍下属性注入和工厂方法注入

#### 属性注入

属性注入是使用频率非常高的依赖注入方法，具体如下

```
class Car{
    private int price;
    private String name;
    public void setPrice(int price){
        this.price = price;
    }
    public void setName(String name){
        this.name = name;
    }

    public void printCar(){
        System.out.println("carName：" + name + " carPrice：" + price);
    }
}
```

applicationContext.xml文件中配置参数值

```
    <bean id="car" class="dao.Car">
        <property name="price"><value>100</value></property>
        <property name="name"><value>小推车</value></property>
    </bean>
```

测试

```
class test{
    public static void main(String[] args) {
        //初始化Spring容器ApplicationContext，加载配置文件
        ApplicationContext application = new ClassPathXmlApplicationContext("applicationContext.xml");
        Car car = application.getBean(dao.Car.class);
        car.printCar();
    }
}
```

输出

```
carName：小推车 carPrice：100
```

#### **工厂方法注入**

由于Spring IoC容器以框架的形式提供工厂方法的功能，很少需要手动编写基于工厂方法的类，所以工厂方法注入并不常用，可以简单了解一下。工厂方法注入可以分为**静态方法注入**和**非静态方法注入**

##### 静态方法注入

除了上面Car类，还需要先创建一个工厂类

```
class CarFactory{
    public static Car creatCar(){
        Car car = new Car();
        car.setName("路人车");
        car.setPrice(200);
        return car;
    }
}
```

配置applicationContext.xml，需要指定静态方法及工厂类

```
<bean id="car2" class="dao.CarFactory" factory-method="creatCar"/>
```

测试

```
class test{
    public static void main(String[] args) {
        //初始化Spring容器ApplicationContext，加载配置文件
        ApplicationContext application = new ClassPathXmlApplicationContext("applicationContext.xml");
        Car car = (Car) application.getBean("car2");
        car.printCar();

    }
}
```

输出

```
carName：路人车 carPrice：200
```

##### 非静态方法注入

非静态方法注入相比于静态方法注入要费事一些，因为需要先实例化工厂类后才可以调用工厂方法，这也是类和静态类的区别

还是先创建工厂类，这次是非静态的

```
class CarFactory{
    public  Car creatCar(){
        Car car = new Car();
        car.setName("路人车");
        car.setPrice(300);
        return car;
    }
}
```

配置applicationContext.xml，和静态工厂方法不同，需要先实例化工厂类，所以先配置了一个工厂bean，并将car2的factory-bean指向工厂bean，factory-method指向工厂的方法

```
    <bean id="carFactory" class="dao.CarFactory"/>
    <bean id="car2" factory-bean="carFactory" factory-method="creatCar"/>
```

测试

```
class test{
    public static void main(String[] args) {
        //初始化Spring容器ApplicationContext，加载配置文件
        ApplicationContext application = new ClassPathXmlApplicationContext("applicationContext.xml");
        Car car = (Car) application.getBean("car2");
        car.printCar();

    }
}
```

输出

```
carName：路人车 carPrice：300
```

### 如何选择合适的依赖注入方式？

在实际应用中，没有最好的依赖注入方式，只有最合适的依赖注入方式

**选择构造函数注入的理由：**

- 不需要为每个属性提供Setter方法，减少了类的方法个数
- 构造函数可以保证一些重要的属性在Bean实例化时就设置好，避免因为一些重要属性没有提供而导致一个无用Bean实例的情况
- 可以吧更好地封装变量，不需要为每个属性指定Setter的方法，避免外部错误调用

**选择属性注入的理由：**

- 如果类的属性很多，构造函数将会变得非常臃肿，可读性较差
- 构造函数注入不够灵活，如果有些属性是可选的，也需要为可选参数提供null值
- 存在多个构造函数，需要配置文件和构造函数配置歧义问题，配置比较复杂
- 构造函数不利于类的集成和扩展，因为子类需要引用父类复杂的构造函数
- 构造函数注入可能产生循环依赖问题

参考：《精通Spring4.x企业应用开发实战》