# 分享一道超高频的Spring面试题



**文章目录：**

- Spring 怎么解决循环依赖问题？

- - 什么是循环依赖
  - Spring是如何解决循环依赖的，任何形式的循环依赖都可以解决吗？
  - 解决循环依赖的Spring源码
  - 面试中如何简短地回答Spring是如何解决循环依赖的



## Spring 怎么解决循环依赖问题？

> 这是面试中非常高频的一道题，和前面的问题比也是一个相对麻烦一点的面试题

对于这个问题，估计游戏人人看了网上很多博客还是很头大，就看到了一堆头大的源码，感觉很复杂的样子，其实没有那么复杂。本篇文章，先大白话告诉你Spring到底怎么解决循环依赖的，毕竟没人愿意看源码，先来看看什么是循环依赖。

### 什么是循环依赖

循环依赖的定义是非常好理解的，就是A依赖B，B也依赖A，或者A依赖本身。

简单来讲就是之前看到的一个段子，一个应聘者去找工作，企业都要求有相关工作经验，但是应聘者找不到工作就没有工作经验，而没有工作经验的人企业不要，卡死了。在Spring中代码表示如下

```
@Component
public class A {
    // A中注入了B
 @Autowired
 private B b;
}

@Component
public class B {
    // B中注入了A
 @Autowired
 private A a;
}
```

还有自己依赖自己的

```
@Component
public class A {
 @Autowired
 private A a;
}
```

### Spring是如何解决循环依赖的，任何形式的循环依赖都可以解决吗？

先说下下答案，Spring是通过**三级缓存**解决循环依赖的，既然是基于缓存，那**prototype**（Bean的一种作用域，忘了可以看看前面的文章）的bean所造成的循环依赖肯定是不行了，因为Spring并没有缓存prototype的bean。那其他的循环依赖就都能解决了吗？

答案是否定的，在解释这个之前需要先了解Spring在创建Bean的过程。

Spring创建Bean的过程主要有三步，

1. 实例化（`createBeanInstance`方法）
2. 属性注入（`populateBean`方法）
3. 初始化（`initializeBean`方法）

而常用的Bean注入方法有构造方法注入和属性注入，这两者有什么区别呢？

**构造方法注入**

```
@Component
public class A {  
    public A(B b) {
        
    }
}

@Component
public class B {  
    public B(A a) {
        
    }
}
```

构造方法注入步骤：

1. 调用B的构造方法
2. 调用A的构造方法

不出意外已经卡死了

**属性注入**

```
@Service
public class A {  //1
    @Autowired  
    private B b; //2
}
 
@Service
public class B {  //3
    @Autowired  
    public A a; //4 
}
```

属性注入的步骤：

1. 调用A的构造方法
2. 检查依赖的对象（B）
3. 调用B的构造方法
4. 使用注解@Autowired 将b注入给A

对于不理解为什么是这个步骤的小伙伴，可以去看看类实例化时什么时候执行构造方法

从上述构造方法注入和属性注入的步骤来看，通过构造方法注入的bean所导致的循环依赖是无法解决的，因为构造方法注入时，要想先实例化A，那么依赖B必须先实例化，但是B的实例化也会依赖A。而采用属性注入Bean时，不需要保证先实例化B，可以先实例化A，再实例化B，然后再将b注入到A中。所以Spring可以解决的是通过属性注入的Bean所引起的循环依赖。

那具体是怎么实现的呢？流程如下，前四步对应代码中的1，2，3，4

1. 创建A的bean，这时先调用A的构造方法实例化，也就是上面创建Bean的第一步，所以到这里创建了一个A的半成品的Bean
2. 这时候需要将B的Bean注入到A中，需要先实例化B（未完成属性注入）
3. 调用B构造方法进行实例化，也是个半成品的bean
4. 将A的半成品的注入到B中，完成了属性注入，然后初始化。但这里B的bean已经是一个完整的bean了（创建bean的三步都完成了）
5. 回到第2步，将B的bean注入到属性b中，然后初始化，A也是一个完整的bean了

流程图如下：

![图片](https://mmbiz.qpic.cn/mmbiz_png/cBnxLn7axrxTmNqnozrWeT64YGsJia5pHmvn5G6UIzOicdHicWfUsNORoiaDib407DY22Ly0SVzTK2hiatvOhAoLX9zw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

其实简单来说就是，创建bean需要三步，A先完成了第一步，这时需要B的bean，去找B要。这时B的bean也没创建，也先完成了第一步实例化，第二步将A的只完成第一步的bean注入到属性中了，然后初始化，B的bean创建完成。B将bean给A，A也完成了属性注入及初始化。到此循环依赖结束。

就靠这个**创建一半的bean**解决了循环依赖问题，构造方法注入为啥不行，因为它不能先完成创建bean的第一步，必须先要B的bean。

这个创建一般的bean就是具体就是靠三级缓存实现的，在看源码之前，还有一个问题需要解决。

是否只要是构造方法注入的bean所产生的循环依赖就是无法解决的呢？

答案是否定的，上面上说的是两个bean的注入方式都是构造函数注入，这个确实解决不了，那一个是构造方法注入，一个是属性注入，这种循环依赖可以解决吗？

答案是不一定的，得看先创建的bean中的注入方式是什么，如果先创建的bean的注入方式是构造方法注入，那开始就无法提供半成品的bean，这种循环依赖是无法解决的。如果先创建的bean中的注入方法是属性注入，后创建bean的注入方法是构造方法注入，这种循环依赖是可以解决的，总结如下，A和B为上面代码中的类

| 依赖注入方式                                         | 是否可以解决 |
| :--------------------------------------------------- | :----------- |
| 两个都是构造方法注入                                 | 否           |
| 两个都是属性注入                                     | 是           |
| A中的注入方式是构造方法注入，B中的注入方式是属性注入 | 否           |
| A中的注入方式是属性注入，B中的注入方式是构造方法注入 | 是           |

**扩展**

如果是三个bean相互依赖呢？A依赖B，B依赖C，C依赖A，A中是属性注入，B中是构造方法注入，C中是属性注入，这种循环依赖可以解决吗？（想不出来就再把上面的看一遍）

最后要看源码了，看看三级缓存是怎么实现这个半成品bean的获取的，不想看的小伙伴可以跳过了

### 解决循环依赖的Spring源码

既然是创建bean，那就要从`getBean`方法开始，点进去是这样子的，

```
    public Object getBean(String name, Object... args) throws BeansException {
        return this.doGetBean(name, (Class)null, args, false);
    }
```

继续查看`doGetBean`方法，如下，这个方法非常的长，只拿出来了一部分

```
    protected <T> T doGetBean(String name, @Nullable Class<T> requiredType, @Nullable Object[] args, boolean typeCheckOnly) throws BeansException {
        String beanName = this.transformedBeanName(name);
        Object sharedInstance = this.getSingleton(beanName);
        Object bean;
        .......
  if (mbd.isSingleton()) {
                    sharedInstance = this.getSingleton(beanName, () -> { 
                        try {
                            return this.createBean(beanName, mbd, args);
                        } catch (BeansException var5) {
                            this.destroySingleton(beanName);
                            throw var5;
                        }
                    });
                    bean = this.getObjectForBeanInstance(sharedInstance, name, beanName, mbd);
                } 
  .......
```

比较重要的是`getSingleton`方法，通过beanName获取bean，点击去是这个方法

```
    protected Object getSingleton(String beanName, boolean allowEarlyReference) {
        Object singletonObject = this.singletonObjects.get(beanName);  //一级缓存
        if (singletonObject == null && this.isSingletonCurrentlyInCreation(beanName)) {
            synchronized(this.singletonObjects) {
                singletonObject = this.earlySingletonObjects.get(beanName);  //二级缓存
                if (singletonObject == null && allowEarlyReference) {
                    ObjectFactory<?> singletonFactory = (ObjectFactory)this.singletonFactories.get(beanName);  //三级缓存
                    if (singletonFactory != null) {
                        singletonObject = singletonFactory.getObject();
                        this.earlySingletonObjects.put(beanName, singletonObject);
                        this.singletonFactories.remove(beanName); //二级缓存获取bean后，从三级缓存删除
                    }
                }
            }
        }

        return singletonObject;
    }
```

从上述代码可以看出来`getSingleton(String beanName, boolean allowEarlyReference)`的作用是从缓存中获取bean，一共有三级缓存

- singletonObjects，一级缓存，存储的是所有创建好了的单例bean，其实就是个Map，其定义是这样的，`private final Map<String, Object> singletonObjects = new ConcurrentHashMap(256);`
- earlySingletonObjects，二级缓存，完成实例化，但是还未进行属性注入及初始化的对象，其定义是这样的，`private final Map<String, Object> earlySingletonObjects = new HashMap(16);`
- singletonFactories，三级缓存，提前暴露的一个单例工厂，二级缓存中存储的就是从这个工厂中获取到的对象，其定义是这样的，`private final Map<String, ObjectFactory<?>> singletonFactories = new HashMap(16);`

依次从一级缓存获取bean，但因为是第一次创建Bean，显然三个缓存中都没有，那`singletonObject`应该是null，这就又回到上面的`doGetBean`方法if语句中的`getSingleton`方法，点进去是这样的

```
    public Object getSingleton(String beanName, ObjectFactory<?> singletonFactory) {
        Assert.notNull(beanName, "Bean name must not be null");
        synchronized(this.singletonObjects) {
            Object singletonObject = this.singletonObjects.get(beanName);
            if (singletonObject == null) {
                if (this.singletonsCurrentlyInDestruction) {
                    throw new BeanCreationNotAllowedException(beanName, "Singleton bean creation not allowed while singletons of this factory are in destruction (Do not request a bean from a BeanFactory in a destroy method implementation!)");
                }

                if (this.logger.isDebugEnabled()) {
                    this.logger.debug("Creating shared instance of singleton bean '" + beanName + "'");
                }

                this.beforeSingletonCreation(beanName);
                boolean newSingleton = false;
                boolean recordSuppressedExceptions = this.suppressedExceptions == null;
                if (recordSuppressedExceptions) {
                    this.suppressedExceptions = new LinkedHashSet();
                }

                try {
                    singletonObject = singletonFactory.getObject();
                    newSingleton = true;
                } catch (IllegalStateException var16) {
                    singletonObject = this.singletonObjects.get(beanName);
                    if (singletonObject == null) {
                        throw var16;
                    }
                } catch (BeanCreationException var17) {
                    BeanCreationException ex = var17;
                    if (recordSuppressedExceptions) {
                        Iterator var8 = this.suppressedExceptions.iterator();

                        while(var8.hasNext()) {
                            Exception suppressedException = (Exception)var8.next();
                            ex.addRelatedCause(suppressedException);
                        }
                    }

                    throw ex;
                } finally {
                    if (recordSuppressedExceptions) {
                        this.suppressedExceptions = null;
                    }

                    this.afterSingletonCreation(beanName);
                }

                if (newSingleton) {
                    this.addSingleton(beanName, singletonObject);
                }
            }

            return singletonObject;
        }
    }
```

上述代码执行完，又回到了最上面的`doGetBean`方法if语句中的`createBean`方法，点进去是这样的

```
    protected Object createBean(String beanName, RootBeanDefinition mbd, @Nullable Object[] args) throws BeanCreationException {
        if (this.logger.isDebugEnabled()) {
            this.logger.debug("Creating instance of bean '" + beanName + "'");
        }

        RootBeanDefinition mbdToUse = mbd;
        Class<?> resolvedClass = this.resolveBeanClass(mbd, beanName, new Class[0]);
        if (resolvedClass != null && !mbd.hasBeanClass() && mbd.getBeanClassName() != null) {
            mbdToUse = new RootBeanDefinition(mbd);
            mbdToUse.setBeanClass(resolvedClass);
        }

        try {
            mbdToUse.prepareMethodOverrides();
        } catch (BeanDefinitionValidationException var10) {
            throw new BeanDefinitionStoreException(mbdToUse.getResourceDescription(), beanName, "Validation of method overrides failed", var10);
        }

        Object beanInstance;
        try {
            beanInstance = this.resolveBeforeInstantiation(beanName, mbdToUse);
            if (beanInstance != null) {
                return beanInstance;
            }
        } catch (Throwable var11) {
            throw new BeanCreationException(mbdToUse.getResourceDescription(), beanName, "BeanPostProcessor before instantiation of bean failed", var11);
        }

        try {
            beanInstance = this.doCreateBean(beanName, mbdToUse, args); //在这里
            if (this.logger.isDebugEnabled()) {
                this.logger.debug("Finished creating instance of bean '" + beanName + "'");
            }

            return beanInstance;
        } catch (BeanCreationException var7) {
            throw var7;
        } catch (ImplicitlyAppearedSingletonException var8) {
            throw var8;
        } catch (Throwable var9) {
            throw new BeanCreationException(mbdToUse.getResourceDescription(), beanName, "Unexpected exception during bean creation", var9);
        }
    }
```

从代码中找到`doCreateBean`方法，点进去，是这样的，太长了，省略一部分

```
    protected Object doCreateBean(String beanName, RootBeanDefinition mbd, @Nullable Object[] args) throws BeanCreationException {
        BeanWrapper instanceWrapper = null;
        if (mbd.isSingleton()) {
            instanceWrapper = (BeanWrapper)this.factoryBeanInstanceCache.remove(beanName);
        }

        if (instanceWrapper == null) {
            instanceWrapper = this.createBeanInstance(beanName, mbd, args); //上面介绍创建bean的第一步，实例化
        }

        Object bean = instanceWrapper.getWrappedInstance();
        Class<?> beanType = instanceWrapper.getWrappedClass();
        if (beanType != NullBean.class) {
            mbd.resolvedTargetType = beanType;
        }

        synchronized(mbd.postProcessingLock) {
            if (!mbd.postProcessed) {
                try {
                    this.applyMergedBeanDefinitionPostProcessors(mbd, beanType, beanName);
                } catch (Throwable var17) {
                    throw new BeanCreationException(mbd.getResourceDescription(), beanName, "Post-processing of merged bean definition failed", var17);
                }

                mbd.postProcessed = true;
            }
        }

        boolean earlySingletonExposure = mbd.isSingleton() && this.allowCircularReferences && this.isSingletonCurrentlyInCreation(beanName);
        if (earlySingletonExposure) {
            if (this.logger.isDebugEnabled()) {
                this.logger.debug("Eagerly caching bean '" + beanName + "' to allow for resolving potential circular references");
            }
   
            this.addSingletonFactory(beanName, () -> {  //添加到三级缓存中
                return this.getEarlyBeanReference(beanName, mbd, bean);
            });
        }

        Object exposedObject = bean;

        try {
            this.populateBean(beanName, mbd, instanceWrapper); //前面提到的创建bean的第二步，属性注入
            exposedObject = this.initializeBean(beanName, exposedObject, mbd); //前面提到的创建bean的第二步，初始化
        } catch (Throwable var18) {
            if (var18 instanceof BeanCreationException && beanName.equals(((BeanCreationException)var18).getBeanName())) {
                throw (BeanCreationException)var18;
            }

            throw new BeanCreationException(mbd.getResourceDescription(), beanName, "Initialization of bean failed", var18);
        }

        .......
```

上面代码中可以看到，bean的创建在第一步实力化后，被放到了三级缓存中，然后再进行的属性注入和初始化，这也就是说，bean的创建再完成第一步后就可以放到缓存中，供需要它的地方注入，这时缓存中的bean也就是前面说的半成品的bean。

整个过程看代码挺复杂，其实过程没有那么复杂，就是先从getBean获取bean，依次从一级、二级、三级缓存中获取，都没获取到说明这个bean没有被创建过，那就去创建bean，创建bean需要三步，完成第一步就可以作为半成品的bean放到缓存中，供需要的地方获取。

Spring就是这么解决循环依赖的，是不是也不复杂，但其实还有挺多细节可以看，比如要用三级缓存，二级缓存行不行？为什么第三级缓存获取bean后要放到二级缓存中，然后从第三级中删除？

当然，肯定有人是懒得看代码的，那面试中问到Spring是如何解决循环依赖的要怎么回答呢？下面进行一个简单的总结

### 面试中如何简短地回答Spring是如何解决循环依赖的

Spring是通过三级缓存解决的循环依赖问题，创建bean的过程分为实例化、属性注入、初始化三步。假设A和B发生了循环依赖，A完成实例化后会放到缓存中，这时需要在A中注入B的bean。对B进行实例化，这时需要在B中注入A的bean，从缓存中获取A实例化后的bean，B的bean创建完成。A从缓存中获取B的bean，完成属性注入和初始化。