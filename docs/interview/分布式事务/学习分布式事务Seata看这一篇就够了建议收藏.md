# 学习分布式事务Seata看这一篇就够了，建议收藏

**简介：** 学习分布式事务Seata看这一篇就够了，建议收藏

![目录](https://ucc.alicdn.com/images/user-upload-01/img_convert/15d574e0d688b06c50753c511c2e4421.png?x-oss-process=image/resize,w_1400/format,webp)

## 一、事务的特性

**ACID特性**

- A（Atomic）：原子性，构成事务的所有操作，要么都执行完成，要么全部不执行，不可能出现部分成功部分失败的情况。
- C（Consistency）：一致性，在事务执行前后，数据库的一致性约束没有被破坏。例如：张三向李四转100元， 转账前和转账后的数据是正确状态这叫一致性，如果出现张三转出100元，李四账户没有增加100元这就出现了数据错误，就没有达到一致性。
- I（Isolation）：隔离性，数据库中的事务一般都是并发的，隔离性是指并发的两个事务的执行互不干扰，一个事务不能看到其他事务运行过程的中间状态。通过配置事务隔离级别可以避脏读、重复读等问题。
- D（Durability）：持久性，事务完成之后，该事务对数据的更改会被持久化到数据库，且不会被回滚。

## 二、本地事务与分布式事务

- 本地事务：同一数据库和服务器，称为本地事务。
  在计算机系统中，更多的是通过关系型数据库来控制事务，这是利用数据库本身的事务特性来实现的，因此叫数据库事务，由于应用主要靠关系数据库来控制事务，而数据库通常和应用在同一个服务器，所以基于关系型数据库的事务又被称为本地事务。
- 分布式事务：
  分布式事务指事务的参与者、支持事务的服务器、资源服务器以及事务管理器分别位于**不同的分布式系统**的不同节点之上，且属于不同的应用，分布式事务需要保证这些操作要么全部成功，要么全部失败。本质上来说，分布式事务就是为了保证不同数据库的数据一致性。

**分布式事务的引入**

举例：分布式系统会把一个应用系统拆分为可独立部署的多个服务，因此需要服务与服务之间远程协作才能完成事务操 作，这种分布式系统环境下由不同的服务之间通过网络远程协作完成事务称之为分布式事务，例如用户注册送积分事务、创建订单减库存事务，银行转账事务等都是分布式事务。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/fef386d9c641c0c63cde8cd1011dee44.png?x-oss-process=image/resize,w_1400/format,webp)

通过以上的图中我们可以看出，其实只要涉及到操作多个数据源，就可能会产生事务问题，当然在实际开发中我们要尽量避免这种问题的出现，当然如果避免不了，我们就需要进行解决，在我们的微服务系统架构中，目前比较好，比较常用的解决方案就是Seata。

## 三、分布式事务理论依据

随着互联化的蔓延，各种项目都逐渐向分布式服务做转换。如今微服务已经普遍存在，本地事务已经无法满足分布式的要求，由此分布式事务问题诞生。 分布式事务被称为世界性的难题，目前分布式事务存在两大理论依据：

- CAP定律
- BASE理论

### 3.1、CAP定律

这个定理的内容是指：在一个分布式系统中、Consistency(一致性)、Availability(可用性)、Partitiontolerance(分区容错性)，三者不可得兼。

- 一致性（C）

  在分布式系统中的所有数据备份，在同一时刻是否同样的值。（等同于所有节点访问同一份最新的数据副本）

- 可用性（A）

  在集群中一部分节点故障后，集群整体是否还能响应客户端的读写请求。（对数据更新具备高可用性）

- 分区容错性（P）

  以实际效果而言，分区相当于对通信的时限要求。系统如果不能在时限内达成数据一致性，就意味着发生了分区的情况，必须就当前操作在C和A之间做出选择

CAP是无法同时存在的，通过下面的例子进行说明

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/4d81cde756ed9dc08f356640bf5b31ae.png?x-oss-process=image/resize,w_1400/format,webp)

> - 当库存服务减库存以后，那么需要将数据同步到其他的服务上，这是为了保证数据一致性C，但是网络是不可靠的，所以我们系统就需要保证分区容错性P，也就是我们必须容忍网络所带来的的一些问题，此时如果我们想保证C那么就需要舍弃A，也就是说我们在保证C的情况下，就必须舍弃A，也就是CP无法保证高可用。
> - 如果为了保证A，高可用的情况下，也就是必须在限定时间内给出响应，同样由于网络不可靠P，订单服务就有可能无法拿到新的数据，但是也要给用户作出响应，那么也就无法保证C一致性。所以AP是无法保证强一致性的。
> - 如果我们想保证CA，也就是高可用和一致性，也就是必须保证网络良好才能实现，那么也就是说我们需要将库存、订单、用户放到一起，但是这种情况也就丧失了P这个保证，这个时候系统也就不是分布式系统了。

总结：在分布式系统中，p是必然的存在的，所以我们只能在C和A之间进行取舍，在这种条件下就诞生了BASE理论

### 3.2、BASE理论

BASE是Basically Available（基本可用）、Soft state（软状态）和 Eventually consistent（最终一致性）三个短语的缩写。BASE理论是对CAP中一致性和可用性权衡的结果，其来源于对大规模互联网系统分布式实践的总结， 是基于CAP定理逐步演化而来的。BASE理论的核心思想是：即使无法做到强一致性，但每个应用都可以根据自身业务特点，采用适当的方式来使系统达到最终一致性。

- 基本可用

  基本可用是指分布式系统在出现不可预知故障的时候，允许损失部分可用性—-注意，这绝不等价于系统不可用。比如：

  （1）响应时间上的损失。正常情况下，一个在线搜索引擎需要在0.5秒之内返回给用户相应的查询结果，但由于出现故障，查询结果的响应时间增加了1~2秒

  （2）系统功能上的损失：正常情况下，在一个电子商务网站上进行购物的时候，消费者几乎能够顺利完成每一笔订单，但是在一些节日大促购物高峰的时候，由于消费者的购物行为激增，为了保护购物系统的稳定性，部分消费者可能会被引导到一个降级页面

- 软状态

  软状态指允许系统中的数据存在中间状态，并认为该中间状态的存在不会影响系统的整体可用性，即允许系统在不同节点的数据副本之间进行数据同步的过程存在延时

- 最终一致性

  最终一致性强调的是所有的数据副本，在经过一段时间的同步之后，最终都能够达到一个一致的状态。因此，最终一致性的本质是需要系统保证最终数据能够达到一致，而不需要实时保证系统数据的强一致性。

那这个位置我们依旧可以用我们刚才的例子来进行说明

**基本可用：**保证核心服务是可以使用的，至于其他的服务可以适当的降低响应时间，甚至是服务降级

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/4711c99c64b1d37d8c3a51a3efd60166.png?x-oss-process=image/resize,w_1400/format,webp)

**软状态：**存在中间状态，不影响整体系统使用，数据同步存在延时。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/ab32126adf9b981b8fdace2d071bb32c.png?x-oss-process=image/resize,w_1400/format,webp)

**最终一致性：**再过了流量高峰期以后，经过一段时间的同步，保持各服务数据的一致。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/c571a8e3b80246f53bb1e4cf6fd640e1.png?x-oss-process=image/resize,w_1400/format,webp)

## 四、Seata简介

### 4.1、Seata是什么

Seata 是一款开源的分布式事务解决方案，致力于提供高性能和简单易用的分布式事务服务。Seata 将为用户提供了 AT、TCC、SAGA 和 XA 事务模式，为用户打造一站式的分布式解决方案。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/fdacc2fa159fb31cb577ec5e2b7c6885.png?x-oss-process=image/resize,w_1400/format,webp)

在我们的微服务系统中，对应业务被对应的拆分成独立模块，在官方提供的架构图中，我们可以看出当前是三个服务分别是：

- 仓储服务：对给定的商品进行增删操作记录数量。
- 订单服务：根据采购者的需求创建订单。
- 账户服务：从用户账户中扣除余额、积分等。

在这套架构中，用户下单购买商品的业务，就需要三个服务来完成，每个服务内部的数据一致性由**本地事务**来保证，但是全局的数据一致性问题就没办法保证，Seata就是来进行解决这种问题的解决方案。

### 4.2、官网地址

Seata中文文档

### 4.3、Seata基本架构

- TC (Transaction Coordinator) - 事务协调者；维护全局和分支事务的状态，驱动全局事务提交或回滚。
- TM (Transaction Manager) - 事务管理器；定义全局事务的范围：开始全局事务、提交或回滚全局事务。
- RM (Resource Manager) - 资源管理器；管理分支事务处理的资源，与TC交谈以注册分支事务和报告分支事务的状态，并驱动分支事务提交或回滚。

注：上述的TC (Transaction Coordinator) - 事务协调者 也就是`Seata-Server`服务端。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/8138d255f3f2674fdc0f2c9eac15e9e9.png?x-oss-process=image/resize,w_1400/format,webp)

### 4.4、分布式事务解决方案

Seata提供了四种不同的分布式事务解决方案：

- XA模式：强一致性分阶段事务模式，牺牲了一定的可用性，无业务侵入。
- TCC模式：最终一致的分阶段事务模式，有业务侵入。
- AT模式：最终一致的分阶段事务模式，无业务侵入，也是**Seata的默认模式**。
- SAGA模式：长事务模式，有业务侵入。

#### 4.4.1、Seata-AT模式

**基本概念：**AT模式是一种无侵入的分布式事务解决方案，在AT模式下，用户只需要关注自己的“业务SQL”,用户的“业务SQL”作为一阶段，Seata框架会自动的生成事务的二阶段提交和回滚。

**整体机制**

两阶段提交协议的演变：

- 一阶段：业务数据和回滚日志在同一个本地事务中提交，释放本地锁和连接资源。
- 二阶段：提交异步化，非常快速的完成；回滚通过一阶段的回滚日志进行反向补偿。

**一阶段**：在一阶段中，Seata会拦截“业务SQL”,首先解析SQL的语义，找到要更新的业务数据，在数据更新前，保存下来“undo”,然后执行“业务SQL”更新数据，更新之后再次保存数据“redo”,最后生成行锁，这些操作都在本地数据库事务内完成，这样保证了一阶段的原子性。

**二阶段**：相对一阶段，二阶段比较简单，负责整体的回滚和提交，如果之前的一阶段中有本地事务没有通过，那么就执行全局回滚，否则执行全局提交，回滚用到的就是一阶段记录的“undo Log”，通过回滚记录生成反向更新SQL并执行，以完成分支的回滚。当然事务完成后会释放所有资源和删除所有的日志。

**图解**

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/6130f3de63adc701c5894a391013e66d.png?x-oss-process=image/resize,w_1400/format,webp)

注：关于AT模式的详细使用介绍见五、六章节！

#### 4.4.2、Seata-XA模式

Seata 1.2.0 版本重磅发布新的事务模式：XA 模式，实现对 XA 协议的支持。

我们从三个方面来深入分析：

1. XA模式是什么？
2. 为什么支持XA？
3. XA模式如何实现的，以及如何使用？

##### 4.4.2.1、XA模式

首先我们需要先了解一下什么是XA？

XA 规范早在上世纪 90 年代初就被提出，用以解决分布式事务处理这个领域的问题。

注意：不存在某一种分布式事务机制可以完美适应所有场景，满足所有需求。

现在，无论 AT 模式、TCC 模式还是 Saga 模式，这些模式的提出，本质上都源自 XA 规范对某些场景需求的无法满足。

###### 什么是XA协议

XA 规范 是 X/Open 组织定义的分布式事务处理（DTP，Distributed Transaction Processing）标准

XA 规范 描述了全局的事务管理器与局部的资源管理器之间的接口。 XA规范 的目的是允许的多个资源（如数据库，应用服务器，消息队列等）在同一事务中访问，这样可以使 ACID 属性跨越应用程序而保持有效。

XA 规范 使用两阶段提交（2PC，Two-Phase Commit）来保证所有资源同时提交或回滚任何特定的事务。

XA 规范 在上世纪 90 年代初就被提出。目前，几乎所有主流的数据库都对 XA 规范 提供了支持。

DTP模型定义如下角色：

- AP：即应用程序，可以理解为使用DTP分布式事务的程序
- RM：资源管理器，可以理解为事务的参与者，一般情况下是指一个数据库的实例（MySql），通过资源管理器对该数据库进行控制，资源管理器控制着分支事务
- TM：事务管理器，负责协调和管理事务，事务管理器控制着全局事务，管理实务生命周期，并协调各个RM。全局事务是指分布式事务处理环境中，需要操作多个数据库共同完成一个工作，这个工作即是一个全局事务。
- DTP模式定义TM和RM之间通讯的接口规范叫XA，简单理解为数据库提供的2PC接口协议，基于数据库的XA协议来实现的2PC又称为XA方案。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/a6a73046a484ac0e98442f30cf9f3e0c.png?x-oss-process=image/resize,w_1400/format,webp)

案例解释：

1. 应用程序（AP）持有订单库和商品库两个数据源。
2. 应用程序（AP）通过TM通知订单库（RM）和商品库（RM），来创建订单和减库存，RM此时未提交事务，此时商品和订单资源锁定。
3. TM收到执行回复，只要有一方失败则分别向其他RM发送回滚事务，回滚完毕，资源锁释放。
4. TM收到执行回复，全部成功，此时向所有的RM发起提交事务，提交完毕，资源锁释放。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/6d570f85b166976101af9b7fcc2463fd.png?x-oss-process=image/resize,w_1400/format,webp)

**XA协议的痛点**

如果一个参与全局事务的资源 “失联” 了（收不到分支事务结束的命令），那么它锁定的数据，将一直被锁定。进而，甚至可能因此产生死锁。

这是 XA 协议的核心痛点，也是 Seata 引入 XA 模式要重点解决的问题。

###### Seata的事务模式

Seata 定义了全局事务的框架。

全局事务 定义为若干 分支事务 的整体协调：

1. TM 向 TC 请求发起（Begin）、提交（Commit）、回滚（Rollback）全局事务。
2. TM 把代表全局事务的 XID 绑定到分支事务上。
3. RM 向 TC 注册，把分支事务关联到 XID 代表的全局事务中。
4. RM 把分支事务的执行结果上报给 TC。（可选）
5. TC 发送分支提交（Branch Commit）或分支回滚（Branch Rollback）命令给 RM。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/79d5cf6ba7648573aa3455fe3d1d5a95.png?x-oss-process=image/resize,w_1400/format,webp)

Seata 的 全局事务 处理过程，分为两个阶段：

- 执行阶段 ：执行分支事务，并保证执行结果满足是 *可回滚的（Rollbackable）* 和 *持久化的（Durable）*。
- 完成阶段： 根据 执行阶段 结果形成的决议，应用通过 TM 发出的全局提交或回滚的请求给 TC，TC 命令 RM 驱动 分支事务 进行 Commit 或 Rollback。

Seata 的所谓事务模式是指：运行在 Seata 全局事务框架下的 分支事务 的行为模式。准确地讲，应该叫作 分支事务模式。

不同的 事务模式 区别在于 分支事务 使用不同的方式达到全局事务两个阶段的目标。即，回答以下两个问题：

- 执行阶段 ：如何执行并 保证 执行结果满足是 *可回滚的（Rollbackable）* 和 *持久化的（Durable）*。
  - 完成阶段： 收到 TC 的命令后，如何做到分支的提交或回滚？

我们以AT模式举例：

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/b298f692622227482798ae819f9160aa.png?x-oss-process=image/resize,w_1400/format,webp)

- 执行阶段：
  - 可回滚：根据 SQL 解析结果，记录回滚日志
  - 持久化：回滚日志和业务 SQL 在同一个本地事务中提交到数据库
- 完成阶段：
  - 分支提交：异步删除回滚日志记录
  - 分支回滚：依据回滚日志进行反向补偿更新

##### 4.4.2.2、Seata的XA模式

XA模式：

在 Seata 定义的分布式事务框架内，利用事务资源（数据库、消息服务等）对 XA 协议的支持，以 XA 协议的机制来管理分支事务的一种事务模式。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/20f482d530640a1b63cd344830c2f8eb.png?x-oss-process=image/resize,w_1400/format,webp)

- 执行阶段：
  - 可回滚：业务 SQL 操作放在 XA 分支中进行，由资源对 XA 协议的支持来保证 可回滚
  - 持久化：XA 分支完成后，执行 XA prepare，同样，由资源对 XA 协议的支持来保证 *持久化*（即，之后任何意外都不会造成无法回滚的情况）
- 完成阶段：
  - 分支提交：执行 XA 分支的 commit
  - 分支回滚：执行 XA 分支的 rollback

###### 为什么要在Seata中支持XA

为什么要在 Seata 中增加 XA 模式呢？支持 XA 的意义在哪里呢？

本质上，Seata 已经支持的 3 大事务模式：**AT、TCC、Saga 都是补偿型 的**。

补偿型事务处理机制构建在事务资源之上（要么在中间件层面，要么在应用层面），事务资源 本身对分布式事务是无感知的。

事务资源对分布式事务的无感知存在一个根本性的问题：无法做到真正的全局一致性 。

比如，一条库存记录，处在 补偿型 事务处理过程中，由 100 扣减为 50。此时，仓库管理员连接数据库，查询统计库存，就看到当前的 50。之后，事务因为异外回滚，库存会被补偿回滚为 100。显然，仓库管理员查询统计到的 50 就是 脏 数据。所以补偿型事务是存在中间状态的（中途可能读到脏数据）。

###### XA的价值

与 补偿型 不同，XA 协议 要求 事务资源 本身提供对规范和协议的支持。

因为 事务资源 感知并参与分布式事务处理过程，所以 事务资源（如数据库）可以保障从任意视角对数据的访问有效隔离，满足全局数据一致性。

比如，刚才提到的库存更新场景，XA 事务处理过程中，中间状态数据库存 50 由数据库本身保证，是不会仓库管理员的查询统计看到的。

除了 全局一致性 这个根本性的价值外，支持 XA 还有如下几个方面的好处：

1. 业务无侵入：和 AT 一样，XA 模式将是业务无侵入的，不给应用设计和开发带来额外负担。
2. 数据库的支持广泛：XA 协议被主流关系型数据库广泛支持，不需要额外的适配即可使用。
3. 多语言支持容易：因为不涉及 SQL 解析，XA 模式对 Seata 的 RM 的要求比较少。
4. 传统基于 XA 应用的迁移：传统的，基于 XA 协议的应用，迁移到 Seata 平台，使用 XA 模式将更平滑。

##### 4.4.2.3、项目中应用XA模式

**代码获取**

下面使用官方的一个例子进行演示：

![官方案例项目](https://ucc.alicdn.com/images/user-upload-01/img_convert/debf1dddaaa07c8c266f184bf6352195.png?x-oss-process=image/resize,w_1400/format,webp)

**初始化工程**

XA案例所在工程`seata-xa`,如下图所示：

![seata-xa工程](https://ucc.alicdn.com/images/user-upload-01/img_convert/e34b3cb2ce71e8a01f9be606677200cf.png?x-oss-process=image/resize,w_1400/format,webp)

**数据库初始化**

将数据库文件脚本all_in_one.sql导出到数据库中，并修改项目配置文件`application.properties`数据库连接。

初始数据：

![初始化数据](https://ucc.alicdn.com/images/user-upload-01/img_convert/2adcb386997c400a3a4876b4942bcf15.png?x-oss-process=image/resize,w_1400/format,webp)

**启动项目**

配置文件修改完成后，分别启动以上四个基础服务即可。

![项目启动](https://ucc.alicdn.com/images/user-upload-01/img_convert/3ea8386ff7e7723926692890f202bfaa.png?x-oss-process=image/resize,w_1400/format,webp)

**代码测试**

调用成功后，返回`SUCCESS`

此时，数据如下：

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/16387e16f2584052d958833ea7035c02.png?x-oss-process=image/resize,w_1400/format,webp)

注：以上是正常的业务处理流程，下面演示发生分布式事务问题的情况，并重启订单`order服务`。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/542a6cf03f289a7aa6a99456c5a01ff3.png?x-oss-process=image/resize,w_1400/format,webp)

将表中数据恢复为初始化的状态，再次调用

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/4e196f3b06c5391565ec65df80c90951.png?x-oss-process=image/resize,w_1400/format,webp)

此时，查看表中数据无变化，即XA模式应用生效。

官方案例演示图：

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/e5bc13c2479cf8aea54fbb8da755725e.png?x-oss-process=image/resize,w_1400/format,webp)

案例解析：

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/2c56137ebf6b41034e1f3721cb81bed6.png?x-oss-process=image/resize,w_1400/format,webp)

整体运行机制：

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/7551f52474e6834244d19f9c083654b4.png?x-oss-process=image/resize,w_1400/format,webp)

**总结**

在当前的技术发展阶段，不存一个分布式事务处理机制可以完美满足所有场景的需求。

一致性、可靠性、易用性、性能等诸多方面的系统设计约束，需要用不同的事务处理机制去满足。

Seata项目最核心的价值在于：构建一个全面解决分布式事务问题的 标准化 平台。

基于Seata，上层应用架构可以根据实际场景的需求，灵活选择合适的分布式事务解决方案。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/4c7e9d6dd8e02f7664b2bd567a7dfe34.png?x-oss-process=image/resize,w_1400/format,webp)

XA 模式的加入，补齐了 Seata 在 全局一致性 场景下的缺口，形成 AT、TCC、Saga、XA 四大事务模式 的版图，基本可以满足所有场景的分布式事务处理诉求。

##### 4.4.2.4、XA模式如何切换

切换XA模式，只需要修改数据源代理为XA模式即可。

```java
@Configuration
public class StockXADataSourceConfiguration {

    @Bean
    @ConfigurationProperties(prefix = "spring.datasource")
    public DruidDataSource druidDataSource() {
        return new DruidDataSource();
    }

    @Bean("dataSourceProxy")
    public DataSource dataSource(DruidDataSource druidDataSource) {
        // DataSourceProxy for AT mode
        // return new DataSourceProxy(druidDataSource);

        // DataSourceProxyXA for XA mode
        return new DataSourceProxyXA(druidDataSource);
    }

    @Bean("jdbcTemplate")
    public JdbcTemplate jdbcTemplate(DataSource dataSourceProxy) {
        return new JdbcTemplate(dataSourceProxy);
    }
}
```

#### 4.4.3、Seata-TCC事务模式

##### 4.4.3.1、什么是TCC

TCC 是分布式事务中的二阶段提交协议，它的全称为 Try-Confirm-Cancel，即资源预留（Try）、确认操作（Confirm）、取消操作（Cancel），他们的具体含义如下：

- Try：对业务资源的检查并预留。
- Confirm：对业务处理进行提交，即 commit 操作，只要 Try 成功，那么该步骤一定成功。
- Cancel：对业务处理进行取消，即回滚操作，该步骤回对 Try 预留的资源进行释放。

TCC 是一种侵入式的分布式事务解决方案，以上三个操作都需要业务系统自行实现，对业务系统有着非常大的入侵性，设计相对复杂，但优点是 TCC 完全不依赖数据库，能够实现跨数据库、跨应用资源管理，对这些不同数据访问通过侵入式的编码方式实现一个原子操作，更好地解决了在各种复杂业务场景下的分布式事务问题。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/387b3011d7543412f1a7d263347be32d.png?x-oss-process=image/resize,w_1400/format,webp)

##### 4.4.3.2、Seata的TCC模式

Seata TCC 模式跟通用型 TCC 模式原理一致。

**TCC和AT区别**

AT 模式基于 **支持本地 ACID 事务** 的 **关系型数据库**：

- 一阶段 prepare 行为：在本地事务中，一并提交业务数据更新和相应回滚日志记录。
- 二阶段 commit 行为：马上成功结束，**自动** 异步批量清理回滚日志。
- 二阶段 rollback 行为：通过回滚日志，**自动** 生成补偿操作，完成数据回滚。

相应的，TCC 模式，不依赖于底层数据资源的事务支持：

- 一阶段 prepare 行为：调用 **自定义** 的 prepare 逻辑。
- 二阶段 commit 行为：调用 **自定义** 的 commit 逻辑。
- 二阶段 rollback 行为：调用 **自定义** 的 rollback 逻辑。

所谓 TCC 模式，是指支持把 **自定义** 的分支事务纳入到全局事务的管理中。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/cc1d0e97cc4aad996ddb2235bc68b0ab.png?x-oss-process=image/resize,w_1400/format,webp)

**特点**

- 侵入性比较强，并且需要自己实现相关事务控制逻辑。
- 在整个过程基本没有锁，性能较强。

**详细讲解**

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/c5bd254a9e4daafb7353826fed0fcdcf.png?x-oss-process=image/resize,w_1400/format,webp)

#### 4.4.4、Seata-Saga事务模式

##### 4.4.4.1、基本概念

Saga模式是SEATA提供的长事务解决方案，在Saga模式中，业务流程中每个参与者都提交本地事务，当出现某一个参与者失败则补偿前面已经成功的参与者，一阶段正向服务和二阶段补偿服务（执行处理时候出错了，给一个修复的机会）都由业务开发实现。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/0741ef80d08106a770da0a849f550391.png?x-oss-process=image/resize,w_1400/format,webp)

Saga 模式下分布式事务通常是由事件驱动的，各个参与者之间是异步执行的，Saga 模式是一种长事务解决方案。

##### 4.4.4.2、为什么需要Saga

之前我们学习的Seata分布式三种操作模型中所使用的的微服务全部可以根据开发者的需求进行修改，但是在一些特殊环境下，比如老系统，封闭的系统（无法修改，同时没有任何分布式事务引入），那么AT、XA、TCC模型将全部不能使用，为了解决这样的问题，才引用了Saga模型。

比如：事务参与者可能是其他公司的服务或者是遗留系统，无法改造，可以使用Saga模式。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/3c1838f5e28b0c9d590a1901966eeb5f.png?x-oss-process=image/resize,w_1400/format,webp)

Saga模式是Seata提供的长事务解决方案，提供了**异构系统的事务统一处理模型**。在Saga模式中，所有的子业务都不在直接参与整体事务的处理（只负责本地事务的处理），而是全部交由了最终调用端来负责实现，而在进行总业务逻辑处理时，在某一个子业务出现问题时，则自动补偿全面已经成功的其他参与者，这样一阶段的正向服务调用和二阶段的服务补偿处理全部由总业务开发实现。

![Saga执行模型](https://ucc.alicdn.com/images/user-upload-01/img_convert/1b272c2bf271c2f1ac7640f78f395d67.png?x-oss-process=image/resize,w_1400/format,webp)

##### 4.4.4.3、Saga状态机

目前Seata提供的Saga模式只能通过状态机引擎来实现，需要开发者手工的进行Saga业务流程绘制，并且将其转换为Json配置文件，而后在程序运行时，将依据子配置文件实现业务处理以及服务补偿处理，而要想进行Saga状态图的绘制，一般需要通过Saga状态机来实现。

基本原理：

- 通过状态图来定义服务调用的流程并生成json定义文件。
- 状态图中一个节点可以调用一个服务，节点可以配置它的补偿节点。
- 状态图 json 由状态机引擎驱动执行，当出现异常时状态引擎反向执行已成功节点对应的补偿节点将事务回滚。
- 可以实现服务编排需求，支持单项选择、并发、子流程、参数转换、参数映射、服务执行状态判断、异常捕获等功能。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/e13ce28f79d1e4faa95e7e46ce8d4075.png?x-oss-process=image/resize,w_1400/format,webp)

##### 4.4.4.4、Saga状态机设计器

Seata Saga 提供了一个可视化的状态机设计器方便用户使用，代码和运行指南请参考：

> https://github.com/seata/seata/tree/develop/saga/seata-saga-statemachine-designer

![状态机设计器](https://ucc.alicdn.com/images/user-upload-01/img_convert/21adee845a35adcc3630856f39c7b493.png?x-oss-process=image/resize,w_1400/format,webp)

### 4.5、四种模式的对比

![四种模型对比](https://ucc.alicdn.com/images/user-upload-01/img_convert/4c5416532b670f1de37fced8035d8342.png?x-oss-process=image/resize,w_1400/format,webp)

AT模式，是我们常用的处理模式，也是使用最多的一种。

XA和AT，是无侵入式的，二者间的切换只需要更改数据源的代理对象即可。

TCC需要我们手动、自定义，try、Confirm、Cancel。

Saga是针对老项目，不可更改的项目，通过外部的形式解决调用的时候出现的分布式问题，通过Saga中的状态机进行总业务逻辑的设计。

## 五、部署Seata TC服务

### 5.1、下载seata-server

这里下载的是Seata的`seata-server-1.5.2`版本。

### 5.2、解压修改配置

解压后的文件夹结构如下所示：

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/fa25ab1f6f95f7cd3b26c37ee39a2269.png?x-oss-process=image/resize,w_1400/format,webp)

**修改配置文件**

配置文件所在位置：

> seata—>conf目录—>application.yml文件

完整配置文件如下：

```yaml
server:
  port: 7091

spring:
  application:
    name: seata-server
# 日志配置
logging:
  config: classpath:logback-spring.xml
  file:
    path: ${user.home}/logs/seata
  # 不外接日志，故如下配置可暂不考虑
  extend:
    logstash-appender:
      destination: 127.0.0.1:4560
    kafka-appender:
      bootstrap-servers: 127.0.0.1:9092
      topic: logback_to_logstash
# 新增加的console控制台，
# 可通过访问http://localhost:7091进行登录，账号如下seata/seata
console:
  user:
    username: seata
    password: seata

seata:
  # Seata接入Nacos配置中心
  config:
    # support: file, nacos, consul, apollo, zk, etcd3
    type: nacos
    nacos:
      server-addr: 127.0.0.1:8848
      namespace: 0fff12f9-61ef-4c65-b48a-70150001c547
      group: SEATA_GROUP
      username: nacos
      password: nacos
      ##if use MSE Nacos with auth, mutex with username/password attribute
      #access-key: ""
      #secret-key: ""
  # Seata接入Nacos服务注册中心
  registry:
    # support: file, nacos, eureka, redis, zk, consul, etcd3, sofa
    type: nacos
    nacos:
      application: seata-server
      server-addr: 127.0.0.1:8848
      group: SEATA_GROUP
      namespace: 0fff12f9-61ef-4c65-b48a-70150001c547
      cluster: default
      username: nacos
      password: nacos

      ##if use MSE Nacos with auth, mutex with username/password attribute
      #access-key: ""
      #secret-key: ""
  # 此处可不必配置，由于接入了nacos配置，以下store相关配置可直接通过seataServer.properties进行配置
  # store:
    # support: file 、 db 、 redis
    # mode: db
#  server:
#    service-port: 8091 #If not configured, the default is '${server.port} + 1000'
  security:
    secretKey: SeataSecretKey0c382ef121d778043159209298fd40bf3850a017
    tokenValidityInMilliseconds: 1800000
    ignore:
      urls: /,/**/*.css,/**/*.js,/**/*.html,/**/*.map,/**/*.svg,/**/*.png,/**/*.ico,/console-fe/public/**,/api/v1/auth/login
```

注意：低版本的配置文件有两个，分别为`registry.conf`、`file.conf`两个文件。

比如：seata-server-1.4.2版本，关于以上两个文件的具体配置这里不再介绍。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/30e50a6b6a69deebf84c6b59d14a965a.png?x-oss-process=image/resize,w_1400/format,webp)

### 5.3、初始化数据库配置

新建数据库`test_seata`将seata解压目录`script\server\db`下面的mqsql.sql导入导入到test_seata中。

导入成功后，如下所示:

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/fc68eb79b4c6b763ecf0e13e8cc5c2f9.png?x-oss-process=image/resize,w_1400/format,webp)

### 5.4、Nacos配置中心添加配置

我们需要把Seata的一些配置上传到Nacos中，配置比较多，所以官方给我们提供了一个`config.txt`，我们下载并且修改其中参数，上传到Nacos中。

> 下载地址： https://github.com/seata/seata/tree/develop/script/config-center

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/533e32623560491c41ffd38251e78d5d.png?x-oss-process=image/resize,w_1400/format,webp)

主要修改以下的几处内容：

```plaintext
-- 修改1：配置事务分组
#Transaction routing rules configuration, only for the client
service.vgroupMapping.dev_xxkfz_group=default
#If you use a registry, you can ignore it
service.default.grouplist=127.0.0.1:8091

-- 修改2：配置存储模式为db、数据库连接信息（4.3中初始化的数据库）
store.mode=db
store.db.datasource=druid
store.db.dbType=mysql
store.db.driverClassName=com.mysql.jdbc.Driver
store.db.url=jdbc:mysql://127.0.0.1:3306/test_seata?useUnicode=true&rewriteBatchedStatements=true
store.db.user=xxkfz
store.db.password=xxkfz
```

注：事务分组：用于防护机房停电，来启用备用机房，或者异地机房，容错机制，当然如果Seata-Server配置了对应的事务分组，Client也需要配置相同的事务分组。

配置事务分组： service.vgroupMapping.dev_xxkfz_group=default
dev_xxkfz_group：需要与客户端保持一致 ，用户可以自定义。
default：需要跟客户端和`application.yml`中的`cluster`保持一致。

以上修改完成后，将config.txt文件放到seata目录下：

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/3d115b7980e2b6a1c8317b5243a81fe9.png?x-oss-process=image/resize,w_1400/format,webp)

此时我们需要把这些配置一个个的加入到Nacos配置中，所以我们需要一个脚本来进行执行，官方已经提供好了

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/b0064bfc841fb29961d6974744789de7.png?x-oss-process=image/resize,w_1400/format,webp)

将下载完成的nacos-config.sh脚本文件，同样放到seata目录下面。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/566aa35f1eca699dbbacc90c6c9f56a0.png?x-oss-process=image/resize,w_1400/format,webp)

执行脚本进行导入：

```bash
sh nacos-config.sh -h localhost -p 8848 -g SEATA_GROUP -t 命名空间 -u nacos -w nacos
```

参数说明：

-h：host，默认值localhost

-p：port，默认值8848

-g：配置分组，默认为SEATA_GROUP

-t：租户信息，对应Nacos的命名空间ID，默认为空

特此注意：

在执行naocs-config.sh文件脚本的时候，它默认寻找config.txt的路径和我们的路径不同，所以要打开naocs-config.sh文件进行修改，否则无法执行。

找到下方对应的位置，进行修改保存。

修改前：

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/81e375be99c26b12e0fd48bbfb5e85c6.png?x-oss-process=image/resize,w_1400/format,webp)

修改后：

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/b49b031001d41be4ff50c881d83fd836.png?x-oss-process=image/resize,w_1400/format,webp)

针对以上案例，小编这里执行的导入命令如下：

```bash
sh nacos-config.sh -h localhost -p 8848 -g SEATA_GROUP -t 0fff12f9-61ef-4c65-b48a-70150001c547 -u nacos -w nacos
```

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/2f02d7b096724e279b9679714297067c.png?x-oss-process=image/resize,w_1400/format,webp)

开始执行导入了：

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/d4484cadf04277006ba2e15312e665c5.png?x-oss-process=image/resize,w_1400/format,webp)

### 5.5、测试启动TC服务

经过以上配置完成以后，我们就可以启动nacos和seata-server了，此时我们查看Nacos的配置中心，就会看到我们传入的所有配置信息。

进入到bin目录，双击运行 `seata-server.bat`即可启动。

启动成功后，浏览器访问nacos地址 然后进入`服务列表`页面，可以看到seata-server服务已经注册到Nacos上。

导入的配置如下：

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/1e5203c7c15f23b079a51aade4fa8c95.png?x-oss-process=image/resize,w_1400/format,webp)

seata-server注册到nacos：

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/1c1944b17672bcf33f7874e2ef9bc10f.png?x-oss-process=image/resize,w_1400/format,webp)

## 六、项目集成Seata

### 6.1、业务背景

用户购买商品的业务逻辑——>整个业务逻辑由3个微服务提供支持：

- **仓储服务(storage-service)：** 对给定的商品扣除仓储数量。
- **订单服务(order-service)：** 根据采购需求创建订单。
- **帐户服务(account-service)：** 从用户帐户中扣除余额。

### 6.2、数据表创建

创建数据库`xxkfz_test` 执行以下脚本创建表。

- t_order：订单表
- t_storage：库存表
- t_account：账户表
- undo_log：undo_log表，用于数据的回滚

```sql
DROP TABLE IF EXISTS `t_order`;
CREATE TABLE `t_order` (
`id` bigint(11) NOT NULL AUTO_INCREMENT,
`user_id` bigint(20) DEFAULT NULL COMMENT '用户id',
`product_id` bigint(11) DEFAULT NULL COMMENT '产品id',
`count` int(11) DEFAULT NULL COMMENT '数量',
`money` decimal(11, 0) DEFAULT NULL COMMENT '金额',
`status` int(1) DEFAULT NULL COMMENT '订单状态: 0:创建中 1:已完结',
PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '订单表' ROW_FORMAT = Dynamic;


DROP TABLE IF EXISTS `t_storage`;
CREATE TABLE `t_storage` (
`id` bigint(11) NOT NULL AUTO_INCREMENT,
`product_id` bigint(11) DEFAULT NULL COMMENT '产品id',
`total` int(11) DEFAULT NULL COMMENT '总库存',
`used` int(11) DEFAULT NULL COMMENT '已用库存',
`residue` int(11) DEFAULT NULL COMMENT '剩余库存',
PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '库存' ROW_FORMAT = Dynamic;

INSERT INTO `t_storage` VALUES (1, 1, 100, 0, 100);


CREATE TABLE `t_account` (
`id` bigint(11) NOT NULL COMMENT 'id',
`user_id` bigint(11) DEFAULT NULL COMMENT '用户id',
`total` decimal(10, 0) DEFAULT NULL COMMENT '总额度',
`used` decimal(10, 0) DEFAULT NULL COMMENT '已用余额',
`residue` decimal(10, 0) DEFAULT NULL COMMENT '剩余可用额度',
PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '账户表' ROW_FORMAT = Dynamic;

INSERT INTO `t_account` VALUES (1, 1, 1000, 0, 1000);

-- Table structure for undo_log
-- 注意此处0.3.0+ 增加唯一索引 ux_undo_log
-- ----------------------------
DROP TABLE IF EXISTS `undo_log`;
CREATE TABLE `undo_log`
(
    `id`            bigint(20) NOT NULL AUTO_INCREMENT,
    `branch_id`     bigint(20) NOT NULL,
    `xid`           varchar(100) NOT NULL,
    `context`       varchar(128) NOT NULL,
    `rollback_info` longblob     NOT NULL,
    `log_status`    int(11) NOT NULL,
    `log_created`   datetime     NOT NULL,
    `log_modified`  datetime     NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `ux_undo_log` (`xid`,`branch_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
```

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/a1737271eb3b529e83c93a33e0301fea.png?x-oss-process=image/resize,w_1400/format,webp)

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/ac8a315aaaa38831c61b0214575b7b90.png?x-oss-process=image/resize,w_1400/format,webp)

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/3201b00393a7b4f2306741f13149f2b1.png?x-oss-process=image/resize,w_1400/format,webp)

### 6.3、搭建基本服务

#### 6.3.1、代码基本结构

代码基本工程涉及到三个微服务：

- 账户服务
- 库存服务
- 订单服务

代码基本结构如下：

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/dc05e1e5186aad9bf1d72b56aac52d1c.png?x-oss-process=image/resize,w_1400/format,webp)

#### 6.3.2、pom.xml引入依赖

```xml
        <dependency>
            <groupId>com.xxkfz.simplememory</groupId>
            <artifactId>xxkfz-service-common</artifactId>
            <version>1.0-SNAPSHOT</version>
        </dependency>
        <dependency>
            <groupId>javax.servlet</groupId>
            <artifactId>javax.servlet-api</artifactId>
        </dependency>
        <!-- seata -->
        <dependency>
            <groupId>com.alibaba.cloud</groupId>
            <artifactId>spring-cloud-starter-alibaba-seata</artifactId>
        </dependency>
        <dependency>
            <groupId>io.seata</groupId>
            <artifactId>seata-spring-boot-starter</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>com.alibaba.cloud</groupId>
            <artifactId>spring-cloud-starter-alibaba-nacos-discovery</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-bootstrap</artifactId>
        </dependency>
        <dependency>
            <groupId>com.alibaba.cloud</groupId>
            <artifactId>spring-cloud-starter-alibaba-nacos-config</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-loadbalancer</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-openfeign</artifactId>
            <version>3.1.3</version>
        </dependency>
        <!-- MySql连接驱动 -->
        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
        </dependency>
        <!-- Druid 连接池 -->
        <dependency>
            <groupId>com.alibaba</groupId>
            <artifactId>druid-spring-boot-starter</artifactId>
        </dependency>
         <!-- mybatis plus -->
        <dependency>
            <groupId>com.baomidou</groupId>
            <artifactId>mybatis-plus</artifactId>
        </dependency>
        <dependency>
            <groupId>com.baomidou</groupId>
            <artifactId>mybatis-plus-boot-starter</artifactId>
        </dependency>
         <!-- lombok -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
        </dependency>
```

#### 6.3.3、配置文件application.yml

注：下面配置文件为账户服务的配置，其他两个类似，这里不再展示。

> account-service ——> application.yml文件

```yaml
server:
  port: 8090

spring:
  application:
    name: account-service
  cloud:
    nacos:
      discovery:
        # 服务分组
        group: SEATA_GROUP
        server-addr: http://localhost:8848
        # 必须填命名空间的ID
        namespace: 0fff12f9-61ef-4c65-b48a-70150001c547
  datasource:
    type: com.alibaba.druid.pool.DruidDataSource  #当前数据源操作类型
    driver-class-name: com.mysql.jdbc.Driver
    url: jdbc:mysql://localhost:3306/xxkfz_test?allowMultiQueries=true&useUnicode=true&characterEncoding=UTF-8&useSSL=false #useSSL安全加固
    username: xxkfz
    password: xxkfz

# MyBatis Plus配置
mybatis-plus:
  # 配置mapper的扫描，找到所有的mapper.xml映射文件
  mapper-locations: classpath*:mapper/**/*.xml
  #实体扫描，多个package用逗号或者分号分隔
  typeAliasesPackage: com.xxkfz.simplememory.entity
  global-config:
    db-config:
      id-type: auto
  configuration:
    # 开启驼峰，开启后，只要数据库字段和对象属性名字母相同，无论中间加多少下划线都可以识别
    map-underscore-to-camel-case: true

# Seata 配置
seata:
  application-id: seata-server
  # 是否启用数据源bean的自动代理
  enable-auto-data-source-proxy: false
  tx-service-group: dev_xxkfz_group  # 必须和服务器配置一样  # 必须和服务器配置一样
  registry:
    type: nacos
    nacos:
      # Nacos 服务地址
      server-addr: http://localhost:8848
      group: SEATA_GROUP
      namespace: 0fff12f9-61ef-4c65-b48a-70150001c547
      application: seata-server # 必须和服务器配置一样
      username: nacos
      password: nacos
      cluster: default
  config:
    type: nacos
    nacos:
      server-addr: ${spring.cloud.nacos.discovery.server-addr}
      group: SEATA_GROUP
      namespace: 0fff12f9-61ef-4c65-b48a-70150001c547
  service:
    vgroup-mapping:
      tx-service-group: dev_xxkfz_group # 必须和服务器配置一样
    disable-global-transaction: false
  client:
    rm:
      # 是否上报成功状态
      report-success-enable: true
      # 重试次数
      report-retry-count: 5
```

#### 6.3.4、创建订单接口

> order-service ——> OrderController.java

```pgsql
@GetMapping("/order/create")
    public R<Order> createOrder(Order order) {
        orderService.create(order);
        return new R<>(200, "订单创建成功!", order);
}
```

处理逻辑

> order-service ——> OrderServiceImpl.java

```lasso
public void createOrder(Order order) {
    // 创建订单
    baseMapper.createOrder(order);

    // 库存扣减
    storageService.decrStorage(order.getProductId(), order.getCount());
    log.info("----->库存扣减Count完成");

    // 账户扣减
    accountService.decrAccount(order.getUserId(), order.getMoney());

}
```

#### 6.3.5、声明Feign接口

声明storage、account的Feign接口。

```java
@FeignClient(value = "storage-service")
public interface StorageService {

    /**
     * 扣减库存
     *
     * @param productId
     * @param count
     * @return
     */
    @PostMapping(value = "/storage/decrease")
    R decrStorage(@RequestParam("productId") Long productId, @RequestParam("count") Integer count);
}
@FeignClient(value = "account-service")
public interface AccountService {

    /**
     * 账户扣减
     *
     * @param userId
     * @param money
     * @return
     */
    @PostMapping(value = "/account/decrease")
    R decrAccount(@RequestParam("userId") Long userId, @RequestParam("money") BigDecimal money);
}
```

#### 6.3.6、测试验证

当前用户userId = 1 的账户为1000，库存100，模拟用户购买商品1个，消费100，业务调用后，数据库数据状态应该如下：

- 用户购买商品消费100，此时余额 = 1000 - 100 = 900
- 用户购买一个商品，此时商品余额 = 100 - 1 = 99

测试正常下单过程：

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/4ba0e870e8591f7a4c042cfb327f02ed.png?x-oss-process=image/resize,w_1400/format,webp)

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/cdf3c1d3548ac05e76a81262114d3d96.png?x-oss-process=image/resize,w_1400/format,webp)

### 6.4、使用Seata全局事务注解@GlobalTransactional

下面使用Seata全部事务注解@GlobalTransactional模拟异常，进行回滚操作。

模拟操作：

代码修改1：在创建订单createOrder方法上添加注解`@GlobalTransactional`。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/77f7892cc16eed258469756f71dcb491.png?x-oss-process=image/resize,w_1400/format,webp)

代码修改2：在账户服务中模拟异常。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/9f3705ab749c6d5f5d2c8dc7dee72e95.png?x-oss-process=image/resize,w_1400/format,webp)

### 6.5、配置数据源代理

由于Seata需要对数据源进行代理，以实现分布式事务的管理，我们需要对数据源进行配置。示例配置如下：

```java
@Configuration
public class DataSourceConfig {
    @Value("${mybatis-plus.mapper-locations}")
    private String mapperLocations;

    @Bean
    @ConfigurationProperties(prefix = "spring.datasource")
    public DataSource druidDataSource(){
        return new DruidDataSource();
    }

    @Bean
    @Primary
    public DataSourceProxy dataSourceProxy(DataSource dataSource) {
        return new DataSourceProxy(dataSource);
    }

    @Bean
    public SqlSessionFactory sqlSessionFactoryBean(DataSourceProxy dataSourceProxy) throws Exception {
        SqlSessionFactoryBean sqlSessionFactoryBean = new SqlSessionFactoryBean();
        sqlSessionFactoryBean.setDataSource(dataSourceProxy);
        sqlSessionFactoryBean.setMapperLocations(new PathMatchingResourcePatternResolver()
                .getResources(mapperLocations));
        sqlSessionFactoryBean.setTransactionFactory(new SpringManagedTransactionFactory());
        return sqlSessionFactoryBean.getObject();
    }
}
```

### 6.6、启动服务测试

分别重启三个服务，同时把数据库表数据恢复为原来的数据。

访问接口：

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/9ccdb02513f491c42e4f8543d373a921.png?x-oss-process=image/resize,w_1400/format,webp)

发现表数据无变化，全局事务回滚成功。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/082d45f96fc3a7fbec3441dafe813509.png?x-oss-process=image/resize,w_1400/format,webp)

**seata 控制台全局事务和分支事务回滚日志**

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/48b297738381d060efe82ff6e61edd3e.png?x-oss-process=image/resize,w_1400/format,webp)

**打断点调试查看seata 和 undo_log 数据的变化**

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/92c839b2872ab8340c37b76188399896.png?x-oss-process=image/resize,w_1400/format,webp)

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/bd47aa6a9771a50b1219fc885437f77d.png?x-oss-process=image/resize,w_1400/format,webp)

断点继续往下走，触发异常，，已插入的数据被回滚，且undo_log被清空，分布式事务回滚正常。

![img](https://ucc.alicdn.com/images/user-upload-01/img_convert/b552da73eb87783163eec71ce93451a9.png?x-oss-process=image/resize,w_1400/format,webp)

[学习seata](https://developer.aliyun.com/article/1460045)