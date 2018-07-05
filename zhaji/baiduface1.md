# 百度闸机

## 注册模块

- **从相册选取**

压缩选取的相册图片

注： (图片很大，不能全部加在到内存中处理，要是全部加载到内存中会内存溢出)

压缩人脸图片至300 * 300, 减少网络传输时间

{%ace edit=true lang='java' %}


public static void resize(Bitmap bitmap, File outputFile, int maxWidth, int maxHeight) {
    try {
        int bitmapWidth = bitmap.getWidth();
        int bitmapHeight = bitmap.getHeight();
        // 图片大于最大高宽，按大的值缩放
        if (bitmapWidth > maxHeight || bitmapHeight > maxWidth) {
            float widthScale = maxWidth * 1.0f / bitmapWidth;
            float heightScale = maxHeight * 1.0f / bitmapHeight;

            float scale = Math.min(widthScale, heightScale);

            //矩阵
            Matrix matrix = new Matrix();
            matrix.postScale(scale, scale);

            /**
             * android.graphics.Bitmap createBitmap(android.graphics.Bitmap source, int x, int y, int width, int height,
             *                 android.graphics.Matrix m, boolean filter)
             */
            bitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmapWidth, bitmapHeight, matrix, false);
        }
        LogUtil.i("APIService", "upload face size" + bitmap.getWidth() + "*" + bitmap.getHeight());
        // save image
        FileOutputStream out = new FileOutputStream(outputFile);
        try {
            /**
             * 90代表压缩率, 表示压缩10%,  100表示不压缩，压缩0%
             */
            bitmap.compress(Bitmap.CompressFormat.JPEG, 90, out);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                out.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    } catch (IOException e) {
        e.printStackTrace();
    }
}

{%endace%}

- **自动检测**

activity_reg_detected.xml :

{%ace edit=true lang='java'%}

<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
                android:layout_width="match_parent"
                android:layout_height="match_parent">

    <com.baidu.aip.face.TexturePreviewView
            android:id="@+id/texture_view"
            android:layout_width="match_parent"
            android:layout_height="match_parent"
            android:visibility="visible"/>

    <View
            android:id="@+id/rect_view"
            android:background="@drawable/avator_rect_shape"
            android:layout_margin="20dip"
            android:layout_width="match_parent"
            android:layout_height="400dp"
            android:layout_centerInParent="true"
            android:visibility="visible"/>

    <ImageView
            android:id="@+id/display_avatar"
            android:layout_width="125dp"
            android:layout_height="150dp"/>

    <TextView
            android:id="@+id/hint_text_view"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:textSize="18sp"
            android:textColor="#FFFFFF"
            android:padding="6dp"
            android:layout_marginTop="12dp"
            android:layout_centerHorizontal="true"
            android:background="#66000000"
            android:layout_below="@+id/rect_view"/>

</RelativeLayout>

{%endace%}

如下图：

![image](https://raw.githubusercontent.com/Jackchen0514/Pictures/master/regdetect1.png)

texture_view 是整个显示区域

rect_view 是中间的黄框所显示区域

`人脸识别的图片只截取黄框里的图片作为识别图片`

RegDetectActivity.java:

{%ace edit=true lang='java'%}

/**
 * 自动检测获取人脸
 */
public class RegDetectActivity extends AppCompatActivity {

    private PreviewView previewView;
    private View rectView;
    private ImageView displayAvatar;
    private TextView hintTextView;

    private int lastTipResId;
    private boolean success = false;

    private FaceDetectManager faceDetectManager;

    private DetectRegionProcessor cropProcessor = new DetectRegionProcessor();

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        faceDetectManager = new FaceDetectManager(getApplicationContext());
        setContentView(R.layout.activity_reg_detected);
        previewView = (PreviewView) findViewById(R.id.texture_view);
        displayAvatar = (ImageView) findViewById(R.id.display_avatar);
        rectView = findViewById(R.id.rect_view);
        rectView.setKeepScreenOn(true);
        hintTextView = (TextView) findViewById(R.id.hint_text_view);
        init();

        hintTextView.setText(R.string.hint_move_into_frame);
    }

    private Handler handler = new Handler();

    private void init() {

        final CameraImageSource cameraImageSource = new CameraImageSource(this);
        // 从相机获取图片
        faceDetectManager.setImageSource(cameraImageSource);
        // 设置预览View
        cameraImageSource.setPreviewView(previewView);
        // 添加PreProcessor对图片进行裁剪。
        faceDetectManager.addPreProcessor(cropProcessor);

        rectView.getViewTreeObserver().addOnGlobalLayoutListener(new ViewTreeObserver.OnGlobalLayoutListener() {
            @Override
            public void onGlobalLayout() {
                rectView.getViewTreeObserver().removeOnGlobalLayoutListener(this);
                // 打开相机，映射View到相机之间的坐标
                start();
            }
        });

        faceDetectManager.setOnFaceDetectListener(new FaceDetectManager.OnFaceDetectListener() {
            @Override
            public void onDetectFace(int status, FaceInfo[] infos, ImageFrame frame) {
                handleFace(status, infos, frame.getArgb(), frame.getWidth(), frame.getHeight());
            }
        });

        // 安卓6.0+的系统相机权限是动态获取的，当没有该权限时会回调。
        cameraImageSource.getCameraControl().setPermissionCallback(new PermissionCallback() {
            @Override
            public boolean onRequestPermission() {
                ActivityCompat
                        .requestPermissions(RegDetectActivity.this, new String[] {Manifest.permission.CAMERA}, 100);
                return true;
            }
        });

        boolean isPortrait = getResources().getConfiguration().orientation == Configuration.ORIENTATION_PORTRAIT;

        if (isPortrait) {
            previewView.setScaleType(PreviewView.ScaleType.FIT_WIDTH);
            cameraImageSource.getCameraControl().setDisplayOrientation(CameraView.ORIENTATION_PORTRAIT);
        } else {
            previewView.setScaleType(PreviewView.ScaleType.FIT_HEIGHT);
            cameraImageSource.getCameraControl().setDisplayOrientation(CameraView.ORIENTATION_HORIZONTAL);
        }

//        // 摄像头的类型，是否是usb摄像头，不设置检测的图片是倒立的，无法检测到人脸
//        cameraImageSource.getCameraControl().setUsbCamera(true);
//        // USB摄像头使用镜面翻转 。相机自带的前置摄像头自己加了镜面翻转处理
//        // 但其它摄像头，如USB摄像头，或者网络摄像头没有做这样的处理。该行代码可以实现预览时的镜面翻转。
//        previewView.getTextureView().setScaleX(-1);
    }

    @Override
    protected void onStop() {
        super.onStop();
        faceDetectManager.stop();
    }

    private void start() {
        Rect detectedRect = new Rect();
        rectView.getGlobalVisibleRect(detectedRect);
        RectF newDetectedRect = new RectF(detectedRect);
        cropProcessor.setDetectedRect(newDetectedRect);
        faceDetectManager.start();
    }

    private long lastTipTime;

    private Rect rect = new Rect();
    private RectF rectF = new RectF(rect);

    private void handleFace(int retCode, FaceInfo[] faces, int[] argb, int width, int height) {
        if (success) {
            return;
        }
        if (faces == null || faces.length == 0) {
            // 获取状态码
            int hint = LivenessDetector.getInstance().getHintCode(retCode, null , 0, 0);
            // 根据状态码获取相应的资源ID
            final int resId = LivenessDetector.getInstance().getTip(hint);
            displayTip(resId);
            lastTipResId = resId;
            return;
        }

        rectView.getGlobalVisibleRect(rect);
        // 屏幕显示坐标对应到，实际图片坐标。
        rectF.set(rect);
        previewView.mapToOriginalRect(rectF);
        LivenessDetector.getInstance().setDetectRect(rectF);

        // 获取状态码
        final int hint = LivenessDetector.getInstance().getHintCode(retCode, faces[0], width, height);
        // 根据状态码获取相应的资源ID
        final int resId = LivenessDetector.getInstance().getTip(hint);

        final Bitmap bitmap = FaceCropper.getFace(argb, faces[0], width);

        handler.post(new Runnable() {
            @Override
            public void run() {
                displayAvatar.setImageBitmap(bitmap);
                // 在主线程，显示。
                displayTip(resId);
                lastTipResId = resId;
            }
        });

        if (hint != LivenessDetector.HINT_OK) {
            return;
        }

        try {
            final File file = File.createTempFile(UUID.randomUUID().toString() + "", ".jpg");
            ImageUtil.resize(bitmap, file, 300, 300);

            Intent intent = new Intent();
            intent.putExtra("file_path", file.getAbsolutePath());
            setResult(Activity.RESULT_OK, intent);
            success = true;
            finish();

        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private DisplayTipRunnable displayTipRunnable;

    private void displayTip(final int resId) {
        if (lastTipTime != 0 && (System.currentTimeMillis() - lastTipTime < 1500) && lastTipResId == resId) {
            lastTipTime = System.currentTimeMillis();
            return;
        }

        if (resId != 0) {
            handler.removeCallbacks(displayTipRunnable);
            displayTipRunnable = new DisplayTipRunnable(resId);
            handler.postDelayed(displayTipRunnable, 500);
        }
        lastTipTime = System.currentTimeMillis();
    }

    private class DisplayTipRunnable implements Runnable {

        private int resId;

        DisplayTipRunnable(int resId) {
            this.resId = resId;
        }

        @Override
        public void run() {
            hintTextView.setText(resId);
        }
    }
}

{%endace%}

- **工具类**

知识补充：

```
ARGB数据  是一种色彩模式，也就是RGB色彩模式附加上Alpha（透明度）通道，常见于32位位图的存储结构。

RGB 色彩模式是工业界的一种颜色标准，是通过对红(R)、绿(G)、蓝(B)三个颜色通道的变化以及它们相互之间的叠加来得到各式各样的颜色的，RGB即是代表红、绿、蓝三个通道的颜色，这个标准几乎包括了人类视力所能感知的所有颜色，是目前运用最广的颜色系统之一。

Rect 表示坐标系中的一块矩形区域，并可以对其做一些简单操作。这块矩形区域，需要用左上和右下两个坐标点表示。

RectF 表示使用float类型作为数值，Rect是使用int类型作为数值
```

`FaceCropper: `

{%ace edit=true lang='java'%}

/**
 *人脸裁剪工具类。
 */
public class FaceCropper {

    /**
     * 高速裁剪狂，防止框超出图片范围。
     * @param argb 图片argb数据
     * @param width 图片宽度
     * @param rect 裁剪框
     */
    public static void adjustRect(int[] argb, int width, Rect rect) {
        rect.left = Math.max(rect.left ,0);
        rect.right = Math.min(rect.right,width);
        int height = argb.length / width;
        rect.bottom = Math.min(rect.bottom,height);
        rect.sort();
    }

    /**
     * 裁剪argb中的一块儿，裁剪框如果超出图片范围会被调整，所以记得检查。
     * @param argb 图片argb数据
     * @param width 图片宽度
     * @param rect 裁剪框
     */
    public static int[] crop(int[] argb, int width, Rect rect) {
        adjustRect(argb, width, rect);
        int[] image = new int[rect.width() * rect.height()];

        for (int i = rect.top; i < rect.bottom; i++) {
            int rowIndex = width * i;
            try {
                System.arraycopy(argb, rowIndex + rect.left, image, rect.width() * (i - rect.top), rect.width());
            } catch (Exception e) {
                e.printStackTrace();
                return argb;
            }
        }
        return image;
    }

    /**
     * 裁剪图片中的人脸。
     * @param argb argb图片数据
     * @param faceInfo 人脸信息
     * @param imageWidth 图片宽度
     * @return 返回裁剪后的人脸图片
     */
    public static Bitmap getFace(int[] argb, FaceInfo faceInfo, int imageWidth) {
        int[] points = new int[8];

        faceInfo.getRectPoints(points);

        int left = points[2];
        int top = points[3];
        int right = points[6];
        int bottom = points[7];

        int width = right - left;
        int height = bottom - top;

        width = width * 3 / 2;
        height = height * 2;
        //
        left = faceInfo.mCenter_x - width / 2;
        top = faceInfo.mCenter_y - height / 2;

        height = height * 4 / 5;
        //
        left = Math.max(left, 0);
        top = Math.max(top, 0);

        Rect region = new Rect(left, top, left + width, top + height);
        FaceCropper.adjustRect(argb, imageWidth, region);
        int offset = region.top * imageWidth + region.left;
        return Bitmap.createBitmap(argb,offset,imageWidth,region.width(),region.height(),
                Bitmap.Config.ARGB_8888);
    }
}

{%endace%}

`FaceProcessor: `

{%ace edit=true lang='java'%}

/**
 *  FaceDetectManager 人脸检测之前的回调。可以对图片进行预处理。如果ImageFrame中的argb数据为空，将不进行检测。
 */
public interface FaceProcessor {
    /**
     * FaceDetectManager 回调该方法，对图片帧进行处理。
     * @param detectManager 回调的 FaceDetectManager
     * @param frame 需要处理的图片帧。
     * @return 返回true剩下的FaceProcessor将不会被回调。
     */
    boolean process(FaceDetectManager detectManager, ImageFrame frame);
}

{%endace%}

`FaceDetectManager`

{%ace edit=true lang='java'%}

/**
 * 封装了人脸检测的整体逻辑。
 */
public class FaceDetectManager {
    /**
     * 该回调用于回调，人脸检测结果。当没有人脸时，infos 为null,status为 FaceDetector.DETECT_CODE_NO_FACE_DETECTED
     */
    public interface OnFaceDetectListener {
        void onDetectFace(int status, FaceInfo[] infos, ImageFrame imageFrame);
    }

    public FaceDetectManager(Context context) {
        Ast.getInstance().init(context.getApplicationContext(), "2.1.0.0", "faceturnstile");
    }

    /**
     * 图片源，获取检测图片。
     */
    private ImageSource imageSource;
    /**
     * 人脸检测事件监听器
     */
    private OnFaceDetectListener listener;
    private FaceFilter faceFilter = new FaceFilter();
    private HandlerThread processThread;
    private Handler processHandler;
    private Handler uiHandler;
    private ImageFrame lastFrame;

    private ArrayList<FaceProcessor> preProcessors = new ArrayList<>();

    /**
     * 设置人脸检测监听器，检测后的结果会回调。
     *
     * @param listener 监听器
     */
    public void setOnFaceDetectListener(OnFaceDetectListener listener) {
        this.listener = listener;
    }

    /**
     * 设置图片帧来源
     *
     * @param imageSource 图片来源
     */
    public void setImageSource(ImageSource imageSource) {
        this.imageSource = imageSource;
    }

    /**
     * @return 返回图片来源
     */
    public ImageSource getImageSource() {
        return this.imageSource;
    }

    /**
     * 增加处理回调，在人脸检测前会被回调。
     *
     * @param processor 图片帧处理回调
     */
    public void addPreProcessor(FaceProcessor processor) {
        preProcessors.add(processor);
    }

    /**
     * 设置人检跟踪回调。
     *
     * @param onTrackListener 人脸回调
     */
    public void setOnTrackListener(FaceFilter.OnTrackListener onTrackListener) {
        faceFilter.setOnTrackListener(onTrackListener);
    }

    /**
     * @return 返回过虑器
     */
    public FaceFilter getFaceFilter() {
        return faceFilter;
    }

    public void start() {
        LogUtil.init();
        this.imageSource.addOnFrameAvailableListener(onFrameAvailableListener);
        processThread = new HandlerThread("process");
        processThread.setPriority(9);
        processThread.start();
        processHandler = new Handler(processThread.getLooper());
        uiHandler = new Handler();
        this.imageSource.start();
    }

    private Runnable processRunnable = new Runnable() {
        @Override
        public void run() {
            if (lastFrame == null) {
                return;
            }
            int[] argb;
            int width;
            int height;
            ArgbPool pool;
            synchronized (lastFrame) {
                argb = lastFrame.getArgb();
                width = lastFrame.getWidth();
                height = lastFrame.getHeight();
                pool = lastFrame.getPool();
                lastFrame = null;
            }
            process(argb, width, height, pool);
        }
    };

    public void stop() {
        if (imageSource != null) {
            this.imageSource.stop();
            this.imageSource.removeOnFrameAvailableListener(onFrameAvailableListener);
        }

        if (processThread != null) {
            processThread.quit();
            processThread = null;
        }
        Ast.getInstance().immediatelyUpload();
    }

    private void process(int[] argb, int width, int height, ArgbPool pool) {
        int value;

        ImageFrame frame = imageSource.borrowImageFrame();
        frame.setArgb(argb);
        frame.setWidth(width);
        frame.setHeight(height);
        frame.setPool(pool);
        //        frame.retain();

        for (FaceProcessor processor : preProcessors) {
            if (processor.process(this, frame)) {
                break;
            }
        }
        long starttime = System.currentTimeMillis();
        value = FaceDetector.getInstance().detect(frame);
        FaceInfo[] faces = FaceDetector.getInstance().getTrackedFaces();
        // LogUtil.e("wtf", value + " process->" + (System.currentTimeMillis() - starttime));

        if (value == 0) {
            faceFilter.filter(faces, frame);
        }
        if (listener != null) {
            listener.onDetectFace(value, faces, frame);
        }
        Ast.getInstance().faceHit("detect",  60 * 60 * 1000, faces);

        frame.release();

    }

    private OnFrameAvailableListener onFrameAvailableListener = new OnFrameAvailableListener() {
        @Override
        public void onFrameAvailable(ImageFrame imageFrame) {
            lastFrame = imageFrame;
//            processHandler.removeCallbacks(processRunnable);
//            processHandler.post(processRunnable);
//            uiHandler.removeCallbacks(processRunnable);
//            uiHandler.post(processRunnable);
            processRunnable.run();
        }
    };
}

{%endace%}


RegDetectActivity.java:

```
我们知道在oncreate中View.getWidth和View.getHeight无法获得一个view的高度和宽度，这是因为View组件布局要在onResume回调后完成。
所以现在需要使用getViewTreeObserver().addOnGlobalLayoutListener()来获得宽度或者高度。这是获得一个view的宽度和高度的方法之一。

```


## 注意事项

Application 初始化的时候 apiKey,secretKey 要先注册认证，否则会报如下错误：

```
java.lang.UnsatisfiedLinkError: No implementation found for int
com.baidu.idl.facesdk.FaceSDK.getARGBFromYUVimg(byte[], int[], int, int, int, int) (tried
Java_com_baidu_idl_facesdk_FaceSDK_getARGBFromYUVimg and
Java_com_baidu_idl_facesdk_FaceSDK_getARGBFromYUVimg___3B_3IIIII)

```


