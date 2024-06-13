###1. cloudflare网站
[cloudflare网站链接](https://dash.cloudflare.com/)
没有邮箱注册多个cf账号可以使用临时邮箱进行注册和验证。

[临时邮箱1](https://email10min.com/zh)
[临时邮箱2](https://www.linshiyouxiang.net/)
###2. worker部署代码：（任意一个代码都可部署）
[单代理proxyIP](/docs/vvv/singbox/cloudflare_worker_js/one-ip-worker-vless.js)
> 源：单代理proxyIP https://github.com/leilei223/edgetunnel/blob/main/src/worker-vless.js

[多代理proxyIPs](/docs/vvv/singbox/cloudflare_worker_js/batch-ip-worker-vless.js)
> 源：多代理proxyIPs https://github.com/3Kmfi6HP/EDtunnel/blob/main/_worker.js

###3. uuid生成
[uuid生成](https://1024tools.com/uuid)


```proxyips
cdn-all.xn--b6gac.eu.org
cdn.xn--b6gac.eu.org
cdn-b100.xn--b6gac.eu.org
edgetunnel.anycast.eu.org
cdn.anycast.eu.org
```

###4. singbox下载地址
4.1 安卓可在Google商店下载或 https://github.com/SagerNet/sing-box/releases/tag/v1.8.8

4.2 苹果手机或macos可在apple store里下载

> singbox使用vless配置（请自己配置修改，我配置的worker请求每天只有10w次，超过就次日才能使用）
1.8.0及以上版singbox，精细分流 https://github.com/leilei223/confg/blob/main/1.8.0%2Bnewsingbox-fenliu.json

> http port: 80, 8080, 8880, 2052, 2086, 2095
 
###5. cloudflare颁发证书的网站收集
[站长](https://ping.chinaz.com/) 或 [itdog](https://www.itdog.cn/ping/)
```text
gamer.com.tw
steamdb.info
toy-people.com
silkbook.com
cdn.anycast.eu.org
icook.hk
shopify.com
www.visa.com.tw
time.is
japan.com
www.hugedomains.com
www.visa.com.sg
www.whoer.net
www.visa.com.hk
malaysia.com
www.visa.co.jp
www.ipget.net
icook.tw
www.visa.com
www.gov.ua
www.udacity.com
www.shopify.com
www.whatismyip.com
singapore.com
www.visakorea.com
www.csgo.com
russia.com
ip.sb
www.4chan.org
www.glassdoor.com
xn--b6gac.eu.org
www.digitalocean.com
www.udemy.com
cdn-all.xn--b6gac.eu.org
dnschecker.org
tasteatlas.com
pixiv.net
comicabc.com
icook.tw
gamer.com.tw
steamdb.info
toy-people.com
silkbook.com


CF优选域名

wz.weishao2023.dk.eu.org
wz.weishao2023.uk.eu.org
cloudflare.cfgo.cc
086181.xyz
stock.hostmonit.com
www.lyzdzy.com
xs.wxtv.cc
cf.zmdhc.com
www.90dushu.com
www.tushencn.com
7sc.cc
0550cq.com
www.xinpian8.com
www.c333.net
www.7749tv.com
www.888dyy.cc
manmankan.cc
www.ddwhm.com



CF https端口：2053，2083，2087，2096，8443，443 

CF http端口：2052，2082，2086，2095，80，8080，8880

```