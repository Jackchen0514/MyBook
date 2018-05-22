# OKHTTP之缓存配置详解

## 前言

在Android开发中我们经常要进行各种网络访问，比如查看各类新闻、查看各种图片。但有一种情形就是我们每次重复发送的网络请求其实返回的内容都是一样的。比如一个电影类APP，每一次向服务器申请某个电影的相关信息，如封面、简介、演员表等等，它们的信息都是一样的。显然，这样有点浪费资源，最主要的是这些重复的请求产生了没有必要的流量。流量、流量、流量！！！重要的事情说三遍！刚开始工作的我也不懂，后来才发现，流量是要付费的，而且超贵，公司那么小，一个月要支付宽带运营商巨额的流量费用。所以领导们都想方设法地要节省带宽。
其实这在整个软件开发中随时可见，解决的方法就是把重复请求的数据缓存在本地，并设置超时时间，在规定时间内，客户端不再向远程请求数据，而是直接从本地缓存中取数据。这样一来提高了响应速度，二来节省了网络带宽（也就是节省了钱）。
本文就是讲解在OKHTTP中如何配置缓存。

## HTTP协议中缓存相关

为了更好的讲解OKHTTP怎么设置缓存，我们追根溯源先从浏览器的缓存说起，这样后面的OKHTTP缓存内容自然更加好理解。

https://my.oschina.net/leejun2005/blog/369148

## 缓存分类

http请求有服务端和客户端之分。因此缓存也可以分为两个类型服务端侧和客户端侧。

### 服务端缓存

常见的服务端有Ngix和Apache。服务端缓存又分为代理服务器缓存和反向代理服务器缓存。常见的CDN就是服务器缓存。这个好理解，当浏览器重复访问一张图片地址时，CDN会判断这个请求有没有缓存，如果有的话就直接返回这个缓存的请求回复，而不再需要让请求到达真正的服务地址，这么做的目的是减轻服务端的运算压力。

### 客户端

客户端主要指浏览器（如IE、Chrome等），当然包括我们的OKHTTPClient.客户端第一次请求网络时，服务器返回回复信息。如果数据正常的话，客户端缓存在本地的缓存目录。当客户端再次访问同一个地址时，客户端会检测本地有没有缓存，如果有缓存的话，数据是有没有过期，如果没有过期的话则直接运用缓存内容。

而我们讲的就是客户端的缓存。

## 缓存中重要的概念

### Cache-Control

我们先用浏览器访问下某网页，查看服务端返回来的信息：

```
HTTP/1.1 200 OK
Server: openresty
Date: Mon, 24 Oct 2016 09:00:34 GMT
Content-Type: text/html; charset=utf-8
Transfer-Encoding: chunked
Connection: keep-alive
Keep-Alive: timeout=20
Vary: Accept-Encoding
Cache-Control: private
X-Powered-By: PHP 5.4.28
Content-Encoding: gzip
```

可以看到头信息中有这么一行:

```
Cache-Control: private
```

Cache-control是由服务器返回的Response中添加的头信息，它的目的是告诉客户端是要从本地读取缓存还是直接从服务器摘取消息。它有不同的值，每一个值有不同的作用。

```
  max-age：这个参数告诉浏览器将页面缓存多长时间，超过这个时间后才再次向服务器发起请求检查页面是否有更新。
  对于静态的页面，比如图片、CSS、Javascript，一般都不大变更，因此通常我们将存储这些内容的时间设置为较长的时间，
  这样浏览器会不会向浏览器反复发起请求，也不会去检查是否更新了。
  s-maxage：这个参数告诉缓存服务器(proxy，如Squid)的缓存页面的时间。如果不单独指定，缓存服务器将使用max-age。
  对于动态内容(比如文档的查看页面)，我们可告诉浏览器很快就过时了(max-age=0)，并告诉缓存服务器(Squid)保留内容一段时间(比如，s-maxage=7200)。
  一旦我们更新文档，我们将告诉Squid清除老的缓存版本。
  must-revalidate：这告诉浏览器，一旦缓存的内容过期，一定要向服务器询问是否有新版本。
  proxy-revalidate：proxy上的缓存一旦过期，一定要向服务器询问是否有新版本。
  no-cache：不做缓存。
  no-store：数据不在硬盘中临时保存，这对需要保密的内容比较重要。
  public：告诉缓存服务器, 即便是对于不该缓存的内容也缓存起来，比如当用户已经认证的时候。所有的静态内容(图片、Javascript、CSS等)应该是public的。
  private：告诉proxy不要缓存，但是浏览器可使用private cache进行缓存。一般登录后的个性化页面是private的。
  no-transform: 告诉proxy不进行转换，比如告诉手机浏览器不要下载某些图片。
  max-stale:指示客户机可以接收超出超时期间的响应消息。如果指定max-stale消息的值，那么客户机可以接收超出超时期指定值之内的响应消息。

```

我们上面的例子是Cache-Control:private。说明服务器希望客户端不要缓存消息，但是可以进行private cache方法进行缓存。这是因为http://blog.csdn.net/briblue 是我的博客页面，与用户系统相关，
所以为了安全起见，建议用private cache的方式缓存。

在OKHttp开发中我们常见到的有下面几个：

- max-age
- no-cache
- max-stale


### expires

expires的效果等同于Cache-Control，不过它是Http 1.0的内容，它的作用是告诉浏览器缓存的过期时间，在此时间内浏览器不需要直接访问服务器地址直接用缓存内容就好了。
expires最大的问题在于如果服务器时间和本地浏览器相差过大的问题。那样误差就很大。所以基本上用Cache-Control:max-age=多少秒的形式代替。

### Last-Modified/If-Modified-Since

这个需要配合Cache-Control使用
```
Last-Modified：标示这个响应资源的最后修改时间。web服务器在响应请求时，告诉浏览器资源的最后修改时间。

If-Modified-Since：当资源过期时（使用Cache-Control标识的max-age），发现资源具有Last-Modified声明，则再次向web服务器请求时带上头 If-Modified-Since，表示请求时间。web服务器收到请求后发现有头If-Modified-Since 则与被请求资源的最后修改时间进行比对。若最后修改时间较新，说明资源又被改动过，则响应整片资源内容（写在响应消息包体内），HTTP 200；若最后修改时间较旧，说明资源无新修改，则响应HTTP 304 (无需包体，节省浏览)，告知浏览器继续使用所保存的cache。

```

### Etag/If-None-Match

这个也需要配合Cache-Control使用

Etag对应请求的资源在服务器中的唯一标识（具体规则由服务器决定），比如一张图片，它在服务器中的标识为ETag: W/”ACXbWXd1n0CGMtAd65PcoA==”。

If-None-Match 如果浏览器在Cache-Control:max-age=60设置的时间超时后，发现消息头中还设置了Etag值。然后，浏览器会再次向服务器请求数据并添加In-None-Match消息头，它的值就是之前Etag值。服务器通过Etag来定位资源文件，根据它是否更新的情况给浏览器返回200或者是304。

**Etag机制比Last-Modified精确度更高，如果两者同时设置的话，Etag优先级更高。**

### Pragma

Pragma头域用来包含实现特定的指令，最常用的是Pragma:no-cache。

在HTTP/1.1协议中，它的含义和Cache- Control:no-cache相同。

以上是Http中关于缓存的相关信息。接下来我们进入主题，如何配置OkHttp的缓存

## OKHTTP之Cache

OKHTTP如果要设置缓存，首要的条件就是设置一个缓存文件夹，在Android中为了安全起见，一般设置为私密数据空间。通过getExternalCacheDir()获取。如然后通过调用OKHttpClient.Builder中的cache()方法。如下面代码所示：

```
//缓存文件夹
File cacheFile = new File(getExternalCacheDir().toString(),"cache");
//缓存大小为10M
int cacheSize = 10 * 1024 * 1024;
//创建缓存对象
Cache cache = new Cache(cacheFile,cacheSize);

OkHttpClient client = new OkHttpClient.Builder()
        .cache(cache)
        .build();
```

设置好Cache我们就可以正常访问了。我们可以通过获取到的Response对象拿到它正常的消息和缓存的消息。

Response的消息有两种类型，CacheResponse和NetworkResponse。CacheResponse代表从缓存取到的消息，NetworkResponse代表直接从服务端返回的消息。示例代码如下：

{%ace edit=true, lang='java'%}
private void testCache(){
        //缓存文件夹
        File cacheFile = new File(getExternalCacheDir().toString(),"cache");
        //缓存大小为10M
        int cacheSize = 10 * 1024 * 1024;
        //创建缓存对象
        final Cache cache = new Cache(cacheFile,cacheSize);
        new Thread(new Runnable() {
            @Override
            public void run() {
                OkHttpClient client = new OkHttpClient.Builder()
                        .cache(cache)
                        .build();
                //官方的一个示例的url
                String url = "http://publicobject.com/helloworld.txt";
                Request request = new Request.Builder()
                        .url(url)
                        .build();
                Call call1 = client.newCall(request);
                Response response1 = null;
                try {
                    //第一次网络请求
                    response1 = call1.execute();
                    Log.i(TAG, "testCache: response1 :"+response1.body().string());
                    Log.i(TAG, "testCache: response1 cache :"+response1.cacheResponse());
                    Log.i(TAG, "testCache: response1 network :"+response1.networkResponse());
                    response1.body().close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
                Call call12 = client.newCall(request);
                try {
                    //第二次网络请求
                    Response response2 = call12.execute();
                    Log.i(TAG, "testCache: response2 :"+response2.body().string());
                    Log.i(TAG, "testCache: response2 cache :"+response2.cacheResponse());
                    Log.i(TAG, "testCache: response2 network :"+response2.networkResponse());
                    Log.i(TAG, "testCache: response1 equals response2:"+response2.equals(response1));
                    response2.body().close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }).start();
    }
{%endace%}

我们在上面的代码中，用同一个url地址分别进行了两次网络访问，然后分别用Log打印它们的信息。

{%ace edit=true, lang='java'%}
10-24 21:17:04.720 9901-17925/? I/SeniorActivity: testCache: response1 :
                                                                           \\           //
                                                                            \\  .ooo.  //
                                                                             .@@@@@@@@@.
                                                                           :@@@@@@@@@@@@@:
                                                                          :@@. '@@@@@' .@@:
                                                                          @@@@@@@@@@@@@@@@@
                                                                          @@@@@@@@@@@@@@@@@

                                                                     :@@ :@@@@@@@@@@@@@@@@@. @@:
                                                                     @@@ '@@@@@@@@@@@@@@@@@, @@@
                                                                     @@@ '@@@@@@@@@@@@@@@@@, @@@
                                                                     @@@ '@@@@@@@@@@@@@@@@@, @@@
                                                                     @@@ '@@@@@@@@@@@@@@@@@, @@@
                                                                     @@@ '@@@@@@@@@@@@@@@@@, @@@
                                                                     @@@ '@@@@@@@@@@@@@@@@@, @@@
                                                                          @@@@@@@@@@@@@@@@@
                                                                          '@@@@@@@@@@@@@@@'
                                                                             @@@@   @@@@
                                                                             @@@@   @@@@
                                                                             @@@@   @@@@
                                                                             '@@'   '@@'

                                                       :@@@.
                                                     .@@@@@@@:   +@@       `@@      @@`   @@     @@
                                                    .@@@@'@@@@:  +@@       `@@      @@`   @@     @@
                                                    @@@     @@@  +@@       `@@      @@`   @@     @@
                                                   .@@       @@: +@@   @@@ `@@      @@` @@@@@@ @@@@@@  @@;@@@@@
                                                   @@@       @@@ +@@  @@@  `@@      @@` @@@@@@ @@@@@@  @@@@@@@@@
                                                   @@@       @@@ +@@ @@@   `@@@@@@@@@@`   @@     @@    @@@   :@@
                                                   @@@       @@@ +@@@@@    `@@@@@@@@@@`   @@     @@    @@#    @@+
                                                   @@@       @@@ +@@@@@+   `@@      @@`   @@     @@    @@:    @@#
                                                    @@:     .@@` +@@@+@@   `@@      @@`   @@     @@    @@#    @@+
                                                    @@@.   .@@@  +@@  @@@  `@@      @@`   @@     @@    @@@   ,@@
                                                     @@@@@@@@@   +@@   @@@ `@@      @@`   @@@@   @@@@  @@@@#@@@@
                                                      @@@@@@@    +@@   #@@ `@@      @@`   @@@@:  @@@@: @@'@@@@@
                                                                                                       @@:
                                                                                                       @@:
                                                                                                       @@:
10-24 21:17:04.720 9901-17925/? I/SeniorActivity: testCache: response1 cache :null
10-24 21:17:04.720 9901-17925/? I/SeniorActivity: testCache: response1 network :Response{protocol=http/1.1, code=200, message=OK, url=https://publicobject.com/helloworld.txt}
10-24 21:17:05.031 9901-17925/? I/SeniorActivity: testCache: response2 :
                                                                           \\           //
                                                                            \\  .ooo.  //
                                                                             .@@@@@@@@@.
                                                                           :@@@@@@@@@@@@@:
                                                                          :@@. '@@@@@' .@@:
                                                                          @@@@@@@@@@@@@@@@@
                                                                          @@@@@@@@@@@@@@@@@

                                                                     :@@ :@@@@@@@@@@@@@@@@@. @@:
                                                                     @@@ '@@@@@@@@@@@@@@@@@, @@@
                                                                     @@@ '@@@@@@@@@@@@@@@@@, @@@
                                                                     @@@ '@@@@@@@@@@@@@@@@@, @@@
                                                                     @@@ '@@@@@@@@@@@@@@@@@, @@@
                                                                     @@@ '@@@@@@@@@@@@@@@@@, @@@
                                                                     @@@ '@@@@@@@@@@@@@@@@@, @@@
                                                                          @@@@@@@@@@@@@@@@@
                                                                          '@@@@@@@@@@@@@@@'
                                                                             @@@@   @@@@
                                                                             @@@@   @@@@
                                                                             @@@@   @@@@
                                                                             '@@'   '@@'

                                                       :@@@.
                                                     .@@@@@@@:   +@@       `@@      @@`   @@     @@
                                                    .@@@@'@@@@:  +@@       `@@      @@`   @@     @@
                                                    @@@     @@@  +@@       `@@      @@`   @@     @@
                                                   .@@       @@: +@@   @@@ `@@      @@` @@@@@@ @@@@@@  @@;@@@@@
                                                   @@@       @@@ +@@  @@@  `@@      @@` @@@@@@ @@@@@@  @@@@@@@@@
                                                   @@@       @@@ +@@ @@@   `@@@@@@@@@@`   @@     @@    @@@   :@@
                                                   @@@       @@@ +@@@@@    `@@@@@@@@@@`   @@     @@    @@#    @@+
                                                   @@@       @@@ +@@@@@+   `@@      @@`   @@     @@    @@:    @@#
                                                    @@:     .@@` +@@@+@@   `@@      @@`   @@     @@    @@#    @@+
                                                    @@@.   .@@@  +@@  @@@  `@@      @@`   @@     @@    @@@   ,@@
                                                     @@@@@@@@@   +@@   @@@ `@@      @@`   @@@@   @@@@  @@@@#@@@@
                                                      @@@@@@@    +@@   #@@ `@@      @@`   @@@@:  @@@@: @@'@@@@@
                                                                                                       @@:
                                                                                                       @@:
                                                                                                       @@:
10-24 21:17:05.031 9901-17925/? I/SeniorActivity: testCache: response2 cache :Response{protocol=http/1.1, code=200, message=OK, url=https://publicobject.com/helloworld.txt}
10-24 21:17:05.031 9901-17925/? I/SeniorActivity: testCache: response2 network :null
10-24 21:17:05.031 9901-17925/? I/SeniorActivity: testCache: response1 equals response2:false

{%endace%}

打印的结果非常有意思是一个机器人和一个Okhttp的字符串。打印的结果主要说明了一个现象，第一次访问的时候，Response的消息是NetworkResponse消息，此时CacheResponse的值为Null.而第二次访问的时候Response是CahceResponse，而此时NetworkResponse为空。也就说明了上面的示例代码能够进行网络请求的缓存。

那么OKHTTP中的缓存就这么点内容吗？到此为至吗？显然不是。本篇文章开头讲了大段的Http协议中的相关知识点，貌似它们还没有出现。

其实控制缓存的消息头往往是服务端返回的信息中添加的如”Cache-Control:max-age=60”。所以，会有两种情况。

1. 客户端和服务端开发能够很好沟通，按照达成一致的协议，服务端按照规定添加缓存相关的消息头。
2. 客户端与服务端的开发根本就不是同一家公司，没有办法也不可能要求服务端按照客户端的意愿进行开发。

第一种办法当然很好，只要服务器在返回消息的时候添加好Cache-Control相关的消息便好。

第二种情况，就很麻烦，你真的无法左右别人的行为。怎么办呢？好在OKHTTP能够很轻易地处理这种情况。那就是定义一个拦截器，人为地添加Response中的消息头，然后再传递给用户，这样用户拿到的Response就有了我们理想当中的消息头Headers，从而达到控制缓存的意图，正所谓移花接木。


### 缓存之拦截器

因为拦截器可以拿到Request和Response，所以可以轻而易举地加工这些东西。在这里我们人为地添加Cache-Control消息头。

{%ace edit=true, lang='java'%}

class CacheInterceptor implements Interceptor{

        @Override
        public Response intercept(Chain chain) throws IOException {

            Response originResponse = chain.proceed(chain.request());

            //设置缓存时间为60秒，并移除了pragma消息头，移除它的原因是因为pragma也是控制缓存的一个消息头属性
            return originResponse.newBuilder().removeHeader("pragma")
                    .header("Cache-Control","max-age=60").build();
        }
    }

{%endace%}

定义好拦截器中后，我们可以添加到OKHttpClient中了。

{%ace edit=true, lang='java'%}
private void testCacheInterceptor(){
        //缓存文件夹
        File cacheFile = new File(getExternalCacheDir().toString(),"cache");
        //缓存大小为10M
        int cacheSize = 10 * 1024 * 1024;
        //创建缓存对象
        final Cache cache = new Cache(cacheFile,cacheSize);

        OkHttpClient client = new OkHttpClient.Builder()
                .addNetworkInterceptor(new CacheInterceptor())
                .cache(cache)
                .build();
        .......
}
{%endace%}

代码后面部分有省略。主要通过在OkHttpClient.Builder()中addNetworkInterceptor()中添加。而这样也挺简单的，就几步完成了缓存代码。

### 拦截器进行缓存的缺点

网上有人说用拦截器进行缓存是野路子，是HOOK行为。这个我不大同意，前面我有分析过情况，如果客户端能够同服务端一起协商开发，当然以服务器控制的缓存消息头为准，但问题在于你没法这样做。所以，能够解决问题才是最实在的。

好了，回到正题。用拦截器控制缓存有什么不好的地方呢？我们先看看下面的情况。

1. 网络访问请求的资源是文本信息，如新闻列表，这类信息经常变动，一天更新好几次，它们用的缓存时间应该就很短
2. 网络访问请求的资源是图片或者视频，它们变动很少，或者是长期不变动，那么它们用的缓存时间就应该很长。

那么，问题来了。
因为OKHTTP开发建议是同一个APP，用同一个OKHTTPCLIENT对象这是为了只有一个缓存文件访问入口。

这个很容易理解，单例模式嘛。但是问题拦截器是在OKHttpClient.Builder当中添加的。

如果在拦截器中定义缓存的方法会导致图片的缓存和新闻列表的缓存时间是一样的，这显然是不合理的，这属于一刀切，就像这两天专家说的要把年收入12万元的人群划分为高收入人群而不区别北上广深的房价物价情况。

真实的情况不应该是图片请求有它的缓存时间，新闻列表请求有它的缓存时间，应该是每一个Request有它的缓存时间。

### okhttp官方文档建议缓存方法

okhttp中建议用CacheControl这个类来进行缓存策略的制定。
它内部有两个很重要的静态实例。

{%ace edit=true lang='java'%}

/**强制使用网络请求*/
public static final CacheControl FORCE_NETWORK = new Builder().noCache().build();

  /**
   * 强制性使用本地缓存，如果本地缓存不满足条件，则会返回code为504
   */
  public static final CacheControl FORCE_CACHE = new Builder()
      .onlyIfCached()
      .maxStale(Integer.MAX_VALUE, TimeUnit.SECONDS)
      .build();
{%endace%}

我们看到FORCE_NETWORK常量用来强制使用网络请求。FORCE_CACHE只取本地的缓存。

它们本身都是CacheControl对象，由内部的Buidler对象构造。下面我们来看看CacheControl.Builder

### CacheControl.Builder

它有如下方法：

```
- noCache();//不使用缓存，用网络请求
- noStore();//不使用缓存，也不存储缓存
- onlyIfCached();//只使用缓存
- noTransform();//禁止转码
- maxAge(10, TimeUnit.MILLISECONDS);//设置超时时间为10ms。
- maxStale(10, TimeUnit.SECONDS);//超时之外的超时时间为10s
- minFresh(10, TimeUnit.SECONDS);//超时时间为当前时间加上10秒钟。
```

知道了CacheControl的相关信息，那么它怎么使用呢？不同于拦截器设置缓存，CacheControl是针对Request的，所以它可以针对每个请求设置不同的缓存策略。比如图片和新闻列表。下面代码展示如何用CacheControl设置一个60秒的超时时间。

{%ace edit=true lang='java'%}

private void testCacheControl(){
        //缓存文件夹
        File cacheFile = new File(getExternalCacheDir().toString(),"cache");
        //缓存大小为10M
        int cacheSize = 10 * 1024 * 1024;
        //创建缓存对象
        final Cache cache = new Cache(cacheFile,cacheSize);

        new Thread(new Runnable() {
            @Override
            public void run() {
                OkHttpClient client = new OkHttpClient.Builder()
                        .cache(cache)
                        .build();
                //设置缓存时间为60秒
                CacheControl cacheControl = new CacheControl.Builder()
                        .maxAge(60, TimeUnit.SECONDS)
                        .build();
                Request request = new Request.Builder()
                        .url("http://blog.csdn.net/briblue")
                        .cacheControl(cacheControl)
                        .build();

                try {
                    Response response = client.newCall(request).execute();

                    response.body().close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }).start();

    }

{%endace%}


### 强制使用缓存

前面有讲CacheControl.FORCE_CACHE这个常量。

{%ace edit=true lang='java'%}
public static final CacheControl FORCE_CACHE = new Builder()
      .onlyIfCached()
      .maxStale(Integer.MAX_VALUE, TimeUnit.SECONDS)
      .build();
{%endace%}

它内部其实就是调用onlyIfCached()和maxStale方法。
它的使用方法为

{%ace edit=true lang='java'%}
Request request = new Request.Builder()
            .url("http://blog.csdn.net/briblue")
            .cacheControl(Cache.FORCE_CACHE)
            .build();
{%endace%}

但是如前面后提到的，如果缓存不符合条件会返回504.这个时候我们要根据情况再进行编码，如缓存不行就再进行一次网络请求。

{%ace edit=true lang='java'%}
Response forceCacheResponse = client.newCall(request).execute();
     if (forceCacheResponse.code() != 504) {
       // 资源已经缓存了，可以直接使用
     } else {
       // 资源没有缓存，或者是缓存不符合条件了。
     }
{%endace%}

### 不使用缓存

前面也有讲CacheControl.FORCE_NETWORK这个常量。

```
public static final CacheControl FORCE_NETWORK = new Builder().noCache().build();
```

它的内部其实是调用noCache()方法，也就是不缓存的意思。
它的使用方法为

{%ace edit=true lang='java'%}
Request request = new Request.Builder()
            .url("http://blog.csdn.net/briblue")
            .cacheControl(Cache.FORCE_NETWORK)
            .build();
{%endace%}

还有一种情况将maxAge设置为0，也不会取缓存，直接走网络。

{%ace edit=true lang='java'%}

Request request = new Request.Builder()
            .url("http://blog.csdn.net/briblue")
            .cacheControl(new CacheControl.Builder()
            .maxAge(0, TimeUnit.SECONDS))
            .build();

{%endace%}

## 总结

本文其实内容不多，前面讲了很多http协议下的缓存机制，我认为是值得的，知道了Cache-Control这些定义，才能更好的懂得OKHTTP中的缓存设置。能够明白为什么它要这样做，为什么它可以这样做。
最后归纳下要点


   - http协议下Cache-Control等消息头的作用
   - okhttp如何用拦截器添加Cache-Control消息头进行缓存定制
   - okhttp如何用CacheControl进行缓存的控制。

## 参考

[1] https://blog.csdn.net/briblue/article/details/52920531
[2] http://www.cnblogs.com/l1pe1/archive/2010/07/14/1777621.html
[3] http://www.cnblogs.com/whoislcj/p/5537640.html
