/****************************************************************************
Copyright (c) 2008-2010 Ricardo Quesada
Copyright (c) 2010-2016 cocos2d-x.org
Copyright (c) 2013-2017 Chukong Technologies Inc.
 
http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
****************************************************************************/
package org.cocos2dx.lua;

import org.cocos2dx.lib.Cocos2dxActivity;

import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.KeyEvent;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.TextView;
import android.os.Build;
import android.view.DisplayCutout;


import org.cocos2dx.lua.CallInfo;
import org.cocos2dx.lua.MessageHandler;


import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.io.InputStream;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.json.JSONException;
import org.json.JSONObject;
import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager.NameNotFoundException;
import android.graphics.Rect;
import android.os.Environment;
import android.os.StatFs;
import android.provider.Settings;
import android.telephony.TelephonyManager;
import android.text.format.Formatter;
import android.util.DisplayMetrics;
import android.view.DisplayCutout;
import android.view.WindowInsets;
import android.view.WindowManager;



public class AppActivity extends Cocos2dxActivity
{
    private Cocos2dxActivity activity;
	private MessageHandler messageHandler;


   @Override
protected void onCreate(Bundle savedInstanceState)
{
    super.onCreate(savedInstanceState);
    activity = this;
    this.messageHandler = new MessageHandler(this);

    // 👉 เพิ่มตรงนี้เพื่อรองรับ cutout/notch และ fullscreen immersive
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        WindowManager.LayoutParams lp = getWindow().getAttributes();
        lp.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
        getWindow().setAttributes(lp);

        getWindow().getDecorView().setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN |
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE |
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION |
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        );
    }
}


	public void isHasNotchScreen(CallInfo info)
	{
        messageHandler.callbackToLua(info.msgID, HasNotchScreen(AppActivity.this));
    }

	public static String HasNotchScreen(AppActivity activity)
	{
        System.out.println("Build.MANUFACTURER::" + Build.MANUFACTURER);
        //android  P 以上有标准 API 来判断是否有刘海屏
        //https://blog.csdn.net/u011494285/article/details/86681405
        //https://developer.android.com/about/versions/pie/android-9.0#cutout
        try
		{
            if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
			{
                DisplayCutout displayCutout = activity.getWindow().getDecorView().getRootWindowInsets().getDisplayCutout();
                if(displayCutout != null)
				{
                    //说明有刘海屏
                    return "1";
                }
            }
			else
			{
                //通过其他方式判断是否有刘海屏  目前官方提供有开发文档的就 小米，vivo，华为（荣耀），oppo
                if (hasNotchXiaomi(activity) || hasNotchAtHuawei(activity) || hasNotchAtVivo(activity) || hasNotchAtOPPO(activity))
				{
                    return "1";
                }
            }
        }
		catch(Exception e)
		{
            e.printStackTrace();
        }
		
        return "0";
    }
	
    /**
     * oppo刘海屏判断
     * https://open.oppomobile.com/wiki/doc#id=10159
     */
    private static boolean hasNotchAtOPPO(AppActivity activity)
	{
        if("OPPO".equals(Build.MANUFACTURER))
		{
            return activity.getPackageManager().hasSystemFeature("com.oppo.feature.screen.heteromorphism");
        }
		else
		{
            return false;
        }
    }

    /**
     * vivo刘海屏判断
     * https://swsdl.vivo.com.cn/appstore/developer/uploadfile/20180328/20180328152252602.pdf
     */
    private static boolean hasNotchAtVivo(AppActivity activity)
	{
        if("VIVO".equals(Build.MANUFACTURER))
		{
            try
			{
                Class<?> c = Class.forName("android.util.FtFeature");
                Method get = c.getMethod("isFeatureSupport", int.class);
				
                return (boolean) (get.invoke(c, 0x00000020));//刘海屏
            }
			catch(Exception e)
			{
                e.printStackTrace();
				
                return false;
            }
        }
		else
		{
            return false;
        }
    }

    /**
     * huawei刘海屏判断
     * https://devcenter.huawei.com/consumer/cn/devservice/doc/50114
     */
    private static boolean hasNotchAtHuawei(AppActivity activity)
	{
        boolean ret = false;
        if("HUAWEI".equals(Build.MANUFACTURER))
		{
            try
			{
                ClassLoader cl = activity.getClassLoader();
                Class HwNotchSizeUtil = cl.loadClass("com.huawei.android.util.HwNotchSizeUtil");
                Method get = HwNotchSizeUtil.getMethod("hasNotchInScreen");
                ret = (boolean) get.invoke(HwNotchSizeUtil);
            }
			catch(ClassNotFoundException e)
			{
                Log.e("hasNotchAtHuawei", "hasNotchInScreen ClassNotFoundException");
            }
			catch(NoSuchMethodException e)
			{
                Log.e("hasNotchAtHuawei", "hasNotchInScreen NoSuchMethodException");
            }
			catch(Exception e)
			{
                Log.e("hasNotchAtHuawei", "hasNotchInScreen Exception");
            }
			finally
			{
                return ret;
            }
        }
		
        return ret;
    }

    /**
     * 小米刘海屏判断.
     * https://dev.mi.com/console/doc/detail?pId=1293
     */
    private static boolean hasNotchXiaomi(AppActivity activity)
	{
        if("Xiaomi".equals(Build.MANUFACTURER))
		{
            try
			{
                ClassLoader classLoader = activity.getClassLoader();
                @SuppressWarnings("rawtypes")
                Class SystemProperties = classLoader.loadClass("android.os.SystemProperties");
                //参数类型
                @SuppressWarnings("rawtypes")
                Class[] paramTypes = new Class[2];
                paramTypes[0] = String.class;
                paramTypes[1] = int.class;
                Method getInt = SystemProperties.getMethod("getInt", paramTypes);
                //参数
                Object[] params = new Object[2];
                params[0] = new String("ro.miui.notch");
                params[1] = new Integer(0);
				
                return (Integer) getInt.invoke(SystemProperties, params) == 1;
            }
			catch(ClassNotFoundException e)
			{
                e.printStackTrace();
            }
			catch(NoSuchMethodException e)
			{
                e.printStackTrace();
            }
			catch(IllegalAccessException e)
			{
                e.printStackTrace();
            }
			catch(IllegalArgumentException e)
			{
                e.printStackTrace();
            }
			catch(InvocationTargetException e)
			{
                e.printStackTrace();
            }
        }
		
        return false;
    }
	
	public void trackEvent(CallInfo info)
	{
        System.out.println("trackEvent: " + info.msgID);
        messageHandler.callbackToLua(info.msgID, "ok");
    }
}
