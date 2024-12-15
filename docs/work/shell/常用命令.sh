常用命令
1. kubectl get pod -n namespace 查看pod列表
2. kubectl get ns  查看当前集群下所有命名空间（即所有的测试环境列表）
3. kubectl describe po xxx -n namespace
4. kubectl get svc -n namespace 查看service 列表（主要看工程对外暴露的端口号）
5. kubectl get ing -n namespace  查看ingrss 列表（主要看工程对外暴露域名）
6. kubectl describe ing xxx -n namespace
7. kubectl exec -it xxx bash -n namespace 进去pod容器
8. kubectl logs -f xxx -n namespace 查看pod日志
9. kubectl delete pod xxx -n --namespace=namespace 删除pod（实现应用重启效果）
10. kubectl get pod -o wide --all-namespaces | grep <ip>  根据IP地址查询Pod
其中“xxx” 表示某一个pod的名称。 “namespace” 表示某一个环境  test1,test2...


-- 线下k8s文件下载
kubectl cp test/quark-min-service-8c8974756-kpf97:/tmp/logs/service-biz-20230824_3.tar.gz /Users/lvyue/Downloads/service-biz-20230824_3.tar.gz


kubectl cp test/quark-min-service-8c8974756-kpf97:/tmp/logs/service-biz-standard-20230824_3.tar.gz /Users/lvyue/Downloads/service-biz-standard-20230824_3.tar.gz


查看端口占用
lsof -i:

该命令会列出当前系统中所有正在运行的进程，并通过内存使用量进行降序排序，然后显示前5个进程。
ps aux | sort -k4nr | head -n 5

### 日志查询
> 1.查询2022-06-22 18:00 到 2022-06-22 18:10之间的日志
> sed -n '/2022-06-22 18:00/,/2022-06-22 18:10/p' cm.log
> 打印行号
awk '/2023-08-22 19:55/,/2023-08-22 19:56/ {print NR " " $0}' service-biz.log.2023-08-22

> 2.查询2021-10-10 00:10 和 2021-10-10 00:13 两个时间点的日志，这里用到正则 | 表示或的意思，注意|为特殊字符需要转义 \|
> sed -n '/2021-10-10 00:11\|2021-10-10 00:13/p' crm.log


> 3.查询2021-10-10 00:13这个时间点的日志
> sed -n '/2021-10-10 00:13/p' crm.log

> 4.查询2021-10-10 00:13这个时间点并且包含 task3 的日志，这里用到正则 .* 表示任意字符有0个或多个
> sed -n '/2021-10-10 00:13.*task3/p' crm.log
> 这里还有一种方式  {/task3/p} 将前面一个条件的查询结果，再做一次子查询筛选
> sed -n '/2021-10-10 00:13/{/task3/p}' app.log


> 5.按行号查看---过滤出关键字附近的日志
1）cat -n test.log |grep "debug" 得到关键日志的行号

2）cat -n test.log |tail -n +92|head -n 20 查看92号，到92+20范围内的日志
tail -n +92表示查询92行之后的日志
head -n 20 则表示在前面的查询结果里再查前20条记录

3) cat 日志文件 | grep -n -B10 -A10 "关键字"      检索日志，并显示该条日志的前后N（10）行记录

B - before  A - after


####  从第3000行开始，显示1000行。即显示3000~3999行

cat filename | tail -n +3000 | head -n 1000

####  显示1000行到3000行

cat filename| head -n 3000 | tail -n +1000

####  将文件关键字第一次出现的输出到 log.txt
grep "47003000013.X02" service-biz.log | head -1 > log.txt


#### 查询关键字 error出现的次数 -i 忽略大小写
cat -n jstack.log |grep -ci "error"


### 获取"duration"后面数字大于100 的前10条
grep -E -m10 '"duration":[1-9][0-9]{2,}' quark-biz.log.3.2024-01-17


LESS 命令
N/N下一个匹配项

idea 快捷键
复制包的全路径 Shift+option+command + C




Redis

./redis-cli -h redisbjcrmtest.redis.rds.aliyuncs.com -p 6379 -a kOBsqkRp40FlTmIB -n 1 keys "*" | xargs
./redis-cli -h redisbjcrmtest.redis.rds.aliyuncs.com  -p 6379 -a kOBsqkRp40FlTmIB -n 1 del

-h ip地址
-p 端口
-a pwd：认证，需填入redis 密钥
-n 2：指定库 “2” ，相当于 select 2
keys ‘user*’：找到前缀为 “user” 的数据
|xargs 等等：删除上文找到的前缀为 “user” 的数据
不存在key前缀为 "user"的数据时，执行报error

+++ Linux下进程号查看和pid查看端口号

netstat -anp | grep pid

查找文件大于100M
find / -type f -size +100M
清空某个文件
> 文件名
++++++++++++++++++++++++++++++++CPU 高++++++++++++++++++++++++++++
top
top -Hp pid   或 ps -T -p 17038 -o pid,tid,%cpu,cmd
printf "0x%x\n" pid
jstack pid >> stack.log

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

++++++++++++++++++++++++++++++++JVM 内存快照++++++++++++++++++++++++++++
jmap -dump:format=b,file= 应用.hprof pid
tar -czvf 应用日期.tar.gz 应用.hprof

Zip -vr 压缩文件名.zip 被压缩文件

scp -v le.lv@fort.wz-inc.com:/192.168.252.77/root/opt/wzapp/install/weaver/ecology/log/应用日期.tar.gz /User/lvyue/Downloads/oa20230519.tar.gz
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



+++++++++++++++++++++++++++linux指令++++++++++++++++++++++++++++++++++++++
清空文件内容
truncate -s 0 /path/to/file

Linux内存消耗前十查看
ps aux --sort=-%mem | head -n 11 | tail -n 10
pmap -X <pid>将从操作系统的角度显示RSS的详细分类。


···描述
USER：运行该进程的用户的用户名。
PID：进程 ID。
%CPU：该进程使用的 CPU 使用量的百分比。
%MEM：该进程使用的物理内存量的百分比。
VSZ：Virtual Size，该进程使用的虚拟内存量 (KB)。
RSS：Resident Set Size，该进程使用的非交换出去的物理内存量 (KB)。
STAT：进程的状态。其中常见的有：
R：运行
S：休眠
T：停止状态
Z：僵尸状态
START：该进程启动时的时间。
TIME：CPU 时间，即该进程占用的总 CPU 时间。
COMMAND：启动进程的命令行命令。
···

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Subline text
findAll shift+command < >

UPDATE wmdm_serial_number wsn
INNER JOIN winv_stock_serial wss ON wsn.serial_number = wss.serial_number
SET wsn.batch_id = wss.batch_id, wsn.batch_code = wss.batch_code
WHERE wsn.batch_id  IS NULL;


Redis:
/Users/lvyue/applicationTools/toolApp/redis-stack-server-6.2.6-v3.catalina.x86_64/bin
Dev:
redis-cli -h bfd2f146e8ad11e4.m.cnbja.kvstore.aliyuncs.com -p 6379 -a EdpLj5VY


Create a new repository
git clone git@code.wz-inc.com:sd-shared/quark-authcap-api.git
cd quark-authcap-api
touch README.md
git add README.md
git commit -m "add README"
git push -u origin master

Existing folder or Git repository
cd existing_folder
git init
git remote add origin git@code.wz-inc.com:sd-shared/quark-authcap-api.git
git add .
git commit
git push -u origin master



Idea 目录
/Users/lvyue/Library/Application Support/JetBrains/IntelliJIdea2021.2/idea.vmoptions

####################################################################################################
# Oa 发布
#本次发布文件
#/opt/wzapp/install/weaver/ecology/classbean/com/node/action/ApprovalMiddleWithDataActionV2.class
#/opt/wzapp/install/weaver/ecology/classbean/com/node/cron/SaleContractSubmitCron.class


#备份文件部分
cp /opt/wzapp/install/weaver/ecology/classbean/com/node/cron/SaleContractSubmitCron.class /opt/wzapp/install/weaver/oaBakFile/classbean/com/node/cron/SaleContractSubmitCron.class-0207

/opt/wzapp/install/weaver/ecology/oaloginsrm/js

#发布文件准备
scp -v /Users/xuyihang/data/publish/SaleContractSubmitCron.class  yihang.xu@fort.wz-inc.com:/192.168.252.77/root/tmp/SaleContractSubmitCron.class



scp -v /Users/xuyihang/data/publish/SaleContractSubmitCron.class  yihang.xu@fort.wz-inc.com:/172.16.224.10/root/


scp -v yihang.xu@fort.wz-inc.com:/192.168.252.77/root/opt/wzapp/install/weaver/ecology/interface/alitrip/getAlitripOrderListAjax.jsp ~/data


#停机
sh resinstop.sh


#发布文件复制
sudo cp /tmp/SaleContractSubmitCron.class /opt/wzapp/install/weaver/ecology/classbean/com/node/cron/SaleContractSubmitCron.class

#启动
sh resinstart.sh

scp -v ~/data/upload/CommonSubmitCron.class yihang.xu@fort.wz-inc.com:/172.16.224.10/root/usr/weaver/ecology/classbean/com/node/cron/CommonSubmitCron.class




scp -v ~/data/publish/submitPurchase.png yihang.xu@fort.wz-inc.com:/192.168.252.77/root/tmp/submitPurchase.png

scp -v ~/data/publish/businessFrame.png yihang.xu@fort.wz-inc.com:/192.168.252.77/root/tmp/businessFrame.png

scp -v ~/data/publish/supplier_query.png yihang.xu@fort.wz-inc.com:/192.168.252.77/root/tmp/supplier_query.png


cp /tmp/submitPurchase.png /opt/wzapp/install/weaver/ecology/oaloginsrm/submitPurchase0327.png
cp /tmp/businessFrame.png /opt/wzapp/install/weaver/ecology/oaloginsrm/businessFrame0327.png
cp /tmp/supplier_query.png /opt/wzapp/install/weaver/ecology/oaloginsrm/supplier_query0327.png
####################################################################################################

####################################################################################################
1.确定到底是哪个进程占用内存高
ps aux --sort=-%mem
2.堆外到底占用多少？
jcmd pid GC.heap_info


#####################################dify部署########################################################

Dify:(di fan)
官方文档：https://docs.dify.ai/zh-hans/getting-started/install-self-hosted/docker-compose
数据存储目录：/home/admin/volumes_dify/volumes/
应用启动目录：使用【root用户】：docker compose -f docker-compose.yaml up -d

直接改的docker-compose.yaml（目录：/home/admin/dify/docker）
升级是这样的：
1. 拉最新版本镜像：api/web 使用【admin 用户】 上传到 /home/admin/dify_images目录
2. 修改docekr-compose.yaml 里的版本号
3. 重启docker compose -f docker/docker-compose.yaml up -d



错误信息：
2024-11-28 13:32:30 Error: Database is uninitialized and superuser password is not specified. 2024-11-28 13:32:30 You must specify POSTGRES_PASSWORD to a non-empty value for the 2024-11-28 13:32:30 superuser. For example, "-e POSTGRES_PASSWORD=password" on "docker run". 2024-11-28 13:32:30 2024-11-28 13:32:30 You may also use "POSTGRES_HOST_AUTH_METHOD=trust" to allow all 2024-11-28 13:32:30 connections without a password. This is not recommended. 2024-11-28 13:32:30 2024-11-28 13:32:30 See PostgreSQL documentation about "trust": 2024-11-28 13:32:30 https://www.postgresql.org/docs/current/auth-trust.html

运行镜像时：添加参数 POSTGRES_PASSWORD=mysecretpassword


本地启动：
/Users/lvyue/applicationTools/workApp/ideaWorkSpaces/github/dify
拉取最新代码：
cd /Users/lvyue/applicationTools/workApp/ideaWorkSpaces/github/dify/docker
启动：docker compose up -d    停止：docker compose down
访问：http://localhost/apps
####################################################################################################
查看镜像信息：
docker images -a

1.将镜像保存为 tar：
docker save -o /Users/lvyue/Downloads/dify-web.tar langgenius/dify-api:0.11.1

docker save -o /Users/lvyue/Downloads/dify-web-0.12.1.tar langgenius/dify-web:0.12.1
docker save -o /Users/lvyue/Downloads/dify-api-0.12.1.tar langgenius/dify-api:0.12.1



2.传输 tar 文件到目标服务器
scp /home/user/my_image.tar user@remote-server:/home/user/

3.在目标服务器上加载 tar 文件导入docker镜像：
docker load -i <镜像文件名>.tar



########################################## MOSS start ###############################################
要查看 iptables 的所有配置，可以使用以下命令：
sudo iptables -L -v -n


添加新可对外访问端口
sudo firewall-cmd --zone=public --add-port=9099/tcp --permanent
sudo firewall-cmd --reload

########################################## MOSS end #################################################