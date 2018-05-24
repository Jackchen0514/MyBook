# mvp架构搭建

## 为什么要用MVP模式

MVP 模式将Activity中的业务逻辑全部分离出来， 让Activity只做UI逻辑的处理， 所有跟Android API无关的业务逻辑由
Presenter层来完成。

将业务处理分离出来后最明显的好处就是管理方便，但是缺点就是增加了代码量。

## MVP理论知识

在MVP架构中跟MVC类似的同样也分为三层。

Activity和Fragment视为View层，负责处理UI。

Presenter为业务处理层， 既能调用UI逻辑， 又能请求数据， 该层为纯Java类， 不涉及任何的Android API。

Model层中包含着具体的数据请求， 数据源。

三层之间调用顺序为view->presenter->model, 为了调用安全着想**不可反向调用！不可跨级调用！**

那Model层如何反馈给Presenter层呢？Presenter又是如何操控View层呢？看图：

![image](http://www.jcodecraeer.com/uploads/userup/13953/1G020140036-F40-0.png)

上图中说明了低层的不会直接给上一层做反馈，而是通过 View 、 Callback 为上级做出了反馈，这样就解决了请求数据与更新界面的异步操作。上图中 View 和 Callback 都是以接口的形式存在的，其中 View 是经典 MVP 架构中定义的，Callback 是我自己加的。

View 中定义了 Activity 的具体操作，主要是些将请求到的数据在界面中更新之类的。

Callback 中定义了请求数据时反馈的各种状态：成功、失败、异常等。


## 参考

[1] http://www.jcodecraeer.com/a/anzhuokaifa/2017/1020/8625.html