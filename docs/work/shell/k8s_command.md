
### 1. 常用命令
```
kubectl get pod -n namespace 查看pod列表
kubectl get ns 查看当前集群下所有命名空间（即所有的测试环境列表）
kubectl describe po xxx -n namespace 查看指定pod详情
kubectl get svc -n namespace 查看service列表（主要看工程对外暴露的端口号）
kubectl get ing -n namespace 查看ingress列表（主要看工程对外暴露域名）
kubectl describe xxx -n namespace 查看指定资源详情
kubectl exec -it xxx bash -n namespace 进入pod容器
kubectl logs -f xxx -n namespace 查看pod日志
kubectl delete pod xxx -n namespace --grace-period=0 强制删除pod（实现应用重启效果）
kubectl get pod -o wide --all-namespaces | grep  根据IP地址查询Pod
其中"xxx" 表示某一个pod的名称，“namespace” 表示某一个环境 如test1,test2...
```


### 2.线下k8s文件下载
```
kubectl cp test/quark-main-service-8c8974756-kpf97:/tmp/logs/service-biz-20230824_3.tar.gz /Users/***/Downloads/service-biz-20230824_3.tar.gz
kubectl cp test/quark-main-service-8c8974756-kpf97:/tmp/logs/service-biz-standard-20230824_3.tar.gz /Users/***/Downloads/service-biz-standard-20230824_3.tar.gz
```



### 3.查看端口占用
```
lsof -i:


```
> 该命令会列出当前系统中所有正在运行的进程，并通过内存使用量进行降序排序，然后显示前5个进程。

```
ps aux | sort -k4nr | head -n 5
```



### 4.日志查询
1. 查询2022-06-22 18:00 到 2022-06-22 18:10之间的日志
```
sed -n '/2022-06-22 18:00/,/2022-06-22 18:10/p' cm.log
```
> 打印行号
>
> awk '/2023-08-22 19:55/,/2023-08-22 19:56/ {print NR " " $0}' service-biz.log.2023-08-22


2. 查询2021-10-18 08:10 和 2021-10-18 08:13 两个时间点的日志，这里用到正则 | 表示或的意思，注意|为特殊字符需要转义 \|
```
sed -n '/2021-10-18 08:10|2021-10-18 08:13/p' crm.log
```
3. - 查询2021-10-18 08:13这个时间点的日志
```
sed -n '/2021-10-18 08:13/p' crm.log
```

4. - 查询2021-10-18 08:13这个时间点并且包含 task3 的日志，这里用到正则 .* 表示任意字符有0个或多个
```
sed -n '/2021-10-18 08:13.*task3/p' crm.log
```
> 这里还有一种方式  {/task3/p}  将前面一个命令的结果，再做一次子查询筛选
```
sed -n '/2021-10-18 08:13/ {/task3/p}' app.log
````

5. - 按行号查看 ——-- 过滤出关键字附近的日志
```
1. cat -n test.log |grep "debug" 得到关键日志的行号
2. cat -n test.log |tail -n +92|head -n 28 查看92号，到92+28范围内的日志
tail -n +92表示查询92行之后的日志
head -n 28 则表示在前面的查询结果里再查前28条记录

3. - cat 日志文件 | grep -B10 -A18 "关键字"
- B - before A - after 检索日志，并显示该日志的前后(N (10) 行记录
- 从3000行开始，显示1000行，即显示3000-3999行

- cat filename | tail -n +3000 | head -n 1000
4. 显示1000行到3000行
- cat filename | head -n 3000 | tail -n +1000
5. 将文件关键字第一次出现的输出 | head -1 > log.txt
- grep "47083000013.X02" service-biz.log.txt
6. 查询关键字error出现的次数 -i 忽略大小写
- cat -n jstack.log |grep -ci "error"
7. 获取“duration”后面数字大于100的前10条
- grep -E -m10 "duration":[1-9][0-9]{2,}" quark-biz.log.3.2024-01-17
8. LESS命令
- N/N下一个匹配项

```
### 5. idea快捷键
- 复制包的全路径 Shift+option+command + C
### 6. Redis
```
./redis-cli -h rediscjcmctest.redis.rds.aliyuncs.com -p 6379 -a k08sgk0p40fLteInf -n 1 keys "*" | xargs
./redis-cli -h rediscjcmctest.redis.rds.aliyuncs.com -p 6379 -a k08sgk0p40fLteInf -n 1 del
```
> -h ip地址
> -p 端口
> -a pwd：认证，需填入redis密钥
> -n 2:指定库 “2”，相当于 select 2
>  keys 'user*' : 找到前缀为"user"的数据
> |xargs 等等：删除上文找到的前缀为“user"的数据
> 不存在key前缀为”user“ 的数据时，执行报 error


### 7. Linux下进程号查看和pid查看端口号

```
netstat -anp | grep pid
```
> 搜索名称后缀为 .xml 文件中包含 DB_URL 的文件信息
```

find . -name *.xml | xargs grep 'DB_URL'

find . -name '*.conf' -exec grep 'crm' {} +

find . -name '*.conf' -exec grep 'qianwen' {} +
```

> 查找文件大于100M
```
find / -type f -size +100M
```
清空某个文件
> 文件名

### 8.CPU高
- top
- top -Hp pid 或 ps -T -p 17038 -o pid,tid,%cpu,cmd
- printf "0x%x\n" tid
- jstack pid >> stack.log


2. JVM内存快照
- jmap -dump:format=b,file=应用.hprof pid
- tar -zcvf 应用日期.tar.gz 应用.hprof
- Zip -vr 压缩文件名.zip 被压缩文件
- scp -v ***@fort.test.com:/***.***.252.77/opt/wzapp/install/weaver/ecology/log/应用日期.tar.gz /User/***/Downloads/o28280519.tar.gz


3. linux指令
- 清空文件内容
- truncate -s 0 /path/to/file
- Linux内存消耗前十查看
- ps aux --sort=-%mem | head -n 11 | tail -n 10
- pmap -X -pid将从操作系统的角度显示RSS的详细分类。
- 描述
- USER：运行该进程的用户的用户名。
- PID：进程ID。
- %CPU：该进程使用的CPU使用量的百分比。
- %MEM：该进程使用的物理内存的百分比。
- VSZ：Virtual Size，该进程使用的虚拟内存量（KB）。
- RSS：Resident Set Size，该进程使用的非交换出去的物理内存量（KB）。
- STAT：进程的状态。其中常见的有：
- R：运行
- S：睡眠
- T：停止状态
- Z：僵尸状态
- START：该进程启动的时间。
- TIME：CPU时间，即该进程占用的总CPU时间。
- COMMAND：启动进程的命令行命令。


### 9.Sublime text
```
findAll shift+command + <
```


```sql
UPDATE wmdm_serial_number wsn 
INNER JOIN winv_stock_serial wss ON wsn.serial_number = wss.serial_number 
SET wsn.batch_id = wss.batch_id, wsn.batch_code = wss.batch_code 
WHERE wsn.batch_id IS NULL; 
```

### 10.Redis
- /Users/***/applicationTools/toolApp/redis-stack-server-6.2.6-v3.catalina_x86_64/bin
- redis-cli -h bfd2f146e8ad4ile.m.cnbja.kvstore.aliyuncs.com -p 6379 -a EdplJ5VY

### 11.Create a new repository
- git clone git@code.test.com:sd-shared/quark-authcap-api.git
- cd quark-authcap-api
- touch README.md
- git add README.md
- git commit -m "add README"
- git push -u origin master


### 12. Existing folder or Git repository
- cd existing_folder
- git init
- git remote add origin git@code.test.com:sd-shared/quark-authcap-api.git
- git add .
- git commit
- git push -u origin master


### 13. Idea 目录
- /Users/***/Library/Application Support/JetBrains/IntelliJIdea2021.2/idea.vmoptions



### 14. OA 发布
- 本次发布文件
> /opt/wzapp/install/weaver/ecology/classbean/com/node/action/ApprovaMiddleWithDataActionV2.class
- /opt/wzapp/install/weaver/ecology/classbean/com/node/cron/SaleContractSubmitCron.class
- 备份文件部分
- cp /opt/wzapp/install/weaver/ecology/classbean/com/node/cron/SaleContractSubmitCron.class /opt/wzapp/install/weaver/oaBakFile/classbean/com/node/cron/SaleContractSubmitCron-class-0207
- /opt/wzapp/install/weaver/ecology/ologinrsm/js
- 发布文件准备
- scp -v /Users/xuyihang/data/publish/SaleContractSubmitCron.class ***@fort.test.com:/***.***.252.77/root/tmp/SaleContractSubmitCron.class
- scp -v /Users/xuyihang/data/publish/SaleContractSubmitCron.class ***@fort.test.com:/172.16.***.**/root/
- scp -v ***@fort.test.com:/***.***.252.77/root/wzapp/install/weaver/ecology/interface/alitrip/optAlitripOrderListAjax.jsp ~/data
- 停机
- sh resinstop.sh

1. 发布文件复制
- sudo cp /tmp/SaleContractSubmitCron.class /opt/wzapp/install/weaver/ecology/classbean/com/node/cron/SaleContractSubmitCron.class
- 启动
- sh resinstart.sh
- scp -v ~/data/upload/CommonSubmitCron.class ***@fort.test.com:/172.16.***.**/root/usr/weaver/ecology/classbean/com/node/cron/CommonSubmitCron.class
- scp -v ~/data/publish/submitPurchase.png ***@fort.test.com:/***.***.252.77/root/tmp/submitPurchase.png
- scp -v ~/data/publish/businessFrame.png ***@fort.test.com:/***.***.252.77/root/tmp/businessFrame.png
- scp -v ~/data/publish/supplier_query.png ***@fort.test.com:/***.***.252.77/root/tmp/supplier_query.png
- cp /tmp/submitPurchase.png /opt/wzapp/install/weaver/ecology/ologinrsm/submitPurchase0327.png
- cp /tmp/businessFrame.png /opt/wzapp/install/weaver/ecology/ologinrsm/businessFrame0327.png
- cp /tmp/supplier_query.png /opt/wzapp/install/weaver/ecology/ologinrsm/supplier_query0327.png



### 15.linux 内存查看
1. 确定到底是哪个进程占用内存
ps aux --sort=-%mem

2.堆外内存到底占用多少？
- jcmd pid GC.heap_info


### 16. Dify
- 官方文档：https://docs.dify.ai/zh-hans/getting-started/install-self-hosted/docker-compose
- 数据存储目录：/home/admin/volumes_dify/volumes
- 应用启动目录：使用[root用户]：docker compose -f docker-compose.yaml up -d

- 直接改的docker-compose.yaml（目录 /home/admin/dify/docker）
- 升级是这样的
1. - 拉最新版本镜像：api/web 使用[admin 用户] 上传到 /home/admin/dify_images目录
2. - 修改docker-compose.yml里的版本号
3. - 重启
- docker compose -f docker-compose.yaml up -d
- docker compose -f docker-compose.yaml up -d
4. - 停止docker compose down


- 错误信息
- 2024-11-28 13:32:30 Error: Database is uninitialized and superuser password is not specified. 2024-11-28 13:32:30 You must specify POSTGRES_PASSWORD to a non - empty value for 2024-11-28 13:32:30 superuser. For example, “-e POSTGRES_PASSWORD=password” on “docker run”. 2024-11-28 13:32:30 2024-11-28 13:32:30 You may also use “POSTGRES_HOST_AUTH_METHOD=trust” to allow all 2024-11-28 13:32:30 connections without a password. This is not recommended. 2024-11-28 13:32:30 See PostgreSQL documentation about “trust”: https://www.postgresql.org/docs/current/auth-trust.html
- 运行镜像时：添加参数 POSTGRES_PASSWORD=mysecretpassword

本地启动

- 路径：/Users/***/applicationTools/workApp/ideaworkSpaces/github/dify
- 拉取最新代码：
- cd /Users/***/applicationTools/workApp/ideaworkSpaces/github/dify/docker
- 启动与停止命令：
- 启动：docker compose up -d
- 停止：docker compose down
- 访问地址：http://localhost/apps



### 17.docker 查看镜像信息

- 命令：docker images -a

查看正在运行的容器

- 命令：docker ps -a

镜像保存为tar文件

1. docker save -o /Users/***/Downloads/dify - web.tar langgenius/dify - api:0.11.1
2. docker save -o /Users/***/Downloads/dify - web - 0.15.0.tar langgenius/dify - web:0.15.0
3. docker save -o /Users/***/Downloads/dify - api - 0.15.0.tar langgenius/dify - api:0.15.0
4. docker save -o /Users/***/Downloads/dify - web - 0.15.3.tar langgenius/dify - web:0.15.3
5. docker save -o /Users/***/Downloads/dify - api - 0.15.3.tar langgenius/dify - api:0.15.3

传输tar文件到目标服务器

- 命令：scp /home/user/my_image.tar user@remote - server:/home/user/

在目标服务器上加载tar文件导入docker镜像

- 命令：docker load -i <镜像文件名>.tar

手动拉取对应tag镜像

- 链接：https://hub.docker.com/r/langgenius/dify - web/tags?name=0.15.2

解决“com.docker.vmnetd”将对你的电脑造成伤害的问题

1. 停掉Docker服务
- 命令：sudo pkill '[dD]ocker'
2. 停掉vmnetd服务
- 命令：sudo launchctl bootout system /Library/LaunchDaemons/com.docker.vmnetd.plist
3. 停掉socket服务
- 命令：sudo launchctl bootout system /Library/LaunchDaemons/com.docker.socket.plist
4. 删除vmnetd文件
- 命令：sudo rm -f /Library/PrivilegedHelperTools/com.docker.vmnetd
5. 删除socket文件
- 命令：sudo rm -f /Library/PrivilegedHelperTools/com.docker.socket


要查看iptables 的所有配置，可以使用以下命令：
sudo iptables -L -v -n 
添加新可对外访问的端口

sudo firewall-cmd --zone=public --add-port=9099/tcp --permanent
sudo firewall-cmd --reload


### 18.NTP

1. NTP（Network Time Protocol）
- NTP 是最常见的时间同步协议，它通过网络从远程的时间服务器同步计算机的系统时间。NTP 通常使用 ntpd（NTP Daemon）进程来执行时间同步。
- 安装NTP：sudo yum install ntp
- 启动和启用NTP服务
- 安装完 NTP 后，可以启动 NTP 服务来同步时间，并确保它在系统启动时自动启动。
- 启动 NTP 服务：sudo systemctl start ntpd
- 设置 NTP 服务开机启动：sudo systemctl enable ntpd
- 配置NTP
- NTP 的配置文件通常位于 /etc/ntp.conf。你可以在这个文件中指定时间服务器、调整同步频率等。
- 编辑 /etc/ntp.conf 来配置时间服务器（例如，使用公共 NTP 服务器）：
- server 0.centos.pool.ntp.org
- server 1.centos.pool.ntp.org
- server 2.centos.pool.ntp.org
- 检查同步状态
- 你可以使用以下命令检查 NTP 服务的同步状态：ntpq -p
2. 手动替换镜像源
- 如果DNS和网络正常，但官方仓库仍不可用，可以手动替换为国内镜像源（如阿里云）
1. - 测试网络连接

- ping 8.8.8.8
- 如果不通：检查网卡配置（如 IP 地址、网关）或联系网络管理员。
2. - 手动替换镜像源

- 备份原仓库文件
- sudo cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
- 使用阿里云镜像源
- 下载阿里云的 CentOS 7 仓库文件：
- sudo curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/CentOS-7.repo
- 更新缓存
- sudo yum clean all
- sudo yum makecache
