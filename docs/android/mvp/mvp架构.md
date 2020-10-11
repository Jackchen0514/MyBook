# mvp架构搭建

## 为什么要用MVP模式

MVP 模式将Activity中的业务逻辑全部分离出来， 让Activity只做UI逻辑的处理， 所有跟Android API无关的业务逻辑由
Presenter层来完成。

将业务处理分离出来后最明显的好处就是管理方便，但是缺点就是增加了代码量。

## MVP理论知识

随着UI创建技术的功能日益增强，UI层也履行着越来越多的职责。为了更好地细分视图(View)与模型(Model)的功能，让View专注于处理数据的可视化以及与用户的交互，同时让Model只关系数据的处理，基于MVC概念的MVP(Model-View-Presenter)模式应运而生。

在MVP模式里通常包含4个要素：

(1) `View`: 负责绘制UI元素， 与用户进行交互（Activity， Fragment）;

(2) `View interface`: 需要View实现的接口，View通过View Interface与Presenter进行交互， 降低耦合， 方便进行单元测试；

(3) `Model`: 负责存储、检索、操纵数据(有时也实现一个Model interface用来降低耦合)；

(4) `Presenter`:作为View与Model交互的中间纽带，处理与用户交互的负责逻辑


## 利用MVP进行Android开发的例子

- **首先我们需要一个UserBean， 用来保存用户信息**

{%ace edit=true lang='java'%}

package com.example.xinsi.myapplication.bean;

public class UserBean {
    private String mFirstName;
    private String mLastName;

    public UserBean(String firstName, String lastName) {
        this.mFirstName = firstName;
        this.mLastName = lastName;
    }

    public String getFirstName() {
        return mFirstName;
    }

    public String getLastName() {
        return mLastName;
    }
}


{%endace%}


- **再来看看View接口**

根据需求可知，View可以对ID、FirstName、LastName这三个EditText进行读操作，对FirstName和LastName进行写的操作，由此定义IUserView接口：

{%ace edit=true lang='java'%}

public interface IUserView {
       int getID();
       String getFristName();
       String getLastName();
       void setFirstName (String firstName);
       void setLastName (String lastName);
}

{%endace%}

- **Model接口**

同样，Model也需要对这三个字段进行读写操作，并存储在某个载体内（这不是我们所关心的，可以存在内存、文件、数据库或者远程服务器，但对于Presenter及View无影响)，定义IUserModel接口：

{%ace edit=true lang='java'%}

public interface IUserModel {
       void setID (int id);
       void setFirstName (String firstName);
       void setLastName (String lastName);
       int getID();
       UserBean load (int id);//通过id读取user信息,返回一个UserBean
}

{%endace%}

- **Presenter**

至此，Presenter就能通过接口与View及Model进行交互

{%ace edit=true lang='java'%}

public class UserPresenter {
       private IUserView mUserView ;
       private IUserModel mUserModel ;

       public UserPresenter (IUserView view) {
             mUserView = view;
             mUserModel = new UserModel ();
       }

       public void saveUser( int id , String firstName , String lastName) {
             mUserModel .setID (id );
             mUserModel .setFirstName (firstName );
             mUserModel .setLastName (lastName );
       }

       public void loadUser( int id ) {
             UserBean user = mUserModel .load (id );
             mUserrView .setFirstName (user .getFirstName ());//通过调用IUserView的方法来更新显示
             mUserView .setLastName (user .getLastName ());
       }
}

{%endace%}

- **UserActivity**

UserActivity实现了IUserView及View.OnClickListener接口，同时有一个UserPresenter成员变量

{%ace edit=true lang='java'%}

public class UserActivity extends Activity implements OnClickListener ,
             IUserView {

       private EditText mFirstNameEditText , mLastNameEditText , mIdEditText ;
       private Button mSaveButton , mLoadButton ;
       private UserPresenter mUserPresenter ;

{%endace%}


重写了OnClick方法：

{%ace edit=true lang='java'%}

@Override
       public void onClick(View v) {
             // TODO Auto-generated method stub
             switch ( v. getId()) {
             case R .id .saveButton :
                   mUserPresenter .saveUser (getID (), getFristName (),
                               getLastName ());
                   break ;
             case R .id .loadButton :
                   mUserPresenter .loadUser (getID ());
                   break ;
             default :
                   break ;
             }
       }

{%endace%}


可以看到，View只负责处理与用户进行交互，并把数据相关的逻辑操作都扔给了Presenter去做。而Presenter调用Model处理完数据之后，再通过IUserView更新View显示的信息。

## 参考

[1] http://www.jcodecraeer.com/a/anzhuokaifa/2017/1020/8625.html

[2] https://blog.csdn.net/vector_yi/article/details/24719873?utm_source=tuicool