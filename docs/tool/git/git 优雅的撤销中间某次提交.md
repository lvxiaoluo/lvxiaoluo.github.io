

# git 优雅的撤销中间某次提交

## 环境
git : 2+

## 前言
最近两天，公司的git合并代码时，出现了严重的问题，浪费很多时间；
现在记录下；
情况是这样的，一个同事自己的本地分支（远程没有），不知怎么的，有了别人开发分支的代码，而他自己又不知道；
其在切换到主分支，并merge自己的分支，此时其已经把别人正在开发的代码都合并到了主分支。

到了晚上准备升级时，才发现，主分支的代码出了问题；此时版本库是这样的：

![这里写图片描述](https://img-blog.csdn.net/20180412224815820?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3UwMTMwNjYyNDQ=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

如图 **100047dcc**这一步就有不该有的代码；

而此时版本库已经提交过了很多次，现在的问题就是，如何撤销掉**100047dcc**提交的代码，并且保留其他人提交的代码。

这个问题，折腾到了晚上9点半左右，尝试了网上给出的：
```shell
git rebase -i commit_id
//再通过将pick改为drop
```
但是，实际的效果是，**100047dcc**代码没了，其他人提交的代码也没有了！
也就是给人感觉和**git reset --hard be8c6f6dd**没有什么区别！

最后因为太晚，从提交记录上看，**100047dcc**之后就一个人提交了代码，所以就执行了：
```shell
//先切一个备份分支
git branch -b master_tmp
//再执行
git reset --hard be8c6f6dd
```
之后，那个人（也就是我）从备份分支上把文件拷贝回来—（因为我是直接在主分支上改的，自己的分支并没有代码）。

第二天，我打算去拷贝文件，我执行如下操作：
```shell
yutao@yutao MINGW64 /d/sts/workspace/ggservice (master)
$ git pull
remote: Counting objects: 44, done.
remote: Compressing objects: 100% (23/23), done.
remote: Total 26 (delta 19), reused 0 (delta 0)
Unpacking objects: 100% (26/26), done.
From gitlab.gofund.cn:gg-service/ggservice
 + 1784b12...384decc master     -> origin/master  (forced update)
   f8f2b19..eb33489  devyaomy   -> origin/devyaomy
 * [new branch]      master_tmp -> origin/master_tmp
Already up-to-date.

yutao@yutao MINGW64 /d/sts/workspace/ggservice (master)
$ git status
On branch master
Your branch is ahead of 'origin/master' by 796 commits.
  (use "git push" to publish your local commits)
nothing to commit, working directory clean

yutao@yutao MINGW64 /d/sts/workspace/ggservice (master)
$ git push
Total 0 (delta 0), reused 0 (delta 0)
To git@gitlab.gofund.cn:gg-service/ggservice.git
   384decc..1784b12  master -> master
```
简单的说，我的操作就是两步：

1、git pull
2、git push
结果又把代码还原回去了！

为啥呢？

虽然昨天晚上，把远程库的版本回退到了正确的版本，但是我的本地主分支还是最新的commit，也就是说，相比远程库，我本地库是超前了多次提交，毕竟因为远程库回退了嘛！

这个时候，我必须也得对本地库进行回退，回退到线上相同的commit节点才行。

这个时候，我做了以下几个操作：
```shell
yutao@yutao MINGW64 /d/sts/workspace/ggservice (master)
$ git reset --soft 384deccaa6
$ git status
On branch master
Your branch is up-to-date with 'origin/master'.
Changes to be committed:
  (use "git reset HEAD <file>..." to unstage)

        modified:   .gitignore
        modified:   conf/application.conf
        new file:   conf/hanlp.properties
        new file:   dataservice/app/ggservice/common/UserCodeEnum.java
        new file:   dataservice/app/ggservice/v1/email/action/BindEmailGG3Action.java
        new file:   dataservice/app/ggservice/v1/email/action/SendEmailCaptchaGG3Action.java
        // 文件太多不一一显示
yutao@yutao MINGW64 /d/sts/workspace/ggservice (master)
$ git reset --hard 384deccaa6
```
上面敲了很多命令，其实真正只需要** git reset --hard 384deccaa6**即可。

> git reset --hard 384deccaa6

接下来，我开始复制粘贴，从备份分支上，把代码拷贝下。
真的操蛋，这等于是增加工作量啊！

#### revert 撤销某次提交
到了下午，又有个同事干了类似我上午的操作。把不该有的代码提交上去了！
这就麻烦了，虽然远程库回退了！结果是要求凡是pull最新代码的人，都得进行本地回退的操作。
否则，就没完没了！

到了晚上，对着备份分支进行测试，终于找到了优雅的解决办法！

这就是**revert**命令

该命令就是为撤销某次提交而存在的；

首先，我是明白**100047dcc/88这次提交是有问题的，这是问题的源头；
也就是说，只要我们把这次提交的给撤销了，就不会有问题了！

#### 步骤 一
```shell
$ git revert 100047dcc
error: Commit 100047dccb58f3ee5e27b0dfaf5c02ac91dc2c73 is a merge but no -m option was given.
fatal: revert failed
```
结果报错了，报了一个Commit is a merge but no -m option was given.

为什么呢？

如果100047dcc这只是一个普通的提交，其实是不会报错的！
但是，这是一个merge的提交。

那么在撤销时，git并不知道我要撤销具体哪次！如下图：

![这里写图片描述](https://img-blog.csdn.net/20180412232654370?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3UwMTMwNjYyNDQ=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)


这个时候，怎么办呢？

我的做法

### 步骤二
```sh
yutao@yutao MINGW64 /d/sts/workspace/ggservice (master_tmp)
$ git revert 100047dcc -m 1
error: could not revert 100047d... Merge branch 'master' of gitlab.gofund.cn:gg-service/ggservice into wjs
hint: after resolving the conflicts, mark the corrected paths
hint: with 'git add <paths>' or 'git rm <paths>'
hint: and commit the result with 'git commit'
```
我执行了这样的一个操作：

> git revert 100047dcc -m 1

参数 -m 就是指定要撤销的那个提价，从左往右，从1开始数；也就是我撤销的是ca4a7ff999。

接着其把代码冲突，然后我就解决冲突，保留主分支的代码，去掉那个人的代码。

解决完冲突后，我执行如下操作：
```sh
yutao@yutao MINGW64 /d/sts/workspace/ggservice (master_tmp|REVERTING)
$ git add -A

yutao@yutao MINGW64 /d/sts/workspace/ggservice (master_tmp|REVERTING)
$ git status
On branch master_tmp
Your branch is up-to-date with 'origin/master_tmp'.
You are currently reverting commit 100047d.
  (all conflicts fixed: run "git revert --continue")
  (use "git revert --abort" to cancel the revert operation)

Changes to be committed:
  (use "git reset HEAD <file>..." to unstage)

        modified:   dataservice/app/ggservice/v1/datacentre/action/GetIncomeDistributeAction.java
        //文件太多省略。。。

yutao@yutao MINGW64 /d/sts/workspace/ggservice (master_tmp|REVERTING)
$ git commit -m "ceshi"
[master_tmp d2ae829] ceshi
 18 files changed, 95 insertions(+), 396 deletions(-)
```
我上面执行的语句其实就是：
```sh
$ git add -A
$ git commit -m "ceshi"
```
### 步骤三
```
yutao@yutao MINGW64 /d/sts/workspace/ggservice (master_tmp)
$ git revert 100047dcc -m 2
error: could not revert 100047d... Merge branch 'master' of gitlab.gofund.cn:gg-service/ggservice into wjs
hint: after resolving the conflicts, mark the corrected paths
hint: with 'git add <paths>' or 'git rm <paths>'
hint: and commit the result with 'git commit'
```
也就是执行：

> $ git revert 100047dcc -m 2

即 撤销be8c6f6dde的提交，这个时候也会提示代码冲突了，

接着和上面一样，解决冲突，在提交：
```sh
yutao@yutao MINGW64 /d/sts/workspace/ggservice (master_tmp|REVERTING)
$ git status
On branch master_tmp
Your branch is ahead of 'origin/master_tmp' by 1 commit.
  (use "git push" to publish your local commits)
You are currently reverting commit 100047d.
  (fix conflicts and run "git revert --continue")
  (use "git revert --abort" to cancel the revert operation)

Changes to be committed:
  (use "git reset HEAD <file>..." to unstage)

        modified:   .gitignore
        deleted:    conf/hanlp.properties
        deleted:    dataservice/app/ggservice/common/UserCodeEnum.java
        deleted:    dataservice/app/ggservice/v1/email/action/BindEmailGG3Action.java
        deleted:    dataservice/app/ggservice/v1/email/action/SendEmailCaptchaGG3Action.java
        deleted:    dataservice/app/ggservice/v1/email/service/EmailCaptchaService.java
        deleted:    dataservice/app/ggservice/v1/expert/action/GetExpertOfStockAssessAction.java
        modified:   dataservice/app/ggservice/v1/expert/service/ExpertGG3Service.java
        modified:   dataservice/app/ggservice/v1/ggmtoolbox/action/GetMyStockLabelInfoAction.java
        modified:   dataservice/app/ggservice/v1/ggmtoolbox/action/UpdateUserTokenInfoAction.java
        modified:   dataservice/app/ggservice/v1/ggmtoolbox/service/AppDOSInfoService.java
        modified:   dataservice/app/ggservice/v1/ggmtoolbox/service/UserInfoService.java
        modified:   dataservice/app/ggservice/v1/graph/action/GetStockPlateComponentAction.java
        modified:   dataservice/app/ggservice/v1/graph/service/StockPlateService.java
        // 文件太多省略。。。

yutao@yutao MINGW64 /d/sts/workspace/ggservice (master_tmp|REVERTING)
$ git add -A

yutao@yutao MINGW64 /d/sts/workspace/ggservice (master_tmp|REVERTING)
$ git status
On branch master_tmp
Your branch is ahead of 'origin/master_tmp' by 1 commit.
  (use "git push" to publish your local commits)
You are currently reverting commit 100047d.
  (all conflicts fixed: run "git revert --continue")
  (use "git revert --abort" to cancel the revert operation)

Changes to be committed:
  (use "git reset HEAD <file>..." to unstage)

        modified:   .gitignore
        modified:   conf/application.conf
        deleted:    conf/hanlp.properties
        deleted:    dataservice/app/ggservice/common/UserCodeEnum.java
        deleted:    dataservice/app/ggservice/v1/email/action/BindEmailGG3Action.java
        deleted:    dataservice/app/ggservice/v1/email/action/SendEmailCaptchaGG3Action.java
        deleted:    dataservice/app/ggservice/v1/email/service/EmailCaptchaService.java
        deleted:    dataservice/app/ggservice/v1/expert/action/GetExpertOfStockAssessAction.java
        modified:   dataservice/app/ggservice/v1/expert/service/ExpertGG3Service.java
        modified:   dataservice/app/ggservice/v1/ggmtoolbox/action/GetMyStockLabelInfoAction.java
        modified:   dataservice/app/ggservice/v1/ggmtoolbox/action/UpdateUserTokenInfoAction.java
        modified:   dataservice/app/ggservice/v1/ggmtoolbox/service/AppDOSInfoService.java
        modified:   dataservice/app/ggservice/v1/ggmtoolbox/service/UserInfoService.java
        modified:   dataservice/app/ggservice/v1/graph/action/GetStockPlateComponentAction.java
        modified:   dataservice/app/ggservice/v1/graph/service/StockPlateService.java
        modified:   dataservice/app/ggservice/v1/hq/action/GetStockHistoryDynamicAction.java
        modified:   dataservice/app/ggservice/v1/keybordspirit/action/GetMyGroupStockIndexAction.java

yutao@yutao MINGW64 /d/sts/workspace/ggservice (master_tmp|REVERTING)
$ git commit -m "使用revert 版本号 -m 1或者2同时进行撤销某次提交测试"
[master_tmp 236da00] 使用revert 版本号 -m 1或者2同时进行撤销某次提交测试
 95 files changed, 2093 insertions(+), 10011 deletions(-)
 delete mode 100644 conf/hanlp.properties
 delete mode 100644 dataservice/app/ggservice/common/UserCodeEnum.java
 delete mode 100644 dataservice/app/ggservice/v1/email/action/BindEmailGG3Action.java
 delete mode 100644 dataservice/app/ggservice/v1/email/action/SendEmailCaptchaGG3Action.java
 delete mode 100644 dataservice/app/ggservice/v1/email/service/EmailCaptchaService.java
 delete mode 100644 dataservice/app/ggservice/v1/expert/action/GetExpertOfStockAssessAction.java
 delete mode 100644 dataservice/app/ggservice/v1/mobile/action/BindMobileGG3Action.java
 delete mode 100644 dataservice/app/ggservice/v1/mobile/action/SendMobileCaptchaGG3Action.java
 rewrite dataservice/app/ggservice/v1/mystocktags/service/MyStockTagService.java (82%)
 delete mode 100644 dataservice/app/ggservice/v1/report/action/GetAuthorRankListAction.java
 delete mode 100644 dataservice/app/ggservice/v1/report/action/GetAuthorRecommendReportListAction.java
 delete mode 100644 dataservice/app/ggservice/v1/report/action/GetHonoraryAuthorListAction.java
 delete mode 100644 dataservice/app/ggservice/v1/report/action/GetHotIndustryListAction.java
 delete mode 100644 dataservice/app/ggservice/v1/report/action/GetHotStockListAction.java
 delete mode 100644 dataservice/app/ggservice/v1/report/action/GetHotThemeListAction.java
 delete mode 100644 dataservice/app/ggservice/v1/report/action/GetOrganRankListAction.java
 delete mode 100644 dataservice/app/ggservice/v1/report/condition/AuthorOrganRankCondition.java
 delete mode 100644 dataservice/app/ggservice/v1/report/condition/HotReportCondition.java
 delete mode 100644 dataservice/app/ggservice/v1/report/service/HotReportService.java
 delete mode 100644 dataservice/app/ggservice/v1/usergg/action/AutoLoginAction.java
 delete mode 100644 dataservice/app/ggservice/v1/usergg/action/BindOuterChannelAction.java
 delete mode 100644 dataservice/app/ggservice/v1/usergg/action/EmailRegisterAction.java
 delete mode 100644 dataservice/app/ggservice/v1/usergg/action/GetUserAction.java
 delete mode 100644 dataservice/app/ggservice/v1/usergg/action/IsAccountExistAction.java
 delete mode 100644 dataservice/app/ggservice/v1/usergg/action/LoginAction.java
 delete mode 100644 dataservice/app/ggservice/v1/usergg/action/LogoutAction.java
 delete mode 100644 dataservice/app/ggservice/v1/usergg/action/OuterChannelLoginAction.java
 delete mode 100644 dataservice/app/ggservice/v1/usergg/action/RegisterAction.java
 delete mode 100644 dataservice/app/ggservice/v1/usergg/service/LoginService.java
 delete mode 100644 dataservice/app/ggservice/v1/usergg/service/RegisterService.java
 delete mode 100644 dataservice/app/ggservice/v1/usergg/service/UserCommonUtils.java
 delete mode 100644 dataservice/app/ggservice/v1/usergg/service/UserService.java
```
即：
```
> $ git add -A
> $ git commit -m "使用revert 版本号 -m 1或者2同时进行撤销某次提交测试"
```
可以看出删除掉了那个人提交的文件。

### 最后一步
```sh
yutao@yutao MINGW64 /d/sts/workspace/ggservice (master_tmp)
$ git push
```
这样就把那个人提交错误的代码给删除了，其他人的本地分支也不需要版本回退了！
一次改好，到处OK！

### 总结
当想撤销中间某次提交时，强烈建议使用revert命令，而不是reset。
git reset –hard commit_id 虽然可以回退远程库，但是其要求pull最新代码的每个人的本地分支都要进行版本回退。这样就增加工作量了！

正确的步骤：
```sh
git revert commit_id
//如果commit_id是merge节点的话,-m是指定具体哪个提交点
git revert commit_id -m 1
//接着就是解决冲突
git add -A
git commit -m ".."
git revert commit_id -m 2
//接着就是解决冲突
git add -A
git commit -m ".."
git push
```
其中**git revert commit_id -m**数字是针对，merge提交点的操作。
如果是普通的提交点，不需要这么麻烦。

参考地址：
[Git高级教程(二)] 远程仓库版本回退方法
https://www.cnblogs.com/ShaYeBlog/p/5368064.html
https://blog.csdn.net/hongchangfirst/article/details/49472913
———————————————
原文链接：https://blog.csdn.net/u013066244/article/details/79920012