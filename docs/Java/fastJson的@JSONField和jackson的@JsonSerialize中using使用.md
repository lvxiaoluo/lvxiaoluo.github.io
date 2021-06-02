
### fastJson的@JSONField和jackson的@JsonSerialize中using使用 <font color=#7FFF00 size=4 face="黑体">【原创】</font>

#### fastJson的@JSONField使用

>- 类型字段序列化时转为字符串，避免js丢失精度

```xml
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>fastjson</artifactId>
    <version>1.2.31</version>
</dependency>
```
```java
public class LongJsonDeserializer implements ObjectDeserializer {
    private static final Logger logger = (Logger) LoggerFactory.getLogger(LongJsonDeserializer.class);

    @Override
    public Long deserialze(DefaultJSONParser parser, Type type, Object fieldName) {
        String value = (String)parser.parse(fieldName);
        logger.info("String字符串转成Long类型 value:{}",value);
        try {
            return value == null ? null : Long.parseLong(value);
        } catch (NumberFormatException e) {
            logger.error("解析长整形错误", e);
            return null;
        }
    }

    @Override
    public int getFastMatchToken() {
        return 0;
    }
}
```

```java
public  class LongJsonSerializer implements ObjectSerializer {

    private static final Logger logger = (Logger) LoggerFactory.getLogger(LongJsonDeserializer.class);

    @Override
    public void write(JSONSerializer serializer, Object object, Object fieldName, Type fieldType,
                      int features) throws IOException {
        Long value = (Long) object;
        logger.info("long类型转成string类型 value:{}",value);
        String text = (value == null ? null : String.valueOf(value));
        logger.info("long类型转成string类型转换之后value:{}",JsonUtil.java2Json(text));
        if (text != null) {
            serializer.write(text);
        }
    }
}
```

```java
@Data
public class User{
    /** 用户id */
    @JSONField(serializeUsing =LongJsonSerializer.class,deserializeUsing = LongJsonDeserializer.class)
    private Long customerId;
}
```

---

#### jackson的@JsonSerialize

```txt
<dependency>
  <groupId>com.fasterxml.jackson.core</groupId>
  <artifactId>jackson-databind</artifactId>
</dependency>
```
```java
@Data
@AllArgsConstructor
public class User implements Serializable {

    @JsonSerialize(using = ToStringSerializer.class)
    private Long userId;
}
```