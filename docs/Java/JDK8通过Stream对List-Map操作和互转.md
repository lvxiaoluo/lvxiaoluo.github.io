### JDK 8 通过Stream 对List，Map操作和互转

Stream的原理和Lambda不在这了展开讨论。仅仅做笔记，方便后面查看，熟能生巧：

1. Map数据转换为自定义对象的List，例如把map的key,value分别对应Person对象两个属性：

```java
List<Person> list = map.entrySet().stream().sorted(Comparator.comparing(e -> e.getKey()))
		.map(e -> new Person(e.getKey(), e.getValue())).collect(Collectors.toList());
```

```java
List<Person> list = map.entrySet().stream().sorted(Comparator.comparing(Map.Entry::getValue))
		.map(e -> new Person(e.getKey(), e.getValue())).collect(Collectors.toList());
```

```java
List<Person> list = map.entrySet().stream().sorted(Map.Entry.comparingByKey())
	.map(e -> new Person(e.getKey(), e.getValue())).collect(Collectors.toList());
```

2. List对象转换为其他List对象：

```java
List<Employee> employees = persons.stream()
                .filter(p -> p.getLastName().equals("l1"))
                .map(p -> new Employee(p.getName(), p.getLastName(), 1000))
                .collect(Collectors.toList());
```

3. 从List中过滤出一个元素
```java
 User match = users.stream().filter((user) -> user.getId() == 1).findAny().get();
```

4. List转换为Map

```java
public class Hosting {
 
    private int Id;
    private String name;
    private long websites;
 
    public Hosting(int id, String name, long websites) {
        Id = id;
        this.name = name;
        this.websites = websites;
    }
 
    //getters, setters and toString()
}

```
```java
 Map<Integer, String> result1 = list.stream().collect(
                Collectors.toMap(Hosting::getId, Hosting::getName));
```


