# 帮助

## 本地运行

1. 安装docsify

命令行执行：
``` bash
$ npm i docsify-cli -g
```
全局安装docsify。

2. 初始化文档

假设文档存在`docs`目录下：
``` bash
$ docsify init docs

> Initialization succeeded! Please run docsify serve docs
```
执行完以上命令 `docs` 文件目录下会生成以下 3 个文件：

- `index.html`：入口文件
- `README.md`：会做为主页内容渲染
- `.nojekyll`：用于阻止 GitHub Pages 会忽略掉下划线开头的文件

3. 启动本地服务预览

`docs` 同级目录下执行以下命令，打开本地服务器，默认地址为：http://localhost:3000
``` bash
$ docsify serve docs

Serving /Users/may/Nodejs-Roadmap/docs now.
Listening at http://localhost:3000
```

或者进入`docs`目录执行命令：
``` bash
$ docsify serve
```
亦可。

4. 设置端口

默认的启用端口`3000`，如果想更换可执行：

``` bash
$ docsify serve --port 3333
```

## 部署到iis

只需要将网站物理路径指向`docs`目录，但需要注意的是需要添加`.md`文件的MINME

添加文件扩展名为：`.md`

添加MIME 类型为：`text/x-markdown`