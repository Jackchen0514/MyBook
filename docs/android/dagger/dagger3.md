# Dagger2(三)

## @Scope和@Singleton

@Scope是用来管理依赖的生命周期的。它和@Qualifier一样是用来自定义注解的，而@Singleton则是@Scope的默认实现。

```
/**
 * Identifies a type that the injector only instantiates once. Not inherited.
 *
 * @see javax.inject.Scope @Scope
 */

 @Scope
 @Documented
 @Retention(RUNTIME)
 public @interface Singleton {}
```

Component会帮我们注入被@Inject标记的依赖，并且可以注入多个。
但是每次注入都是重新new了一个依赖。如

{%ace edit=true lang='java'%}
public class MainActivity extends AppCompatActivity {

    private static final String TAG = "MainActivity";

    @Inject
    Pot pot;

    @Inject
    Pot pot2;

    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        DaggerMainActivityComponent.builder()
                .potComponent(DaggerPotComponent.builder()
                                .flowerComponent(DaggerFlowerComponent.create()).build())
                .build().inject(this);

        Log.d(TAG, "pot = " + pot.hashCode() +", pot2 = " + pot2.hashCode());


        String show = pot.show();
        Toast.makeText(MainActivity.this, show, Toast.LENGTH_SHORT).show();

    }
}
{%endace%}

打印的地址值不一样，是两个对象。

```
D/MainActivity: pot = com.aitsuki.architecture.pot.Pot@240f3ff5, pot2 = com.aitsuki.architecture.pot.Pot@2c79118a
```

假设我们需要Pot对象的生命周期和app相同，也就是单例，我们需要怎么做？这时候就可以用到@Scope注解了。

我们来使用默认的@Scope实现——@Singleton
需要在@Provide和@Component中同时使用才起作用，为什么呢，待会会说明。

{%ace edit=true lang='java'%}

@Module
public class PotModule {

    @Provides
    @Singleton
    Pot providePot(@RoseFlower Flower flower) {
        return new Pot(flower);
    }
}

{%endace%}

-


{%ace edit=true lang='java'%}

@Singleton
@Component(modules = PotModule.class, dependencies = FlowerComponent.class)
public interface PotComponent {
    Pot getPot();
}

{%endace%}

然后我们再运行下项目，报错了

那是因为我们的MainActivityComponent依赖PotComponent，而dagger2规定子Component也必须标注@Scope。

但是我们不能给MainActivityComponent也标注@Singleton，并且dagger2也不允许。因为单例依赖单例是不符合设计原则的，我们需要自定义一个@Scope注解。

定义Scope是名字要起得有意义，能一眼就让你看出这个Scope所规定的生命周期。
比如ActivityScope 或者PerActivity，生命周期和Activity相同。

{%ace edit=true lang='java'%}

@Scope
@Retention(RetentionPolicy.RUNTIME)
public @interface ActivityScope {}

{%endace%}

{%ace edit=true lang='java'%}

@ActivityScope
@Component(dependencies = PotComponent.class)
public interface MainActivityComponent {
    void inject(MainActivity activity);
}

{%endace%}

```
D/MainActivity: pot = com.aitsuki.architecture.pot.Pot@240f3ff5, pot2 = com.aitsuki.architecture.pot.Pot@240f3ff5
```

这时候我们看到两个pot对象的地址值是一样的，@Scope注解起作用了。

那么我再新建一个Activity，再次注入pot打印地址值。

{%ace edit=true lang='java'%}



public class SecondActivity extends AppCompatActivity {

    private static final String TAG = "SecondActivity";

    @Inject
    Pot pot3;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        DaggerSecondActivityComponent.builder()
                .potComponent(DaggerPotComponent.builder().flowerComponent(DaggerFlowerComponent.create()).build())
                .build().inject(this);


        Log.d(TAG, "pot3 = " + pot3);
    }
}

{%endace%}

-

{%ace edit=true lang='java'%}

@ActivityScope
@Component(dependencies = PotComponent.class)
public interface SecondActivityComponent {
    void inject(SecondActivity activity);
}

{%endace%}


在MainActivity初始化时直接跳转到SecondActivity


{%ace edit=true lang='java'%}
public class MainActivity extends AppCompatActivity {

    private static final String TAG = "MainActivity";

    @Inject
    Pot pot;

    @Inject
    Pot pot2;


    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        DaggerMainActivityComponent.builder()
                .potComponent(DaggerPotComponent.builder()
                                .flowerComponent(DaggerFlowerComponent.create()).build())
                .build().inject(this);


        Log.d(TAG, "pot = " + pot +", pot2 = " + pot2);

        String show = pot.show();

        Toast.makeText(MainActivity.this, show, Toast.LENGTH_SHORT).show();

        startActivity(new Intent(this, SecondActivity.class));
    }
}

{%endace%}


```
D/MainActivity: pot = com.aitsuki.architecture.pot.Pot@240f3ff5, pot2 = com.aitsuki.architecture.pot.Pot@240f3ff5
D/SecondActivity: pot3 = com.aitsuki.architecture.pot.Pot@1b7661c7
```

可以看到，在SecondActivity中，Pot对象地址和MainActivity中的不一样了。
为什么呢？不是叫@Singleton么，为什么使用了它Pot还不是单例的，Dagger2你逗我

---

那么现在我可以说说@Scope的作用了，它的作用只是保证依赖在@Component中是唯一的，可以理解为“局部单例”

@Scope是需要成对存在的，在Module的Provide方法中使用了@Scope，那么对应的Component中也必须使用@Scope注解，当两边的@Scope名字一样时（比如同为@Si
ngleton）, 那么该Provide方法提供的依赖将会在Component中保持“局部单例”。
而在Component中标注@Scope，provide方法没有标注，那么这个Scope就不会起作
用，而Component上的Scope的作用也只是为了能顺利通过编译，就像我刚刚定义的ActivityScope一样。

@Singleton也是一个自定义@Scope，它的作用就像上面说的一样。但由于它是Dagger2中默认定义的，所以它比我们自定义Scope对了一个功能，就是编译检测，防止我们不规范的使用Scope注解，仅此而已。

在上面的Demo中，Pot对象在PotComponent中是“局部单例”的。
而到了SecondActivity，因为是重新Build了一个PotComponent，所以Pot对象的地址值也就改变了。

**那么，我们如何使用Dagger2实现单例呢？**

很简单，做到以下两点即可。

1. 依赖在Component中是单例的（供该依赖的provide方法和对应的Component类使用同一个Scope注解。）

2. 对应的Component在App中只初始化一次，每次注入依赖都使用这个Component对象。（在Application中创建该Component）

如：

{%ace edit=true lang='java'%}

public class App extends Application {

    private PotComponent potComponent;


    @Override
    public void onCreate() {
        super.onCreate();
        potComponent = DaggerPotComponent.builder()
                .flowerComponent(DaggerFlowerComponent.create())
                .build();
    }

    public PotComponent getPotComponent() {
        return potComponent;
    }
}

{%endace%}


然后修改MainActivity和SecondActivity的Dagger代码如下

{%ace edit=true lang='java'%}

public class MainActivity extends AppCompatActivity {

    private static final String TAG = "MainActivity";

    @Inject
    Pot pot;

    @Inject
    Pot pot2;


    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        DaggerMainActivityComponent.builder()
                .potComponent(((App) getApplication()).getPotComponent())
                .build().inject(this);

        Log.d(TAG, "pot = " + pot +", pot2 = " + pot2);

        String show = pot.show();

        Toast.makeText(MainActivity.this, show, Toast.LENGTH_SHORT).show();

        startActivity(new Intent(this, SecondActivity.class));

        }
}
{%endace%}

-

{%ace edit=true lang='java'%}

public class SecondActivity extends AppCompatActivity {

    private static final String TAG = "SecondActivity";

    @Inject
    Pot pot3;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);


        DaggerSecondActivityComponent.builder()
                .potComponent(((App) getApplication()).getPotComponent())
                .build().inject(this);

        Log.d(TAG, "pot3 = " + pot3);
    }
}

{%endace%}

运行后的log输出

```
D/MainActivity: pot = com.aitsuki.architecture.pot.Pot@240f3ff5, pot2 = com.aitsuki.architecture.pot.Pot@240f3ff5
D/SecondActivity: pot3 = com.aitsuki.architecture.pot.Pot@240f3ff5
```
现在Pot的生命周期就和app相同了。

你也可以试试自定义一个@ApplicationScope，替换掉@Singleton，结果是一样的，这里就不演示了。

稍微总结下@Scope注解：

Scope是用来给开发者管理依赖的生命周期的，它可以让某个依赖在Component中保持 “局部单例”（唯一），如果将Component保存在Application中复用，则可以让该依赖在app中保持单例。
我们可以通过自定义不同的Scope注解来标记这个依赖的生命周期，所以命名是需要慎重考虑的。

**@Singleton告诉我们这个依赖时单例的**

**@ActivityScope告诉我们这个依赖的生命周期和Activity相同**

**@FragmentScope告诉我们这个依赖的生命周期和Fragment相同**

**@xxxxScope ……**

## MapKey和Lazy

### Mapkey

这个注解用在定义一些依赖集合（目前为止，Maps和Sets）。让例子代码自己来解释吧：

定义：

{%ace edit=true lang='java'%}

@MapKey(unwrapValue = true)
@interface TestKey {
    String value();
}

{%endace%}

提供依赖:


{%ace edit=true lang='java'%}

@Provides(type = Type.MAP)
@TestKey("foo")
String provideFooKey() {
    return "foo value";
}

@Provides(type = Type.MAP)
@TestKey("bar")
String provideBarKey() {
    return "bar value";
}
{%endace%}

使用：

{%ace edit=true lang='java'%}

@Inject
Map<String, String> map;

map.toString() // => „{foo=foo value, bar=bar value}”
{%endace%}

@MapKey注解目前只提供两种类型-String和Enum.

### Lazy

Dagger2还支持Lazy模式，通过Lazy模拟提供的实例，
在@Inject的时候并不初始化，而是等到你要使用的时候，
主动调用其.get方法来获取实例。

比如：

{%ace edit=true lang='java'%}
public class MainActivity extends AppCompatActivity {

    private static final String TAG = "MainActivity";

    @Inject
    Lazy<Pot> potLazy;

    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        DaggerMainActivityComponent.builder()
                .potComponent(((App) getApplication()).getPotComponent())
                .build().inject(this);


        Pot pot = potLazy.get();
        String show = pot.show();
        Toast.makeText(MainActivity.this, show, Toast.LENGTH_SHORT).show();

        }
}
{%endace%}

## 项目实战

https://github.com/googlesamples/android-architecture/tree/todo-mvp-dagger/
