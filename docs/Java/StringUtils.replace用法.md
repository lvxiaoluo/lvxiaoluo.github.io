### StringUtils.replace用法

```java
public class Test{
    
    public void test(){
         /*1.替换字符串:把text中的searchString替换成replacement,max是最大替换次数，默认是替换所有*/
        StringUtils.replaceOnce("sshhhss", "ss", "p");//只替换一次-->结果是：phhhss
        StringUtils.replace("sshhhs", "ss", "p");//全部替换  ---> 结果是：phhhs
        StringUtils.replace("sshhhsshss", "ss", "7777",2);//max：最大替换次数--> 结果是：7777hhh7777hss

        StringUtils.replaceChars("sshhhs", "ss", "p");//替换所有字符，区别于replace --->结果是：pphhhp而不是pphhhs

        /*2.按照数组进行替换,位置要匹配，数组长度要相等;
        *  暂时没发现下面replaceEach和replaceEachRepeatedly二者的区别*/
        StringUtils.replaceEach("www.baidu.com", new String[]{"baidu","com"}, new String[]{"taobao","net"});//结果是：www.taobao.net

        StringUtils.replaceEach("www.baidu,baidu.com", new String[]{"baidu","com"}, new String[]{"taobao","net"});//结果是：www.taobao,taobao.net

        StringUtils.replaceEachRepeatedly("www.baidu.com", new String[]{"baidu","com"}, new String[]{"taobao","net"});//结果是：www.taobao.net

    }
   
}

```