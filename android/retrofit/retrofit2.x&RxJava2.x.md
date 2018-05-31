# Retrofit2.x+RxJava2.x

## 依赖项

```
implementation 'io.reactivex.rxjava2:rxjava:2.0.1'
implementation 'io.reactivex.rxjava2:rxandroid:2.0.1'
implementation 'com.squareup.retrofit2:retrofit:2.0.1'
implementation 'com.squareup.retrofit2:converter-gson:+'
implementation 'com.squareup.retrofit2:adapter-rxjava:+'

```

可以看到，除了RxAndroid, RxJava, Retrofit依赖，另外还有两个： converter-gson, adapter-rxjava. 下面会做详细介绍。

## 定义请求接口

通过注解的方式，为每个请求声明请求的类型(Get, Post, Delete...),地址，以及参数等，如下：

```
public interface CommentService{
  @GET("shots/{id}/comments")
  Observable<Comment[]> getComments(@Path("id") int id,
                                    @Query("page") String page); }

```


## 创建Retrofit实例

Retrofit提供了Builder和工厂模式来创建对应的请求实例，如下：

{%ace edit=true lang='java'%}

public static <T> T createRetrofitService(final Class<T> clazz) {
    String GET_API_URL = "https://api.dribbble.com/v1/";

    Retrofit retrofit = new Retrofit.Builder()
              .baseUrl(GET_API_URL)
              .addConverterFactory(GsonConverterFactory.create())
              .addCallAdapterFactory(RxJavaCallAdapterFactory.create())
              .build();

    return retrofit.create(clazz);
}

{%endace%}

我们可以看到， 在build过程中，增加了GsonConverterFactory和RxJavaCallAdapterFactory， 分别是在上述引用依赖时候的内容， 下面我们来看看Retrofit提供的这两个工厂类：

1. GsonConverterFactory

   顾名思义，它是一个Json数据转化类，其中Gson是目前应用最广泛的Json解析库，所以Retrofit引入它就是为了将数据转化封装到内部实现，也减少了我们的工作量。
   当然1.0的Retrofit还没有引入， 我们会看到1.0是使用RestAdapter来实现请求结果转化的

2. RxJavaCallAdapterFactory

   这个类是为了与RxJava衔接而提供的， 如果不添加这个实现， 直接使用RxJava的观察者模式，会得到如下报错：

   `Unable to create call adapter for class`


## 进一步封装

通过上述“定义接口”， “创建实例”， 我们已经可以实现一个完整的请求，并将结果输出， 但是， 这样的请求并不是非常灵活， 例如，如何为每个请求中添加header信息？（我们在项目中经常把token作为每次请求的必带参数），如果按照上述方法，得在每个接口中申明header参数，显然是不太合理。
Retrofit当然也会考虑这些问题， 可以实现自定义http客户端，我们在builder之前进行自定义，代码：

{%ace edit=true lang='java'%}
public static <T> T createRetrofitService(final Class<T> clazz) {

    String GET_API_URL = "https://api.dribbble.com/v1/";
    final OkHttpClient.Builder httpClient = new OkHttpClient.Builder();
    httpClient.addInterceptor(new Interceptor() {
         @Override
         public Response intercept(Chain chain) throws IOException {
             Request original = chain.request();
             Request.Builder builder = original.newBuilder()
                      .method(original.method(), original.body())
                      //添加请求头部信息
                      .header("Authorization", "Bearer " + ServiceConfig.ACCESS_TOKEN);

             return chain.proceed(builder.build());

         }

    });

    OkHttpClient okHttpClient = httpClient.build();

    Retrofit retrofit = new Retrofit.Builder()
              .baseUrl(GET_API_URL)
              .client(okHttpClient)
              .addConverterFactory(GsonConverterFactory.create())
              .addCallAdapterFactory(RxJavaCallAdapterFactory.create())
              .build();

    return retrofit.create(clazz);

 }


{%endace%}

这样，就实现了每次请求都带了Header信息。以此为例， 我们还可以进一步实现请求缓存等功能, 后续再更新...
另外， RxJava的监听线程等方法也可以封装：

{%ace edit=true lang='java'%}

public static <T> void toSubscribe(Observable<T> o, Subscriber<T> s) {
    o.subscribeOn(Schedulers.io())
            .unsubscribeOn(Schedulers.io())
            .observeOn(AndroidSchedulers.mainThread())
            .subscribe(s);
}
{%endace%}


## 完成请求

有了以上的封装，以下是我在UI层调用网络请求的代码：

{%ace edit=true lang='java'%}

ServiceFactory.toSubscribe(getObservable(), new Subscriber<Shot[]>() {
    @Override
    public void onCompleted() {

    }

    @Override
    public void onError(Throwable e) {
        requestFailed();
    }

    @Override
    public void onNext(Shot[] resultList) {
        requestSuccess(resultList);
    }
});



Observable<Shot[]> getObservable() {
    return ServiceFactory.createRetrofitService(
            DribService.ShotService.class).getShots(String.valueOf(mPage), mQueryMap);
}

{%endace%}
