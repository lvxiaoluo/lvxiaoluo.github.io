## @DateTimeFormat 和 @JsonFormat 注解 <font color=#7FFF00 size=4 face="黑体">【原创】</font>

入参使用 @DateTimeFormat格式化  
出参使用 @JsonFormat格式化



```java
public class Class{
    //入参格式化
    @DateTimeFormat(pattern="yyyy-MM-dd HH:mm:ss")
    // 时区
    //timezone = "GMT+8"
    
    //出参格式化
    @JsonFormat(
        pattern = "yyyy-MM-dd HH:mm:ss",timezone = "GMT+8"
    )
    private Date date;
}

```