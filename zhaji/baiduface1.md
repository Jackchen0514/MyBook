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

