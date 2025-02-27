###  错误 Failed to connect to github.com port 443 after 75033 ms: Couldn‘t connect to server的解决方案
```shell
# http ｜ https
git config --global http.proxy 127.0.0.1:7890
git config --global https.proxy 127.0.0.1:7890
#socks5代理
git config --global http.proxy socks5 127.0.0.1:7890
git config --global https.proxy socks5 127.0.0.1:7890
#关闭代理
git config --global --unset http.proxy
```


