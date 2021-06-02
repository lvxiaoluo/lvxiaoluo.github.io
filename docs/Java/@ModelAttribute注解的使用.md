### @ModelAttribute注解的使用

#### 在SpringMVC的Controller中使用@ModelAttribute时，其位置包括下面三种：
* 应用在方法上
* 应用在方法的参数上
* 应用在方法上，并且方法也使用了@RequestMapping

##### 1. 应用在方法上
首先说明一下，被@ModelAttribute注解的方法会在Controller每个方法执行之前都执行，因此对于一个Controller中包含多个URL的时候，要谨慎使用。

###### 1）使用@ModelAttribute注解无返回值的方法
```java
@Controller
@RequestMapping(value = "/modelattribute")
public class ModelAttributeController {

    @ModelAttribute
    public void myModel(@RequestParam(required = false) String abc, Model model) {
        model.addAttribute("attributeName", abc);
    }

    @RequestMapping(value = "/method")
    public String method() {
        return "method";
    }
}
```

这个例子，在请求/modelattribute/method?abc=aaa后，会先执行myModel方法，然后接着执行method方法，参数abc的值被放到Model中后，接着被带到method方法中。

当返回视图/modelattribute/method时，Model会被带到页面上，当然你在使用@RequestParam的时候可以使用required来指定参数是否是必须的。

如果把myModel和method合二为一，代码如下，这也是我们最常用的方法：

```java
@RequestMapping(value = "/method")
public String method(@RequestParam(required = false) String abc, Model model) {
    model.addAttribute("attributeName", abc);
    return "method";
}
```
###### 2）使用@ModelAttribute注解带有返回值的方法
```java
@ModelAttribute
public String myModel(@RequestParam(required = false) String abc) {
    return abc;
}

@ModelAttribute
public Student myModel(@RequestParam(required = false) String abc) {
    Student student = new Student(abc);
    return student;
}

@ModelAttribute
public int myModel(@RequestParam(required = false) int number) {
    return number;
}
```

对于这种情况，返回值对象会被默认放到隐含的Model中，在Model中的key为返回值首字母小写，value为返回的值。

上面3种情况等同于：

```java
model.addAttribute("string", abc);
model.addAttribute("int", number);
model.addAttribute("student", student);
```

> 在jsp页面使用${int}表达式时会报错：javax.el.ELException: Failed to parse the expression [${int}]。
> 解决办法：
> 在tomcat的配置文件conf/catalina.properties添加配置org.apache.el.parser.SKIP_IDENTIFIER_CHECK=true

如果只能这样，未免太局限了，我们很难接受key为string、int、float等等这样的。

想自定义其实很简单，只需要给@ModelAttribute添加value属性即可，如下：

```java
@ModelAttribute(value = "num")
public int myModel(@RequestParam(required = false) int number) {
    return number;
}
```
这样就相当于model.addAttribute("num", number);

使用@ModelAttribute注解的参数


```java
@Controller
@RequestMapping(value = "/modelattribute")
public class ModelAttributeParamController {

    @ModelAttribute(value = "attributeName")
    public String myModel(@RequestParam(required = false) String abc) {
        return abc;
    }

    @ModelAttribute
    public void myModel3(Model model) {
        model.addAttribute("name", "zong");
        model.addAttribute("age", 20);
    }

    @RequestMapping(value = "/param")
    public String param(@ModelAttribute("attributeName") String str,
                       @ModelAttribute("name") String str2,
                       @ModelAttribute("age") int str3) {
        return "param";
    }
}

```

从代码中可以看出，使用@ModelAttribute注解的参数，意思是从前面的Model中提取对应名称的属性。

这里提及一下@SessionAttributes的使用：

> 如果在类上面使用了@SessionAttributes("attributeName")注解，而本类中恰巧存在attributeName，则会将attributeName放入到session作用域。
> 如果在类上面使用了@SessionAttributes("attributeName")注解，SpringMVC会在执行方法之前，自动从session中读取key为attributeName的值，并注入到Model中。所以我们在方法的参数中使用ModelAttribute("attributeName")就会正常的从Model读取这个值，也就相当于获取了session中的值。
> 使用了@SessionAttributes之后，Spring无法知道什么时候要清掉@SessionAttributes存进去的数据，如果要明确告知，也就是在方法中传入SessionStatus对象参数，并调用status.setComplete就可以了。

应用在方法上，并且方法上也使用了@RequestMapping
```java
@Controller
@RequestMapping(value = "/modelattribute")
public class ModelAttributeController {

    @RequestMapping(value = "/test")
    @ModelAttribute("name")
    public String test(@RequestParam(required = false) String name) {
        return name;
    }
}
```

这种情况下，返回值String（或者其他对象）就不再是视图了，而是放入到Model中的值，此时对应的页面就是@RequestMapping的值test。
如果类上有@RequestMapping，则视图路径还要加上类的@RequestMapping的值，本例中视图路径为modelattribute/test.jsp。















@ModelAttribute运用详解
被@ModelAttribute注释的方法会在此controller每个方法执行前被执行，因此对于一个controller映射多个URL的用法来说，要谨慎使用。

我们编写控制器代码时，会将保存方法独立成一个控制器也是如此。


1.@ModelAttribute注释void返回值的方法

```java
@Controller
public class HelloModelController {

    @ModelAttribute 
    public void populateModel(@RequestParam String abc, Model model) {  
       model.addAttribute("attributeName", abc);  
    }  

    @RequestMapping(value = "/helloWorld")  
    public String helloWorld() {  
       return "helloWorld.jsp";  
    }  

}
```
在这个代码中，访问控制器方法helloWorld时，会首先调用populateModel方法，将页面参数abc(/helloWorld.ht?abc=text)放到model的attributeName属性中，在视图中可以直接访问。

jsp页面页面如下。

```xml
<%@ page language="java" contentType="text/html; charset=utf-8"
    pageEncoding="utf-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<html>
<head>
</head>
<body>
<c:out value="${attributeName}"></c:out>
</body>
</html>
```
2.@ModelAttribute注释返回具体类的方法

```java
@Controller
public class Hello2ModelController {

    @ModelAttribute 
    public User populateModel() {  
       User user=new User();
       user.setAccount("ray");
       return user;
    }  
    @RequestMapping(value = "/helloWorld2")  
    public String helloWorld() {  
       return "helloWorld.jsp";  
    }  
}
```
当用户请求 http://localhost:8080/test/helloWorld2.ht时，首先访问populateModel方法，返回User对象，model属性的名称没有指定，

它由返回类型隐含表示，如这个方法返回User类型，那么这个model属性的名称是user。
这个例子中model属性名称有返回对象类型隐含表示，model属性对象就是方法的返回值。它无须要特定的参数。

jsp 中如下访问：
```xml
<c:out value="${user.account}"></c:out>
```
也可以指定属性名称

```java
@Controller
public class Hello2ModelController {

    @ModelAttribute(value="myUser")
    public User populateModel() {  
       User user=new User();
       user.setAccount("ray");
       return user;
    }  
    @RequestMapping(value = "/helloWorld2")  
    public String helloWorld(Model map) {  
       return "helloWorld.jsp";  
    }  
}
```
jsp中如下访问：
```xml
<c:out value="${myUser.account}"></c:out>
```
对象合并:

```java
@Controller
public class Hello2ModelController {

    @ModelAttribute
    public User populateModel() {  
       User user=new User();
       user.setAccount("ray");
       return user;
    }  
    
    @RequestMapping(value = "/helloWorld2")  
    public String helloWorld(User user) {
        user.setName("老王");
       return "helloWorld.jsp";  
    }  
}
```
这个在编写代码的时候很有用处,比如在更新的时候，我们可以现在populateModel方法中根据ID获取对象，然后使用spring mvc的自动组装功能，组装

User对象，这样在客户端提交了值的属性才会被组装到对象中。

比如：User对象，首先从数据库中获取此对象，客户端表单只有account属性，提交时就只会改变account属性。



对象合并指定对象名称：

```java
@Controller
public class Hello2ModelController {

    @ModelAttribute("myUser")
    public User populateModel() {  
       User user=new User();
       user.setAccount("ray");
       return user;
    }  
    
    @RequestMapping(value = "/helloWorld2")  
    public String helloWorld(@ModelAttribute("myUser") User user) {
        user.setName("老王");
       return "helloWorld.jsp";  
    }  
}
```
这样在jsp中可以使用如下方式访问
```xml
<c:out value="${myUser.name}"></c:out>
<c:out value="${myUser.account}"></c:out>
```
3.通过此特性控制权限.

我们可以在基类方法中控制写此注解，需要控制权限的控制器，继承控制器就可以了。

```java
public class BaseController {

    @ModelAttribute
    public void populateModel() throws Exception {  
       SysUser user=ContextUtil.getCurrentUser();
       if(user.getAccount().equals("admin")){
           throw new Exception("没有权限");
       }
    }  
}
```
需要控制权限的类继承BaseController

```java
@Controller
public class Hello2ModelController extends BaseController {

    @RequestMapping(value = "/helloWorld2")  
    public String helloWorld(@ModelAttribute("myUser") User user) {
        user.setName("老王");
       return "helloWorld.jsp";  
    }  
}
```
这样就可以控制权限了，当然控制权限的方法有很多，比如通过过滤器等。这里只是提供一种思路。