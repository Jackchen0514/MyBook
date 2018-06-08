# Retrofit2.x(1/3)

## 简介

Retrofit is a type-safe HTTP client for Android and java.

Retrofit 适用于与 Web 服务器提供的 API 接口进行通信。

关于 Retrofit 的原理，有三个十分重要的概念：『注解』，『动态代理』，『反射』。将会在以后逐步进行分析。

## 初步使用

官方教程： http://square.github.io/retrofit/

GRADLE
```
compile 'com.squareup.retrofit2:retrofit:2.0.2'
```

Retrofit requires at minimum Java 7 or Android 2.3.

Maven
```
<dependency>
  <groupId>com.squareup.retrofit2</groupId>
  <artifactId>retrofit</artifactId>
  <version>2.4.0</version>
</dependency>
```

如果要将 JSON 数据转化为 Java 实体类对象，需要自己显式指定一个 Gson Converter。

GRADLE
```
// build gradle
compile 'com.squareup.retrofit2:converter-gson:2.0.1'
```

## 定义接口

我们的API接口地址为：
https://api.github.com/users/Guolei1130

转化为Java接口为：
```
public interface APIInterface {
  @GET("/users/{user}")
  Call<TestModel> repo(@Path("user") String user);
```

在后文构造 Retrofit 对象时会添加一个 baseUrl（https://api.github.com）。

在此处 GET 的意思是 发送一个 GET请求，请求的地址为：baseUrl + "/users/{user}"。

{user} 类似于占位符的作用，具体类型由 repo(@Path("user") String user) 指定，这里表示 {user} 将是一段字符串。

Call<TestModel> 是一个请求对象，<TestModel>表示返回结果是一个 TestModel 类型的实例。


## 定义 Model

请求会将 Json 数据转化为 Java 实体类，所以我们需要自定义一个 Model：
{%ace edit=true, lang='java'%}
public class TestModel {
    private String login;
    public String getLogin() { return login; }
    public void setLogin(String login) { this.login = login; }
}
{%endace%}

## 进行连接通信

首先， 构造一个Retrofit对象

{%ace edit=true, lang='java'%}
Retrofit retrofit= new Retrofit.Builder()
  .baseUrl("https://api.github.com")
  .addConverterFactory(GsonConverterFactory.create())
  .build();
{%endace%}
注意这里添加的 baseUrl 和 GsonConverter，前者表示要访问的网站，后者是添加了一个转换器。

{%ace edit=true, lang='java'%}
//创建我们的 API 接口对象，这里 APIInterface 是我们创建的接口

APIInterface service = retrofit.create(APIInterface.class);
{%endace%}

创建一个『请求对象』:

{%ace edit=true, lang='java'%}
//
Call<TestModel> model = service.repo("Guolei1130");
{%endace%}

注意这里的 .repo("Guolei1130") 取代了前面的 {user}。到这里，我们要访问的地址就成了：

```
https://api.github.com/users/Guolei1130
```


可以看出这样的方式有利于我们使用不同参数访问同一个 Web API 接口，比如你可以随便改成 .repo("ligoudan")

最后，就可以发送请求了！

{%ace edit=true, lang='java'%}
model.enqueue(
new Callback<TestModel>() {
@Override
public void onResponse(Call<TestModel> call, Response<TestModel> response) {
// Log.e("Test", response.body().getLogin());
System.out.print(response.body().getLogin());
}
@Override
public void onFailure(Call<TestModel> call, Throwable t) {
System.out.print(t.getMessage());
}
});
{%endace%}



至此，我们就利用 Retrofit 完成了一次网络请求。


## GET 请求参数设置

在我们发送 GET 请求时，如果需要设置 GET 时的参数，Retrofit 注解提供两种方式来进行配置

{%ace edit=true, lang='java'%}
// @Query（一个键值对）和 @QueryMap（多对键值对）

Call<TestModel> one(@Query("username") String username);
Call<TestModel> many(@QueryMap Map<String, String> params);
{%endace%}

## POST 请求参数设置

POST 的请求与 GET 请求不同，POST 请求的参数是放在请求体内的。

所以当我们要为 POST 请求配置一个参数时，需要用到 @Body 注解：

Call<TestModel> post(@Body User user);

这里的 User 类型是需要我们去自定义的：

{%ace edit=true, lang='java'%}

public class User {

  public String username;
  public String password;
  public User(String username,String password){
    this.username = username;
    this.password = password;
  }
}

{%endace%}

最后在获取请求对象时：

{%ace edit=true, lang='java'%}

User user = new User("lgd","123456");
Call<TestModel> model = service.post(user);

{%endace%}

就能完成 POST 请求参数的发送，注意该请求参数 user 也会转化成 Json 格式的对象发送到服务器。