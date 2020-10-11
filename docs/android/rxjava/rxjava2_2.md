# RxJava2.x(2/2)

## 线程控制

其实线程控制也是一种操作符。但它不属于创建、变换、过滤。所以我这边把它单独拉出来讲讲。
subscribeOn是指上游发送事件的线程。说白了也就是子线程。
多次指定上游的线程只有第一次指定的有效, 也就是说多次调用`subscribeOn()` 只有第一次的有效, 其余的会被忽略。observerOn是指下游接受事件的线程。
也就是主线程。多次指定下游的线程是可以的, 也就是说每调用一次`observeOn()` , 下游的线程就会切换一次。

举个例子：

{%ace edit=true lang='java'%}
//
Observable.just(1, 2, 3, 4) // IO 线程，由 subscribeOn() 指定
    .subscribeOn(Schedulers.io())
    .observeOn(Schedulers.newThread())
    .map(mapOperator) // 新线程，由 observeOn() 指定
    .observeOn(Schedulers.io())
    .map(mapOperator2) // IO 线程，由 observeOn() 指定
    .observeOn(AndroidSchedulers.mainThread)
    .subscribe(subscriber);  // Android 主线程，由 observeOn() 指定
//
//
{%endace%}

在RxJava中，已经内置了很多线程选项供我们选择，例如：

- `Schedulers.io()` : I/O操作（读写文件、数据库，及网络交互等）所使用的Scheduler。行为模式和newThread()差不多。区别在于io()的内部实现是用一个无数量上限的线程池。可以重用空闲的线程。因此多数情况下io()比newThread()更有效率。

- `Schedulers.immediate()`: 直接在当前线程运行。

- `Schedulers.computation()`: 计算所使用的Scheduler，例如图形的计算。这个Scheduler使用固定线程池，大小为CPU核数。不要把I/O操作放在computation中。否则I/O操作的等待会浪费CPU。

- `Schedulers.newThread()`: 代表一个常规的新线程

- `Schedulers.trampoline()`: 当我们想在线程执行一个任务时（不是立即执行），可以用此方法将它加入队列。这个调度器将会处理它的队列并且按序执行队列中的每一个任务。

- `AndroidSchedulers.mainThread()`: 代表Android的主线程

这些内置的Scheduler已经足够满足我们开发的需求, 因此我们应该使用内置的这些选项, 在RxJava内部使用的是线程池来维护这些线程, 所有效率也比较高。

## 与Retrofit结合

就目前开发角度而言，retrofit可以说是最火的网络框架。
其原因我认为有两点，
第一：可以和okhttp结合。
第二：可以和rxjava结合。
也就是说Retrofit 除了提供了传统的 `Callback` 形式的 API，还有 RxJava 版本的 `Observable` 形式 API。

如果需要使用retrofit，我们需要在gradle的配置加上这句：

```
compile 'com.squareup.retrofit2:retrofit:2.0.1'
compile 'com.squareup.retrofit2:converter-gson:+'
compile 'com.squareup.retrofit2:adapter-rxjava:+'

```

话不多说，直接上例子：

{%ace edit=true lang='java'%}


    private static OkHttpClient mOkHttpClient;
    private static Converter.Factory gsonConverterFactory = GsonConverterFactory.create();
    private static CallAdapter.Factory rxJavaCallAdapterFactory = RxJavaCallAdapterFactory.create();
    public static BaseHttpApi getObserve() {

        if (baseHttpApi == null) {
            Retrofit retrofit = new Retrofit.Builder()
                    .addConverterFactory(gsonConverterFactory)
                    .addCallAdapterFactory(rxJavaCallAdapterFactory)
                    .client(mOkHttpClient)
                    .baseUrl(BaseUrl.WEB_BASE)
                    .build();
            baseHttpApi = retrofit.create(BaseHttpApi.class);
       }
        return baseHttpApi;

    }

{%endace%}

如上代码，可以很清晰的看出，它通过2个工厂模式创建了gson和rxjava。并且通过了链式调用将他们进行了绑定。那么怎么通过链式调用实现网络请求呢？不急，我们喝杯茶，接着往下看。

比如，一个post请求，我们可以这么写：

{%ace edit=true lang='java'%}

public interface BaseHttpApi{
    @FormUrlEncoded
    @POST("seller/cash_flow_log_detail.json")
    Observable<ServiceReward> serviceReward(@Field("requestmodel") String model);
}

{%endace%}

敲黑板了。注意，我这边是interface而不是一个class。接下来就是日常调用了，代码如下：

{%ace edit=true lang='java'%}

 Network.getObserve()
                .serviceReward(new Gson().toJson(map))
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(new Observer<ServiceReward>() {
                    @Override
                    public void onCompleted() {

                    }

                    @Override
                    public void onError(Throwable e) {

                    }

                    @Override
                    public void onNext(ServiceReward serviceReward) {
                        parseOrderDetail(serviceReward);
                    }
                });

{%endace%}

看第二行，这就是为什么刚开始为什么要用工厂模式创建gson的原因。现在我们只要在parseOrderDetail方法中处理正常的逻辑就可以了。是不是看起来代码有点多？那么我们可以这样：

{%ace edit=true lang='java'%}

 Network.getObserve()
                .serviceReward(new Gson().toJson(map))
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(serviceReward ->{
                        parseOrderDetail(serviceReward);
                 });

{%endace%}

一个lamada表达式，是不是感觉瞬间代码少了很多，不过有人要说，我加载的时候是一个弹窗显示的，如果加载失败了我这个弹窗岂不是影藏不了？不存在的，如果真有这种情况怎么做？我们接着看：

{%ace edit=true lang='java'%}

 Network.getObserve()
                .serviceReward(new Gson().toJson(map))
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(serviceReward ->{
                        parseOrderDetail(serviceReward);
                 },throwable ->{do something when net error...});
{%endace%}

这么处理岂不是快哉。对于lamada，刚开始可能都是各种不习惯，不过用习惯了就会发现代码各种简洁（我最近也在适应中）。


## 参考

https://www.jianshu.com/p/cc19cc9f4a36
