# Camera开发（一）:最简单的相机


## 让APP显示相机预览

- **添加布局**

想要相机预览显示在窗口中，实际上就是要显示在布局中，我们首先在布局中给相机预览留个位置，对于这个APP来说的话，就是把全部的位置都留给相机预览了。

修改 `activity_main.xml`:

{%ace edit=true, lang='xml'%}
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">
    <FrameLayout
        android:id="@+id/camera_preview"
        android:layout_width="0px"
        android:layout_height="fill_parent"
        android:layout_weight="1"
        />
</LinearLayout>
{%endace%}

我们会让相机预览填充在`FrameLayout`中， 但因为这个填充会在Java代码中实现，所以目前我们只给它指定一个ID，
供以后使用，ID名字就是camera_preview;而剩下的就是在设置这个`FrameLayout`所占布局大小。



- **添加CameraPreview类**

从布局层面来说，我们想要添加相机预览实际上就是在`FrameLayout`中再添加一个`View`，这个`View`可以理解为一个“控件”，就像之前的`TextView`，也是`View`中的一种，只不过相机预览这个View的内容是会一直变化的预览帧。因为Android并没有提供相机预览这个`View`，所以需要我们自己创造一个，而这个View我们就起名叫做`CameraPreview`。

在java->com.polarxiong.camerademo（这个根据你自己写的APP名字来）下新建一个Java Class CameraPreview，并修改其内容为：

新建一个Java类CameraPreview，并修改其内容为：

{%ace edit=true, lang='java'%}

import android.content.Context;
import android.hardware.Camera;
import android.util.Log;
import android.view.SurfaceHolder;
import android.view.SurfaceView;

import java.io.IOException;

public class CameraPreview extends SurfaceView implements SurfaceHolder.Callback {
    private static final String TAG = "CameraPreview";
    private SurfaceHolder mHolder;
    private Camera mCamera;

    public CameraPreview(Context context) {
        super(context);
        mHolder = getHolder();
        mHolder.addCallback(this);
    }

    private static Camera getCameraInstance() {
        Camera c = null;
        try {
            c = Camera.open();
        } catch (Exception e) {
            Log.d(TAG, "camera is not available");
        }
        return c;
    }

    public void surfaceCreated(SurfaceHolder holder) {
        mCamera = getCameraInstance();
        try {
            mCamera.setPreviewDisplay(holder);
            mCamera.startPreview();
        } catch (IOException e) {
            Log.d(TAG, "Error setting camera preview: " + e.getMessage());
        }
    }

    public void surfaceDestroyed(SurfaceHolder holder) {
        mHolder.removeCallback(this);
        mCamera.setPreviewCallback(null);
        mCamera.stopPreview();
        mCamera.release();
        mCamera = null;
    }

    public void surfaceChanged(SurfaceHolder holder, int format, int w, int h) {
    }
}

{%endace%}




`SurfaceView`是一个包含有`Surface`的`View`,而`Surface`用来处理直接呈现在屏幕上的内容，这个我们不细究，可以认为是相机预览的原始数据交给`Surface`就能转换成呈现在屏幕上的样子，这也是为什么`CameraPreview`一定要继承`SurfaceView`。
`CameraPreview`还使用了`SurfaceHolder.Callback`接口，这个接口包含有三个方法：`surfaceChanged()`、`surfaceCreated()`和`surfaceDestroyed()`，这三个方法会对应在`Surface`内容变化、`Surface`生成和`Surface`销毁时触发。

成员变量`mHolder`保存这个`Surface`的“持有者”（还是`Holder`顺口），而只有`Holder`才能对对应的`Surface`进行修改。成员变量`mCamera`保存相机`Camera`的实例。

先看构造函数， 构造函数实际就是指定本`View`(即`CameraPreview`)是这个`Surface`的`Holder`。

对于`SurfaceView`来说，这个`View`创建时就会创建`Surface`,而当`Surface`创建时就会触发`surfaceCreated()`,所以我们就要在`surfaceCreated()`中打开相机、开始预览，并将预览帧交给Surface处理。
所以我们就要在`surfaceCreated()`中打开相机、开始预览，并将预览帧交给Surface处理。`getCameraInstance()`是一个比较安全的获取并打开相机的方法，很简单。
`Camera的setPreviewDisplay()`方法就是告知将预览帧数据交给谁，这里当然就是这个`Surface`的`Holder`了；最后用`startPreview()`开启相机，这样我们就完成了整个过程，创建好了`CameraPreview`类。

但我们还要做一些善后处理，相机是共享资源，在APP运行结束后就应当“放弃”相机。我们在APP退出，即`surfaceDestroyed()`中完成这些善后处理，`surfaceDestroyed()`中的代码很简单，不需要详细说明，就是构造函数和
`surfaceCreated()`的逆过程。

我们目前还不需要`surfaceChanged()`，所以代码留空。

- **将CameraPreview加入到FrameLayout**

上一步只是创建了一个View，而现在就是要将这个View添加到activity_main中，因为这个View是实时创建的，当然我们不能直接去修改activity_main.xml，而应当在MainActivity中用代码添加。

修改MainActivity，在onCreate()最后添加：

{%ace edit=true, lang='java'%}

CameraPreview mPreview = new CameraPreview(this);
FrameLayout preview = (FrameLayout) findViewById(R.id.camera_preview);
preview.addView(mPreview);

{%endace%}


代码首先创建一个`CameraPreview`的实例`mPreview`，再在布局中通过ID找到`FrameLayout`，最后在`FrameLayout`中添加`mPreview`。修改之后的`MainActivity`就是：

{%ace edit=true, lang='java'%}

import android.app.Activity;
import android.os.Bundle;
import android.widget.FrameLayout;

public class MainActivity extends Activity {
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        CameraPreview mPreview = new CameraPreview(this);
        FrameLayout preview = (FrameLayout) findViewById(R.id.camera_preview);
        preview.addView(mPreview);
    }
}

{%endace%}

- **在AndroidManifest中申请和声明相机**

现在APP启动时就会调用`MainActivity`，而`MainActivity`创建时就会创建`CameraPreview`,`CameraPreview`创建时则会调用相机并开启相机预览。
现在还存在的一个问题是APP启动后才会调用相机，而很显然我们希望APP在安装时就告知Android需要用到相机，这就是`AndroidManifest`要干的事情啦。

```
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature android:name="android.hardware.camera" />
    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:supportsRtl="true"
        android:theme="@style/AppTheme">
        <activity android:name=".MainActivity"
            android:screenOrientation="landscape">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
```

- **运行**

很显然这个“相机”APP还不能算真正的相机，不能拍照，而且还支持对焦，这个屏幕一篇模糊简直不能用。但如果你能成功写出这个APP，本文的目的也算达到了，至少你已经大体明白了Android开发的步骤，以及Android APP运行的基本过程。


## 参考

[1] https://www.polarxiong.com/archives/Android%E7%9B%B8%E6%9C%BA%E5%BC%80%E5%8F%91-%E4%B8%80-%E6%9C%80%E7%AE%80%E5%8D%95%E7%9A%84%E7%9B%B8%E6%9C%BA.html

