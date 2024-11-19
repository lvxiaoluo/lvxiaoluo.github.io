## python 介绍与安装
Python 官方文档
> https://www.python.org/doc/

Pip
> https://pip.pypa.io/cn/stable/installing

### 基本数据类型
数据类型
    整数int 8
    浮点数float 8.8
    字符串(str) "8" "Python"
    布尔值(bool) True False


网络带宽计算器案例
【比特】 bit 线路速度的计算单位
     计算机存储数据的单位 byte 【字节】

我们经常要估算一个文档要多久能传输完成，可以写一个计算器来计算传输时间。


序列
是指它的成员都是有序排列，并且可以通过下标偏移量访问到它的一个或几个成员
 字符串、列表、元组三种类型都属于序列
    字符串 "abcd"
    列表 ["0","abcd"]  可变更
    元组 ("abcd","def") 不可变更
序列的基本操作
成员关系操作符（in 、not it）-> 对象[not] in 序列
连接操作符(+) -> 序列 + 序列
重复操作符(*) -> 序列 * 整数
切片操作符([:]) -> 序列[0:整数]


条件判断：if
if语句
    关键字
    判断条件表达式
    判断为真时的代码块

```python
if 表达式:
    代码块
```



if 语句还可以和else、elif(else-if) 语句组合构成更复杂的判断
```python
    if表达式：
      代码块
    elif 表达式
      代码块
    else:
      代码块
```
    

循环语句
    while语句  for语句
```python
while 表达式:
    代码块
```


```python
for 迭代变量in可迭代对象:
    代码块 
```


映射的类型：字典
    字典包含哈希值和指向的对象
    {"哈希值":"对象"}
    {'length':180,'width':80}


文件内建函数和方法
    open() 打开文件
    read() 输入
    readline() 输入一行
    seek() 文件内移动
    write() 输出
    close() 关闭文件

