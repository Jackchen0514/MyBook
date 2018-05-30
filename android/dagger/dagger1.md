# Dagger2(一)

## 简述

dagger2是一个基于JSR-330标准的依赖注入框架，在编译期间自动生成代码，负责依赖对象的创建。
JSR即Java Specification Requests，意思是java规范提要。
为了进一步解耦和方便测试，我们会使用依赖注入的方式构建对象。

## Dagger2 API
```
public @interface Component {
    Class<?>[] modules() default {};
    Class<?>[] dependencies() default {};
}

public @interface Subcomponent {
    Class<?>[] modules() default {};
}

public @interface Module {
    Class<?>[] includes() default {};
}

public @interface Provides {
}

public @interface MapKey {
    boolean unwrapValue() default true;
}

public interface Lazy<T> {
    T get();
}
```

还有在Dagger 2中用到的定义在 JSR-330 （Java中依赖注入的标准）中的其它元素：

```
public @interface Inject {
}

public @interface Scope {
}

public @interface Qualifier {
}
```

## @Inject和@Component

先来看一段没有使用dagger的依赖注入Demo
MainActivity依赖Pot， Pot依赖Rose
Rose.java:

{%ace edit=true lang='java'%}
//Rose.java
public class Rose {
    public String whisper()  {
        return "热恋";
    }
}

{%endace%}

Pot.java:

{%ace edit=true lang='java'%}
//Pot.java

public class Pot {

    private Rose rose;

    public Pot(Rose rose) {
        this.rose = rose;
    }

    public String show() {
        return rose.whisper();
    }
}

{%endace%}

MainActivity.java:

{%ace edit=true lang='java'%}
//MainActivity.java

public class MainActivity extends AppCompatActivity {

    private Pot pot;

    protected void onCreate(@Nullable Bundle savedInstanceState) {
         super.onCreate(savedInstanceState);
         Rose rose = new Rose();
         pot = new Pot(rose);

         String show = pot.show();
         Toast.makeText(MainActivity.this, show, Toast.LENGTH_SHORT).show();
    }
}
{%endace%}

使用Dagger2进行依赖注入如下:

Rose.java:

{%ace edit=true lang='java'%}

public class Rose {

    @Inject
    public Rose() {}

    public String whisper()  {
        return "热恋";
    }
}
{%endace%}

Pot.java:

{%ace edit=true lang='java'%}
//Pot.java
public class Pot {

    private Rose rose;

    @Inject
    public Pot(Rose rose) {
        this.rose = rose;
    }

    public String show() {
        return rose.whisper();
    }
}

{%endace%}

MainActivityComponent.java:

{%ace edit=true lang='java'%}
//MainActivityComponent.java

@Component
public interface MainActivityComponent {
    void inject(MainActivity activity);
}

{%endace%}

MainActivity.java:

{%ace edit=true lang='java'%}
//MainActivity.java

public class MainActivity extends AppCompatActivity {

    @Inject
    Pot pot;

    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // 这个类是重新编译后Dagger2自动生成的，所以写这行代码之前要先编译一次
        // Build --> Rebuild Project
        DaggerMainActivityComponent.create().inject(this);
        String show = pot.show();
        Toast.makeText(MainActivity.this, show, Toast.LENGTH_SHORT).show();
    }
}

{%endace%}

Dagger2生成的代码保存在这里：

![image](https://upload-images.jianshu.io/upload_images/2202079-cdf20511b8e40939.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/435)


源码待会分析，现在先来了解下`@Inject`和`@Component`两个API，想要使用`Dagger2`进行依赖注入，至少要使用到这两个注解。
`@Inject`用于标记需要注入的依赖，或者标记用于提供依赖的方法。
`@Component`则可以理解为注入器，在注入依赖的目标类MainActivity使用Component完成注入。


## @Inject

依赖注入中第一个并且是最重要的就是`@Inject`注解。JSR-330标准中的一部分，标记那些应该被依赖注入框架提供的依赖。在Dagger 2中有3种不同的方式来提供依赖：

- **构造器注入**

  1) 告诉Dagger2可以使用这个构造器构建对象。如Rose类
  2) 注入构造器所需要的参数的依赖。 如Pot类，构造上的Rose会被注入。

  构造器注入的局限：如果有多个构造器，我们只能标注其中一个，无法标注多个。

- **属性注入**

  如MainActivity类，标注在属性上。被标注的属性不能使用`private`,否则无法注入。

  属性注入也是Dagger2使用最多的一个注入方式。

- **方法注入**

{%ace edit=true lang='java'%}

public class MainActivity extends AppCompatActivity {


    private Pot pot;

    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // 这个类是重新编译后Dagger2自动生成的，所以写这行代码之前要先编译一次
        // Build --> Rebuild Project
        DaggerMainActivityComponent.create().inject(this);
        String show = pot.show();
        Toast.makeText(MainActivity.this, show, Toast.LENGTH_SHORT).show();
    }

    @Inject
    public void setPot(Pot pot) {
        this.pot = pot
    }
}

{%endace%}

标注在public方法上，Dagger2会在构造器执行之后立即调用这个方法。
方法注入和属性注入基本上没有区别， 那么什么时候应该使用方法注入呢？
比如该依赖需要this对象的时候，使用方法注入可以提供安全的this对象，因为方法注入是在构造器之后执行的。

比如google mvp dagger2中，给View设置Presenter的时候可以这样使用方法注入。

```
    @Inject
    void setupListeners() {
        mTasksView.setPresenter(this);
    }
```

## @Component

`@Inject`注解只是JSR-330中定义的注解，在javax.inject包中。
这个注解本身并没有作用，它需要依赖于注入框架才具有意义，用来标记需要被注入框架注入的方法，属性，构造。


而Dagger2则是用`Component`来完成依赖注入的，`@Component`可以说是Dagger2中最重要的一个注解。

```
@Component
public interface MainActivityComponent {
    void inject(MainActivity activity);
}
```

以上是定义一个Component的方式。使用接口定义，并且@Component注解。
命名方式推荐为：目标类名+Component，在编译后Dagger2就会为我们生成DaggerXXXComponent这个类，它是我们定义的xxxComponent的实现，在目标类中使用它就可以实现依赖注入了。

- **Component中一般使用两种方式定义方法**

1. `void inject(目标类 obj);` Dagger2会从目标类开始查找@Inject注解，自动生成依赖注入的代码，调用inject可完成依赖的注入。

2. `Object getObj();`  如： `Pot getPot();`

Dagger2会到Pot类中找被@Inject注解标注的构造器，自动生成提供Pot依赖的代码，这种方式一般为其他Component提供依赖。（一个Component可以依赖另一个Component，后面会说）

- **Component和Inject的关系如下：**

![image](https://upload-images.jianshu.io/upload_images/2202079-51b78542dd3c8575.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/592)

Dagger2框架以Component中定义的方法作为入口，到目标类中寻找JSR-330定义的@Inject标注，生成一系列提供依赖的Factory类和注入依赖的Injector类。
而Component则是联系Factory和Injector，最终完成依赖的注入。

## @Module和@Provides

使用@Inject标记构造器提供依赖是有局限性的，比如说我们需要注入的对象是第三方库提供的，我们无法在第三方库的构造器上加上@Inject注解。
或者，我们使用依赖倒置的时候，因为需要注入的对象是抽象的，@Inject也无法使用，因为抽象的类并不能实例化，比如：

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

    @Inject
    Lily() {}

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

    @Inject
    public Rose() {}

    public String whisper()  {
        return "热恋";
    }
}

{%endace%}

Pot.java:

{%ace edit=true lang='java'%}
//Pot.java
public class Pot {

    private Flower flower;

    @Inject
    public Pot(Flower flower) {
        this.flower = flower;
    }

    public String show() {
        return flower.whisper();
   }
}
{%endace%}

修改下Demo，遵循依赖倒置规则。但是这时候Dagger就报错了，因为Pot对象需要Flower，而Flower是抽象的，无法使用@Inject提供实例。

![image](https://upload-images.jianshu.io/upload_images/2202079-798acb053f54eb7d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/700)

这个时候就需要用到Module了。

清除Lily和Rose的@Inject

Flower.java:
{%ace edit=true lang='java'%}
//Flower
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

    public String whisper()  {
        return "热恋";
    }
}

{%endace%}

@Module标记在类上面，@Provodes标记在方法上，表示可以通过这个方法获取依赖。

FlowerModule.java:

{%ace edit=true lang='java'%}
//FlowerModule.java

@Module
public class FlowerModule {
    @Provides
    Flower provideFlower() {
        return new Rose();
    }
}
{%endace%}

在@Component中指定Module

{%ace edit=true lang='java'%}

@Component(modules = FlowerModule.class)
public interface MainActivityComponent {
    void inject(MainActivity activity);
}

{%endace%}

其他类不需要更改，这样就完成了。

那么Module是干嘛的，我们来看看生成的类。

![image](https://upload-images.jianshu.io/upload_images/2202079-60ef03623d0d85c6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/401)

可以看到，被@Module注解的类生成的也是Factory。

{%ace edit=true lang='java'%}

public final class FlowerModule_FlowerFactory implements Factory<Flower> {
  private final FlowerModule module;

  public FlowerModule_FlowerFactory(FlowerModule module) {
    assert module != null;
    this.module = module;
  }

   @Override
    public Flower get() {
      return Preconditions.checkNotNull(
           module.provideFlower(), "Cannot return null from a non-@Nullable @Provides method");
    }

    public static Factory<Flower> create(FlowerModule module) {
          return new FlowerModule_FlowerFactory(module);
        }
    }

{%endace%}

@Module需要和@Provide是需要一起使用的时候才具有作用的，并且@Component也需要指定了该Module的时候。

@Module是告诉Component，可以从这里获取依赖对象。Component就会去找被@Provide标注的方法，相当于构造器的@Inject，可以提供依赖。

还有一点要说的是，@Component可以指定多个@Module的，如果需要提供多个依赖的话。
并且Component也可以依赖其它Component存在。

## 参考

[1] https://www.jianshu.com/p/24af4c102f62