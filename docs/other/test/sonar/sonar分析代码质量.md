# [测试框架：使用SONAR分析代码质量](https://www.cnblogs.com/topplay/p/3945013.html)

**介绍**

Sonar是一个用于代码质量管理的开源平台，用于管理Java源代码的质量。通过插件机制，Sonar 可以集成不同的测试工具，代码分析工具，以及持续集成工具，比如pmd-cpd、checkstyle、findbugs、Jenkins。通过不同的插件对这些结果进行再加工处理，通过量化的方式度量代码质量的变化，从而可以方便地对不同规模和种类的工程进行代码质量管理。同时 Sonar 还对大量的持续集成工具提供了接口支持，可以很方便地在持续集成中使用 Sonar。此外，Sonar 的插件还可以对 Java 以外的其他编程语言提供支持，对国际化以及报告文档化也有良好的支持。

**SONAR安装&运行**

下载地址：http://www.sonarqube.org/downloads/

运行：解压后，根据平台运行bin下不同目录下的启动脚本。对于linux x86_64，运行bin/linux-x86-64/sonar.sh。

可用命令：

./sonar.sh { console | start | stop | restart | status | dump }

安装插件：

SONAR中文包：http://docs.codehaus.org/display/SONAR/Chinese+Pack

将插件放置在${SONARHOME}/extensions/plugins下，重启sonar后生效。注意版本号要匹配。本例中，SonarQube版本为4.4，所以选择插件版本为1.8的。

![img](https://images0.cnblogs.com/blog/651308/201408/291612345795499.png)



**SONAR + Maven分析代码质量**

**1）设置sonar使用的数据库信息。**

本例设置sonar使用mysql数据库存储分析数据。保存设置后，执行restart使其生效。

${SONARHOME}/conf/sonar.properties:

```ini
# Permissions to create tables, indices and triggers must be granted to JDBC user.
# The schema must be created first.
sonar.jdbc.username=root
sonar.jdbc.password=root

# Comment the following line to deactivate the default embedded database.
#sonar.jdbc.url=jdbc:h2:tcp://localhost:9092/sonar

#----- MySQL 5.x
# Comment the embedded database and uncomment the following line to use MySQL
sonar.jdbc.url=jdbc:mysql://localhost:3306/sonar?useUnicode=true&characterEncoding=utf8&rewriteBatchedStatements=true

INI 复制 全屏
```

**2）需要在Maven的settings.xml设置sonar信息。**

其中<sonar.host.url>http://localhost:9000</sonar.host.url>指明了sonar服务器的地址。所以在执行maven命令的时候，<sonar.host.url>指明的服务器必须已运行起来。

${MAVEN_HOME}/conf/settings.xml：

```xml
<profiles>
    <profile>
	<id>sonar</id>
        <properties>
            <sonar.jdbc.url>jdbc:mysql://192.168.198.128:3306/sonar</sonar.jdbc.url>
            <sonar.jdbc.driver>com.mysql.jdbc.Driver</sonar.jdbc.driver>
            <sonar.jdbc.username>root</sonar.jdbc.username>
            <sonar.jdbc.password>root</sonar.jdbc.password>
            <sonar.host.url>http://localhost:9000</sonar.host.url> <!-- Sonar服务器访问地址 -->
        </properties>
    </profile>
</profiles>
<activeProfiles>
    <activeProfile>sonar</activeProfile>
</activeProfiles>
```

**3）执行mvn sonar:sonar命令进行代码分析。**

我们可以在Eclipse中，对一个标准maven工程执行sonar。说明：由于maven对sonar有很好的支持，会自动执行相应的脚本，所以无需在pom中添加sonar说明。

在执行maven进行sonar分析之前，必须确保sonar服务器已经处于运行状态。本例中sonar服务器运行在localhost:9000上。

首先，执行sonar:sonar命令，最后得到输出如下输出。如果输出”BUILD SUCCESS“说明已经构建成功。

![img](https://images0.cnblogs.com/blog/651308/201408/291612353605627.png)

然后，我们可以在浏览器查看分析结果。

**查看分析结果**

对于使用sonar自带服务器来说，在浏览器访问：http://sonar_ip:9000，打开sonar结果页面。可使用admin/admin账号登录进入。

**1）home页**

下面是home页，右边PROJECTS页面列出了所有的工程。点击红色框内的链接，可以查看详细情况。

![img](https://images0.cnblogs.com/blog/651308/201408/291612361415754.png)**
**

**2）工程总面板视图**

Dashboard包含了很多信息，比如程序统计信息、问题统计信息、技术债务、代码复杂度、单元测试覆盖度等。

![img](https://images0.cnblogs.com/blog/651308/201408/291612373916039.png)**
**

**3）Hotspots热点区**

在热点区，可以查看比较主要（hot）的信息。

![img](https://images0.cnblogs.com/blog/651308/201408/291612382355382.png)**
**

**4）问题视图**

点击左侧导航树的“问题”，打开问题视图页。通过点击问题数，如下红框所示，可以查看具体问题。

![img](https://images0.cnblogs.com/blog/651308/201408/291612387204066.png)

点击问题数后，进入具体问题页。SonarQube允许管理员对问题进行重新确认，比如可以认为一个打开的问题是误判的。

![img](https://images0.cnblogs.com/blog/651308/201408/291612396262624.png)**
**

下面是认为一个问题是误判后的情况。

![img](https://images0.cnblogs.com/blog/651308/201408/291612400798552.png)**
**

在问题页面，可以通过“状态”搜索问题。下面是搜索“误判”问题的结果。

![img](https://images0.cnblogs.com/blog/651308/201408/291612409386422.png)**
**

**5）技术债务**

这里列出了修复问题所需要的时间，所谓技术债务。出来混总要还的，遗留的问题越多，技术债务越大。

![img](https://images0.cnblogs.com/blog/651308/201408/291612417359779.png)**
**

**6）问题明细**

这里列出问题明细，包括问题严重级别，对应的问题数量，问题的描述。

![img](https://images0.cnblogs.com/blog/651308/201408/291612423768650.png)**
**

**结合Jenkins**

可以将SONAR服务器放置在任意master或者slave节点上，在进行sonar分析时，必须在maven的conf/settings.xml中配置sonar服务器信息。然后就可以在jenkins中进行sonar分析了。

有两种方法使jenkins与sonar结合：一种就是上面介绍的通过maven（jenkins -maven - sonar），另外一种是直接在jenkins中调用sonar。