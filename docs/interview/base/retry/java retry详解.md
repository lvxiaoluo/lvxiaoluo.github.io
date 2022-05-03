# [java retry:详解](https://www.cnblogs.com/captainad/p/10931314.html)

# 发现

今天在探秘线程池原理知识点，在阅读JDK源码时遇到程序代码中出现如下代码，因为之前没有遇到过，于是特地记录下来并谷歌了一番，后面我自己做了一些简要的验证和分析。

![img](https://img2018.cnblogs.com/blog/1684605/201905/1684605-20190527161629133-279455281.png)

# 验证

网上溜达一番发现，**这retry就是一个标记，标记对一个循环方法的操作（continue和break）处理点，功能类似于goto，所以retry一般都是伴随着for循环出现，retry:标记的下一行就是for循环，在for循环里面调用continue（或者break）再紧接着retry标记时，就表示从这个地方开始执行continue（或者break）操作**，具体我们来看看下面的例子：

1、使用continue跳出循环的操作：

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
 1 public static void testContinue() {
 2     retry:
 3     for(int i = 0; i < 3; i++) {
 4         for(int j = 0; j < 5; j++) {
 5             System.out.print(j + ", ");
 6             if(j == 3) {
 7                 continue retry;
 8             }
 9         }
10     }
11     System.out.print(" >>> OK");
12 }
13 // 输出：0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3,  >>> OK
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

2、使用breank跳出循环的操作：

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
 1 public static void testBreak() {
 2     retry:
 3     for(int i = 0; i < 3; i++) {
 4         for(int j = 0; j < 5; j++) {
 5             System.out.print(j + ", ");
 6             if(j == 3) {
 7                 break retry;
 8             }
 9         }
10     }
11     System.out.print(" >>> OK");
12 }
13 // 输出：0, 1, 2, 3,  >>> OK
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

从上面的两个例子可以看出，在内层循环里面调用continue（或者break）后接着retry标识符，程序直接转到最外层for循环去处理了。

# 揭秘

我多想了一下，这个retry标记的使用原理是什么样的？于是我扒了扒上面程序的**反编译代码**，希望能够从中找到答案：

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
 1 public static void testContinue()
 2   {
 3     for (int i = 0; i < 3; i++) {
 4       for (int j = 0; j < 5; j++)
 5       {
 6         System.out.print(j + ", ");
 7         if (j == 3) {
 8           break;
 9         }
10       }
11     }
12     System.out.print(" >>> OK");
13   }
14 
15 public static void testBreak()
16   {
17     for (int i = 0; i < 3; i++) {
18       for (int j = 0; j < 5; j++)
19       {
20         System.out.print(j + ", ");
21         if (j == 3) {
22           break label59;
23         }
24       }
25     }
26     label59:
27     System.out.print(" >>> OK");
28   }
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

很明显，编译的时候**编译器**自动按照程序逻辑转换成了我们日常使用的方式来处理，比如continue的语句则翻译成了break，而下面的break方法同样使用了标记位，只是顺序不同了而已，这和程序执行的逻辑顺序应该是有关系的，显然编译器很聪明，如果你不加for循环下面的那一个关于OK的打印语句，编译器就直接把break retry；转换成了return；语句，说明编译器已经知道在这里根据逻辑来判断和处理了。

# 启发

这一个标记的作用，给了我们一点点启发，因为平时好像都没有怎么见到过这个使用方法，但是类似跳出多重循环的场景却不在少数，看看以前我们都是怎么样处理的。

1、跳出里面的for循环，继续从外面for循环开始执行：

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
 1 public static void testContinueR() {
 2     for(int i = 0; i < 3; i++) {
 3         for(int j = 0; j < 5; j++) {
 4             System.out.print(j + ", ");
 5             if(j == 3) {
 6                 break;
 7             }
 8         }
 9     }
10 }
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

使用break直接结束里面这一层循环，然后从外出for循环继续开始。

2、跳出里外两层循环，直接往下执行逻辑：

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
 1 public static void testBreakR() {
 2     boolean flag = false;
 3     for(int i = 0; i < 3; i++) {
 4         for(int j = 0; j < 5; j++) {
 5             System.out.print(j + ", ");
 6             if(j == 3) {
 7                 flag = true;
 8                 break;
 9             }
10         }
11         if(flag) {
12             break;
13         }
14     }
15     System.out.println(" >>> OK");
16 }
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

其实这里有两种情况，如果for循环后面没有内容了，可以直接在最里层循环执行return语句，如果后面还有其他逻辑执行，那么可以使用标记位辅助。

# 总结

如果你现在积累到了这个retry标记的用法，这个地方就可以更加灵活的处理了，可以不用写那么多的辅助代码，还有一点需要提一下，其实这个retry标识符不是指定的，只要**任意符合Java变量命名的标识符都可以**，只要后面接上英文冒号就行了。

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
 1 public static void testOtherFlag() {
 2     abc:
 3     for(int i = 0; i < 3; i++) {
 4         for(int j = 0; j < 5; j++) {
 5             System.out.print(j + ", ");
 6             if(j == 3) {
 7                 break abc;
 8             }
 9         }
10     }
11 }
12 
13 // 输出：0, 1, 2, 3, 
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

其实和goto有同样争议的是，在过于复杂的循环程序里面使用这个标记，**可能会降低程序的可读性**，所以在使用之前，还是需要自己权衡。