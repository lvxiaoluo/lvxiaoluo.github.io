# Java SPI一探究竟 

![图片](https://mmbiz.qpic.cn/mmbiz_png/P13HW4Fm1HUwS9asyQyic1eBt0BG1RSKNxF0MJ1z1F0fKD6bE7b2Py2p89srPzCwq6TOHVM23iagKlA5aSJ7cyZQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

师傅：这不师傅最近… 你懂得…（此处省略一万字）

![图片](https://mmbiz.qpic.cn/mmbiz_png/P13HW4Fm1HUwS9asyQyic1eBt0BG1RSKNO8E9XUlYD3wsj69oNiaZyGuQ0MUIEUjTO6bmbicC8IpjHjtfgruNtSbQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

悟纤：师傅你太瞧得起我了，我又不会读心术。

师傅：师傅今天就给你分享一个JavaSPI，用处大大滴。

悟纤：师傅，来露一手。

![图片](https://mmbiz.qpic.cn/mmbiz_png/P13HW4Fm1HUwS9asyQyic1eBt0BG1RSKNyvUxDqkF51BGP6XzibHCrdUKCSqJNVGQDhJjhNe5Y0KicoGsdH1DpyxA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

 

**一、什么是SPI ?**

​    SPI全称Service Provider Interface，是Java提供的一套用来被第三方实现或者扩展的接口，是一种将服务接口与服务实现分离以达到解耦、大大提升了程序可扩展性的机制。引入服务提供者就是引入了spi接口的实现者，通过本地的注册发现获取到具体的实现类，轻松可插拔。



**二、SPI整体机制图**

![图片](https://mmbiz.qpic.cn/mmbiz_png/P13HW4Fm1HUwS9asyQyic1eBt0BG1RSKN491kfmgmCfBZ2bM04uLIialYhUfWHrdP7Suf8uicxECIEsk4Yy4kS4DA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

当服务的提供者提供了一种接口的实现之后，需要在classpath下的META-INF/services/目录里创建一个以服务接口命名的文件，这个文件里的内容就是这个接口的具体的实现类。当其他的程序需要这个服务的时候，就可以通过查找这个jar包（一般都是以jar包做依赖）的META-INF/services/中的配置文件，配置文件中有接口的具体实现类名，可以根据这个类名进行加载实例化，就可以使用该服务了。JDK中查zhao服务的实现的工具类是：java.util.ServiceLoader。

 

**三、SPI的应用场景**

​    SPI扩展机制应用场景有很多，比如Common-Logging，JDBC，Dubbo、Sharding-JDBC等等。

​    jdbc4.0以前， 开发人员还需要基于Class.forName("xxx")的方式来装载驱动，jdbc4也基于spi的机制来发现驱动提供商了，可以通过METAINF/services/java.sql.Driver文件里指定实现类的方式来暴露驱动提供者。

 

**四、SPI机制的约定**

（1）在 META-INF/services/ 目录中创建以接口全限定名命名的文件，该文件内容为API具体实现类的全限定名。

（2）使用 ServiceLoader 类动态加载 META-INF 中的实现类。

（3）如 SPI 的实现类为 Jar 则需要放在主程序 ClassPath 中

（4）API 具体实现类必须有一个不带参数的构造方法

 

**五、SPI的一个小栗子**

**5.1** **说明**

​    接下里我们来实现一个小栗子：就是主键生成的实现，通过UUID的实现和时间戳的实现。

 

**5.2** **编码步骤**

（1）创建一个maven java project；

（2）创建主键生成的接口；

（3）主键生成的接口实现类：UUID的实现和时间戳的实现；

（4）编写配置文件

（5）编写测试类

 

**5.3** **具体编码**

**（1）创建一个maven java project；**

​    使用idea创建一个简单的maven javaproject。

 

**（2）创建主键生成的接口；**

​    新建一个包com.kfit.id，然后新建一个接口IdGenerator：
```
package com.kfit.id;

/**
 * ID生成接口
 *
 * @author 悟纤「公众号SpringBoot」
 * @date 2021-01-18
 * @slogan 大道至简 悟在天成
 */
public interface IdGenerator {
    /**
     * 生成ID
     * @return
     */
    Comparable generate();

    /**主键生成方式的类型 ：timestamp | uuid */
    String getType();
}
```



​    这个接口的全限定名是：com.kfit.id.IdGenerator，这个下面需要用到。

 

**（3）主键生成的接口实现类：UUID的实现和时间戳的实现；**

​    这里实现两种生成方式：

UUID的生成方式：

```
package com.kfit.id.impl;

import com.kfit.id.IdGenerator;

import java.util.UUID;

/**
 * UUID生成的方式
 *
 * @author 悟纤「公众号SpringBoot」
 * @date 2021-01-18
 * @slogan 大道至简 悟在天成
 */
public class UUIDIdGenerator implements IdGenerator {
    public Comparable generate() {
        return UUID.randomUUID().toString().replaceAll("-", "");
    }

    @Override
    public String getType() {
        return "uuid";
    }
}
```

 

时间戳的实现方式：
```
package com.kfit.id.impl;

import com.kfit.id.IdGenerator;

import java.util.Date;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicLong;

/**
 * UUID生成的方式
 *
 * @author 悟纤「公众号SpringBoot」
 * @date 2021-01-18
 * @slogan 大道至简 悟在天成
 */
public class TimestampGenerator implements IdGenerator {
    private AtomicLong atomicLong = new AtomicLong();
    public Comparable generate() {
       
        String id = new Date().getTime()+""+atomicLong.addAndGet(1);
        return new Long(id);
    }

    @Override
    public String getType() {
        return "timestamp";
    }
}
```



**（4）编写配置文件**

​    接下来我们需要编写配置文件：

在resources目录下新建META-INF/services目录，并且在这个目录下新建一个与上述接口的全限定名一致的文件，在这个文件中写入接口的实现类的全限定名：

​    在这里文件名称就是：com.kfit.id.IdGenerator

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)

​    在文件中com.kfit.id.IdGenerator添加我们的实现方式：

- 
- 

```
com.kfit.id.impl.UUIDIdGenerator
com.kfit.id.impl.TimestampGenerator
```

**（5）编写测试类**

​    最后我们就可以使用java.util.ServiceLoader进行载入我们的信息：

```
package com.kfit.id;

import java.util.ServiceLoader;

/**
 * @author 悟纤「公众号SpringBoot」
 * @date 2021-01-18
 * @slogan 大道至简 悟在天成
 */
public class Test {
    public static void main(String[] args) {
        ServiceLoader<IdGenerator> idGenerators = ServiceLoader.load(IdGenerator.class);
        for (IdGenerator idGenerator : idGenerators) {
            System.out.println(idGenerator.getType()+":"+idGenerator.generate());
        }
    }
}
```

​    执行结果：

![图片](https://mmbiz.qpic.cn/mmbiz_png/P13HW4Fm1HUwS9asyQyic1eBt0BG1RSKNViaic8V9wvfmicIHJSkBsxrTghwVL1DCTxmAC1mia0Q38T9BiaW2WLIkf1Q/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

*题外话*：在实际的项目中，我们在项目启动的时候，使用ServiceLoader加载，然后放到Map容器中，当用户调用的时候，根据用户传递的类型进行获取对应的主键生成策略。

**六、小结**

![图片](https://mmbiz.qpic.cn/mmbiz_png/P13HW4Fm1HUwS9asyQyic1eBt0BG1RSKNFKcc780hvspXiamRIQRs55qsWW81D7P5Atznm2M9ibBe256Sp0IK6Siag/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

```
我就是我，是颜色不一样的烟火。
我就是我，是与众不同的小苹果。
```