# Spring面试八股文第二弹

**推荐阅读：**

- [Spring面试八股文第一弹](http://mp.weixin.qq.com/s?__biz=MzA4NjU1MzA2MQ==&mid=2647726281&idx=1&sn=7028e6294a58aac7f2444ae8a7feaecd&chksm=87e34043b094c955631f4248d75c7eab6aefc353e15a569d925637b95ea91332159d573dbc48&scene=21#wechat_redirect)
- [JVM面试八股文第三弹（完结）](http://mp.weixin.qq.com/s?__biz=MzA4NjU1MzA2MQ==&mid=2647726128&idx=1&sn=64b1f854ad6aa2ae62bddd5343e495a6&chksm=87e340bab094c9ac51f046e2b8ad1cca46b661fc2d74b3ed398ed003f66c384a8dc4b7bf82c9&scene=21#wechat_redirect)
- [面试八股文系列](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=MzA4NjU1MzA2MQ==&action=getalbum&album_id=1966226418825035778#wechat_redirect)
- [程序人生系列](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=MzA4NjU1MzA2MQ==&action=getalbum&album_id=1816486914183512067#wechat_redirect)

**文章目录：**

- Spring Bean

- - 什么是Spring bean？
  - 将一个类声明为Spring的 bean 的注解有哪些?
  - 如何给Spring 容器提供配置元数据？Spring有几种配置方式？
  - Spring基于xml注入bean的几种方式
  - Spring 中的 Bean 的作用域有哪些?
  - Spring框架中的单例bean是线程安全的吗？
  - 解释Spring框架中bean的生命周期
  - 什么是bean的自动装配？
  - Spring 自动装配 bean 有哪些方式？
  - 自动装配有哪些局限性？



## Spring Bean

### 什么是Spring bean？

Spring bean是Spring框架在运行时管理的对象，比如在xml进行配置的bean。

### 将一个类声明为Spring的 bean 的注解有哪些?

Spring中将类声明为Bean的注解主要有以下几个：

- @Component，通用的注解，可标注任意类为 Spring 组件。如果一个Bean不知道属于哪个层，通常使用这个
- @Controller，对应 Spring MVC控制层，主要用户接受用户请求并调用 Service 层返回数据给前端页面。
- @Repostory，对应持久层即 Dao 层，主要用于数据库相关操作。
- @Service，对应服务层，主要涉及一些复杂的逻辑，需要用到 Dao层。

从上面几个注解的名字上也很容易判断出注解用在哪里。

### 如何给Spring 容器提供配置元数据？Spring有几种配置方式？

Spring配置元数据的方式主要有三种方式：

- 基于XML文件配置元数据
- 基于注解配置元数据
- 基于Java类配置元数据

之前举了很多例子都是基于XML文件配置元数据，下面简单说说基于注解和基于Java类配置元数据

#### 基于注解配置元数据

其实无论是XML文件还是注解，本质上都是为Spring容器提供Bean定义的信息，采用XML文件和采用注解的区别就是，采用XML文件配置元数据时，Bean定义信息和Bean实现类本身是分离的，而采用注解配置元数据时，Bean定义信息可以在Bean实现类上直接标注注解实现。

前面刚提到将一个类声明名为bean的注解有哪些，其实用注解配置元数据还是非常简单的，就是在类上面加上注解就好了，如下

```
@Component
public class LuRenZhang{
    .......
}
```

除了在类上面直接加注解，还得在XML文件中定义下扫描包用于扫描注解定义的Bean，如下

```
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
       http://www.springframework.org/schema/beans/spring-beans.xsd
       http://www.springframework.org/schema/context
       http://www.springframework.org/schema/context/spring-context-3.0.xsd">

    <context:component-scan base-package="dao" />

</beans>
```

然后就可以进行依赖注入了，通过@Autowired注解，如下

```
@Service
public class LuRenService{
    @Autowired //将上面定义的Bean注入
    private LuRenZhang luRenZhang;
    
    ......
}
```

#### 基于Java类配置元数据

基于Java类配置元数据也很简单，需要两个注解，在类上标注@Configuration，标注这个注解的类表示其是作为Bean定义的来源，在类中的方法上标注@Bean定义Bean，如下

先写个User类

```
class User{
    private String name;
    private int age;
    public User(String name, int age){
        this.name = name;
        this.age = age;
    }
    public void print(){
        System.out.println("名字："+ name + " 年龄：" + age);
    }
}
```

再写个Bean配置类

```
@Configuration
class BeanConfiguration {

    @Bean
    public User user(){
        return new User("路人张",18);
    }

}
```

通过`AnnotationConfigApplicationContext`实例化Spring容器，如下

```
class test{
    public static void main(String[] args) {
        ApplicationContext application = new AnnotationConfigApplicationContext(BeanConfiguration.class);
        User user= application.getBean(User.class);
        user.print();
    }
}
```

输出：

```
名字：路人张 年龄：18
```

也可以通过注解@Autowired注入

```
class School{
    @Autowired
    private User user;
//    .......
}
```

类比XML文件配置元数据，@Configuration相当于XML文件中<beans>的，@Beanx相当于XML文件中<bean>的，就好理解多了。

### Spring基于xml注入bean的几种方式

在介绍Spring IoC时介绍过了，主要有三种：

- 基于属性注入
- 基于构造方法注入
- 基于工厂方法注入

### Spring 中的 Bean 的作用域有哪些?

常见的Spring Bean的作用域主要有五种：

- **singleton**：Spring中的Bean默认都是单例的，也就是Bean在每个Spring ioc 容器中只有一个实例。
- **prototype**：每次请求都会创建一个新的 bean 实例。
- **request**：每次http请求都会创建一个bean，该作用域仅在基于web的Spring ApplicationContext情形下有效。
- **session**：在一个HTTP Session中，一个bean定义对应一个实例。该作用域仅在基于web的Spring ApplicationContext情形下有效。
- **global-session**：在一个全局的HTTP Session中，一个bean定义对应一个实例。该作用域仅在基于web的Spring ApplicationContext情形下有效。

需要注意的是：使用prototype需要慎重，频繁创建和销毁bean会带来比较大的性能开销。

### Spring框架中的单例bean是线程安全的吗？

Spring中的单例bean不是线程安全的，不过如果没有涉及到多线程也不需要考虑这个问题。

单例bean全局只有一个bean，是线程共享的。简单来说就是如果这个bean是有状态的，会对bean的成员变量进行写操作，那就是线程不安全的。如果bean是无状态的，对bean的成员变量进行读操作，那就是线程安全的。这里的有状态一般是指具备数据存储功能，无状态一般不具备数据存储功能，比如查询等。

那如何解决单例bean的线程安全问题呢？

- 在Bean对象中尽量不定义可边的成员变量
- 将Bean定义成多例的，每次请请求都创建一个新的bean

大家可能也都看出来了这两种办法不太靠谱，比较推荐的是将Bean中的成员变量保存在ThreadLocal中，因为ThreadLocal本身就具备线程间数据隔离的作用。

### 解释Spring框架中bean的生命周期

Beand的生命周期比较长，并且不是很容易记住，如下图

![图片](https://mmbiz.qpic.cn/mmbiz_png/cBnxLn7axrziaHgpE5frbZK5RKia5vRt43w2rg2RYkRq6g8Zzgok454yMG2B15z3ibia3J1JoPKsRRQrYPbXmgick5A/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

具体步骤如下：

1. 首先通过`getBean()`方法向容器请求一个Bean
2. 如果容器注册了InstantiationAwareBeanPostProcessor接口，则在实例化Bean前调用接口的`postProcessBeforeInstantiation()`方法
3. 根据配置情况调用Bean构造函数或工厂方法实例化Bean
4. 如果容器注册了InstantiationAwareBeanPostProcessor接口，在实例化Bean之后，调用接口的`postProcessAfterInstantiation()`方法
5. 如果Bean配置了属性信息，容器会将配置值设置到Bean对应的属性中，不过在设置每个属性前将先调用InstantiationAwareBeanPostProcessor接口的`postProcessPropertyValues()`方法
6. 调用Bean的属性设置方法设置属性值
7. 如果Bean实现了BeanNameAware接口，则将调用`setBeanName()`方法，将配置文件中的该Bean对应的名称设置到Bean中
8. 如果Bean实现了BeanFactoryAware接口，则将调用`setBeanFactory()`方法，将BeanFactory容器实例设置到Bean中
9. 如果BeanFactory装配了BeanPostProcessor后处理器，则将调用BeanPostProcessor的`postProcessBeforeInstantiation(Object bean, String beanName)`方法对Bean进行加工操作。其中，参数Object bean是指当前正在处理的Bean，而beanName是当前Bean的配置名，返回对象为加工处理后的Bean
10. 如果Bean实现了InitializingBean接口，则将调用接口的`afterPropertiesSet()`方法
11. 如果在Bean中通过init-method属性定义了初始方法，则将执行这个方法
12. BeanPostProcessor后处理器定义了两个方法，其中一个在第8步中调用过了，这里调用`postProcessAfterinitialization(Object bean, String beanName)`方法再次对Bean进行加工处理
13. 如果没有指定Bean的范围，则Bean的默认范围为单例，将Bean放入Spring IoC容器的缓存池中，并将Bean返回给调用者
14. 如果Bean实现了DisposableBean接口，则将调用接口的`destory()`方法
15. 如果通过的destory-method属性指定了Bean的销毁方法，那么将执行这个方法完成对Bean资源的释放

### 什么是bean的自动装配？

之前都是在XML文件中进行手动装备配的，除此之外，Spring也提供了Bean之间的自动装配功能，在Spring的XML配置文件中，通过的autowire属性可以为bean指定自动装配的形式。

### Spring 自动装配 bean 有哪些方式？

在Spring中实现自动装配的方式有两类，一个是通过XML文件，还有一类是通过注解

#### 通过XML文件

XML文件中的有一个指定自动装配类型的属性为autowire，autowire有4种装配类型。

- byName，根据名称自动装配，Spring会将属性名和bean名称进行匹配，如果可以找到就会将bean装配给属性。比如LuRenZhang有一个house属性，而刚好有一个名称为house的bean，则会将bean装配到house属性上
- byType，根据类型自动装配，Spring会将属性类型和bean类型进行匹配，如果可以找到就会将bean装配给属性。比如LuRenZhang有一个House类型的属性，而刚好有一个类型为House的bean，则会将bean装配到house属性上
- constructor，Spring容器会尝试找到那些类型与构造函数相匹配的bean，比如LuRenZhang有一个构造函数，构造函数中需要传一个House类型的参数，而刚好有一个类型为House的bean，则会将bean装配到构造函数的参数上
- autodetect，根据Bean的自省机制决定采用byType还是constructor，首先尝试通过 constructor 来自动装配，如果它不执行，则Spring 尝试通过 byType 来自动装配（spring5.x已经没有了）

举个简单例子，先建两个类，User类，House类

```
public class House {

    public int getHousePrice() {
        return housePrice;
    }

    public void setHousePrice(int housePrice) {
        this.housePrice = housePrice;
    }

    private int housePrice;


}
public class User {

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public void setUserAge(int userAge) {
        this.userAge = userAge;
    }


    public void setUserAddress(String userAddress) {
        this.userAddress = userAddress;
    }

    public void setHouse(House house) {
        this.house = house;
    }


    public String getUserName() {
        return userName;
    }

    public int getUserAge() {
        return userAge;
    }

    public String getUserAddress() {
        return userAddress;
    }

    public House getHouse() {
        return house;
    }

    private String userName;
    private int userAge;
    private String userAddress;
    private House house;

    public User() {
    }

    public User(int userId, String userName, int userAge, String userPwd,
                String userAddress, House house) {
        this.userName = userName;
        this.userAge = userAge;
        this.userAddress = userAddress;
        this.house = house;
    }

}
```

配置XML文件，手动装配bean时

```
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
       http://www.springframework.org/schema/beans/spring-beans.xsd
       http://www.springframework.org/schema/context
       http://www.springframework.org/schema/context/spring-context-3.0.xsd">

    <bean id="house" class="dao.House">
        <property name="housePrice" value="100"/>
    </bean>

    <bean id="user" class="dao.User">
        <!--注入普通值：使用 value 属性-->
        <property name="userName" value="路人张"/>
        <property name="userAge" value="18"/>
        <property name="userAddress" value="北京"/>
        <property name="house" ref="house"/>
    </bean>

</beans>
```

测试：

```
class test{
    public static void main(String[] args) {
        //初始化Spring容器ApplicationContext，加载配置文件
        ApplicationContext application = new ClassPathXmlApplicationContext("applicationContext.xml");
        User user =  application.getBean("user", User.class);
        System.out.println(user.getUserName()+" 房子价值："+user.getHouse().getHousePrice());

    }
}
```

结果

```
路人张 房子价值：100
```

通过byType自动装配，只需改两行代码，加上`autowire="byType"`，注释或者删掉` <property name="house" ref="house"/>`

```
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
       http://www.springframework.org/schema/beans/spring-beans.xsd
       http://www.springframework.org/schema/context
       http://www.springframework.org/schema/context/spring-context-3.0.xsd">

    <bean id="house" class="dao.House">
        <property name="housePrice" value="100"/>
    </bean>

    <bean id="user" class="dao.User" autowire="byType">
        <!--注入普通值：使用 value 属性-->
        <property name="userName" value="路人张"/>
        <property name="userAge" value="18"/>
        <property name="userAddress" value="北京"/>
<!--        <property name="house" ref="house"/>-->
    </bean>

</beans>
```

测试结果还是

```
路人张 房子价值：100
```

这时可能有人会问了，如果使用byName或byType时，在XML文件中多个相同名字的bean或者相同类型的bean怎么半，会报异常的。

#### 通过注解

通过注解自动装配bean主要是通过@Autowired等注解完成，前面提到了将类声明为bean的几个注解，还是上面那个例子，如下，通过@Component将类声明为bean，通过@Value这个注解将一些常量值注入到变量中，通过@Autowired将bean装配到属性中

```
@Component
public class User {


    public String getUserName() {
        return userName;
    }

    public int getUserAge() {
        return userAge;
    }

    public String getUserAddress() {
        return userAddress;
    }

    public House getHouse() {
        return house;
    }

    @Value(value = "路人张")
    private String userName;
    @Value(value = "18")
    private int userAge;
    @Value(value = "北京")
    private String userAddress;
    @Autowired
    private House house;

    public User() {
    }

    public User(int userId, String userName, int userAge, String userPwd,
                String userAddress, House house) {
        this.userName = userName;
        this.userAge = userAge;
        this.userAddress = userAddress;
        this.house = house;
    }

}
@Component
public class House {

    public int getHousePrice() {
        return housePrice;
    }

    @Value(value = "100")
    private int housePrice;


}
```

测试

```
class test{
    public static void main(String[] args) {
        //初始化Spring容器ApplicationContext，加载配置文件
        ApplicationContext application = new ClassPathXmlApplicationContext("applicationContext.xml");
        User user =  application.getBean("user", User.class);
        System.out.println(user.getUserName()+" 房子价值："+user.getHouse().getHousePrice());

    }
}
```

输出

```
路人张 房子价值：100
```

要想让代码可以正常运行，还需要在XML文件中配置组件自动扫描的包，如下。

```
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
       http://www.springframework.org/schema/beans/spring-beans.xsd
       http://www.springframework.org/schema/context
       http://www.springframework.org/schema/context/spring-context-3.0.xsd">

    <context:component-scan base-package="dao" />

</beans>
```

需要注意的是@Autowired：它默认是按byType进行匹配，如果存在多个相同类型的bean，可以使用@Qualifier指定bean的名字，例如@Qualifier(value="user")

### 自动装配有哪些局限性？

- 不能自动装配简单的属性，如基本数据类型，String字符串，和类
- 自动装配不如显式装配精确，可能会引发意想不到的问题

参考：《精通Spring4.X 企业应用开发实战》