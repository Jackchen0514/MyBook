# RxJava2.x(1/2)

## 添加依赖

Android端使用RxJava需要依赖新的包名：

```
//RxJava的依赖包（我使用的最新版本）
compile 'io.reactivex.rxjava2:rxjava:2.0.1'
//RxAndroid的依赖包
compile 'io.reactivex.rxjava2:rxandroid:2.0.1'
```


## 创建Observable

Observable是什么？观察者还是被观察者？我又忘了。哈哈。开个玩笑，当然是后者了。为什么是先创建Observable而不是Observer？当然了，先后顺序的无所谓的。但是考虑到后面的链式调用。所以我这边就先写了先创建Observable了。

{%ace edit=true lang='java'%}

Observable<String> observable = Observable.create(new ObservableOnSubscribe<String>() {
            @Override
            public void subscribe(ObservableEmitter<String> emitter) throws Exception {
                emitter.onNext("Hello");
                emitter.onNext("Rxjava2");
                emitter.onNext("My name is Silence");
                emitter.onNext("What's your name");
                //一旦调用onComplete,下面将不在接受事件
                emitter.onComplete();
            }
        });

{%endace%}


现在我来解释一下上面的ObservableEmitter到底是什么。字面意思是可观察的发射器。没错，这个就是被观察者用来发送事件的。它可以发出三种类型的事件，通过调用emitter的onNext(T value)、onError(Throwable error)和onComplete()就可以分别发出next事件、error事件和complete事件。至于这三个事件到底什么意思。不急，我们后面说。

## 创建Observer

现在我们来创建一个观察者，它决定了在观察中到底应该有着什么样的行为操作。

{%ace edit=true lang='java'%}

Observer<String> observer = new Observer<String>() {
    @Override
    public void onSubscribe(Disposable d) {
        Log.i(TAG, "onSubscribe: " + d);
        result += "onSubscribe: " + d + "\n";
    }

    @Override
    public void onNext(String string) {
        Log.i(TAG, "onNext: " + string);
        result += "onNext: " + string + "\n";
    }

    @Override
    public void onError(Throwable e) {
        Log.i(TAG, "onError: " + e);
        result += "onError: " + e + "\n";
    }

    @Override
    public void onComplete() {
        Log.i(TAG, "onComplete: ");
        result += "onComplete: " + "\n";
    }
};

{%endace%}

其中onSubscribe、onNext、onError和onComplete是必要的实现方法，其含义如下：

- `onSubscribe`：它会在事件还未发送之前被调用，可以用来做一些准备操作。而里面的Disposable则是用来切断上下游的关系的。

- `onNext`：普通的事件。将要处理的事件添加到队列中。

- `onError`：事件队列异常，在事件处理过程中出现异常情况时，此方法会被调用。同时队列将会终止，也就是不允许在有事件发出。

- `onComplete`：事件队列完成。rxjava不仅把每个事件单独处理。而且会把他们当成一个队列。当不再有onNext事件发出时，需要触发onComplete方法作为完成标识。

## 进行subscribe

订阅其实只需要一行代码就够了:

```
observerable.subscribe(Observer);

```

运行一个看看效果：

![image](https://user-gold-cdn.xitu.io/2017/12/27/160984b5f1866840?imageView2/0/w/1280/h/960/ignore-error/1)

和之前介绍的一样，先调用onSubscribe，然后走了onNext，最后以onComplete收尾。

## 神奇的操作符

- **创建操作符**

一般创建操作符是指，刚开始创建观察者的时候调用的。在基本使用中我已经介绍了create操作符，那么这边我们就要说到just，fromarray和interval了。

- **just**

此操作符是将传入的参数依次发出来。

{%ace edit=true lang='java'%}

Observable observable = Observable.just("Hello", "Rxjava2", "My name is Silence","What's your name");
// 将会依次调用：
// onNext("Hello");
// onNext("Rxjava2");
// onNext("My name is Silence");
// onNext("What's your name");
// onCompleted();

{%endace%}

- **fromarray**

将传入的数组通过坐标一次发送出去。

{%ace edit=true lang='java'%}

String[] words = {"Hello", "Rxjava2", "My name is Silence","What's your name"};
Observable observable = Observable.from(words);
// 将会依次调用：
// onNext("Hello");
// onNext("Rxjava2");
// onNext("My name is Silence");
// onNext("What's your name");
// onCompleted();

{%endace%}


- **interval**

这个其实就是定时器，用了它你可以抛弃CountDownTimer了。现在我们看看怎么用：

{%ace edit=true lang='java'%}

 Observable.interval(2, TimeUnit.SECONDS).subscribe(
                new Consumer<Long>() {
                    @Override
                    public void accept(Long aLong) throws Exception {
                        Log.i(TAG, "accept: "+aLong.intValue());
                    }
                }
        );

{%endace%}

我们看看结果：

![image](https://user-gold-cdn.xitu.io/2017/12/27/160984c4b460c6e9?imageView2/0/w/1280/h/960/ignore-error/1)

上面就是我们每隔2s打印一次long的值。

### 变换操作符

变换操作符的作用是对Observable发射的数据按照一定规则做一些变换操作，然后讲变换后的数据发射出去。变换操作符有map，flatMap，concatMap，switchMap，buffer，groupBy等等。这里我们会讲解最常用的map，flatMap、concatMap以及compose。

- **map**

map操作符通过指定一个Function对象，将Observable转换为一个新的Observable对象并发射，观察者将收到新的Observable处理。直接上代码：

{%ace edit=true lang='java'%}

  Observable.create(new ObservableOnSubscribe<Integer>() {
            @Override
            public void subscribe(ObservableEmitter<Integer> emitter) throws Exception {
                emitter.onNext(1);
                emitter.onNext(2);
                emitter.onNext(3);
                emitter.onNext(4);
            }
        }).map(new Function<Integer, String>() {
            @Override
            public String apply(Integer integer) throws Exception {
                return "This is result " + integer + "\n";
            }
        }).subscribe(new Consumer<String>() {
            @Override
            public void accept(String str) throws Exception {
                Log.i("--->", "accept: "+str);
                string += str;
            }
        });
        tv_first.setText(string);

{%endace%}

输入结果如下：

![image](https://user-gold-cdn.xitu.io/2017/12/27/160984c7ffcc5121?imageView2/0/w/1280/h/960/ignore-error/1)

仔细看，map()方法中，我们把一个integer对象转换成了一个String对象。然后当map()调用结束时，事件的参数类型也从integer转换成了String。这就是最常见的变换操作。

- **flatMap**

flatmap的操作符是将Observable发射的数据集合变成一个Observable集合。也就是说它可以讲一个观察对象变换成多个观察对象，但是并不能保证事件的顺序。想保证事件的顺序？那你过会看下面降到的concatMap。那么什么叫作数据集合变成一个Observable集合呢？还是用上面的例子，我有一组integer集合。我想转换成string集合怎么办？那就继续看代码：

{%ace edit=true lang='java'%}

  Observable.create(new ObservableOnSubscribe<Integer>() {
            @Override
            public void subscribe(ObservableEmitter<Integer> emitter) throws Exception {
                emitter.onNext(1);
                emitter.onNext(2);
                emitter.onNext(3);
            }
        }).flatMap(new Function<Integer, ObservableSource<String>>() {
            @Override
            public ObservableSource<String> apply(Integer integer) throws Exception {
                final List<String> list = new ArrayList<>();
                for (int i = 0; i < 3; i++) {
                    list.add("I am value " + integer + "\n");
                }
                return Observable.fromIterable(list);
            }
        }).subscribe(new Consumer<String>() {
            @Override
            public void accept(String s) throws Exception {
                Log.i("--->", "accept: "+s);
                string += s;
            }
        });
        tv_first.setText(string);

{%endace%}

我们来看看结果：

![image](https://user-gold-cdn.xitu.io/2017/12/27/160984c9dc8ef403?imageView2/0/w/1280/h/960/ignore-error/1)

打住打住，是不是有问题？WTF？有啥问题？还记不记得我上面说过flatMap不能保证事件执行顺序。那么这边事件为什么都是按顺序执行的？不急，我们在发射事件的时候给他加一个延迟在看看结果：

{%ace edit=true lang='java'%}

 Observable.create(new ObservableOnSubscribe<Integer>() {
            @Override
            public void subscribe(ObservableEmitter<Integer> emitter) throws Exception {
                emitter.onNext(1);
                emitter.onNext(2);
                emitter.onNext(3);
            }
        }).flatMap(new Function<Integer, ObservableSource<String>>() {
            @Override
            public ObservableSource<String> apply(Integer integer) throws Exception {
                final List<String> list = new ArrayList<>();
                for (int i = 0; i < 3; i++) {
                    list.add("I am value " + integer + "\n");
                }
                return Observable.fromIterable(list).delay(100,TimeUnit.MILLISECONDS);
            }
        }).subscribe(new Consumer<String>() {
            @Override
            public void accept(String s) throws Exception {
                Log.i("--->", "accept: "+s);
                string += s;
            }
        });
        tv_first.setText(string);

{%endace%}


我们在当他发射事件的时候给他加一个100ms的延迟看看结果：

![image](https://user-gold-cdn.xitu.io/2017/12/27/160984cba872eac3?imageView2/0/w/1280/h/960/ignore-error/1)

看到没有，我说啥的？不能保证执行顺序。所以万事容我慢慢道来。先喝杯茶压压惊。我们在接着往下讲。

- **concatMap**

上面我也介绍了concatMap。除了保证了执行顺序，其他都和concatMap一毛一样。你说保证就保证啊。您先喝杯茶，接着往下看：

{%ace edit=true lang='java'%}

 Observable.create(new ObservableOnSubscribe<Integer>() {
            @Override
            public void subscribe(ObservableEmitter<Integer> emitter) throws Exception {
                emitter.onNext(1);
                emitter.onNext(2);
                emitter.onNext(3);
            }
        }).concatMap(new Function<Integer, ObservableSource<String>>() {
            @Override
            public ObservableSource<String> apply(Integer integer) throws Exception {
                final List<String> list = new ArrayList<>();
                for (int i = 0; i < 3; i++) {
                    list.add("I am value " + integer + "\n");
                }
                return Observable.fromIterable(list).delay(1000,TimeUnit.MILLISECONDS);
//                return Observable.fromIterable(list);
            }
        }).subscribe(new Consumer<String>() {
            @Override
            public void accept(String s) throws Exception {
                Log.i("--->", "accept: "+s);
                string += s;
            }
        });
        tv_first.setText(string);

{%endace%}

为了我们能看的更明显一点，我们这边直接设置了一秒钟的延迟。下面我们来看效果图：

![image](https://user-gold-cdn.xitu.io/2017/12/27/160984cdbca617b9?imageView2/0/w/1280/h/960/ignore-error/1)

可以从执行顺序和打印时间看出，的的确确是延迟了一秒钟。

- **compose**

这个操作符就很厉害了。他的变换是怎么做的呢？我们知道rxjava是通过建造者的模式通过链式来调用起来的。那么多个链式就需要多个Observable。而这个操作符就是把多个Observable转化成一个Observable。听起来是不是很厉害~。具体如何操作，我们接着看：

{%ace edit=true lang='java'%}


    public  <T> ObservableTransformer<T, T> applyObservableAsync() {
        return new ObservableTransformer<T, T>() {
            @Override
            public ObservableSource<T> apply(Observable<T> upstream) {
                return upstream.subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread());
            }
        };
    }

{%endace%}

上面代码可以看出，我把子线程和主线程进行了一个封装，然后返回了一个ObservableTransformer对象。那么我们只要这边做就可以了：

{%ace edit=true lang='java'%}

    Observable.just(1, 2, 3, 4, 5, 6)
                .compose(this.<Integer>applyObservableAsync())
                .subscribe(new Consumer<Integer>() {
            @Override
            public void accept(Integer strings) throws Exception {
                Log.i("-->", "accept: " + strings);
                string += strings;
            }
        });
        tv_first.setText(string);

{%endace%}


## 过滤操作符

过滤操作符用于过滤和选择Observable发射的数据序列。让Observable只返回满足我们条件的数据。过滤操作符有buffer，filter，skip，take，skipLast，takeLast等等，这边我会介绍到filter，buffer，skip，take，distinct。

- **filter**

filter操作符是对源Observable产生的结果进行有规则的过滤。只有满足规则的结果才会提交到观察者手中。例如：

{%ace edit=true lang='java'%}

   Observable.just(1,2,3).filter(new Predicate<Integer>() {
            @Override
            public boolean test(Integer integer) throws Exception {
                return integer < 3;
            }
        }).subscribe(new Consumer<Integer>() {
            @Override
            public void accept(Integer s) throws Exception {
                Log.i("--->", "accept: " + s);
                string += s;
            }
        });
        tv_first.setText(string);
    }

{%endace%}

代码很简单，我们发送1，2，3；但是我们加上一个filter操作符，让它只返回小于3的的内容。那么我们来看一下结果：

![image](https://user-gold-cdn.xitu.io/2017/12/27/160984cfaab37941?imageView2/0/w/1280/h/960/ignore-error/1)

- **distinct**

这个操作符其实就更简单了。比如说，我要在一组数据中去掉重复的内容，就要用到它。也就是去重。它只允许还没有发射的数据项通过。发射过的数据项直接pass。

{%ace edit=true lang='java'%}

        Observable.just(1,2,3,4,2,3,5,6,1,3)
                .distinct().subscribe(new Consumer<Integer>() {
            @Override
            public void accept(Integer s) throws Exception {
                Log.i("--->", "accept: " + s);
                string += s;
            }
        });
        tv_first.setText(string);

{%endace%}

那么输出结果就很简单了：

![image](https://user-gold-cdn.xitu.io/2017/12/27/160984d12ac81648?imageView2/0/w/1280/h/960/ignore-error/1)

- **buffer**

这个其实也不难，主要是缓存，把源Observable转换成一个新的Observable。这个新的Observable每次发射的是一组List，而不是单独的一个个的发送数据源。

{%ace edit=true lang='java'%}

  Observable.just(1,2,3,4,5,6)
                .buffer(2).subscribe(new Consumer<List<Integer>>() {
            @Override
            public void accept(List<Integer> strings) throws Exception {
                for (Integer integer : strings) {
                    Log.i("-->", "accept: "+integer);
                    string+=strings;
                }
                Log.i("-->", "accept: ----------------------->");
            }
        });
        tv_first.setText(string);

{%endace%}

我们让他每次缓存2个，下面我们来看结果：

![image](https://user-gold-cdn.xitu.io/2017/12/27/160984d294f1beda?imageView2/0/w/1280/h/960/ignore-error/1)

- **skip 、take**

skip操作符将源Observable发射过的数据过滤掉前n项，而take操作则只取前n项；另外还有skipLast和takeLast则是从后往前进行过滤。先来看看skip操作符。

{%ace edit=true lang='java'%}

 Observable.just(1, 2, 3, 4, 5, 6)
                .skip(2).subscribe(new Consumer<Integer>() {
            @Override
            public void accept(Integer strings) throws Exception {
                Log.i("-->", "accept: " + strings);
                string += strings;
            }
        });
        tv_first.setText(string);

{%endace%}

结果如下：

![image](https://user-gold-cdn.xitu.io/2017/12/27/160984d44128a065?imageView2/0/w/1280/h/960/ignore-error/1)

接下来我们把skip换成take看看。

{%ace edit=true lang='java'%}

 Observable.just(1, 2, 3, 4, 5, 6)
                .take(3).subscribe(new Consumer<Integer>() {
            @Override
            public void accept(Integer strings) throws Exception {
                Log.i("-->", "accept: " + strings);
                string += strings;
            }
        });
        tv_first.setText(string);

{%endace%}


结果如下：

![image](https://user-gold-cdn.xitu.io/2017/12/27/160984d6247d4153?imageView2/0/w/1280/h/960/ignore-error/1)

### 组合操作符

- **merge**

merge是将多个操作符合并到一个Observable中进行发射，merge可能让合并到Observable的数据发生错乱。（并行无序）

{%ace edit=true lang='java'%}

  Observable<Integer> observable1=Observable.just(1,2,3);
        Observable<Integer> observable2=Observable.just(1,2,3);
        Observable.merge(observable1,observable2).subscribe(new Consumer<Integer>() {
            @Override
            public void accept(Integer integer) throws Exception {
                Log.i(TAG, "accept: "+integer);
            }
        });

{%endace%}

结果如下：

![image](https://user-gold-cdn.xitu.io/2017/12/27/160984d7afcc2e54?imageView2/0/w/1280/h/960/ignore-error/1)

- **concat**

将多个Observable发射的数据进行合并并且发射，和merge不同的是，merge是无序的，而concat是有序的。（串行有序）没有发射完前一个它一定不会发送后一个。

{%ace edit=true lang='java'%}

 Observable<Integer> observable1=Observable.just(1,2,3);
        Observable<Integer> observable2=Observable.just(4,5,6);
        Observable.concat(observable1,observable2).subscribe(new Consumer<Integer>() {
            @Override
            public void accept(Integer integer) throws Exception {
                Log.i(TAG, "accept: "+integer);
            }
        });

{%endace%}

结果如下：

![image](https://user-gold-cdn.xitu.io/2017/12/27/160984d9cf1d83af?imageView2/0/w/1280/h/960/ignore-error/1)

- **zip**

此操作符和合并多个Observable发送的数据项，根据他们的类型就行重新变换，并发射一个新的值。

{%ace edit=true lang='java'%}

  Observable<Integer> observable1=Observable.just(1,2,3);
        Observable<String> observable2=Observable.just("a","b","c");
        Observable.zip(observable1, observable2, new BiFunction<Integer, String, String>() {
​
            @Override
            public String apply(Integer integer, String s) throws Exception {
                return integer+s;
            }
        }).subscribe(new Consumer<String>() {
            @Override
            public void accept(String s) throws Exception {
                Log.i(TAG, "apply: "+s);
            }
        });

{%endace%}

结果如下：

![image](https://user-gold-cdn.xitu.io/2017/12/27/160984db1ee869f9?imageView2/0/w/1280/h/960/ignore-error/1)

- **concatEager**

前面说道串行有序，而concatEager则是并行且有序。我们来看看如果修改

{%ace edit=true lang='java'%}

 Observable<Integer> observable1=Observable.just(1,2,3);
        Observable<String> observable2=Observable.just("a","b","c");
        Observable.concatEager(Observable.fromArray(observable1,observable2)).subscribe(new Consumer<Serializable>() {
            @Override
            public void accept(Serializable serializable) throws Exception {
                Log.i(TAG, "accept: "+serializable);
            }
        });

{%endace%}

结果如下：

![image](https://user-gold-cdn.xitu.io/2017/12/27/160984dd29f3c6d9?imageView2/0/w/1280/h/960/ignore-error/1)



## 参考

[1] https://zhuanlan.zhihu.com/p/24482660