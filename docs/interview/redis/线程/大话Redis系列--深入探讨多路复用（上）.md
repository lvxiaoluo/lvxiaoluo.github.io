# 大话Redis系列--深入探讨多路复用（上）

今天让我们一起来探讨一下多路复用在redis中的具体实现原理。

> **Redis客户端和服务端的连接访问介绍**

之前的文章中我们有稍微提到过，Redis的客户端和服务端之间是通过resp协议进行链接通信的。这种通信的本质其实是借助了socket套接字进行网络连接。如下图所示：

![图片](https://mmbiz.qpic.cn/mmbiz_png/48MFTQpxichlcqsM4YgiaZl8RYx174IJ3zibfialdRSaR0IhBHfV4HpSUXn2PWme6iah9VxZ4dC2cic4FVgsiaYg7LljA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

当客户端的jedis和redis服务器进行连接的时候，首先需要在对应操作系统的内核中建立连接，接着才会将对应的链接分配到指定的redis服务端程序当中。假设redis采用了默认的6379端口，那么对应的链接请求就会发送到对应的进程上。



**如何理解多路复用**

当请求处理完毕之后，这一整条的链接链路不会立马断开，而为维持长链接的状态，方便后续继续传输数据使用。

为了方便大家对于多路复用能有个更好的认识，我们接下来通过一段Java程序来认识多路复用的实际应用案例。

> **Java模拟实现服务端链接**

这是一段非常简单的BIO程序，大概思路便是接纳外界链接请求，然后打印数据到控制台。

```java
package org.idea.iedis.framework.server.io.core;

import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;

/**
 * @Author linhao
 * @Date created in 11:16 上午 2021/8/15
 */
public class BioServer {

    public static void main(String[] args) throws IOException {
        ServerSocket serverSocket = new ServerSocket(6378);
        while (true) {
            System.out.println("wait conn --------");
            Socket socket = serverSocket.accept();
            System.out.println("conn ok ---------");
            byte[] bytes = new byte[1024];
            System.out.println("wait data ---------");
            socket.getInputStream().read(bytes);
            System.out.printf("data is {}" + new String(bytes));
        }
    }
}
```

测试的方式我采用了nc命令进行模拟：
```shell
【idea @ Mac】>>>>>>nc localhost 6378a
```

当请求到达服务端的时候，也会在控制台有所打印输出：

![图片](https://mmbiz.qpic.cn/mmbiz_png/48MFTQpxichlcqsM4YgiaZl8RYx174IJ3zmFNJrLib7JReBJLUp1U7Qd7icwdiaB3Rn2uYXiaFPcrAReaBAQGL3Le86w/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)



**上边代码的哪些点是堵塞的位置？**

- 
- 

```java
serverSocket.accept(); //堵塞部分socket.getInputStream().read(bytes); //堵塞部分
```

我们通过实操可以发现，在accept的位置会出现第一次堵塞的情况，当没有外界连接接入的时候，程序就会堵塞在该位置。

第二次堵塞的位置是在read函数调用的位置，当连接建立之后，服务端会一直等待客户端发送的数据请求，因此一直处于等待状况。



**如果第一个连接建立之后迟迟不发送数据，后续又有第二个连接接入会出现什么问题？**

为了模拟这个场景，我们来看下以下测试案例：



首先是服务端程序的部分改造，对于客户端的请求，我这里新增了一个handleData函数，用于模拟处理数据时候的堵塞情况（耗时大约为2秒左右）

```java
package org.idea.iedis.framework.server.io.core;

import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;

/**
 * @Author linhao
 * @Date created in 11:16 上午 2021/8/15
 */
public class BioServer {

    public static void main(String[] args) throws IOException {
        ServerSocket serverSocket = new ServerSocket(6378);
        while (true) {
            System.out.println("wait conn --------");
            Socket socket = serverSocket.accept();
            System.out.println("conn ok --------- " + System.currentTimeMillis());
            byte[] bytes = new byte[1024];
            System.out.println("wait data ---------");
            socket.getInputStream().read(bytes);
            handleData();
            System.out.printf("data is {}" + new String(bytes));
        }
    }

    /**
     * 处理数据信息
     */
    public static void handleData(){
        System.out.println("handling data begin ----------");
        try {
            Thread.sleep(2000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println("handling data end ----------");
    }
}
```

接着便是客户端部分的模拟，模拟五个客户端的连接服务端，并且发送数据：

```java

package org.idea.iedis.framework.server.io.core;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.util.concurrent.Executors;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

/**
 * @Author linhao
 * @Date created in 11:17 上午 2021/8/15
 */
public class BioClient {

    public static final ThreadPoolExecutor threadPoolExecutor = new ThreadPoolExecutor(2, 5,
            0L, TimeUnit.MILLISECONDS,
            new LinkedBlockingQueue<Runnable>());

    public static void main(String[] args) {
        for (int i = 0; i < 5; i++) {
            Thread t = new Thread(new Runnable() {
                @Override
                public void run() {
                    Socket socket = new Socket();
                    try {
                        socket.connect(new InetSocketAddress("localhost", 6378));
                        socket.getOutputStream().write("this is test".getBytes());
                        System.out.println("send data -----------" + System.currentTimeMillis());
                        socket.close();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            });
            threadPoolExecutor.submit(t);
        }
        Thread.yield();
    }
}
```

通过请求的日志记录可以发现，服务端对于数据的处理时间点如下：

![图片](https://mmbiz.qpic.cn/mmbiz_png/48MFTQpxichlcqsM4YgiaZl8RYx174IJ3z9EoDP3tqzlOn0aXYaSPOibNtZAusLEaxic3nmw7Sj2TRicN4hjhZKichmQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

也就是说当上一个连接在处理请求的时候，下一个连接发送的数据会处于一个就绪状态，单线程依次执行。



> **多线程异步等待模型改造**

将服务端处理线程请求的模块开启单独的线程进行处理。

服务端程序进行改造：
```java

package org.idea.iedis.framework.server.io.core;

import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;

/**
 * @Author linhao
 * @Date created in 11:16 上午 2021/8/15
 */
public class BioServer {

    public static void main(String[] args) throws IOException {
        ServerSocket serverSocket = new ServerSocket(6378);
        while (true) {
            System.out.println("wait conn --------");
            Socket socket = serverSocket.accept();
            System.out.println("conn ok --------- " + System.currentTimeMillis());
            byte[] bytes = new byte[1024];
            System.out.println("wait data ---------");
            socket.getInputStream().read(bytes);
            Thread t = new Thread(new Runnable() {
                @Override
                public void run() {
                    handleData();
                }
            });
            t.start();
            System.out.printf("data is {}" + new String(bytes));
        }
    }

    /**
     * 处理数据信息
     */
    public static void handleData(){
        System.out.println("handling data begin ----------");
        try {
            Thread.sleep(2000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println("handling data end ----------");
    }
}
```

此时控制台打印出来的结果如下所示：

![图片](https://mmbiz.qpic.cn/mmbiz_png/48MFTQpxichlcqsM4YgiaZl8RYx174IJ3zaDJlqEz9deH7JibzPkvLzTpc4Ag06lksHIENT3ulIump2IEZopZkacg/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

看起来似乎是请求处理的效率变高了，但是实际上这种方案对于性能的开销是比较大的。

- 假设我们同时有1000个请求发送过来，那么服务端就得启动1000个线程处理。
- 假设建立了1000个连接，但是其中只有10条连接发送了数据，那么这个开销从利用率来说更加不划算。

> 其实在tomcat7之前，其服务端的程序一直都是采用bio的模式来进行处理请求数据，每次发送请求之后都需要额外创建一个线程处理数据，因此其并发处理能力并不友好。

**改善思路**

- 当没有建立服务端连接的时候，accept函数调用的时候不要出现阻塞，而是直接跳过。
- 在没有数据抵达服务端的时候，read函数调用采用非阻塞的方式执行。



有了这两个思路点之后，我们再来深入思考：

**假设我们是jdk的开发者，需要对现有的代码做怎样的调整？**

这里分享一下我自己的思路：

首先ServerSocket是一个已经存在于JDK内部的对象，而且不建议随意对已有的api进行调整，否则会对业界使用者造成一个不兼容的情况。

因此不妨可以通过一些setter方法去修改阻塞的设置项：

![图片](https://mmbiz.qpic.cn/mmbiz_png/48MFTQpxichmTZRDJkLtx9AeXgLPABiamfCOyYvEcehB0psicJIrhXmrEqlBYnt0NE7LX3SrkTY3WY3UpEKFS0pAQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)



来看看实际JDK开发者是如何改良这部分设计的：

首先是使用nio搭建一个简单的服务端代码案例：

```java
package org.idea.iedis.framework.server.io.core.nio;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.util.ArrayList;
import java.util.List;

/**
 * @Author linhao
 * @Date created in 8:41 上午 2021/8/16
 */
public class NioServer {

    static ByteBuffer byteBuffer = ByteBuffer.allocate(1024);
    static List<SocketChannel> channelList = new ArrayList<>();

    public static void main(String[] args) throws IOException {
        ServerSocketChannel serverSocketChannel = ServerSocketChannel.open();
        SocketAddress socketAddress = new InetSocketAddress("localhost", 6666);
        serverSocketChannel.bind(socketAddress);
        serverSocketChannel.configureBlocking(false);

        //有点类似于poll模型
        while (true) {
            for (SocketChannel socketChannel : channelList) {
                int read = socketChannel.read(byteBuffer);
                if (read > 0) {
                    System.out.println("read ... " + read);
                    byteBuffer.flip();
                    byte[] bs = new byte[read];
                    byteBuffer.get(bs);
                    String content = new String(bs);
                    System.out.println(content);
                    byteBuffer.flip();
                }
            }

            SocketChannel accept = serverSocketChannel.accept();
            if (accept != null) {
                System.out.println("conn success -----");
                accept.configureBlocking(false);
                channelList.add(accept);
                System.out.println(channelList.size() + "---- list --- size");
            }
        }
    }
}
```

接着是基于这套服务端代码去编写相关的客户端程序脚本：

```java

package org.idea.iedis.framework.server.io.core.nio;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SocketChannel;

/**
 * @Author linhao
 * @Date created in 8:40 上午 2021/8/16
 */
public class NioClient {


    public static void main(String[] args) throws IOException, InterruptedException {
        SocketChannel socketChannel = SocketChannel.open();
        socketChannel.connect(new InetSocketAddress("localhost", 6666));
        socketChannel.configureBlocking(false);
        socketChannel.write(ByteBuffer.wrap("this is a test".getBytes()));
        System.out.println("-----");
    }

}
```

上边的这段代码总体的执行思路其实可以抽像化为以下模式：（假设有三个链接请求）
```java
select (3 sockets){
for(Socket socket: sockets) {
int read = socket.getInputStream();    
 if(read >0){  
     // 对应处理代码   
       } else {  
    // 对应处理代码  
       }  
  }
}
```

但是这样的代码我们在进行实际落地实现的时候不可能采用Java程序去实现，通常都是在os底层来进行封装，然后供高级语言去调用。



**思考：**

假设构建了100w条链接，那么对于这一批的链接采用暴力的list遍历方式去询问是否有新数据的写入就会显得效率异常低下。



改善点：

假设当我们建立好了链接请求之后，每个链接都会订阅某个事件，假设是有数据写入的时候，主动去发布这个事件，这样就能避免轮训操作了。



> **NIO内部如何解决多路复用机制**

从这个角度思考出发，我们一起来看下nio内部是如何实现多路复用机制的，

当有新的请求过来的时候，server会提前将accept事件委托给selector处理。

selector会根据连接的事件类型（例如read，write，accept）去通知到具体的socketserver。



来看看案例代码：

服务端新增一个selector代码
```java
package org.idea.iedis.framework.server.io.core.nio.selector;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.Set;

/**
 * @Author linhao
 * @Date created in 8:27 上午 2021/8/17
 */
public class NioSelectorServer {

    static ArrayList<SocketChannel> socketChannels = new ArrayList<>();
    static ByteBuffer byteBuffer = ByteBuffer.allocate(1024);

    public static void main(String[] args) throws IOException {
        ServerSocketChannel serverSocket = ServerSocketChannel.open();
        SocketAddress socketAddress = new InetSocketAddress("localhost", 6555);
        serverSocket.configureBlocking(false);
        serverSocket.bind(socketAddress);

        Selector selector = Selector.open();

        serverSocket.register(selector, SelectionKey.OP_ACCEPT);
        System.out.println("start select!");
        while (true) {
            selector.select();
            Set<SelectionKey> selectionKeys = selector.selectedKeys();
            Iterator<SelectionKey> iterator = selectionKeys.iterator();
            while (iterator.hasNext()) {
                SelectionKey selectionKey = iterator.next();
                if (selectionKey.isAcceptable()) {

                    SocketChannel socketChannel = serverSocket.accept();
                    socketChannel.configureBlocking(false);
                    socketChannel.register(selector, SelectionKey.OP_READ);
                    System.out.println("client is connected!");

                } else if (selectionKey.isReadable()) {

                    SocketChannel socketChannel = (SocketChannel) selectionKey.channel();
                    ByteBuffer byteBuffer = ByteBuffer.allocate(1024);
                    int len = socketChannel.read(byteBuffer);

                    if (len > 0) {
                        System.out.println("receive data!" + new String(byteBuffer.array(),0,len));
                    } else if (len == -1) {
                        System.out.println("client is close");
                        socketChannel.close();
                    }
                }
                iterator.remove();
            }
        }
    }

}
```

客户端向服务端发送数据的案例代码：
```java
package org.idea.iedis.framework.server.io.core.nio.selector;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SocketChannel;

/**
 * @Author linhao
 * @Date created in 8:53 上午 2021/8/17
 */
public class NioSelectorClient {

    public static void main(String[] args) throws IOException, InterruptedException {
        SocketChannel socketChannel = SocketChannel.open();
        socketChannel.connect(new InetSocketAddress("localhost",6555));
        socketChannel.configureBlocking(false);
        while (true) {
            System.out.println("client send data");
            socketChannel.write(ByteBuffer.wrap(("this is success " + Thread.currentThread().getName()).getBytes()));
            Thread.sleep(2500);
        }
    }
}
```

从上边服务端的程序案例可以看出，首先获取到链接之后，会将一个接收事件（accept）给注册到一个叫做selector的组件上。接下来后续这个链接如果有发送请求到数据过来就会被识别是read事件，此时selector再会去通知具体到服务线程处理。大概到思路如下图所示：



![图片](https://mmbiz.qpic.cn/mmbiz_png/48MFTQpxichkQQCUh8CSwyqN8ugdyJuibc5ffV6TpmcCyBgEMq07DBkYtNkI1hzw0lB41jcbOKk5WNuMQSK4iciaWw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)



**思考：**

**selector在进行select的时候，会发生什么情况？**

如果外界没有额外请求进入的话，那么select函数会进入一个堵塞等待的状态。看起来效果有些类似于bio的accept函数。



**selector调用open函数，它会发生了什么变化？**

我们对selector的open函数源代码进行深入挖掘，可以发现具体如下所示：

![图片](https://mmbiz.qpic.cn/mmbiz_png/48MFTQpxichkQQCUh8CSwyqN8ugdyJuibc9AwVabJCVMjkPUiapHpQlzZgEa6bSsPdIYoxQcce7SRuCICzhwT6eZw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

在其源代码的底部调用了JDK内部的sun.nio.ch.DefaultSelectorProvider.create()函数。这个函数的代码底层实际上会调用到jdk内部的一些函数，再由jdk内部去调用一些native方法，最终会调用到os中的接口，假设该程序所运作的os环境是linux操作系统，那么最底层就会调用到epool相关的三个函数。

epoll_create,epoll_ctl,epoll_wait。



> **Redis底层源代码中是如何实现多路复用的**

这里我打开的是redis6.0的源代码进行阅读：

**文件名称：ae_epoll.c**

ps：由于自己对于C源代码并不是特别熟悉，所以这里只能简单说下

下边的这张截图中体现了使用epoll_create函数取创建一个链接。

![图片](https://mmbiz.qpic.cn/mmbiz_png/48MFTQpxichkQQCUh8CSwyqN8ugdyJuibcXRyDhl1N9oS0MpWB15dECzzAYNABmcBaaSzZiciaAEhxiaHj2tULSH5hA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)



这段代码则是使用了epollo_ctl函数来处理一些事件的注册处理。

![图片](https://mmbiz.qpic.cn/mmbiz_png/48MFTQpxichkQQCUh8CSwyqN8ugdyJuibcqJ8Ovj0EtAP9djRFrDFVSKSaIq3ialRrpIWBFA6uHrAh8jtPqrNccYA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)



下边的epoll_wait看起来则像是监听某些兴趣事件。

![图片](https://mmbiz.qpic.cn/mmbiz_png/48MFTQpxichkQQCUh8CSwyqN8ugdyJuibcmPgOwOlFs7Y30K3rL9ibIeUD2yFlOO7Ia4XFwUiamD8p2ibtibEeVgT8bQ/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)



由于文章篇幅有限，后边会接着出一篇文章继续深入研究下多路复用的内容。