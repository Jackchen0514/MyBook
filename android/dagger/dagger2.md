# Dagger2(二)

## @Qualifier和@Named

@Qualifier是限定符，而@Named则是基于String的限定符。

当我有两个相同的依赖（都继承某一个父类或者都是先某一个接口）可以提供给高层时，那么程序就不知道我们到底要提供哪一个依赖，因为它找到了两个。
这时候我们就可以通过限定符为两个依赖分别打上标记，指定提供某个依赖。

接着上一个Demo，例如：Module可以提供的依赖有两个。

FlowerModule.java:

{%ace edit=true lang='java'%}
//FlowerModule.java

@Module
public class FlowerModule {

    @Provides
    Flower provideRose() {
        return new Rose();
    }

    @Provides
    Flower provideLily() {
        return new Lily();
    }
}

{%endace%}


![image](https://upload-images.jianshu.io/upload_images/2202079-1c4a2b616d4e8781.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/700)

多个Provider

这时候就可以用到限定符来指定依赖了，我这里用@Named来演示。


FlowerModule.java:

{%ace edit=true lang='java'%}
//FlowerModule.java

@Module
public class FlowerModule {

    @Provides
    @Named("Rose")
    Flower provideRose() {
        return new Rose();
    }

    @Provides
    @Named("Lily")
    Flower provideLily() {
        return new Lily();
    }
}

{%endace%}

我们是通过@Inject Pot的构造器注入Flower依赖的，在这里可以用到限定符。

{%ace edit=true lang='java'%}

public class Pot {

    private Flower flower;

    @Inject
    public Pot(@Named("Rose") Flower flower) {
        this.flower = flower;
    }

    public String show() {
        return flower.whisper();
    }
}

{%endace%}

而@Qualifier的作用和@Named是完全一样的，不过更推荐使用@Qualifier，因为@Named需要手写字符串，容易出错。

@Qualifier不是直接注解在属性上的，而是用来自定义注解的。

{%ace edit=true lang='java'%}

@Qualifier
@Retention(RetentionPolicy.RUNTIME)
public @interface RoseFlower {}

{%endace%}

-

{%ace edit=true lang='java'%}

@Qualifier
@Retention(RetentionPolicy.RUNTIME)
public @interface LilyFlower {}

{%endace%}

-

{%ace edit=true lang='java'%}

@Module
public class FlowerModule {

    @Provides
    @RoseFlower
    Flower provideRose() {
        return new Rose();
    }

    @Provides
    @LilyFlower
    Flower provideLily() {
        return new Lily();
    }
}

{%endace%}

-

{%ace edit=true lang='java'%}

public class Pot {

    private Flower flower;

    @Inject
    public Pot(@RoseFlower Flower flower) {
        this.flower = flower;
    }


    public String show() {
        return flower.whisper();
    }
}

{%endace%}

我们也可以使用Module来管理Pot依赖，当然还是需要@Qualifier指定提供哪一个依赖

{%ace edit=true lang='java'%}

@Module
public class PotModule {

    @Provides
    Pot providePot(@RoseFlower Flower flower) {
        return new Pot(flower);
    }
}

{%endace%}

然后MainAcitivtyComponent需要增加一个Module

{%ace edit=true lang='java'%}

@Component(modules = {FlowerModule.class, PotModule.class})
public interface MainActivityComponent {
    void inject(MainActivity activity);
}

{%endace%}

## @Component的dependence和@SubComponent

上面也说过，Component可以依赖于其他Component，可以使用@Component的dependence，也可以使用@SubComponent，这样就可以获取其他Component的依赖了。

如：我们也用Component来管理FlowerModule和PotModule，并且使用dependence联系各个Component。
这次我就将代码贴完整点吧。

Flower.java:

{%ace edit=true lang='java'%}
//Flower.java

public abstract class Flower {
    public abstract String whisper();
}

{%endace%}


Lily.java:

{%ace edit=true lang='java'%}

//Lily.java

public class Lily extends Flower {

    @Override
    public String whisper() {
        return "纯洁";
    }
}

{%endace%}



Rose.java:

{%ace edit=true lang='java'%}

//Rose.java

public class Rose extends Flower {

    @Override
    public String whisper() {
        return "热恋";
    }
}

{%endace%}


FlowerModule.java:

{%ace edit=true lang='java'%}

@Module
public class FlowerModule {

    @Provides
    @RoseFlower
    Flower provideRose() {
        return new Rose();
    }

    @Provides
    @LilyFlower
    Flower provideLily() {
        return new Lily();
    }
}

{%endace%}


Component上也需要指定@Qualifier

{%ace edit=true lang='java'%}

@Component(modules = FlowerModule.class)
public interface FlowerComponent {
    @RoseFlower
    Flower getRoseFlower();

    @LilyFlower
    Flower getLilyFlower();
}

{%endace%}

-

{%ace edit=true lang='java'%}

public class Pot {

    private Flower flower;

    public Pot(Flower flower) {
        this.flower = flower;
    }

    public String show() {
        return flower.whisper();
    }
}
{%endace%}

PotModule需要依赖Flower，需要指定其中一个子类实现，这里使用RoseFlower

{%ace edit=true lang='java'%}

@Module
public class PotModule {

    @Provides
    Pot providePot(@RoseFlower Flower flower) {
        return new Pot(flower);
    }
}

{%endace%}

-

{%ace edit=true lang='java'%}

@Component(modules = PotModule.class,dependencies = FlowerComponent.class)
public interface PotComponent {
    Pot getPot();
}

{%endace%}

-

{%ace edit=true lang='java'%}

@Component(dependencies = PotComponent.class)
public interface MainActivityComponent {
    void inject(MainActivity activity);
}


{%endace%}


而在MainActivity则需要创建其依赖的Component

{%ace edit=true lang='java'%}

public class MainActivity extends AppCompatActivity {

    @Inject
    Pot pot;

    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        DaggerMainActivityComponent.builder()
                .potComponent(DaggerPotComponent.builder()
                        .flowerComponent(DaggerFlowerComponent.create())
                        .build())
                .build().inject(this);

        String show = pot.show();
        Toast.makeText(MainActivity.this, show, Toast.LENGTH_SHORT).show();

    }
}

{%endace%}

这就是Component的dependencies的用法了，我们Component不需要重复的指定Module，可以直接依赖其它Component获得。

分析下源码，看下Component的dependencies做了什么事情。

{%ace edit=true lang='java'%}

public final class DaggerPotComponent implements PotComponent {
  private Provider<Flower> getRoseFlowerProvider;

  private Provider<Pot> providePotProvider;

  private DaggerPotComponent(Builder builder) {

    assert builder != null;
    initialize(builder);
  }

  public static Builder builder() {
    return new Builder();
  }

  @SuppressWarnings("unchecked")
  private void initialize(final Builder builder) {
    this.getRoseFlowerProvider =
        new Factory<Flower>() {
          private final FlowerComponent flowerComponent = builder.flowerComponent;

          @Override
          public Flower get() {
            return Preconditions.checkNotNull(
                flowerComponent.getRoseFlower(),
                "Cannot return null from a non-@Nullable component method");
          }
        };

    this.providePotProvider =
        PotModule_ProvidePotFactory.create(builder.potModule, getRoseFlowerProvider);
  }


  @Override
  public Pot getPot() {
    return providePotProvider.get();
  }

  public static final class Builder {
    private PotModule potModule;

    private FlowerComponent flowerComponent;

    private Builder() {}

    public PotComponent build() {
      if (potModule == null) {
        this.potModule = new PotModule();
      }
      if (flowerComponent == null) {
        throw new IllegalStateException(FlowerComponent.class.getCanonicalName() + " must be set");
      }
      return new DaggerPotComponent(this);
    }

    public Builder potModule(PotModule potModule) {
      this.potModule = Preconditions.checkNotNull(potModule);
      return this;
    }

    public Builder flowerComponent(FlowerComponent flowerComponent) {
      this.flowerComponent = Preconditions.checkNotNull(flowerComponent);
      return this;
    }
  }
}
{%endace%}


PotComponent依赖FlowerComponent，其实就是将FlowerComponent的引用传递给PotComponent，这样PotComponent就可以使用FlowerComponent中的方法了。

注意看getRoseFlowerProvider这个Provider，是从 flowerComponent.getRoseFlower()获取到的

---

如果使用Subcomponent的话则是这么写， 其他类不需要改变，只修改Component即可

{%ace edit=true lang='java'%}

@Component(modules = FlowerModule.class)
public interface FlowerComponent {

    PotComponent plus(PotModule potModule);
}

{%endace%}

-

{%ace edit=true lang='java'%}

@Subcomponent(modules = PotModule.class)
public interface PotComponent {
    MainActivityComponent plus();
}

{%endace%}

-

{%ace edit=true lang='java'%}

@Subcomponent
public interface MainActivityComponent {
    void inject(MainActivity activity);
}

{%endace%}

-

{%ace edit=true lang='java'%}

public class MainActivity extends AppCompatActivity {

    @Inject
    Pot pot;

    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);


        DaggerFlowerComponent.create()
                .plus(new PotModule())  // 这个方法返回PotComponent
                .plus()                 // 这个方法返回MainActivityComponent
                .inject(this);

        String show = pot.show();
        Toast.makeText(MainActivity.this, show, Toast.LENGTH_SHORT).show();
    }
}

{%endace%}

FlowerComponent管理了PotComponent和MainActivityComponent，看起来不符合常理。

先来说说Component中的方法的第三种定义方式（上面说了两种）。

{%ace edit=true lang='java'%}

@Component
class AComponpent {
    XxxComponent plus(Module... modules)
}

{%endace%}

-


{%ace edit=true lang='java'%}

@Subcomponent(modules = xxxxx)
class XxxComponent {

}

{%endace%}

xxxComponent是该AComponpent的依赖，被@Subcomponent标注。
而modules参数则是xxxComponent指定的Module。

在重新编译后，Dagger2生成的代码中，Subcomponent标记的类是Componpent的内部类。
像上面的Demo，MainActivityComponent是PotComponent的内部类，而PotComponent又是FlowerComponent的内部类。

---

但是用Subcomponent怎么看怎么别扭，各个Component之间联系太紧密，不太适合我们Demo的使用场景。
**那什么时候该用@Subcomponent呢？**
Subcomponent是作为Component的拓展的时候。
像我写的Demo中，Pot和Flower还有MainActivity只是单纯的依赖关系。就算有，也只能是Flower作为Pot的Subcomponent，而不是Demo中所示，因为我需要给大家展示Dagger的API，强行使用。

**比较适合使用Subcomponent的几个场景：**
很多工具类都需要使用到Application的Context对象，此时就可以用一个Component负责提供，我们可以命名为AppComponent。

需要用到的context对象的SharePreferenceComponent，ToastComponent就可以它作为Subcomponent存在了。

而且在AppComponent中，我们可以很清晰的看到有哪些子Component，因为在里面我们定义了很多`XxxComponent plus(Module... modules)`

每个ActivityComponent也是可以作为AppComponent的Subcomponent，这样可以更方便的进行依赖注入，减少重复代码。

**Component dependencies和Subcomponent区别**

1. Component dependencies 能单独使用，而Subcomponent必须由Component调用方法获取。

2. Component dependencies 可以很清楚的得知他依赖哪个Component， 而Subcomponent不知道它自己的谁的孩子……真可怜

3. 使用上的区别，Subcomponent就像这样`DaggerAppComponent.plus(new SharePreferenceModule());`

   使用Dependence可能是这样`DaggerAppComponent.sharePreferenceComponent(SharePreferenceComponent.create())`

**Component dependencies和Subcomponent使用上的总结**

- Component Dependencies：

1. 你想保留独立的想个组件（Flower可以单独使用注入，Pot也可以）

2. 要明确的显示该组件所使用的其他依赖

- Subcomponent：

1. 两个组件之间的关系紧密

2. 你只关心Component，而Subcomponent只是作为Component的拓展，可以通过Component.xxx调用。

