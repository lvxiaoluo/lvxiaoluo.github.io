# 面试问Redis集群，被虐的不行了......



本篇我将讲解 Redis 集群的工作原理，文末有你们想要的设置 SSH 背景哦！



# 本文主要围绕如下几个方面介绍集群：

- **集群简介**
- **集群作用**
- **配置集群**
- **手动、自动故障转移**
- **故障转移原理**



# 本文实现环境：

- **CentOS 7.3**
- **Redis 4.0**
- **Redis 工作目录 /usr/local/redis**
- **所有操作均在虚拟机模拟进行**

#  

集群简介



集群是为了解决主从复制中单机内存上限和并发问题，假如你现在的云服务内存为 256GB，当达到这个内存时 Redis 就没办法再提供服务。



同时数据量能达到这个地步写数据量也会很大，容易造成缓冲区溢出，造成从节点无限的进行全量复制导致主从无法正常工作。

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7Ld87d5tocUVs7E4TfviahtBkdZkwibqANzz3OFdG9plusYdMpoiaJDMefRA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

那么我们就需要把单机的主从改为多对多的方式，并且所有的主节点都会连接在一起互相通信。



这样的方式既可以分担单机内存，也可以分发请求，提高系统的可用性。



如下图：当有大量请求写入时，不再会单一的向一个主节点发送指令，而会把指令进行分流到各个主节点，达到分担内存、避免大量请求的作用。

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7Ldxhev4rnD65VzpMEFB7rMicEia3xibt1ibCLMl6CpbbUDQby9CXrxWBkmrA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

那么指令是如何进行分流存储的呢？我们就需要到集群存储结构中一探究竟。



集群作用



集群的作用有如下几个：

- **分散单机的存储能力，同时也可以很方便的实现扩展。**
- **分流单机的访问请求。**
- **提高系统的可用性。**



如何理解提高系统的可用性这句话，我们看下图，当 master1 宕机后对系统的影响不会那么大，仍然可以提供正常的服务。

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7Ld0miahG0gtMqxZBrebZyLVld2b3kqmhb4ODkkbickv9frGpwnfw5OINbA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

这个时候就会有人问了，当 master1 宕机后，集群这个时候怎么工作呀？这个问题会在下文的故障转移来给你解答，并且在原理篇会对这个问题进行详解。



集群存储结构





**存储结构**



单机的存储是当用户发起请求后直接把 key 存储到自己的内存即可。 

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdakgDhFynBCMlFo1dxOCSfD25zcSwztywQNxSk9eTibzYDXwibAlGIYQw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

集群的存储结构就没有那么简单了，首先当用户发起一个 key 指令后需要做的事情如下：

- 通过 CRC16(key) 会计算出来一个值。
- 用这个值取模 16384，会得到一个值，我们就先认为是 28。
- 这个值 28 就是 key 保存的空间位置。



那么现在问题来了，这个 key 到底应该存储在哪个 Redis 存储空间里边呢？

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdXwAbIc4Y6vJL6CAKUgn72T8icWagHaKYQgDGGG7hFHmbGyZoYO44ycg/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

其实 Redis 在集群启动后就已经把存储空间划分了 16384 份，每台主机保存一部分。



这里需要注意的是我给每个 Redis 存储空间里边的编号就相当于一个小的存储空间（专业术语“哈希槽”）。



你可以理解为一栋楼里边的编号，一栋楼就是 Redis 的整个存储空间，每个房子的编号就相当于一个存储空间，这个存储空间会有一定的区域来保存对应的 key，并非上图取模后的位置。



箭头指向的 28 是指的 28 会存储在这个区域里，这个房子有可能会存储 29、30、31 等。

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdbkuIxEia7pESBEj1ibpTZd08Z27pXwQE7juJAh0ybsHnyfUqID0YMcLA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

此时问题来了，如果新增、减少一台机器后怎么办呢？看图说话，能用图说明尽量不去用文字。



在新增一台机器后，会从其他三个存储空间中拿出一定的槽分配给新的机器。这里可以自己设置想给新的机器放多少个槽。



同样减少一台机器后会把去掉的槽在重新分配给其它现有的机器跟新增节点一样，可以指定节点接收槽。



所谓的增节点或去节点就是改变槽所存储的位置不同。

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdoFf54BmLlKXdc1Y77ChoyPic2ScSKQbz4qQr55hJ8nM5JGYCPiaY0bPA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

了解了集群的存储结构后，我们就需要在对另一个问题进行说明了，集群是如何设计内部通讯呢？



来了一个值，获取一个 key，去哪拿数据？跟着这个问题我们看下文。





**通讯设计**



集群中的每个节点会在一定的时期给其它节点发送 ping 消息，其他节点返回 pong 作为响应。



经过一段时间后所有节点都会知道集群全部节点的槽信息。如下图有三个节点，那么就会把 16384 个哈希槽分成三份。



分别为：

- **0-5500**
- **5501-11000**
- **11001-16384**

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)

当用户发起了一个 key 的请求，集群是如何处理请求的呢？上图的黑框代表这集群所有节点的槽信息，里边还有很多其它信息。 



如图所示，用户发起请求 key，Redis 接收后计算 key 的槽位置，在根据槽位置找出对应的节点。



如果访问的槽就在节点本身，那么就会直接返回 key 对应数据。否则会回复 moved 重定向错误，并且给客户端返回正确的节点。



然后重发 key 指令，如下图：

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdJm1lzFQKEiblwpLsKwCHFlpLJ0RT0NvEq6gz7K2AicOJqRk5qlhAeVXQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

配置集群



## **①修改配置文件**

##  

## 如下图：

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdpgFnKv05bjBuQKlctB8XmgnjibsyalCUhTlCwpJCxs8fHgDBjn7OCqg/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

只需要注意圈中的配置信息即可：

- **cluster-enabled yes：**开启集群模式。
- **cluster-config-file nodes-6379.conf：**集群配置文件。
- **clustre-node-timeout 10000：**节点超时时间，这里为了方便测试设置为 10s。

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdXNnngAY2Biamv5dRn2zTLGeGFysEUwAA2cdZEhVl0xdK2fRgtyWMfVw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

## **②构建 6 个节点的配置文件并全启动**



给大家提供一个命令可以很方便的替换文件：

```
sed 's/6379/6380/g' 6379-redis.conf > 6380-redis.conf
```



按照这样的方式创建出来 6 个不同端口的配置文件：

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7Ldw3I2P0EuREruwURFneYfutJsmjwGeUBEMEMZQgPQqicQHxcqgz8iaZAw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

随便打开一个配置文件查看，检测是否替换成功：

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdGgdcDSEicJ444VWPvzE3Ta3WaFrYXA3XzkNPpoq6dMLT3JNaWb7p0TA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

为了查看日志信息方便，全部使用前台启动。并且查看服务是否都正常启动，执行命令：

```
ps -ef | grep redis
```



可以看到启动后多了个 cluster 标识，代表着都是集群的一个节点。

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)

所有节点启动完成，集群启动的指令需要基于 Ruby（本人使用 Redis 版本为 4.0），接下来一起安装。



## **③安装 Ruby**



执行命令：

```
wget https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.1.tar.gz
```



解压（根据自己下载的版本来解压）：

```
tar -xvzf ruby-2.7.1.tar.gz
```



安装：

```
./configure | make | make install
```



这三个指令一气呵成，查看 ruby 和 gem 版本：ruby -v。

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)

## **④启动集群**



集群的执行命令在 /usr/local/redis/src/redis-trib.rb，注意如果需要直接使用 redis-trib.rb 命令，需要 ln 到 bin 目录下，否则就必须使用 ./redis-trib.rb 的方式。



如果按照步骤走，这里会出现一个错误，如下图：

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdF2Kx3gOKDhIddlRoDYW5wJ2pjxibETOS79UsC6M02gvcRRf5nKGzIgw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

执行 gem install redis，很不幸的是在这里也会出现错误：

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdGAd58rqc8IUuQn45fyqhfT4x5fTv7SL01Lx1diclIadAj5uzeA2hianA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

随后需要安装 yum install zlib-devel 和 yum install openssl-devel。



安装完成后，在 /ruby-2.7.1/ext/openssl 和 /ruby-2.7.1/ext/zlib 分别执行 ruby extconf.rb，并且执行 make | make install。



然后再执行 gem install redis 就 OK：

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdnIwXnSATAyRIvWianq59uE2HY57oWrfT3YjPNDXpsNOUJMJffff7Zsg/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

这时再回头来执行：

```
./redis-trib.rb create --replicas 1 127.0.0.1:6379 127.0.0.1:6380 127.0.0.1:6381 127.0.0.1:6382 127.0.0.1:6383 127.0.0.1:6384
```



![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdNeQmIaN5YYhSb8ZrCZFibAicib75hg5lgZBniaGNZsm8u4U4vutrmica3eg/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

**信息解读：**创建集群，并且给 6 个节点分配哈希槽，后三个节点配置为前三个节点的从节点。

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdIszpXb8Edx2V0EXZVBibMo1qKKrQptAh5icHMunenZicAzzom6ZMcTqNw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

显示每个节点的哈希槽信息和节点 ID，最后一步需要输入 yes：

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)

来到 data 目录下查看配置文件的变化。配置文件主要信息是每个主节点分的槽：

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdxUHNxteq10sI01ABSiccy0Abg1ictFCiclu781Ccl9tnk6iafcqCwhpxiaw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdbfrhwAR2MqWQa2Om90A6VtswS7DbteNcpJoHDsYdQxn2E6sp1Qx7lQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

**查看主机点的运行日志：**这里给的主要信息 cluster status changed:ok 集群状态正常。

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdVEFgM9QGhptJ0Y3BPOxicQ0FWgMFTOoPQCeOetFtNpbNfkLRBd3FgnA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

## **⑤集群设置与获取数据**



当直接设置数据会报错，并且把 name 这个 key 进行转化后的槽位置为 5798 并且给出了 ip 地址和端口号。 

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7Ldmn43S1a3L54dbmVOmFb8XGOlDuvYTyujQ9kkeEJLqZZ1jnnkJsfQTg/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

需要使用命令 redis-cli -c，在进行设置值的时候提示说重定向到 5798 的这个槽。

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7Ld7HvAnhHRPzlQ9Mk6clCcpqEYPia1LqEYezZgzXKVhYfBFd4mexOEtmg/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

接下来进行获取数据，会自动的切换节点：

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7Ld0ibP4S1Fj9jFT17QHcEG7MNQ1APFSoDYOOkAnRI1JAmWicN8CIl9OySQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

故障转移



## **①集群从节点下线**



根据上文集群启动信息知道端口 6383 是 6379 的从节点。接下来就是让 6383 下线查看 6379 的日志信息。



6379 会报出连接 6383 丢失，并且给上标记 fail，表示不可用。这个时候集群还是正常工作的。



**总结：**从节点下线对集群没有影响。

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdsharyNicDYTdz33wMS7D4GAI5tyicfx4q55KG2HjAq1u2sVwRCGWQKsQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

当端口 6383 上线后，所有的节点会把 fail 的标记清除，如下图：

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdGFdnEQ2Iy7fOMxXD0bOX2FzDmeyWzuSeaK9FVibQulQ3m96ibAetCOyA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

## **②集群主节点下线**



手动下线主节点 6379，查看从节点 6383 日志信息，此时的 6383 节点会持续连接 6379 共计 10 次，那为什么是 10 次呢？



是根据我们配置的参数 cluster-node-timeout 10 来决定的，这里给我们一个信息就是一秒连接一次。



直到时间到期后，开始故障转移。这时 6383 在故障转移选举中胜任，翻身奴隶把歌唱，成为了主节点。

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7Ld5FSQ6kGRBjYoyTyAHeOUX9sZYC7I8YFRaXYVBe3ZyaiaLuibeAMVrD7Q/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

此时在查看一下集群的节点信息，命令 cluster nodes。会发现这里竟然存在四个主节点，但是其中一个主节点时下线状态：

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdkTZlbG3OuI1X541b6xQd0MbsyibrycvMYJXwlYMCW5Egic7VBka82sVA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

**6379 原主节点上线：**6379 上线后，同样所有的节点也会清除 fail 信息。并且节点信息也会改变，此时的 6379 改变为 6383 的从节点。

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LduriaF3UZCXhvR9dibibCCIctdaaHxGufS1OcsoG5vehbiaW5l4ticEkUc9Q/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

## **③新增主节点**



再新增俩个端口 6385 和 6386：

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdicI0n2PWsvDWYw0O96XLJD49BoYo6icIYP4NVe0VshAW6A4QjTdYZhuw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

执行新增命令 ./redis-trib.rb add-node 127.0.0.1:6385 127.0.0.1:6379，这里发送的就是 meet 消息。



执行 add-node 命令，第一个参数为新节点的 ip+端口，第二个参数为已存在集群中的节点。根据下图我们就可以看到新增的节点已经存在集群中了。



注意：虽说 6385 已经成为集群中的节点了，但是跟其它节点有区别。它没有数据，也就是没有哈希槽。

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7Ld5GqLibBiaLb9B3HIMBW88iaAMS22ffJULRkosmSgM1KSlrYcgpnjTYxhA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

接下来我们就需要把集群中的某些哈希槽分配到这个新节点上，分配结束后这个节点才会成为真正意义上的主节点。



执行命令 ./redis-trib.rb reshard 127.0.0.1:6385，会提示转移多少个哈希槽并填写接收节点的 id。



最后一步询问是否从所有节点中转移：我使用的是 all。使用指令：cluster nodes 查看，6385 的这个节点就已经拥有三个范围的哈希槽了。

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdNwqjmBrvWyRbDicNqibITO96MqIlcftC6w4ARzIWibx4RqicMWFrM9qNUQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

主节点已经新增好了，接下来就需要给 6385 这个主节点配置一个从节点 6386，命令如下：

```
./redis-trib.rb add-node --slave --master-id dcc0ec4d0c932ac5c35ae76af4f9c5d27a422d9f 127.0.0.1:6386 127.0.0.1:6385
```



master-id 是 6385 的 id，第一个参数为新节点的 ip+端口，第二个为指定的主节点 ip+端口。

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdWHXhgvHriaFrH2fC0106v7ofmhLepiaJBCUyVDDmzZicHdgnQan9sjSkQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

## **④手动故障迁移**



当想对集群中的主节点进行升级的话可以手动执行故障转移到从节点，避免集群可用性受影响。



**在从节点执行命令：**cluster failover。



**执行过程：**查看节点信息就可以看到 6386 这个节点已经成为了主机点。



当给从节点发送 cluster failover 指令后，从节点会给主节点发送 CLUSTERMSG_TYPE_MFSTART 包。从节点请求主节点停止访问，从而对比两者的数据偏移量达到一致。



这时客户端不会连接我们淘汰的主节点，同时主节点向从节点发送复制偏移量，从节点得到复制偏移量后故障转移开始，接着通知主节点进行配置切换。



当客户端在旧的 master 上解锁后，重新连接到新的主节点上。 

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LddcW9qsMwLaQ5wWyrWKTHD6KR2YcUBs0D6OqADzUsstu4SFiaV8PatXg/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

故障转移原理篇



上文中我们测试了故障转移，主节点下线后从节点变为主节点，接下来剖析这个过程。



## **①故障发现到确认**



集群中的每个节点会定期的给其它节点发送 ping 消息，接收方用 pong 作为回复。



如果在 cluster-node-timeout 的时间内 ping 消息一直失败，则会把接收方的节点标记为 pfail 状态也就是主观下线。



这个下线状态是不是很熟悉？没错，这个跟哨兵判断主节点是否异常有点相似。



当一个哨兵发现主节点有问题时也会标记主节点客观下线(s_down)。突然发现跑题了，尴尬......

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdjMGEmukdYCKmxCyV7ibKic5xkQ7WFFLnA3anCGwCMRpzbNH4yzzsRliaQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

再提一下哨兵，当一个哨兵认为主节点异常后标记主观下线，但是其他哨兵怎么能会同意，不能你说什么就是什么。



都会去尝试连接异常的主节点，当半数以上的哨兵都认为主节点异常后会直接让其主节点客观下线。



同样集群也不会因为一个节点判断其状态为下线就行的，节点直接通过 Gossip 消息传播，集群中节点会不断收集故障节点的下线反馈并且存储到本地的故障节点下线报告中。



当有半数以上的集群主节点都标记为主观下线后改变状态为客观下线。最后向集群广播一条 fail 消息，通知所有节点将故障节点标记为客观下线。



例如：节点 A 发送 ping 到节点 B 通信异常后标记节点 B 为 pfail，之后节点 A 会继续给节点 C 发送 ping，并且携带节点 B 的 pfail 信息，然后节点 C 将节点 B 的故障保存到下线报告中。



当下线报告数量大于有哈希槽主节点的一半数量以上后就会尝试客观下线。



## **②故障恢复（从节点从此翻身奴隶把歌唱）**



当故障节点被定义为客观下线后，故障节点的所有从节点承担故障恢复的责任。



故障恢复是从节点通过定时任务发现自己的主机点客观下线后就会执行故障恢复流程。



**资格检查：**所有的从节点都会进行检查与主节点最后的连接时间，断线时间大于 cluster-node-time*cluster-slave-validity-factor 时不具备故障转移的资格。



**准备选举时间：**先说说为什么这里会有一个准备选举时间。资格检查过后存在多个从节点，那么就需要使用不同的延迟选举时间来支持优先级。



这里的优先级就是以复制偏移量为基准，偏移量越大与故障主节点的延迟越小，那么就更有机会拥有替换主节点的机会。主要的作用就是确保数据一致性最好的节点优先发起选举。



**选举投票：**Redis 集群的投票机制没有采用从节点进行领导选举，这点切记不要跟哨兵搞混了。集群的投票机制都是持有槽的主机点进行投票的。



故障节点的从节点会广播一个 FAILOVER_AUTH_REQUEST 数据包给所有的持有槽的主节点请求投票。



当主节点回复 FAILOVER_AUTH_ACK 投票后在 NODE_TIMEOUT * 2 的这段时间不能给其他的从节点投票。从节点获取到半数以上的投票后就会进行故障恢复阶段。



**故障转移：**选举成功的从节点取消复制变为主节点，删除故障节点的槽，并且将故障节点的槽委托到自己身上，向集群广播自己的 pong 消息，通知主机点的改变和接管了故障节点的槽信息。



福利：你们想要的 SSH 的背景



上一篇利用两个夜晚才弄完的 Redis 哨兵文章，结果你们的关注点却不在文章本身，啊！小编心很痛......



为了满足大家的要求，我忍痛说一下如何设置亮瞎的背景，我使用的工具是xsheel。

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdAwyLAOicGLWLhDoDnyXnD2zgOQeA6Vwo0R0lC410fKOL55qBSMtFSSg/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

打开工具选择选项 ：

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7Ld2XRNwfo9ibBhXdpDGOhGOH0VgJiagglIEaibs9rsicbFMz0BtZ1pb4kutw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

接着到查看有个窗口透明就可以设置 xsheel 透明了。 

![图片](https://mmbiz.qpic.cn/mmbiz_png/MOwlO0INfQpNR5RETFNDrnfthqwtv7LdUib4b2tdKfskSdS8f5Pqq25IVPk9gBT3hGUUl0Raz0OXWLx0TfwIvzw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

对喽！你想的没错，这就是桌面背景，是不是准备开始设置去了？最后，欢迎各路大神给予技术点补充和辨错。