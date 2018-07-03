# TextureView, SurfaceView, GLSurfaceView 和 SurfaceTexture

## SurfaceView


- **简介**

按照官方文档的说法，SurfaceView继承自View，并提供了一个独立的绘图层，你可以完全控制这个绘图层，比如说设定它的大小，所以SurfaceView可以嵌入到View结构树中，但是需要注意的是，由于SurfaceView直接将绘图表层绘制到屏幕上，所以和普通的View不同的地方就在与它不能执行Transition，Rotation，Scale等转换，也不能进行Alpha透明度运算。

SurfaceView的Surface排在Window的Surface(也就是View树所在的绘图层)的下面，SurfaceView嵌入到Window的View结构树中就好像在Window的Surface上强行打了个洞让自己显示到屏幕上，而且SurfaceView另起一个线程对自己的Surface进行刷新。
`特别需要注意的是SurfaceHolder.Callback的所有回调方法都是在主线程中回调的`。

- **SurfaceView SurfaceHolder Surface的关系**

  - SurfaceView是拥有独立绘图层的特殊View
  - Surface就是指SurfaceView所拥有的那个绘图层， 其实它就是内存中的一段绘图缓冲区。
  - SurfaceView中具有两个Surface，也就是我们所说的双缓冲机制
  - SurfaceHolder顾名思义就是Surface的持有者， SurfaceView就是通过SurfaceHolder来对Surface进行管理控制
  - Surface是在SurfaceView所在的Window可见的时候创建的。我们可以使用SurfaceHolder.addCallback方法来监听Surface的创建和销毁的事件。

## GLSurfaceView


## TextureView

- **SurfaceView的缺点**

SurfaceView由于使用的是独立的绘图层，并且使用独立的线程去进行绘制。前面的文章中也说到SurfaceView不能进行Transition，Rotation，Scale等变换，这就导致一个问题SurfaceView在滑动的时候，SurfaceView的刷新由于不受主线程控制导致SurfaceView在滑动的时候会出现黑边的情况

- **简介**

从字面意思来看TextureView是用来绘制纹理的View，官方文档给出解释是说，TextureView专门用来渲染像视频或OpenGL场景之类的数据，而且TextureView只能用在具有硬件加速的Window中,如果使用的是软件渲染，TextureView什么也不显示。

也就是说对于没有GPU的设备，TextureView完全不可用。好在现在的移动设备基本都有GPU进行硬件加速渲染（连我手里这款破旧的华为测试机都有(^o^)）。

- **TextureView的相关类SurfaceTexture**

TextureView在使用的时候涉及到这么几个类：SurfaceTexture，Surface。
Surface就是SurfaceView中使用的Surface，就是内存中的一段绘图缓冲区。
SurfaceTexture是什么呢，官方文档给出的解释是这样的：

SurfaceTexture用来捕获视频流中的图像帧的，视频流可以是相机预览或者视频解码数据。SurfaceTexture可以作为android.hardware.camera2, MediaCodec, MediaPlayer, 和 Allocation这些类的目标视频数据输出对象。可以调用updateTexImage()方法从视频流数据中更新当前帧，这就使得视频流中的某些帧可以跳过。

TextureView可以通过getSurfaceTexture()方法来获取TextureView相应的SurfaceTexture。但是最好的方式还是使用TextureView.SurfaceTextureListener监听器来对SurfaceTexture的创建销和毁进行监听，因为getSurfaceTexture可能获取的是空对象。

## SurfaceTexture


## 参考

[1] https://blog.csdn.net/holmofy/article/details/66578852