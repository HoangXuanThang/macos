package org.cocos2dx.lua;

import android.app.Application;
import android.content.Context;
// import android.os.Handler;
// import android.util.Log;

// import com.enhance.gameservice.IGameTuningService;
// import com.tencent.android.tpush.XGIOperateCallback;
// import com.tencent.android.tpush.XGPushConfig;
// import com.tencent.android.tpush.XGPushManager;

import org.cocos2dx.lib.Cocos2dxRenderer;

public class App extends Application{
    private  static  final String TAG="tj_log";
    // private Handler handler;
    // public static final String UPDATE_STATUS_ACTION="com.tianji.MyLuaGame.action.UPDATE_STATUS";
    // public static final String TC_GAME_TYPE_ALIAS="TC_GAME_TYPE_ALIAS";
    @Override
    public void onCreate() {
        super.onCreate();
        // XGPushConfig.enableDebug(this,true);
        // XGPushConfig.setHuaweiDebug(true);
        //打开第三方推送
        // XGPushConfig.enableOtherPush(getApplicationContext(), true);
        // XGPushConfig.setMiPushAppId(this, "2882303761517900928");
        // XGPushConfig.setMiPushAppKey(this, "5881790014928");
        // XGPushConfig.setMzPushAppId(this, "117181");
        // XGPushConfig.setMzPushAppKey(this, "fd61fe9379344325833040669bf4b47a");
        // XGPushConfig.enableOtherPush(getApplicationContext(), true);
        Tools.tool(getApplicationContext());
        // XGPushConfig.getToken(this);
        // initapp();

    }

	@Override
	public void onLowMemory() {
		super.onLowMemory();
		Cocos2dxRenderer.nativeOnMemoryWarning();		
	}

    // private void initapp() {
    //     XGPushManager.registerPush(this, new XGIOperateCallback() {
    //         @Override
    //         public void onSuccess(Object data, int flag) {
    //             Log.w(TAG, "+++ register push sucess. token:" + data + "flag" + flag);
    //         }

    //         @Override
    //         public void onFail(Object data, int errCode, String msg) {
    //             Log.w(TAG, "+++ register push fail. token:" + data
    //                             + ", errCode:" + errCode + ",msg:"
    //                             + msg);
    //         }
    //     });

    // }

}
