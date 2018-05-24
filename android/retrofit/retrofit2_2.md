# Retrofit2.x(2/3)

## 开启Retrofit2之旅

### 添加依赖

```
compile 'com.squareup.retrofit2:retrofit:2.1.0'
compile 'com.squareup.retrofit2:converter-gson:2.1.0'
compile 'com.squareup.retrofit2:adapter-rxjava:2.1.0'
//日志拦截器
compile 'com.squareup.okhttp3:logging-interceptor:3.5.0'
compile 'io.reactivex:rxjava:1.2.4'
compile 'io.reactivex:rxandroid:1.2.1'
compile 'org.ligboy.retrofit2:converter-fastjson-android:2.1.0'

```

### 注解

retrofit通过使用注解来简化请求，大体分为以下几类：

1. 用于标注请求方式的注解
2. 用于标记请求头的注解
3. 用于标记请求参数的注解
4. 用于标记请求和响应格式的注解

### 请求方法注解

|注解|说明|
|:--|:--|
|@GET|get请求|
|@POST|post请求|
|@PUT|put请求|
|@DELETE|delete请求|
|@PATCH|patch请求，该请求是对put请求的补充，用于更新局部资源|
|@HEAD|head请求|
|@OPTIONS|option请求|
|@HTTP|通用注解,可以替换以上所有的注解，其拥有三个属性：method，path，hasBody|


## 参考

[1] https://www.jianshu.com/p/73216939806a
