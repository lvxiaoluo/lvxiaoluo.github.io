# MySQL主从复制问题总结及排查过程分享

# ◆ 一、概述

mysql主从是常用的高可用架构之一，也是使用最广泛的的系统架构。在生产环境中mysql主从复制有时会出现复制错误问题。**MySQL主从复制中的问题（Coordinator stopped beacause there were errors in the workers......）**

**
**

# ◆ 二、mysql主从复制原理

mysql主从复制是一个异步复制过程（总体感觉是实时同步的）,mysql主从复制整个过程是由三个线程完成。slave端有两个线程（SQL线程和IO线程），Master端有另一个（IO线程）。

**MYSQL主从复制过程**

- 在Slave服务器上执行start slave，开启主从复制开关。

- 此时，Slave 服务器上的 IO 线程通过 Master 服务器上授权复制用户的请求连接到 Master 服务器。它还请求从 binlog 日志文件的指定位置发送 binlog 日志内容。（配置主从复制任务时执行change master命令时指定日志文件名和位置）

- Master服务器收到Slave服务器IO线程的请求后，Master服务器上的IO线程是基于Slave的。服务器的IO线程请求的信息在指定binlog日志文件的指定位置后读取binlog日志信息，然后返回给Slave端IO线程。除了binlog日志内容，在日志内容返回后Master服务器端还有一个新的binlog。binlog 中的文件名和下一个指定的更新位置。

- 当 Slave 服务器的 IO 线程从 Master 服务器获取 IO 线程发送的日志内容、日志文件和位置点时，添加 binlog。日志内容依次写入Slave端自身的relay log文件（mysql-relay-bin.xxxxxx）的末尾。并将新的binlog文件名和位置记录到master-info文件中，以便下次读取Master端新的binlog日志时，可以告诉Master服务器从新的binlog日志中从哪个文件以及从哪里开始请求新的binlog日志内容.

- Slave server端的SQL线程实时检测本地relay log中新增的日志内容，及时relay log。该文件的内容被解析成在Master端执行的SQL语句的内容，在Slave服务器本身按照语句的顺序执行SQL的应用。

- 经过上述过程，可以保证在Master和Slave端执行相同的SQL语句。当复制状态正常时，Master 端和lave端的数据是完全一致的。

  

![图片](https://mmbiz.qpic.cn/mmbiz_png/RQueXibgo0KNhQ5MPF1s79TFXwEkt1zDh1ckoaUfvuWFVTn6SmXSwCqbCH3PvWtIN2NqX1PDM9h8daicHWogRB7g/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)