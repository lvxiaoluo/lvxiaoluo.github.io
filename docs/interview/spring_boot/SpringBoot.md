# SpringBoot

### @SpringBootApplication
```java
@SpringBootApplication
public class JpaApplication{
	public static void main(String[] args){
			SpringApplication.run(JpaApplication.class,args);
	}
}
```
> @SpringBootApplication 注解等同于下面三个注解：
> @SpringBootConfiguration: 底层是Configuration注解，说白了就是支持JavaConfig的方式来进行配置
> @EnableAutoConfiguration: 开启自动配置功能
> @ComponentScan:就是扫描注解，默认是扫描当前类下的package
其实@EnableAutoConfiguration是关键（启动自动配置），内部实际上就去加载META-INF/spring.factories文件的信息，然后筛选出以EanbleAutoConfiguration为key的数据，加载到IOC容器中，实现自动配置功能

> 它主要加载了@SpringBootApplication注解主配置类，这个@SpringApplication注解主配置类里面最主要的功能就是SpringBoot开启了一个@EnableAutoConfiguration注解的自动配置功能。

### @EnableAutoConfiguration作用：
它主要利用一个 EnableAutoConfigurationImportSelector选择器给Spring容器中来导入一些组件。
```java
@Import(EnableAutoConfigurationImportSelector.class)
public @interface EnableAutoConfiguration
```


