# [Spring 的自动装配 → 骚话 @Autowired 的底层工作原理](https://www.cnblogs.com/youzhibing/p/11031216.html)

## 前情回顾

　　[Spring拓展接口之BeanPostProcessor，我们来看看它的底层实现](https://www.cnblogs.com/youzhibing/p/10559330.html)中讲到了 Spring 对 BeanPostProcessor 的底层支持

　　并且知道了 BeanPostProcessor 的两个方法：postProcessBeforeInitialization、postProcessAfterInitialization 的执行时机

　　没看的小伙伴赶紧先去看看

　　本来 Spring 的自动装配是打算放到上一篇博文中详细讲解的，可后来觉得篇幅可能太大了

![img](https://img2018.cnblogs.com/blog/747662/201906/747662-20190618205148192-4164248.gif)

你们：信了你个鬼，除了几幅图，有啥内容？

　　既然你们都感觉出来了，那我也就明人不说暗话了，之所以没放到上篇讲解，确实是因为篇幅太大了

![img](https://img2018.cnblogs.com/blog/747662/201906/747662-20190618170058382-1878173966.gif)

楼主：哈哈哈，是不是很想打我？ 你过来啊！

　　好了，我们言归正传，之所以没放到上篇来讲，篇幅只是原因之一，最主要的原因是发现我犯错了！ 犯什么错了呢

![img](https://img2018.cnblogs.com/blog/747662/201906/747662-20190618205302524-720878543.gif)

楼主：不是黄赌毒啊，那是犯罪，我是正人君子！

　　我想当然了！ 理所当然的认为自动装配是在 AutowiredAnnotationBeanPostProcessor 的 postProcessBeforeInitialization 或 postProcessAfterInitialization 中实现的

　　我们来看下 AutowiredAnnotationBeanPostProcessor 类继承图

![img](https://img2018.cnblogs.com/blog/747662/201906/747662-20190618212414051-1097324017.png)

　　它间接实现了 BeanPostProcessor，我们再去看下那两个方法（在父类 InstantiationAwareBeanPostProcessorAdapter 中）

![img](https://images.cnblogs.com/OutliningIndicators/ExpandedBlockStart.gif)

```
@Override
public Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException {
    return bean;
}

@Override
public Object postProcessAfterInitialization(Object bean, String beanName) throws BeansException {
    return bean;
}
```

　　Oh My God ，竟然啥也没干，只是简单的 return bean

![img](https://img2018.cnblogs.com/blog/747662/201906/747662-20190618210515630-34893313.gif)

楼主：我心态崩了

　　当自己深以为然的认知被推翻时，那感觉真是毙了狗了

![img](https://img2018.cnblogs.com/blog/747662/201906/747662-20190618210951120-1396913431.gif)

萨摩耶：关我什么事

　　所以自动装配不能和 BeanPostProcessor 放一块讲，不得不开两篇来分开讲，我们都知道：强扭的瓜不甜！

## 自动装配简单示例

　　我们先来看一个简单的自动装配的示例，完整实例代码：[spring-boot-BeanPostProcessor](https://gitee.com/youzhibing/spring-boot-2.0.3/tree/master/spring-boot-BeanPostProcessor)

　　AnimalConfig

![img](https://images.cnblogs.com/OutliningIndicators/ExpandedBlockStart.gif)

```
package com.lee.app.configuration;

import com.lee.app.entity.Cat;
import com.lee.app.entity.Dog;
import com.lee.app.entity.Pig;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class AnimalConfig {

    public AnimalConfig() {
        System.out.println("AnimalConfig 实例化");
    }

    @Bean
    public Dog dog() {
        return new Dog("小七");
    }

    @Bean
    public Cat cat() {
        return new Cat("Tom");
    }

    @Bean
    public Pig pig() {
        return new Pig("佩奇");
    }
}
```

　　AnimalServiceImpl

![img](https://images.cnblogs.com/OutliningIndicators/ExpandedBlockStart.gif)

```
@Service
public class AnimalServiceImpl implements IAnimalService {

    @Autowired
    private Dog dog;
    @Resource
    private Cat cat;
    @Inject
    private Pig pig;

    @Override
    public void printName() {
        System.out.println(dog.getName());
        System.out.println(cat.getName());
        System.out.println(pig.getName());
    }
}
```

　　AnimalTest

![img](https://images.cnblogs.com/OutliningIndicators/ExpandedBlockStart.gif)

```
@RunWith(SpringRunner.class)
@SpringBootTest(classes={Application.class})
public class AnimalTest {

    @Autowired
    private IAnimalService animalService;

    @Test
    public void test() {
        animalService.printName();
    }
}
```

　　运行结果

![img](https://img2018.cnblogs.com/blog/747662/201906/747662-20190619214507088-295326343.gif)

　　我们在 AnimalConfig 中只是将 Dog、Cat、Pig 的实例注册到了 Spring 容器，那为什么 AnimalServiceImpl 实例能够直接应用这些实例了，我们并没有手动的将这些实例赋值到 AnimalServiceImpl 实例呀？

　　这其实就是 Spring 提供的自动装配功能，虽然我们没有手动的将这些实例赋值到 AnimalServiceImpl 实例，但是我们发现 AnimalServiceImpl 的属性上多了一些注解：@Autowired、@Resource、@Inject

　　Spring 通过这些注解自动完成了属性的注入，而不需要我们手动的去赋值了

　　那么 Spring 是如何实现自动装配的呢？ 我们慢慢往下看（注意：后文主要以 @Autowired 为例来讲解）

## 自动装配源码解析

### 　　AutowiredAnnotationBeanPostProcessor 的实例化与注册

　　不管怎么说，AutowiredAnnotationBeanPostProcessor 终归还是一个 BeanPostProcessor，那么它的实例化与注册（注册到 Spring 的 beanFactory）过程与[BeanPostProcessor的实例化与注册](https://www.cnblogs.com/youzhibing/p/10559330.html#autoid-4-0-0)一样

　　在spring的启动过程中，刷新上下文（refresh）的时候，会调用 registerBeanPostProcessors(beanFactory)方法完成 BeanPostProcessor 的实例化与注册

　　后续再调用 finishBeanFactoryInitialization(beanFactory)实例化非延迟加载的单例 bean 时，会用到上述注册的 BeanPostProcessor

　　AutowiredAnnotationBeanPostProcessor 的构造方法值得我们看看

![img](https://images.cnblogs.com/OutliningIndicators/ContractedBlock.gif) View Code

　　默认情况下，AutowiredAnnotationBeanPostProcessor 支持 @Autowired 和 @Value，如果类路径下有 java.inject.Inject (也就是引入了javax.inject.jar)，那么也支持 @Inject 注解，是不是与我们最初的认知有些不一样？

![img](https://img2018.cnblogs.com/blog/747662/201906/747662-20190619094400727-770371000.gif)

　　将支持的注解放到了autowiredAnnotationTypes 属性中，后续会用到该属性

### 　　bean的实例化与依赖注入

　　默认情况下，Spring 会把 Spring 容器中的 bean 当成 non-lazy-init singleton 来处理（有些特殊的 bean 除外）

　　也就是说会在 Spring 的启动过程中就会逐个实例化这些 bean，并对这些 bean 进行依赖注入

　　当我们真正用到这些 bean 的时候，直接用就行，不用再去实例化，也不用再去注入 bean 的相关依赖，Spring是不是很厉害？

![img](https://img2018.cnblogs.com/blog/747662/201906/747662-20190619095130243-275836735.gif)

　　具体是不是说的这样，大家准备好花生、瓜子和啤酒，好戏即将开始

![img](https://img2018.cnblogs.com/blog/747662/201906/747662-20190619101215860-1474483557.gif)

　　我们先找到正确的入口，然后省略掉无聊的前戏，直接进入高潮

　　大家先把思想收一收，该醒醒了

![img](https://img2020.cnblogs.com/blog/747662/202101/747662-20210125172058922-1570091342.gif)

　　应该是 doCreateBean

![img](https://img2018.cnblogs.com/blog/747662/201906/747662-20190619202309090-906901076.gif)

　　doCreateBean 内容如下

![img](https://images.cnblogs.com/OutliningIndicators/ExpandedBlockStart.gif)

```
protected Object doCreateBean(final String beanName, final RootBeanDefinition mbd, final @Nullable Object[] args)
        throws BeanCreationException {

    // Instantiate the bean.
    BeanWrapper instanceWrapper = null;
    if (mbd.isSingleton()) {
        instanceWrapper = this.factoryBeanInstanceCache.remove(beanName);
    }
    if (instanceWrapper == null) {
        // 创建bean实例
        instanceWrapper = createBeanInstance(beanName, mbd, args);
    }
    final Object bean = instanceWrapper.getWrappedInstance();
    Class<?> beanType = instanceWrapper.getWrappedClass();
    if (beanType != NullBean.class) {
        mbd.resolvedTargetType = beanType;
    }

    // Allow post-processors to modify the merged bean definition.
    // 允许后置处理器来修改bean定义
    synchronized (mbd.postProcessingLock) {
        if (!mbd.postProcessed) {
            try {
                // 调用MergedBeanDefinitionPostProcessor的postProcessMergedBeanDefinition方法
                // AutowiredAnnotationBeanPostProcessor实现了MergedBeanDefinitionPostProcessor，即MergedBeanDefinitionPostProcessor的MergedBeanDefinitionPostProcessor会被调用
                applyMergedBeanDefinitionPostProcessors(mbd, beanType, beanName);
            }
            catch (Throwable ex) {
                throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                        "Post-processing of merged bean definition failed", ex);
            }
            mbd.postProcessed = true;
        }
    }

    // Eagerly cache singletons to be able to resolve circular references 立即缓存单例以便能够解析循环引用
    // even when triggered by lifecycle interfaces like BeanFactoryAware.
    boolean earlySingletonExposure = (mbd.isSingleton() && this.allowCircularReferences &&
            isSingletonCurrentlyInCreation(beanName));
    if (earlySingletonExposure) {
        if (logger.isDebugEnabled()) {
            logger.debug("Eagerly caching bean '" + beanName +
                    "' to allow for resolving potential circular references");
        }
        addSingletonFactory(beanName, () -> getEarlyBeanReference(beanName, mbd, bean));
    }

    // Initialize the bean instance.
    Object exposedObject = bean;
    try {
        // 填充bean，包含依赖注入
        populateBean(beanName, mbd, instanceWrapper);
        // 初始化bean，BeanPostProcessor的两个方法在此中被调用
        exposedObject = initializeBean(beanName, exposedObject, mbd);
    }
    catch (Throwable ex) {
        if (ex instanceof BeanCreationException && beanName.equals(((BeanCreationException) ex).getBeanName())) {
            throw (BeanCreationException) ex;
        }
        else {
            throw new BeanCreationException(
                    mbd.getResourceDescription(), beanName, "Initialization of bean failed", ex);
        }
    }

    if (earlySingletonExposure) {
        Object earlySingletonReference = getSingleton(beanName, false);
        if (earlySingletonReference != null) {
            if (exposedObject == bean) {
                exposedObject = earlySingletonReference;
            }
            else if (!this.allowRawInjectionDespiteWrapping && hasDependentBean(beanName)) {
                String[] dependentBeans = getDependentBeans(beanName);
                Set<String> actualDependentBeans = new LinkedHashSet<>(dependentBeans.length);
                for (String dependentBean : dependentBeans) {
                    if (!removeSingletonIfCreatedForTypeCheckOnly(dependentBean)) {
                        actualDependentBeans.add(dependentBean);
                    }
                }
                if (!actualDependentBeans.isEmpty()) {
                    throw new BeanCurrentlyInCreationException(beanName,
                            "Bean with name '" + beanName + "' has been injected into other beans [" +
                            StringUtils.collectionToCommaDelimitedString(actualDependentBeans) +
                            "] in its raw version as part of a circular reference, but has eventually been " +
                            "wrapped. This means that said other beans do not use the final version of the " +
                            "bean. This is often the result of over-eager type matching - consider using " +
                            "'getBeanNamesOfType' with the 'allowEagerInit' flag turned off, for example.");
                }
            }
        }
    }

    // Register bean as disposable.
    try {
        registerDisposableBeanIfNecessary(beanName, bean, mbd);
    }
    catch (BeanDefinitionValidationException ex) {
        throw new BeanCreationException(
                mbd.getResourceDescription(), beanName, "Invalid destruction signature", ex);
    }

    return exposedObject;
}
```

　　我们重点看下 posProcessMergedBeanDefinition 方法和 populateBean 方法

### 　　posProcessMergedBeanDefinition

![img](https://img2018.cnblogs.com/blog/747662/201906/747662-20190619222837950-1790628307.gif)

　　可以看到会读取 bean 的 field 和 method 上的注解，并判断该注解是否在 autowiredAnnotationTypes 中

　　如果在则将 field 封装成 AutowiredFiledElement 对象、将 method 封装成 AutoWiredMethodElement 对象，并存放到 InjectionMetadata 对象的 Set<InjectedElement> checkedElements 属性中

　　最后将该 InjectionMetadata 对象缓存到了 AutowiredAnnotationBeanPostProcessor 的 Map<String, InjectionMetadata> injectionMetadataCache 属性中

　　说白了就是将 bean中 被 @Autowried（当然还包括 @Value、@Inject）修饰的 field、method 找出来，封装成 InjectionMetadata 对象并缓存起来，就这么简单

　　不仅仅是上图中的 animalServiceImpl 这一个 bean，Spring 中所有的非延迟加载的 bean 都会走这个创建流程

　　是不是很简单，是不是干劲十足了

![img](https://img2018.cnblogs.com/blog/747662/201906/747662-20190620223751847-950337020.gif)

### 　　populateBean

![img](https://img2018.cnblogs.com/blog/747662/201906/747662-20190620212937678-887634236.gif)

　　调用 AutowiredAnnotationBeanPostProcessor 的 postProcessPropertyValues 方法，从 injectionMetadataCache 中获取当前 bean 的依赖信息

　　比如 animalServiceImpl 依赖的 dog、pig（有人可能会有这样的疑问：cat 呢？ cat 是被 @Resource 修饰的，而 @Resource 不是由 AutowiredAnnotationBeanPostProcessor 支持，后续会讲由谁支持）

　　然后逐个将依赖 bean 注入到目标 bean（将 dog、pig 实例注入到 animalServiceImpl 实例中）

　　依赖 bean 从哪来呢？还是从 beanFactory 中获取，如果不存在，则又回到 bean 的创建过程把依赖 bean（dog、pig）创建出来，流程与创建 animalServiceImpl 实例一模一样

　　也就说在 animalServiceImpl 实例的依赖注入过程中会把 dog、pig 对象也创建出来，而不是等到 Spring 逐个实例化 bean 的过程中轮到 dog、pig 才实例化 dog、pig

　　那后续轮到 dog、pig 时怎么办了，Spring 会把创建的 bean 缓存起来，下次就直接从缓存中取了

　　上图只演示 Field 的，Method 也差不太多，就不演示了，都是通过反射实现的 

## 总结

　　1、bean的创建与初始化

　　　　（1）instanceWrapper = createBeanInstance(beanName, mbd, args)　　创建目标bean实例；

　　　　（2）applyMergedBeanDefinitionPostProcessors(mbd, beanType, beanName)　　寻找目标bean的依赖；

　　　　（3）populateBean(beanName, mbd, instanceWrapper)　　填充目标bean，完成依赖注入； （这里的循环依赖，有兴趣的可以自行去琢磨下）

　　　　（4）initializeBean(beanName, exposedObject, mbd)　　初始化目标bean

　　2、自动装配与自动配置

　　　　自动配置一般而言说的是spring的@Autowired，是spring的特性之一，而自动配置是springboot的@Configuration，是springboot的特性之一

　　3、Spring支持几下几种自动装配的注解

　　　　@Autowired、@Inject、@Resource以及@Value，用的最多的应该是@Autowired（至少我是这样的）

　　　　@Inject 和 @Value 也是由 AutowiredAnnotationBeanPostProcessor 支持，而 @Resource 是由 CommonAnnotationBeanPostProcessor 支持（还支持 @PostConstruct、@PreDestroy 等注解）

　　　　关于 @Value 与 @Autowired，不知道大家是否清楚他们之间的区别，不清楚的可以看看：[Spring: @Value vs. @Autowired](https://stackoverflow.com/questions/29551761/spring-value-vs-autowired) 或者 Spring 的官方文档

　　　　总结下：@Value >= @Autowired，只是平时应用中，@Value 更多的是用来注入配置值（如：@Value("${db.url}")），而 @Autowired 则是 bean 对象的注入


* [原文地址](https://www.cnblogs.com/youzhibing/p/11031216.html)