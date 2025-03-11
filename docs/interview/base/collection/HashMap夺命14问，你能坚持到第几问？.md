# HashMap夺命14问，你能坚持到第几问？

**1. HashMap的底层数据结构是什么？**



在JDK1.7中和JDK1.8中有所区别：



在JDK1.7中，由”数组+链表“组成，数组是HashMap的主体，链表则是主要为了解决哈希冲突而存在的。



在JDK1.8中，有“数组+链表+红黑树”组成。当链表过长，则会严重影响HashMap的性能，红黑树搜索时间复杂度是O(logn)，而链表是O(n)。因此，JDK1.8对数据结构做了进一步的优化，引入了红黑树，链表和红黑树在达到一定条件会进行转换：



- 当链表超过8且数组长度(数据总量)超过64才会转为红黑树
- 将链表转换成红黑树前会判断，如果当前数组的长度小于64，那么会选择先进行数组扩容，而不是转换为红黑树，以减少搜索时间。



![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)



**2. 说一下HashMap的特点**



- hashmap存取是无序的
- 键和值位置都可以是null，但是键位置只能是一个null
- 键位置是唯一的，底层的数据结构是控制键的
- jdk1.8前数据结构是：链表+数组jdk1.8之后是：数组+链表+红黑树
- 阈值（边界值）>8并且数组长度大于64，才将链表转换成红黑树，变成红黑树的目的是提高搜索速度，高效查询



**3. 解决hash冲突的办法有哪些?HashMap用的哪种？**



解决Hash冲突方法有：开放定址法、再哈希法、链地址法（HashMap中常见的拉链法）、简历公共溢出区。HashMap中采用的是链地址法。



- 开放定址法也称为再散列法，基本思想就是，如果p=H(key)出现冲突时，则以p为基础，再次hash，p1=H(p)，如果p1再次出现冲突，则以p1为基础，以此类推，直到找到一个不冲突的哈希地址pi。因此开放定址法所需要的hash表的长度要大于等于所需要存放的元素，而且因为存在再次hash，所以只能在删除的节点上做标记，而不能真正删除节点
- 再哈希法（双重散列，多重散列），提供多个不同的hash函数，R1=H1(key1)发生冲突时，再计算R2=H2（key1），直到没有冲突为止。这样做虽然不易产生堆集，但增加了计算的时间。
- 链地址法（拉链法），将哈希值相同的元素构成一个同义词的单链表，并将单链表的头指针存放在哈希表的第i个单元中，查找、插入和删除主要在同义词链表中进行，链表法适用于经常进行插入和删除的情况。
- 建立公共溢出区，将哈希表分为公共表和溢出表，当溢出发生时，将所有溢出数据统一放到溢出区



注意开放定址法和再哈希法的区别是



- 开放定址法只能使用同一种hash函数进行再次hash，再哈希法可以调用多种不同的hash函数进行再次hash



**4. 为什么要在数组长度大于64之后，链表才会进化为红黑树**



在数组比较小时如果出现红黑树结构，反而会降低效率，而红黑树需要进行左旋右旋，变色，这些操作来保持平衡，同时数组长度小于64时，搜索时间相对要快些，总之是为了加快搜索速度，提高性能



JDK1.8以前HashMap的实现是数组+链表，即使哈希函数取得再好，也很难达到元素百分百均匀分布。当HashMap中有大量的元素都存放在同一个桶中时，这个桶下有一条长长的链表，此时HashMap就相当于单链表，假如单链表有n个元素，遍历的时间复杂度就从O（1）退化成O（n），完全失去了它的优势，为了解决此种情况，JDK1.8中引入了红黑树（查找的时间复杂度为O（logn））来优化这种问题



**5. 为什么加载因子设置为0.75，初始化临界值是12？**



HashMap中的threshold是HashMap所能容纳键值对的最大值。计算公式为length*LoadFactory。也就是说，在数组定义好长度之后，负载因子越大，所能容纳的键值对个数也越大



loadFactory越趋近于1，那么数组中存放的数据（entry也就越来越多），数据也就越密集，也就会有更多的链表长度处于更长的数值，我们的查询效率就会越低，当我们添加数据，产生hash冲突的概率也会更高



默认的loadFactory是0.75，loadFactory越小，越趋近于0，数组中个存放的数据(entry)也就越少，表现得更加稀疏



![图片](https://mmbiz.qpic.cn/mmbiz_png/icu8ekKAcwiaZRHBe71W4uXSBHkAx4YaZib6ScWoXkkzq3mIUD5EicZLe7MHewzyw3xjxKCPeDIMTcLd4Coiah153Pg/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)



0.75是对空间和时间效率的一种平衡选择



如果负载因子小一些比如是0.4，那么初始长度16*0.4=6，数组占满6个空间就进行扩容，很多空间可能元素很少甚至没有元素，会造成大量的空间被浪费



如果负载因子大一些比如是0.9，这样会导致扩容之前查找元素的效率非常低



loadfactory设置为0.75是经过多重计算检验得到的可靠值，可以最大程度的减少rehash的次数，避免过多的性能消耗



**6. 哈希表底层采用何种算法计算hash值？还有哪些算法可以计算出hash值？**



hashCode方法是Object中的方法，所有的类都可以对其进行使用，首先底层通过调用hashCode方法生成初始hash值h1，然后将h1无符号右移16位得到h2，之后将h1与h2进行按位异或（^）运算得到最终hash值h3，之后将h3与(length-1)进行按位与（&）运算得到hash表索引



其他可以计算出hash值的算法有



- 平方取中法
- 取余数
- 伪随机数法



**7. 当两个对象的hashCode相等时会怎样**



hashCode相等产生hash碰撞，hashCode相等会调用equals方法比较内容是否相等，内容如果相等则会进行覆盖，内容如果不等则会连接到链表后方，链表长度超过8且数组长度超过64，会转变成红黑树节点



**8. 何时发生哈希碰撞和什么是哈希碰撞，如何解决哈希碰撞****？**



只要两个元素的key计算的hash码值相同就会发生hash碰撞，jdk8之前使用链表解决哈希碰撞，jdk8之后使用链表+红黑树解决哈希碰撞



**9. HashMap的put方法流程**



以jdk8为例，简要流程如下：



- 首先根据key的值计算hash值，找到该元素在数组中存储的下标
- 如果数组是空的，则调用resize进行初始化；
- 如果没有哈希冲突直接放在对应的数组下标里
- 如果冲突了，且key已经存在，就覆盖掉value
- 如果冲突后是链表结构，就判断该链表是否大于8，如果大于8并且数组容量小于64，就进行扩容；如果链表节点数量大于8并且数组的容量大于64，则将这个结构转换成红黑树；否则，链表插入键值对，若key存在，就覆盖掉value
- 如果冲突后，发现该节点是红黑树，就将这个节点挂在树上

![图片](https://mmbiz.qpic.cn/mmbiz_png/icu8ekKAcwiaZRHBe71W4uXSBHkAx4YaZibHdlf6wes9X51OWH1AocFNuHaPSCCDEsdIO4FpPKnPFnuyfkCXJovtA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)





**10. HashMap的扩容方式**



HashMap在容量超过负载因子所定义的容量之后，就会扩容。java里的数组是无法自己扩容的，将HashMap的大小扩大为原来数组的两倍



我们来看jdk1.8扩容的源码

```java
final Node<K,V>[] resize() {
        //oldTab：引用扩容前的哈希表
        Node<K,V>[] oldTab = table;
        //oldCap：表示扩容前的table数组的长度
        int oldCap = (oldTab == null) ? 0 : oldTab.length;
        //获得旧哈希表的扩容阈值
        int oldThr = threshold;
        //newCap:扩容之后table数组大小
        //newThr:扩容之后下次触发扩容的条件
        int newCap, newThr = 0;
        //条件成立说明hashMap中的散列表已经初始化过了，是一次正常扩容
        if (oldCap > 0) {
            //判断旧的容量是否大于等于最大容量，如果是，则无法扩容，并且设置扩容条件为int最大值，
            //这种情况属于非常少数的情况
            if (oldCap >= MAXIMUM_CAPACITY) {
                threshold = Integer.MAX_VALUE;
                return oldTab;
            }//设置newCap新容量为oldCap旧容量的二倍（<<1）,并且<最大容量，而且>=16，则新阈值等于旧阈值的两倍
            else if ((newCap = oldCap << 1) < MAXIMUM_CAPACITY &&
                     oldCap >= DEFAULT_INITIAL_CAPACITY)
                newThr = oldThr << 1; // double threshold
        }
        //如果oldCap=0并且边界值大于0，说明散列表是null，但此时oldThr>0
        //说明此时hashMap的创建是通过指定的构造方法创建的,新容量直接等于阈值
        //1.new HashMap(intitCap,loadFactor)
        //2.new HashMap(initCap)
        //3.new HashMap(map)
        else if (oldThr > 0) // initial capacity was placed in threshold
            newCap = oldThr;
        //这种情况下oldThr=0;oldCap=0，说明没经过初始化，创建hashMap
        //的时候是通过new HashMap()的方式创建的
        else {               // zero initial threshold signifies using defaults
            newCap = DEFAULT_INITIAL_CAPACITY;
            newThr = (int)(DEFAULT_LOAD_FACTOR * DEFAULT_INITIAL_CAPACITY);
        }
        //newThr为0时，通过newCap和loadFactor计算出一个newThr
        if (newThr == 0) {
            //容量*0.75
            float ft = (float)newCap * loadFactor;
            newThr = (newCap < MAXIMUM_CAPACITY && ft < (float)MAXIMUM_CAPACITY ?
                      (int)ft : Integer.MAX_VALUE);
        }
        threshold = newThr;
        @SuppressWarnings({"rawtypes","unchecked"})
                //根据上面计算出的结果创建一个更长更大的数组
            Node<K,V>[] newTab = (Node<K,V>[])new Node[newCap];
        //将table指向新创建的数组
        table = newTab;
        //本次扩容之前table不为null
        if (oldTab != null) {
            //对数组中的元素进行遍历
            for (int j = 0; j < oldCap; ++j) {
                //设置e为当前node节点
                Node<K,V> e;
                //当前桶位数据不为空，但不能知道里面是单个元素，还是链表或红黑树，
                //e = oldTab[j]，先用e记录下当前元素
                if ((e = oldTab[j]) != null) {
                    //将老数组j桶位置为空，方便回收
                    oldTab[j] = null;
                    //如果e节点不存在下一个节点，说明e是单个元素，则直接放置在新数组的桶位
                    if (e.next == null)
                        newTab[e.hash & (newCap - 1)] = e;
                    //如果e是树节点，证明该节点处于红黑树中
                    else if (e instanceof TreeNode)
                        ((TreeNode<K,V>)e).split(this, newTab, j, oldCap);
                    //e为链表节点，则对链表进行遍历
                    else { // preserve order
                        //低位链表：存放在扩容之后的数组的下标位置，与当前数组下标位置一致
                        //loHead：低位链表头节点
                        //loTail低位链表尾节点
                        Node<K,V> loHead = null, loTail = null;
                        //高位链表，存放扩容之后的数组的下标位置，=原索引+扩容之前数组容量
                        //hiHead:高位链表头节点
                        //hiTail:高位链表尾节点
                        Node<K,V> hiHead = null, hiTail = null;
                        Node<K,V> next;
                        do {
                            next = e.next;
                            //oldCap为16:10000，与e.hsah做&运算可以得到高位为1还是0
                            //高位为0，放在低位链表
                            if ((e.hash & oldCap) == 0) {
                                if (loTail == null)
                                    //loHead指向e
                                    loHead = e;
                                else
                                    loTail.next = e;
                                loTail = e;
                            }
                            //高位为1，放在高位链表
                            else {
                                if (hiTail == null)
                                    hiHead = e;
                                else
                                    hiTail.next = e;
                                hiTail = e;
                            }
                        } while ((e = next) != null);
                        //低位链表已成，将头节点loHead指向在原位
                        if (loTail != null) {
                            loTail.next = null;
                            newTab[j] = loHead;
                        }
                        //高位链表已成，将头节点指向新索引
                        if (hiTail != null) {
                            hiTail.next = null;
                            newTab[j + oldCap] = hiHead;
                        }
                    }
                }
            }
        }
        return newTab;
    }
````

扩容之后原位置的节点只有两种调整



- 保持原位置不动（新bit位为0时）
- 散列原索引+扩容大小的位置去（新bit位为1时）



扩容之后元素的散列设置的非常巧妙，节省了计算hash值的时间，我们来看一 下具体的实现

![图片](https://mmbiz.qpic.cn/mmbiz_png/icu8ekKAcwiaZRHBe71W4uXSBHkAx4YaZibc1yrY9mrP6ziaIxRlJroiajDHNibSjsibV8qgP6ScAU1qVKSPOJrnNM8jg/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)



当数组长度从16到32，其实只是多了一个bit位的运算，我们只需要在意那个多出来的bit为是0还是1，是0的话索引不变，是1的话索引变为当前索引值+扩容的长度，比如5变成5+16=21

![图片](https://mmbiz.qpic.cn/mmbiz_png/icu8ekKAcwiaZRHBe71W4uXSBHkAx4YaZibicyicq3WjIuwkJXyS0WUheSqECAIsAYO8Mr2VMpRL7YI4rC6WWc9f8EA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

这样的扩容方式不仅节省了重新计算hash的时间，而且保证了当前桶中的元素总数一定小于等于原来桶中的元素数量，避免了更严重的hash冲突，均匀的把之前冲突的节点分散到新的桶中去



**11. 一般用什么作为HashMap的key？**



一般用Integer、String这种不可变类当HashMap当key



- 因为String是不可变的，当创建字符串时，它的hashcode被缓存下来，不需要再次计算，相对于其他对象更快
- 因为获取对象的时候要用到equals()和hashCode()方法，那么键对象正确的重写这两个方法是非常重要的，这些类很规范的重写了hashCode()以及equals()方法



**12. 为什么Map桶中节点个数超过8才转为红黑树？**



8作为阈值作为HashMap的成员变量，在源码的注释中并没有说明阈值为什么是8



在HashMap中有这样一段注释说明，我们继续看

```
 * Because TreeNodes are about twice the size of regular nodes, we
 * use them only when bins contain enough nodes to warrant use
 * (see TREEIFY_THRESHOLD). And when they become too small (due to
 * removal or resizing) they are converted back to plain bins.  In
 * usages with well-distributed user hashCodes, tree bins are
 * rarely used.  Ideally, under random hashCodes, the frequency of
 * nodes in bins follows a Poisson distribution
 * (http://en.wikipedia.org/wiki/Poisson_distribution) with a
 * parameter of about 0.5 on average for the default resizing
 * threshold of 0.75, although with a large variance because of
 * resizing granularity. Ignoring variance, the expected
 * occurrences of list size k are (exp(-0.5) * pow(0.5, k) /
 * factorial(k)).
```



翻译
```

因为树节点的大小大约是普通节点的两倍，所以我们只在箱子包含足够的节点时才使用树节点（参见TREEIFY_THRESHOLD）。
当他们边的太小（由于删除或调整大小）时，就会被转换回普通的桶，在使用分布良好的hashcode时，很少使用树箱。
理想情况下，在随机哈希码下，箱子中节点的频率服从泊松分布
第一个值是：

 * 0:    0.60653066
 * 1:    0.30326533
 * 2:    0.07581633
 * 3:    0.01263606
 * 4:    0.00157952
 * 5:    0.00015795
 * 6:    0.00001316
 * 7:    0.00000094
 * 8:    0.00000006
 * more: less than 1 in ten million
```
树节点占用空间是普通Node的两倍，如果链表节点不够多却转换成红黑树，无疑会耗费大量的空间资源，并且在随机hash算法下的所有bin节点分布频率遵从泊松分布，链表长度达到8的概率只有0.00000006，几乎是不可能事件，所以8的计算是经过重重科学考量的



- 从平均查找长度来看，红黑树的平均查找长度是logn，如果长度为8，则logn=3，而链表的平均查找长度为n/4，长度为8时，n/2=4，所以阈值8能大大提高搜索速度
- 当长度为6时红黑树退化为链表是因为logn=log6约等于2.6，而n/2=6/2=3，两者相差不大，而红黑树节点占用更多的内存空间，所以此时转换最为友好



**13. HashMap为什么线程不安全？**



- 多线程下扩容死循环。JDK1.7中的HashMap使用头插法插入元素，在多线程的环境下，扩容的时候有可能导致环形链表的出现，形成死循环。因此JDK1.8使用尾插法插入元素，在扩容时会保持链表元素原本的顺序，不会出现环形链表的问题
- 多线程的put可能导致元素的丢失。多线程同时执行put操作，如果计算出来的索引位置是相同的，那会造成前一个key被后一个key覆盖，从而导致元素的丢失。此问题在JDK1.7和JDK1.8中都存在
- put和get并发时，可能导致get为null。线程1执行put时，因为元素个数超出threshold而导致rehash，线程2此时执行get，有可能导致这个问题，此问题在JDK1.7和JDK1.8中都存在



**14. 计算hash值时为什么要让低16bit和高16bit进行异或处理**



- 我们计算索引需要将hashCode值与length-1进行按位与运算，如果数组长度很小，比如16，这样的值和hashCode做异或实际上只有hashCode值的后4位在进行运算，hash值是一个随机值，而如果产生的hashCode值高位变化很大，而低位变化很小，那么有很大概率造成哈希冲突，所以我们为了使元素更好的散列，将hash值的高位也利用起来\

**为什么要右移16位？**

* 其实是为了减少碰撞，进一步降低hash冲突的几率。int类型的数值是4个字节的，右移16位异或可以同时保留高16位于低16位的特征

**为什么要异或运算?**

* 首先将高16位无符号右移16
位与低十六位做异或运算。如果不这样做，而是直接做&运算那么高十六位所代表的部分特征就可能被丢失 将高十六位无符号右移之后与低十六位做异或运算使得高十六位的特征与低十六位的特征进行了混合得到的新的数值中就高位与低位的信息都被保留了 ，而在这里采用异或运算而不采用& ，| 运算的原因是 异或运算能更好的保留各部分的特征，如果采用&运算计算出来的值会向1靠拢，采用|运算计算出来的值会向0靠拢
```
if ((p = tab[i = (n - 1) & hash]) == null)
            tab[i] = newNode(hash, key, value, null);
```
if ((p = tab[i = (n - 1) & hash]) == null)
            tab[i] = newNode(hash, key, value, null);

总结：
(n-1)&hash判断元素存放的位置，n-1等于数组的长度，与运算相当于取余运算(计算速度大于取余运算)
假如不做右移运算，那么hash仅是最后四位和1111运算(假如数组长度为16)那么hash高位的信息就会全部丢失（比如如果有多个key.hashcode最后四位都是0000那么就会全部存储在索引为0的桶中产生碰撞），如果右移16位就会将高位的信息与低位的16位异或运算，保留了高位与低位的特征更能体现key.hashcode的特征，降低冲突的概率。
主要目的：上面提到的所有问题，最终目的还是为了让哈希后的结果更均匀的分布，减少哈希碰撞，提升hashmap的运行效率

举个例子



如果我们不对hashCode进行按位异或，直接将hash和length-1进行按位与运算就有可能出现以下的情况



![图片](https://mmbiz.qpic.cn/mmbiz_png/icu8ekKAcwiaZRHBe71W4uXSBHkAx4YaZibWy78iau0ibhpicoBP7Y8em1gicNz7qiaDv1OicDqFZHj5pEKPzCHQ0XIa8Sw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)



如果下一次生成的hashCode值高位起伏很大，而低位几乎没有变化时，高位无法参与运算



![图片](https://mmbiz.qpic.cn/mmbiz_png/icu8ekKAcwiaZRHBe71W4uXSBHkAx4YaZibYBqjspBibeRRWlc5dkOu3MaHtEXe2mQV5JXVQ5ajRuI4vsfltDLrHkQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)



可以看到，两次计算出的hash相等，产生了hash冲突



所以无符号右移16位的目的是使高混乱度地区与地混乱度地区做一个中和，提高低位的随机性，减少哈希冲突。