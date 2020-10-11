# SwipeRefreshLayout

## API


## 使用方法

- **布局文件**

{%ace edit=true lang='java'%}

<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent" >
    <android.support.v4.widget.SwipeRefreshLayout
        android:id="@+id/id_swipe_ly"
        android:layout_width="match_parent"
        android:layout_height="match_parent" >
        <ListView
            android:id="@+id/id_listview"
            android:layout_width="match_parent"
            android:layout_height="match_parent" >
        </ListView>
    </android.support.v4.widget.SwipeRefreshLayout>
</RelativeLayout>

{%endace%}



- **MainActivity**

{%ace edit=true lang='java'%}

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.support.v4.widget.SwipeRefreshLayout;
import android.util.Log;
import android.widget.ArrayAdapter;
import android.widget.ListView;

public class MainActivity extends Activity implements SwipeRefreshLayout.OnRefreshListener
{

    private static final int REFRESH_COMPLETE = 0X110;
    private SwipeRefreshLayout mSwipeLayout;
    private ListView mListView;
    private ArrayAdapter<String> mAdapter;
    private List<String> mDatas = new ArrayList<String>(Arrays.asList("Java", "Javascript", "C++", "Ruby", "Json",
            "HTML"));

    private Handler mHandler = new Handler()
    {
        public void handleMessage(android.os.Message msg)
        {
            switch (msg.what)
            {
            case REFRESH_COMPLETE:
                mDatas.addAll(Arrays.asList("Lucene", "Canvas", "Bitmap"));
                mAdapter.notifyDataSetChanged();
                mSwipeLayout.setRefreshing(false);
                break;

            }
        };
    };

    @SuppressLint("InlinedApi")
    protected void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mListView = (ListView) findViewById(R.id.id_listview);
        mSwipeLayout = (SwipeRefreshLayout) findViewById(R.id.id_swipe_ly);

        mSwipeLayout.setOnRefreshListener(this);
        mSwipeLayout.setColorScheme(android.R.color.holo_blue_bright, android.R.color.holo_green_light,
                android.R.color.holo_orange_light, android.R.color.holo_red_light);
        mAdapter = new ArrayAdapter<String>(this, android.R.layout.simple_list_item_1, mDatas);
        mListView.setAdapter(mAdapter);

    }

    public void onRefresh()
    {
        // Log.e("xxx", Thread.currentThread().getName());
        // UI Thread

        mHandler.sendEmptyMessageDelayed(REFRESH_COMPLETE, 2000);

    }
}

{%endace%}


