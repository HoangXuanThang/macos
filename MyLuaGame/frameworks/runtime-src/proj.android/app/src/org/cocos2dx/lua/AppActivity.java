/****************************************************************************
Copyright (c) 2008-2010 Ricardo Quesada
Copyright (c) 2010-2016 cocos2d-x.org
Copyright (c) 2013-2016 Chukong Technologies Inc.
Copyright (c) 2017-2018 Xiamen Yaji Software Co., Ltd.

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

import java.util.ArrayList;
import org.cocos2dx.lib.Cocos2dxActivity;

import android.app.Activity;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.widget.Toast;
import android.os.Build;
import android.view.WindowManager;
import android.view.KeyEvent;

import www.tianji.finalsdk.CallInfo;
import www.tianji.finalsdk.MessageHandler;

public class AppActivity extends Cocos2dxActivity {
	BatteryReceiver receiver;
	MessageHandler messageHandler = null;
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.setEnableVirtualButton(false);
        super.onCreate(savedInstanceState);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON, WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        //动态注册广播
		IntentFilter intentFilter = new IntentFilter(Intent.ACTION_BATTERY_CHANGED);
		receiver = new BatteryReceiver();
		registerReceiver(receiver, intentFilter);

        // Workaround in https://stackoverflow.com/questions/16283079/re-launch-of-activity-on-home-button-but-only-the-first-time/16447508
        if (!isTaskRoot()) {
            // Android launched another instance of the root activity into an existing task
            //  so just quietly finish and go away, dropping the user back into the activity
            //  at the top of the stack (ie: the last state of this task)
            // Don't need to finish it again since it's finished in super.onCreate .
            return;
        }

        // DO OTHER INITIALIZATION BELOW
		this.messageHandler = new MessageHandler(this);

    }

    public void login(final CallInfo info) {
        messageHandler.callbackToLua(info.msgID, "ok");
    }

    public void logout(final CallInfo info) {
        messageHandler.callbackToLua(info.msgID, "ok");
    }

	public void pay(final CallInfo info) {
		messageHandler.callbackToLua(info.msgID, "ok");
	}

	public void commitRoleInfo(final CallInfo info) {
		messageHandler.callbackToLua(info.msgID, "ok");
	}

	public void isHiddenLoginButton(CallInfo info) {
        messageHandler.callbackToLua(info.msgID, "true");
    }

	public void getBattery(CallInfo info) {
        messageHandler.callbackToLua(info.msgID, receiver.getBatteryPercent());
    }

    public void isHasNotchScreen(CallInfo info) {
        messageHandler.callbackToLua(info.msgID, Tools.HasNotchScreen(AppActivity.this));
    }

	@Override
	public void onDestroy() {
		super.onDestroy();
		unregisterReceiver(receiver);
	}

	@Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        if (event.getKeyCode() == KeyEvent.KEYCODE_BACK
                && event.getAction() == KeyEvent.ACTION_DOWN
                && event.getRepeatCount() == 0) {
            // 根据sdk情况票判断
            android.os.Process.killProcess(android.os.Process.myPid());
        }
        return super.dispatchKeyEvent(event);
    }
}
