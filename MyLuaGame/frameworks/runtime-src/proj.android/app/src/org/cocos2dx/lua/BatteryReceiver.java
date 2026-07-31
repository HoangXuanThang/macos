package org.cocos2dx.lua;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.BatteryManager;
import android.util.Log;
import android.widget.Toast;

public class BatteryReceiver extends BroadcastReceiver {
    int mCurrentLevel = 0;
    int m_total = 0;
    String m_strPercent;
    @Override
    public void onReceive(Context context, Intent intent) {
        final String action = intent.getAction();
        if (action.equalsIgnoreCase(Intent.ACTION_BATTERY_CHANGED)) {
            //Log.i("james-fan", "get battery change broad");
        }
        // mCurrentLevel = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1);
        //m_total = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1);
        mCurrentLevel = intent.getExtras().getInt("level");// 获得当前电量
        m_total = intent.getExtras().getInt("scale");// 获得总电量
        int percent = mCurrentLevel * 100 / m_total;
        m_strPercent = percent + "%";
    }
    public int getCurrentLevel() {
        return mCurrentLevel;
    }

    public int getTotal() {
        return m_total;
    }

    public String getBatteryPercent() {
        return m_strPercent;
    }
}