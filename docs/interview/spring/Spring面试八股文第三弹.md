# Spring面试八股文第三弹



**推荐阅读：**

- **[分享一道超高频的Spring面试题](http://mp.weixin.qq.com/s?__biz=MzA4NjU1MzA2MQ==&mid=2647726356&idx=1&sn=d07513d03bb189d57313c22b5f7ae04c&chksm=87e3419eb094c888dceb5da1e9e61b4b0dfde2de61f90ac21fdf13f64583f06ef7ad533d37a9&scene=21#wechat_redirect)**
- **[JVM面试八股文第三弹（完结）](http://mp.weixin.qq.com/s?__biz=MzA4NjU1MzA2MQ==&mid=2647726128&idx=1&sn=64b1f854ad6aa2ae62bddd5343e495a6&chksm=87e340bab094c9ac51f046e2b8ad1cca46b661fc2d74b3ed398ed003f66c384a8dc4b7bf82c9&scene=21#wechat_redirect)**
- **[面试八股文系列](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=MzA4NjU1MzA2MQ==&action=getalbum&album_id=1966226418825035778#wechat_redirect)**
- **[程序人生系列](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=MzA4NjU1MzA2MQ==&action=getalbum&album_id=1816486914183512067#wechat_redirect)
  **

**文章目录**

- 如何开启注解装配？

- Spring bean 相关注解

- - @Component, @Controller, @Repository, @Service 有何区别？
  - @Autowired 注解有什么作用?
  - @Qualifier 注解有什么作用
  - @Configuration注解有什么用？@Bean注解有什么用？
  - @Value注解有什么用？
  - @Scope注解有什么用？

- Web开发相关注解

- - @Controller注解有什么用？
  - @ResponseBody注解有什么用？
  - @RestController注解有什么用？
  - @RequestMapping注解有什么用？
  - @PathVariable 注解有什么用？
  - @RequestBody注解有什么用？
  - @GetMapping、@PostMapping、@PutMapping、@DeleteMapping注解有什么用？

- Spring AOP相关注解

- Spring支持的事务管理类型， Spring 事务实现方式有哪些？

- Spring 的事务隔离级别有哪些？

- Spring事务的传播行为有哪些？

- Spring框架的事务管理有哪些优点？



# Spring注解

## 如何开启注解装配？

这个只需要在Spring配置文件中添加注解扫描即可，即`<context:annotation-config/>`或`<context:component-scan>`，其中`<context:annotation-config>`表示的是注解扫描是针对已经在Spring容器里注册过的Bean，`<context:component-scan>`不仅具备`<context:annotation-config>`的所有功能，还可以在指定的package下面扫描对应的bean。

## Spring bean 相关注解

> Spring Bean相关的注解主要有@Component, @Controller, @Repository, @Service，@Autowired，@Qualifier，@Configuration，@Value，@Bean，@Scope

### @Component, @Controller, @Repository, @Service 有何区别？

这个之前写过了，如下

- @Component，通用的注解，可标注任意类为 Spring 组件。如果一个Bean不知道属于哪个层，通常使用这个。
- @Controller，对应 Spring MVC控制层，主要用户接受用户请求并调用 Service 层返回数据给前端页面。
- @Repostory，对应持久层即 Dao 层，主要用于数据库相关操作。
- @Service，对应服务层，主要涉及一些复杂的逻辑，需要用到 Dao层。

### @Autowired 注解有什么作用?

主要用于依赖注入，标注在类的成员变量、方法及构造方法上，将它们依赖的bean注入到类的成员变量、方法及构造方法中，如下，将TestService的bean注入到testService属性中

```
@Service
public class TestService {
  ......
}

public class TestController {
   @Autowired
   private TestService testService;
   ......
}
```

### @Qualifier 注解有什么作用

@Qualifier通常和@Autowired一起使用，比如当存在多个类型相同的bean时，如果@Autowired采用的是byType时可能会出现混乱，可以搭配@Qualifier使用，只需要在@Qualifier中写上bean的名称即可，如下

```
@Service("testService1")
public class TestService1 implements TestService{
  ......
}

@Service("testService2")
public class TestService2 implements TestService{
  ......
}

public class TestController {
   @Autowired
   @Qualifier("testService1")
   private TestService testService;
   ......
}
```

### @Configuration注解有什么用？@Bean注解有什么用？

`@Configuration`用于定义配置类，可替换`xml`配置文件，被注解的类内部包含有一个或多个被`@Bean`注解的方法，这些方法将会被`AnnotationConfigApplicationContext`或`AnnotationConfigWebApplicationContext`类进行扫描，并用于构建`bean`定义，初始化`Spring`容器。

简单来说就是@Configuration可以看成xml配置文件，@Bean可以看成xml文件中的`<bean> </bean>`，具体使用如下

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
@Configuration
class BeanConfiguration {

    @Bean
    public User user(){
        return new User("路人张",18);
    }

}
```

相当于这玩意

```
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
       http://www.springframework.org/schema/beans/spring-beans.xsd
       http://www.springframework.org/schema/context
       http://www.springframework.org/schema/context/spring-context-3.0.xsd">

    <bean id="user" class="dao.User">
        <constructor-arg index="0" value="路人张"/>
        <constructor-arg index="1" value="18"/>
    </bean>

</beans>
```

### @Value注解有什么用？

@Value主要用于对属性赋值，有三种用法

- @Value(“常量”) ，直接赋值常量，包括字符串等
- @Value(“${}”` : default_value`) ，比较常用的读取配置文件
- @Value(“#{}”`? : default_value`)，读取注入其他bean的属性或者表达式

举例如下

```
public class Person {
 @Value("路人张")   //属性name直接赋值
 private String name;
 @Value("#{20-2}")   //通过表达式对属性age赋值
 private Integer age;
 @Value("${person.sex}") //获取配置文件中的值对属性sexe进行赋值
 private String sex;
  
}
```

配置文件的值

```
person.sex = 男
```

### @Scope注解有什么用？

@Scope用于声明 Spring Bean 的作用域，作用于方法上，bean的作用域有Singleton 、Prototype、Request 、 Session、GlobalSession等，代码如下

```
@Bean
@Scope("singleton")
public User user(){
    return new User("路人张",18);
}
```

## Web开发相关注解

> Web相关注解有@Controller、@RestController、@RequestMapping、@GetMapping、@PostMapping、@PutMapping、@DeleteMapping、@ResponseBody、@RequestBody、@PathVariable

### @Controller注解有什么用？

@Controller，对应 Spring MVC控制层，主要用户接受用户请求并调用 Service 层返回数据给前端页面。

### @ResponseBody注解有什么用？

@ResponseBody通常和@Controller一起使用，@ResponseBody注解的作用是将controller的方法返回的对象通过适当的转换器转换为指定的格式之后，写入到response对象的body区（响应体中），通常用来返回JSON数据或者是XML。

```
@RequestMapping("/login")
@ResponseBody
public User login(User user){
    return user;
}
```

### @RestController注解有什么用？

@RestController注解的作用就相当于@Controller加上@ResponseBody。

### @RequestMapping注解有什么用？

@RequestMapping 用来标识http请求地址与Controller类的方法之间的映射。

@RequestMapping标识一个类：设置映射请求的请求路径的初始信息。

@RequestMapping标识一个方法：设置映射请求的请求路径的具体信息。

注意：如果类上和方法上都有这个注解，那么就先访问初始信息，然后再访问具体信息，举例如下

```
@Controller
@RequestMapping(value="/lurenzhang")
public class HelloWorld {
    
    @RequestMapping("/helloworld")
    public String hello(){
        return "hello,world!";
    }
}
```

上述代码的url映射地址为，你的域名+/lurenzhang/helloworld。

### @PathVariable 注解有什么用？

@PathVariable 映射 URL 绑定的占位符，通过 @PathVariable 可以将 URL 中占位符参数绑定到控制器处理方法的入参中，很容易理解，如下

```
@RequestMapping(value="/getUserById/{name}", method = RequestMethod.GET)
public User getUser(@PathVariable("name") String name){
    return userService.selectUser(name);
}
```

将url中的name传到方法中的name

### @RequestBody注解有什么用？

注解@RequestBody接收的参数是**来自requestBody**中，即**请求体**。一般用于处理非 `Content-Type: application/x-www-form-urlencoded`编码格式的数据，比如：`application/json`、`application/xml`等类型的数据。而 `Content-Type: application/x-www-form-urlencoded`编码格式的数据通常用@RequestParam注解。如下

```
@Controller
public class UserController {
    @RequestMapping(value="/lurenzhang",method = RequestMethod.POST)
    public void getUser(@RequestBody User user){
        System.out.println(user);
    }
} 
```

### @GetMapping、@PostMapping、@PutMapping、@DeleteMapping注解有什么用？

这几个注解一看就是对应着http请求中的get、post、put、delete方法，

```
@Controller
@RequestMapping(value="/lurenzhang")
public class HelloWorld {
    
    @GetMapping("/helloworld")
    public String hello(){
        return "hello,world!";
    }
}
```

上述代码的url映射地址为，你的域名+/lurenzhang/helloworld，等价于

```
@Controller
@RequestMapping(value="/lurenzhang")
public class HelloWorld {
    
    @RequestMapping("/helloworld", method=RequestMethod.GET)
    public String hello(){
        return "hello,world!";
    }
}
```

其他几个也都是类的，不再举例

## Spring AOP相关注解

> AOP的注解主要是@Aspect，@Pointcut，@Around，@Before，@After，@AfterReturning，@AfterThrowing，

- @Aspect，声明一个切面
- @Pointcut，增强的切入点
- @Before，前置注解，被注解的方法将会在目标方法之前执行
- @After，最终注解，被注解的方法将在执行完所有的注解方法后再执行（始终执行）
- @Around，环绕注解，被注解的方法将会之前和之后都进行执行
- @AfterReturning，后置注解，被注解的方法将会在目标方法执行之后执行（异常不执行）
- @AfterThrowing，出现异常后执行

具体用法介绍Spring AOP在举例，不重复举例了

## Spring支持的事务管理类型， Spring 事务实现方式有哪些？

主要有两种，编程式事务管理和声明式事务管理

- 编程式事务管理：在代码中显式调用开启事务、提交事务、回滚事务的相关方法。优点是灵活性高，缺点是难以维护

- 声明式事务管理：通过AOP实现，对方法前后进行拦截，然后在目标方法开始之前创建或者加入一个事务，在执行完目标方法之后根据执行情况提交或者回滚事务。事务管理与业务代码分离，仅使用注解或基于 XML。

  的配置来管理事务。

通常声明式事务管理的使用更多一些，对代码的入侵性更小一些。

## Spring 的事务隔离级别有哪些？

Spring的事务质其实就是数据库对事务的支持，如果数据库不支持事务，Spring的事务也没什么意义。

- ISOLATION_DEFAULT，默认隔离级别，表示使用底层数据库的的隔离级别
- ISOLATION_READ_UNCOMMITTED，未提交读，表示一个是事务可以读取另一个事务修改还未提交的数据，不能防止
- ISOLATION_READ_COMMITTED，提交读，一个事务只能读取另一个事务已经提交的数据，可以防止脏读，会造成幻读、不可重复读
- ISOLATION_REPEATABLE_READ，可重复读，一个事务在整个过程中可以多次重复执行某个查询，并且每次返回的记录都相同，不能防止幻读
- ISOLATION_SERIALIZABLE，序列化，所有的事务依次逐个执行，可以防止脏读、不可重复读以及幻读，但会影响性能

## Spring事务的传播行为有哪些？

事务的传播行为主要是解决了多个方法之间相互调用所产生的事务问题，主要有以下几种：

- PROPAGATION_REQUIRED：如果当前没有事务，就创建一个新事务，如果当前存在事务，就加入该事务，这是`@Transactional`注解默认使用的事务传播行为
- PROPAGATION_SUPPORTS：如果当前存在事务，就加入该事务，如果当前不存在事务，就以非事务执行。
- PROPAGATION_MANDATORY：如果当前存在事务，就加入该事务，如果当前不存在事务，就抛出异常。
- PROPAGATION_REQUIRES_NEW：无论当前存不存在事务，都创建新事务
- PROPAGATION_NOT_SUPPORTED：以非事务方式运行，如果当前存在事务，则把当前事务挂起。
- PROPAGATION_NEVER：以非事务方式执行，如果当前存在事务，则抛出异常。
- PROPAGATION_NESTED：如果当前存在事务，则在嵌套事务内执行。如果当前没有事务，则按PROPAGATION_REQUIRED属性执行

## Spring框架的事务管理有哪些优点？

- 为不同的事务API，如 JDBC，Hibernate，JPA 和JDO，提供一个不变的编程模式。
- 支持声明式事务管理
- 和Spring各种数据访问抽象层很好地集成