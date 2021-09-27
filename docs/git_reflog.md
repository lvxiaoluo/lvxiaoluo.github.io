### 【Git学习】使用git reflog 命令来查看历史提交记录并使用提交记录恢复已经被删除掉的分支

#### 一、问题描述
昨天下午有个同事急急忙忙跑我座位上，要我帮忙，说他刚刚因为手误，将他本地的某个project的某个branch分支删除了，并且也将Gitlab上面的远程分支也删除了。他本来是想发起merge request的，但是后面他眼神不好以为已经merged过了，就直接删了Gitlab上的远程分支并且将他本地的这个分支也直接删除了。

现在他跑过来问我有没有办法恢复，不然他这一天的工作就白费了。

看他急急忙忙不知所措的样子，我直接调侃他说恢复不了。要他以后小心点删除branch，不要眼神不好。后面才慢慢地然后使用了git reflog 查找了他所有的分支提交记录等，然后找到对应的git commit的sha1码，然后恢复过来了。他说居然还有这种操作，666！我去，这是常规操作好吗？

> 所以 如何恢复本地和远程仓库都已经删除掉的分支呢？？下面我来演示一下。

#### 二、复现问题
现在我准备找一个测试的demo git 工程来进行演练一下，如何恢复以及被删除的分支。

##### 1、创建一个git仓库并且提交一个文件
![图片](https://img-blog.csdnimg.cn/20181114093726824.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxNDQ2MjgyNDEy,size_16,color_FFFFFF,t_70)

```sh
DH207891+OuyangPeng@DH207891 MINGW32 /f/git test
$ git init
Initialized empty Git repository in F:/git test/.git/

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (master)
$ vim test.txt

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (master)
$ cat test.txt
11111111111111111111111111111111

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (master)
$ git add .
warning: LF will be replaced by CRLF in test.txt.
The file will have its original line endings in your working directory.

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (master)
$ git commit -m "first commit"
[master (root-commit) 363a197] first commit
 1 file changed, 1 insertion(+)
 create mode 100644 test.txt

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (master)
$ git branch
* master

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (master)
$
```
##### 2、再次编辑test.txt文件并且提交
![图片](https://img-blog.csdnimg.cn/20181114093944520.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxNDQ2MjgyNDEy,size_16,color_FFFFFF,t_70)

##### 3、切换分支并再次编辑test.txt文件并且提交
创建并切换到 feature/test1分支
![图片](https://img-blog.csdnimg.cn/20181114094401453.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxNDQ2MjgyNDEy,size_16,color_FFFFFF,t_70)

在feature/test1分支上继续编辑test.txt文件并且提交
![图片](https://img-blog.csdnimg.cn/201811140945099.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxNDQ2MjgyNDEy,size_16,color_FFFFFF,t_70)

```sh
DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (master)
$ git checkout -b feature/test1
Switched to a new branch 'feature/test1'

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (feature/test1)
$ git branch
* feature/test1
  master

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (feature/test1)
$ git log
commit 77dfdffc87bde49a6361bbdf36a9b01a20c10a3b
Author: ouyangpeng <ouyangpeng@oaserver.dw.gdbbk.com>
Date:   Wed Nov 14 09:38:44 2018 +0800

    second commit

commit 363a197ffb4236ec9d6ee5b7631ae326eae958f4
Author: ouyangpeng <ouyangpeng@oaserver.dw.gdbbk.com>
Date:   Wed Nov 14 09:36:32 2018 +0800

    first commit

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (feature/test1)
$ vim test.txt

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (feature/test1)
$ cat test.txt
11111111111111111111111111111111


22222222222222222222222222222222


33333333333333333333333333333333

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (feature/test1)
$ git add test.txt
warning: LF will be replaced by CRLF in test.txt.
The file will have its original line endings in your working directory.

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (feature/test1)
$ git commit -m "third commit"
[feature/test1 dab39f4] third commit
 1 file changed, 3 insertions(+)

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (feature/test1)
$ git log
commit dab39f4808f6553e57a0551f44044919a31dc76b
Author: ouyangpeng <ouyangpeng@oaserver.dw.gdbbk.com>
Date:   Wed Nov 14 09:42:17 2018 +0800

    third commit

commit 77dfdffc87bde49a6361bbdf36a9b01a20c10a3b
Author: ouyangpeng <ouyangpeng@oaserver.dw.gdbbk.com>
Date:   Wed Nov 14 09:38:44 2018 +0800

    second commit

commit 363a197ffb4236ec9d6ee5b7631ae326eae958f4
Author: ouyangpeng <ouyangpeng@oaserver.dw.gdbbk.com>
Date:   Wed Nov 14 09:36:32 2018 +0800

    first commit

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (feature/test1)
$
```

现在我们有两个分支了，一个 feature/test1分支，一个 master分支。 feature/test1分支比master分支多了一次提交记录。
![图片](https://img-blog.csdnimg.cn/20181114094645494.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxNDQ2MjgyNDEy,size_16,color_FFFFFF,t_70)


##### 4、删除删除 feature/test1 分支
现在我们模拟刚才那位同事之间删除了 feature/test1 分支。我们先checkout到master分支，然后删除 feature/test1 分支
![图片](https://img-blog.csdnimg.cn/20181114094940346.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxNDQ2MjgyNDEy,size_16,color_FFFFFF,t_70)

feature/test1分支因为没有合并到master分支，就被删除了。所以此时master分支没有feature/test1分支上做的新的修改记录。
![图片](https://img-blog.csdnimg.cn/20181114095117506.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxNDQ2MjgyNDEy,size_16,color_FFFFFF,t_70)

```sh
DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (feature/test1)
$ git checkout master
Switched to branch 'master'

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (master)
$ git branch
  feature/test1
* master

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (master)
$ git branch -d feature/test1
error: The branch 'feature/test1' is not fully merged.
If you are sure you want to delete it, run 'git branch -D feature/test1'.

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (master)
$ git branch
  feature/test1
* master

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (master)
$ git branch -D feature/test1
Deleted branch feature/test1 (was dab39f4).

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (master)
$ git branch
* master

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (master)
$ git log
commit 77dfdffc87bde49a6361bbdf36a9b01a20c10a3b
Author: ouyangpeng <ouyangpeng@oaserver.dw.gdbbk.com>
Date:   Wed Nov 14 09:38:44 2018 +0800

    second commit

commit 363a197ffb4236ec9d6ee5b7631ae326eae958f4
Author: ouyangpeng <ouyangpeng@oaserver.dw.gdbbk.com>
Date:   Wed Nov 14 09:36:32 2018 +0800

    first commit
```
#### 三、恢复feature/test1分支
如何恢复feature/test1分支呢？？

##### 3.1 找到feature/test1分支的最后一次提交记录
我们使用 git reflog 来看下git的提交记录，可以发现 dab39f4这次提交记录描述是 third commit 。

> 区别：如果在回退以后又想再次回到之前的版本，**git reflog** 可以查看所有分支的所有操作记录（包括commit和reset的操作），包括已经被删除的commit记录，git log则不能察看已经删除了的commit记录

![图片](https://img-blog.csdnimg.cn/20181114095422936.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxNDQ2MjgyNDEy,size_16,color_FFFFFF,t_70)

```sh
DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (master)
$ git branch
* master

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (master)
$ git log
commit 77dfdffc87bde49a6361bbdf36a9b01a20c10a3b
Author: ouyangpeng <ouyangpeng@oaserver.dw.gdbbk.com>
Date:   Wed Nov 14 09:38:44 2018 +0800

    second commit

commit 363a197ffb4236ec9d6ee5b7631ae326eae958f4
Author: ouyangpeng <ouyangpeng@oaserver.dw.gdbbk.com>
Date:   Wed Nov 14 09:36:32 2018 +0800

    first commit

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (master)
$ git reflog
77dfdff HEAD@{0}: checkout: moving from feature/test1 to master
dab39f4 HEAD@{1}: commit: third commit
77dfdff HEAD@{2}: checkout: moving from master to feature/test1
77dfdff HEAD@{3}: commit: second commit
363a197 HEAD@{4}: commit (initial): first commit
```
我们再来看看之前的截图，在feature/test1分支第三次提交的值为 dab39f4808f6553e57a0551f44044919a31dc76b

![图片](https://img-blog.csdnimg.cn/201811140945099.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxNDQ2MjgyNDEy,size_16,color_FFFFFF,t_70)

dab39f4 和 dab39f4808f6553e57a0551f44044919a31dc76b 不就是提交记录的简写和完整的写法，一模一样。

因此我们找到了这次提交的SHA1校验和，因此我们就可以恢复feature/test1分支了。

##### 3.2 根据feature/test1分支的最后一次提交记录来恢复feature/test1分支
![图片](https://img-blog.csdnimg.cn/20181114100223325.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxNDQ2MjgyNDEy,size_16,color_FFFFFF,t_70)

```sh
DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (master)
$ git reflog
77dfdff HEAD@{0}: checkout: moving from feature/test1 to master
dab39f4 HEAD@{1}: commit: third commit
77dfdff HEAD@{2}: checkout: moving from master to feature/test1
77dfdff HEAD@{3}: commit: second commit
363a197 HEAD@{4}: commit (initial): first commit

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (master)
$ git branch
* master

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (master)
$ git checkout -b feature/test1 dab39f4
Switched to a new branch 'feature/test1'

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (feature/test1)
$ git branch
* feature/test1
  master

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (feature/test1)
$ git log
commit dab39f4808f6553e57a0551f44044919a31dc76b
Author: ouyangpeng <ouyangpeng@oaserver.dw.gdbbk.com>
Date:   Wed Nov 14 09:42:17 2018 +0800

    third commit

commit 77dfdffc87bde49a6361bbdf36a9b01a20c10a3b
Author: ouyangpeng <ouyangpeng@oaserver.dw.gdbbk.com>
Date:   Wed Nov 14 09:38:44 2018 +0800

    second commit

commit 363a197ffb4236ec9d6ee5b7631ae326eae958f4
Author: ouyangpeng <ouyangpeng@oaserver.dw.gdbbk.com>
Date:   Wed Nov 14 09:36:32 2018 +0800

    first commit

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (feature/test1)
$
```
我们可以看到，我们恢复了 feature/test1分支，并且feature/test1分支之前的提交记录都完整的还原回来了，和原来一样，比master分支多了一次提交记录。如下所示：
![图片](https://img-blog.csdnimg.cn/20181114100641227.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxNDQ2MjgyNDEy,size_16,color_FFFFFF,t_70)

##### 3.3 在Gitlab上根据commit SHA直接新建branch来恢复被删除的分支
当然也可以在Gitlab上根据commit SHA直接新建branch来恢复被删除的分支，操作如下所示：
![图片](https://img-blog.csdnimg.cn/20181114104312392.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxNDQ2MjgyNDEy,size_16,color_FFFFFF,t_70)

选择【Create from】，然后输入刚才查找到的commit SHA

![图片](https://img-blog.csdnimg.cn/20181114104424553.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxNDQ2MjgyNDEy,size_16,color_FFFFFF,t_70)

然后点击回车
![图片](https://img-blog.csdnimg.cn/20181114104449400.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxNDQ2MjgyNDEy,size_16,color_FFFFFF,t_70)

接着在【Branch name】写上分支名即可恢复了。

#### 四、git reflog 简介
官方介绍地址 https://git-scm.com/docs/git-reflog

![图片](https://img-blog.csdnimg.cn/2018111410135510.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxNDQ2MjgyNDEy,size_16,color_FFFFFF,t_70)

![图片](https://img-blog.csdnimg.cn/20181114102535810.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxNDQ2MjgyNDEy,size_16,color_FFFFFF,t_70)
具体的操作以及选项可以去上面的官网查看具体的用法，下面我就将刚才我们使用的git reflog 稍微讲下即可。

##### 4.1 查看历史版本记录
命令：git reflog
作用：查看提交版本历史记录
执行命令后如图：
![图片](https://img-blog.csdnimg.cn/20181114102112910.png)
```sh
DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (feature/test1)
$ git reflog
dab39f4 HEAD@{0}: checkout: moving from master to feature/test1
77dfdff HEAD@{1}: checkout: moving from feature/test1 to master
dab39f4 HEAD@{2}: commit: third commit
77dfdff HEAD@{3}: checkout: moving from master to feature/test1
77dfdff HEAD@{4}: commit: second commit
363a197 HEAD@{5}: commit (initial): first commit
```

从图中可以看到，执行git reflog 命令后，显示出来了很多行记录。

> 每行记录都由版本号（commit id SHA），HEAD值和操作描述三部分组成。版本号在第一列，HEAD值在第二列，操作描述信息在第三列。

* 版本号
在之前都有提到，标识着每一次提交、合并等操作时的版本，相当于唯一标识
* HEAD值
同样用来标识版本，但是不同于版本号的是，Head值是相对的。
当HEAD值为HEAD时，表示为提交的最新版本；HEAD^ 表示为最新版本的上一个版本；HEAD^^表示为最新版本的上上个版本；HEAD~100表示为最新版本的往上第100个版本。
> HEAD值越小，表示版本越新，越大表示版本生成时间越久。

在上面图中，我们发现HEAD值的展示形式为HEAD@{0}、HEAD@{1}、HEAD@{2}…同样HEAD值的数字越小，表示版本越新，数字越大表示版本越旧。

* 操作描述
记录了本次是哪种操作，以及操作时编写的描述信息。
##### 4.2 查看历史版本记录–指定显示条数
同时，与git log相同的是，git reflog也提供了控制显示条数的选项：
命令：git reflog -n
执行命令后如图：
![图片](https://img-blog.csdnimg.cn/20181114102218113.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxNDQ2MjgyNDEy,size_16,color_FFFFFF,t_70)

```sh
DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (feature/test1)
$ git reflog -3
dab39f4 HEAD@{0}: checkout: moving from master to feature/test1
77dfdff HEAD@{1}: checkout: moving from feature/test1 to master
dab39f4 HEAD@{2}: commit: third commit

DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (feature/test1)
$
```
如图所示，这里设置显示条数为3条，执行命令后，显示的条数为指定的条数3条。
![图片](https://img-blog.csdnimg.cn/20181114102331783.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxNDQ2MjgyNDEy,size_16,color_FFFFFF,t_70)

```sh
DH207891+OuyangPeng@DH207891 MINGW32 /f/git test (feature/test1)
$ git reflog -6
dab39f4 HEAD@{0}: checkout: moving from master to feature/test1
77dfdff HEAD@{1}: checkout: moving from feature/test1 to master
dab39f4 HEAD@{2}: commit: third commit
77dfdff HEAD@{3}: checkout: moving from master to feature/test1
77dfdff HEAD@{4}: commit: second commit
363a197 HEAD@{5}: commit (initial): first commit
```

如图所示，这里设置显示条数为6条，执行命令后，显示的条数为指定的条数6条。

转载请保留原文地址：https://blog.csdn.net/qq446282412/article/details/84061662


