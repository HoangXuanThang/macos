package org.cocos2dx.lua;

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
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.graphics.Rect;
import android.os.Build;
import android.os.Environment;
import android.os.StatFs;
import android.provider.Settings;
import android.telephony.TelephonyManager;
import android.text.format.Formatter;
import android.util.DisplayMetrics;
import android.util.Log;

import android.view.DisplayCutout;
import android.view.View;
import android.view.WindowInsets;
import android.view.WindowManager;

// import com.tencent.android.tpush.XGIOperateCallback;
// import com.tencent.android.tpush.XGPushManager;

public class Tools {
    private static Context mContext;

    public static void tool(Context c) {
        mContext = c;
        try {
            File logDir = c.getFilesDir();
            System.out.println("tj_device: " + logDir);
            // c.deleteFile("tj_device.log");
            // 创建指定路径的文件
            File file = new File(logDir, "/tj_device.log");
            file.createNewFile();
            // 获取文件的输出流对象
            System.out.println("tj_device: " + file.getPath());
            FileOutputStream outStream = new FileOutputStream(file);
            // 获取字符串对象的byte数组并写入文件流
            outStream.write(fomatCrashInfo(c).getBytes("UTF-8"));
            // 最后关闭文件输出流
            outStream.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @SuppressLint("MissingPermission")
    private static String fomatCrashInfo(Context c) {
        TelephonyManager tm = (TelephonyManager) c
                .getSystemService(Activity.TELEPHONY_SERVICE);
        PackageManager packageManager = c.getPackageManager();
        PackageInfo packageInfo;
        JSONObject json = new JSONObject();

        try {
            json.put("board", Build.BOARD);// 主板
            packageInfo = packageManager.getPackageInfo(c.getPackageName(), 0);
            String logTime = getCurrentTime();
            json.put("game_start_time", logTime);
            json.put("type", "android");
            json.put("game_name", c.getResources().getString(
                            packageInfo.applicationInfo.labelRes));
            json.put("version_code", packageInfo.versionCode);
            json.put("version_name", packageInfo.versionName);
            json.put("package_name", packageInfo.packageName);
            json.put("prodect", Build.BRAND);// 荣耀，魅蓝
            json.put("cpu_abi", Build.CPU_ABI);// cpu指令集
            json.put("cpu_abi", Build.CPU_ABI2);
            json.put("type_int", Build.VERSION.SDK_INT);// 20 21 23 19
            json.put("hardware", Build.HARDWARE);// 硬件名称
            json.put("manufacturer", Build.MANUFACTURER);// 手机生产商
            json.put("dev_model", Build.MODEL);// 设备名称，哪款手机
            json.put("dev_size", devSize());// 屏幕分辨率
            json.put("available_memory", getAvailableInternalMemorySize());// 可用内存大小
            json.put("total_memory", getTotalInternalMemorySize());// 内存总大小
            json.put("cpu_name", getCpuName());// cpu型号
            json.put("cpu_time", getAppCpuTime());// cpu使用时间
//            json.put("cpu_rate", getCurProcessCpuRate());// cpu使用率
//      json.put("cpu_total_rate", getTotalCpuRate());// cpu总使用率
//      json.put("cpu_total_time", getTotalCpuTime());// cpu总使用时间
            json.put("imei", tm.getDeviceId());
            json.put("android_id", Settings.Secure.getString(
                    mContext.getContentResolver(), Settings.Secure.ANDROID_ID));
            json.put("sim_country", tm.getSimCountryIso());// 手机卡国家
            json.put("net_name", tm.getNetworkOperatorName());// 网络类型名
            json.put("imsi", tm.getSubscriberId());
            json.put("sdk", getChannel());
            json.put("sdk_tag", getChannelTag());
            json.put("svn_patch", getSvnPath());
            json.put("svn_version", getSvnVersion());
        } catch (JSONException e) {
            e.printStackTrace();
        } catch (NameNotFoundException e) {
            e.printStackTrace();
        }

        System.out.println("tj_device: " + json.toString());
        return json.toString();
    }

    public static String getChannel() {
        String sdk = "";
        Pattern p = Pattern.compile("<string>(.+?)</string>");
        Matcher m = p.matcher(getFromAssets("res/channel.plist"));
        if (m.find()) {
          sdk = m.group(1);
          if (sdk.equals("tc")) {
              String s = getExtraSDK();
              if (s == "" || s.length() <= 0){
                return "tc";
              } else {
                  return s;
              }
          } else {
            return sdk;
          }
        }
        return "error";
    }

    public static String getChannelTag() {
        String sdk = "";
        Pattern p = Pattern.compile("<string>(.+?)</string>");
        Matcher m = p.matcher(getFromAssets("res/channel.plist"));
        if (m.find() && m.find()) {
            return m.group(1);
        }
        return "error";
    }

    private static String getSvnPath() {
        String text = "";
        Pattern p = Pattern.compile("<string>[0-9]{1,}</string>");
        Matcher m = p.matcher(getFromAssets("res/version.plist"));
        if (m.find()) {
            text = m.group();
//            int indexOf = Text.indexOf("<string>");
            // 截取出字符串后面的数字
            text = text.substring(8, text.length());
        }
        return splitdata(text);
    }

    private static String getSvnVersion() {
        Pattern p1 = Pattern.compile("<string>(\\d+\\.\\d+\\.\\d+\\.\\d+)</string>");
        Matcher m1 = p1.matcher(getFromAssets("res/version.plist"));
        // 将符合规则的提取出来
        if (m1.find()) {
            return m1.group(1);
        }
        return "error";
    }

    private static String getExtraSDK(){
        Pattern p1 = Pattern.compile("extraSDK=\"(.*?)\"");
        String test = getFromAssets("TivicloudSDK.xml");
        test = escapeExprSpecialWord(test);
        Matcher m1 = p1.matcher(test);
        // 将符合规则的提取出来
        while (m1.find()) {
            String a = m1.group(1);
            return a;
        }
        return "error";
    }

    private static String escapeExprSpecialWord(String keyword) {
        String[] fbsArr = { "\\", "$", "(", ")", "*", "+", ".", "[", "]", "?", "^", "{", "}", "|" };
        for (String key : fbsArr) {
            if (keyword.contains(key)) {
                keyword = keyword.replace(key, "\\" + key);
            }
        }
        return keyword;
    }

    private static String splitdata(String chatChar) {
        Pattern p = Pattern.compile("\\d+");
        Matcher m = p.matcher(chatChar);
        m.find();
        return m.group();
    }

    public static String getFromAssets(String fileName) {
        String result = "";
        InputStream in = null;
        try {
            in = mContext.getResources().getAssets().open(fileName);
            // 获取文件的字节数
            int lenght = in.available();
            // 创建byte数组
            byte[] buffer = new byte[lenght];
            // 将文件中的数据读到byte数组中
            in.read(buffer);
            result = new String(buffer, "UTF-8");
            in.close();
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            if (in != null)
                try {
                    in.close();
                } catch (IOException e) {
                    // TODO Auto-generated catch block
                    e.printStackTrace();
                }
        }
        return result;
    }

    static public String devSize() {
        WindowManager wm = (WindowManager) mContext
                .getSystemService(Context.WINDOW_SERVICE);
        DisplayMetrics dm = new DisplayMetrics();
        wm.getDefaultDisplay().getMetrics(dm);
        int width = dm.widthPixels;
        int height = dm.heightPixels;
        return width + "*" + height;

    }

    static public boolean isExternalStorageAvailable() {
        return Environment.getExternalStorageState().equals(
                Environment.MEDIA_MOUNTED);
    }

    static public String getAvailableInternalMemorySize() {
        try {
            File path = Environment.getDataDirectory();
            StatFs stat = new StatFs(path.getPath());
            long blockSize = stat.getBlockSize();
            long availableBlocks = stat.getAvailableBlocks();

            return Formatter.formatFileSize(mContext, availableBlocks * blockSize);
        }catch (Exception e){
            e.printStackTrace();
        }
        return "error";
    }

    static public String getTotalInternalMemorySize() {
        try {
            File path = Environment.getDataDirectory();// Gets the Android data
            // directory
            StatFs stat = new StatFs(path.getPath());
            long blockSize = stat.getBlockSize();
            long totalBlocks = stat.getBlockCount();

            return Formatter.formatFileSize(mContext, totalBlocks * blockSize);
        }catch (Exception e){
            e.printStackTrace();
        }
        return "error";
    }

    static public String getAvailableExternalMemorySize() {
        if (isExternalStorageAvailable()) {
            File path = Environment.getExternalStorageDirectory();
            StatFs stat = new StatFs(path.getPath());
            long blockSize = stat.getBlockSize();
            long availableBlocks = stat.getAvailableBlocks();
            return Formatter.formatFileSize(mContext, availableBlocks
                    * blockSize);

        } else {
            return "-1";
        }
    }

    static public String getTotalExternalMemorySize() {
        if (isExternalStorageAvailable()) {
            File path = Environment.getExternalStorageDirectory();
            StatFs stat = new StatFs(path.getPath());
            long blockSize = stat.getBlockSize();
            long totalBlocks = stat.getBlockCount();

            return Formatter.formatFileSize(mContext, totalBlocks * blockSize);
        } else {
            return "-1";
        }
    }

    public static String getCpuName() {

        String str1 = "/proc/cpuinfo";
        String str2 = "";

        try {
            FileReader fr = new FileReader(str1);
            BufferedReader localBufferedReader = new BufferedReader(fr);
            while ((str2 = localBufferedReader.readLine()) != null) {
                if (str2.contains("Hardware")) {
                    return str2.split(":")[1];
                }
            }
            localBufferedReader.close();
        } catch (IOException e) {
        }
        return null;

    }

    public static float getCurProcessCpuRate() {
        float totalCpuTime1 = getTotalCpuTime();
        float processCpuTime1 = getAppCpuTime();
        try {
            Thread.sleep(360);
        } catch (Exception e) {
        }
        float totalCpuTime2 = getTotalCpuTime();
        float processCpuTime2 = getAppCpuTime();
        float cpuRate = 100 * (processCpuTime2 - processCpuTime1)
                / (totalCpuTime2 - totalCpuTime1);
        return cpuRate;
    }

    public static float getTotalCpuRate() {
        float totalCpuTime1 = getTotalCpuTime();
        float totalUsedCpuTime1 = totalCpuTime1 - sStatus.idletime;
        try {
            Thread.sleep(360);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        float totalCpuTime2 = getTotalCpuTime();
        float totalUsedCpuTime2 = totalCpuTime2 - sStatus.idletime;
        float cpuRate = 100 * (totalUsedCpuTime2 - totalUsedCpuTime1)
                / (totalCpuTime2 - totalCpuTime1);
        return cpuRate;
    }

    public static long getTotalCpuTime() {
        String[] cpuInfos = null;
        try {
            BufferedReader reader = new BufferedReader(new InputStreamReader(
                    new FileInputStream("/proc/stat")), 1000);
            String load = reader.readLine();
            reader.close();
            cpuInfos = load.split(" ");
        } catch (IOException ex) {
            ex.printStackTrace();
        }

        sStatus.usertime = Long.parseLong(cpuInfos[2]);
        sStatus.nicetime = Long.parseLong(cpuInfos[3]);
        sStatus.systemtime = Long.parseLong(cpuInfos[4]);
        sStatus.idletime = Long.parseLong(cpuInfos[5]);
        sStatus.iowaittime = Long.parseLong(cpuInfos[6]);
        sStatus.irqtime = Long.parseLong(cpuInfos[7]);
        sStatus.softirqtime = Long.parseLong(cpuInfos[8]);
        return sStatus.getTotalTime();
    }

    public static long getAppCpuTime() {

        String[] cpuInfos = null;
        long appCpuTime=0;
        try {
            int pid = android.os.Process.myPid();
            BufferedReader reader = new BufferedReader(new InputStreamReader(
                    new FileInputStream("/proc/" + pid + "/stat")), 1000);
            String load = reader.readLine();
            reader.close();
            cpuInfos = load.split(" ");
            appCpuTime = Long.parseLong(cpuInfos[13])
                    + Long.parseLong(cpuInfos[14]) + Long.parseLong(cpuInfos[15])
                    + Long.parseLong(cpuInfos[16]);
        } catch (IOException ex) {
            ex.printStackTrace();
        }

        return appCpuTime;
    }

    static Status sStatus = new Status();

    public static void isPush(AppActivity appActivity, int sw) {
        // if (sw == 0) {
        //     XGPushManager.unregisterPush(appActivity, new XGIOperateCallback() {
        //         @Override
        //         public void onSuccess(Object data, int flag) {
        //             Log.w("isPush", "+++ register unpush sucess. token:" + data + "flag" + flag);
        //         }

        //         @Override
        //         public void onFail(Object data, int errCode, String msg) {
        //             Log.w("isPush", "+++ register push fail. token:" + data
        //                     + ", errCode:" + errCode + ",msg:"
        //                     + msg);
        //         }
        //     });

        // } else if (sw == 1 || sw == 10) {
        //     XGPushManager.registerPush(appActivity, new XGIOperateCallback() {
        //         @Override
        //         public void onSuccess(Object data, int flag) {
        //             Log.w("isPush", "+++ register push sucess. token:" + data + "flag" + flag);
        //         }

        //         @Override
        //         public void onFail(Object data, int errCode, String msg) {
        //             Log.w("isPush", "+++ register push fail. token:" + data
        //                     + ", errCode:" + errCode + ",msg:"
        //                     + msg);
        //         }
        //     });

        // }
    }




    static class Status {
        public long usertime;
        public long nicetime;
        public long systemtime;
        public long idletime;
        public long iowaittime;
        public long irqtime;
        public long softirqtime;

        public long getTotalTime() {
            return (usertime + nicetime + systemtime + idletime + iowaittime
                    + irqtime + softirqtime);
        }
    }

    public static String getCurrentTime() {
        long currentTime = System.currentTimeMillis();
        Date date = new Date(currentTime);
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss",
                Locale.getDefault());
        String time = sdf.format(date);
        return time;
    }

    //刘海屏判断
    public static String HasNotchScreen(AppActivity activity) {
        System.out.println("Build.MANUFACTURER::" + Build.MANUFACTURER);
        // android  P 以上有标准 API 来判断是否有刘海屏
        // https://blog.csdn.net/u011494285/article/details/86681405
        // https://developer.android.com/about/versions/pie/android-9.0#cutout
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                DisplayCutout displayCutout = activity.getWindow().getDecorView().getRootWindowInsets().getDisplayCutout();
                if (displayCutout != null) {
                    // 说明有刘海屏
                    return "1";
                }
            } else {
                // 通过其他方式判断是否有刘海屏  目前官方提供有开发文档的就 小米，vivo，华为（荣耀），oppo
                if (hasNotchXiaomi(activity) || hasNotchAtHuawei(activity)
                        || hasNotchAtVivo(activity) || hasNotchAtOPPO(activity)) {
                    return "1";
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return "0";
    }
    /**
     * oppo刘海屏判断
     * https://open.oppomobile.com/wiki/doc#id=10159
     */
    private static boolean hasNotchAtOPPO(AppActivity activity) {
        if ("OPPO".equals(Build.MANUFACTURER)) {
            return activity.getPackageManager().hasSystemFeature("com.oppo.feature.screen.heteromorphism");
        } else {
            return false;
        }
    }

    /**
     * vivo刘海屏判断
     * https://swsdl.vivo.com.cn/appstore/developer/uploadfile/20180328/20180328152252602.pdf
     */
    private static boolean hasNotchAtVivo(AppActivity activity) {
        if ("VIVO".equals(Build.MANUFACTURER)) {
            try {
                Class<?> c = Class.forName("android.util.FtFeature");
                Method get = c.getMethod("isFeatureSupport", int.class);
                return (boolean) (get.invoke(c, 0x00000020));//刘海屏
            } catch (Exception e) {
                e.printStackTrace();
                return false;
            }
        } else {
            return false;
        }
    }

    /**
     * huawei刘海屏判断
     * https://devcenter.huawei.com/consumer/cn/devservice/doc/50114
     */
    private static boolean hasNotchAtHuawei(AppActivity activity) {
        boolean ret = false;
        if ("HUAWEI".equals(Build.MANUFACTURER)) {
            try {
                ClassLoader cl = activity.getClassLoader();
                Class HwNotchSizeUtil = cl.loadClass("com.huawei.android.util.HwNotchSizeUtil");
                Method get = HwNotchSizeUtil.getMethod("hasNotchInScreen");
                ret = (boolean) get.invoke(HwNotchSizeUtil);
            } catch (ClassNotFoundException e) {
                Log.e("hasNotchAtHuawei", "hasNotchInScreen ClassNotFoundException");
            } catch (NoSuchMethodException e) {
                Log.e("hasNotchAtHuawei", "hasNotchInScreen NoSuchMethodException");
            } catch (Exception e) {
                Log.e("hasNotchAtHuawei", "hasNotchInScreen Exception");
            } finally {
                return ret;
            }
        }
        return ret;
    }

    /**
     * 小米刘海屏判断.
     * https://dev.mi.com/console/doc/detail?pId=1293
     */
    private static boolean hasNotchXiaomi(AppActivity activity) {
        if ("Xiaomi".equals(Build.MANUFACTURER)) {
            try {
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

            } catch (ClassNotFoundException e) {
                e.printStackTrace();
            } catch (NoSuchMethodException e) {
                e.printStackTrace();
            } catch (IllegalAccessException e) {
                e.printStackTrace();
            } catch (IllegalArgumentException e) {
                e.printStackTrace();
            } catch (InvocationTargetException e) {
                e.printStackTrace();
            }

        }
        return false;
    }
}
