package org.cocos2dx.lua;

import android.app.Activity;
import android.os.Handler;
import android.os.Message;
import org.cocos2dx.lib.Cocos2dxHelper;
import org.cocos2dx.lib.Cocos2dxLuaJavaBridge;
import org.cocos2dx.lua.AppActivity;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.concurrent.ConcurrentHashMap;

import org.cocos2dx.lua.CallInfo;

public class MessageHandler extends Handler
{
    private static Integer messageIDCounter = 1;
    private static MessageHandler singleton = null;

    private AppActivity activity;
    private ConcurrentHashMap<Integer, CallInfo> callMap = new ConcurrentHashMap<Integer, CallInfo>();
    public MessageHandler(AppActivity activity)
	{
        this.activity = activity;
        singleton = this;
        messageIDCounter = 1;
    }

    /**
     * 这里不能直接调用Lua代码， 可能会出现ANR问题导致闪退
     * @param msg
     */
    @Override
    public void handleMessage(Message msg)
	{
        super.handleMessage(msg);

        int msgID = (int)msg.obj;
        if (callMap.get(msgID) == null)
		{
            System.out.println("handleMessage: no such msgID " + msgID);
            return;
        }
		
        CallInfo info = callMap.get(msgID);
        System.out.println("handleMessage: " + msgID + " " + info.funcName + ", " + info.bundle);

        try
		{
            Method method = this.activity.getClass().getMethod(info.funcName, CallInfo.class);
            method.invoke(this.activity, info);
        }
		catch (NoSuchMethodException e)
		{
            e.printStackTrace();
        }
		catch (IllegalAccessException e)
		{
            e.printStackTrace();
        }
		catch (InvocationTargetException e)
		{
            e.printStackTrace();
        }
    }

    public void removeCallback(int msgID)
	{
        callMap.remove(msgID);
    }

    public ArrayList<CallInfo> getCallbackByName(String funcName)
	{
        ArrayList<CallInfo> ret = new ArrayList<CallInfo>();
        for(CallInfo v : callMap.values())
		{
            if(v.funcName.equals(funcName))
			{
                ret.add(v);
            }
        }
		
        return ret;
    }

    public void callbackToLua(final int msgID, final String data)
	{
        final CallInfo info = callMap.get(msgID);
        if(info == null)
		{
            System.out.println("callbackToLua: no such msgID " + msgID);
            return;
        }

        System.out.println("callback: " + msgID + " " + info.funcName);
        callMap.remove(msgID);
        Cocos2dxHelper.runOnGLThread(new Runnable()
		{
            @Override
            public void run()
			{
                System.out.println("callbackToLua: " + msgID + " " + info.funcName + ", " + data);
                Cocos2dxLuaJavaBridge.callLuaFunctionWithString(info.callbackId, data);
            }
        });
    }

    /**
     * 将消息发送到主线程处理
     * @param funcName
     * @param bundle
     * @param callbackId
     */
    public void receiveMsg(String funcName, String bundle, int callbackId)
	{
        CallInfo info = new CallInfo();
        info.msgID = this.messageIDCounter;
        this.messageIDCounter = this.messageIDCounter + 1;

        info.funcName = funcName;
        info.bundle = bundle;
        info.callbackId = callbackId;
        callMap.put(info.msgID, info);

        Message message = new Message();
        message.obj = info.msgID;
        this.sendMessage(message);
    }


    /**
     *
     * 从lua到Java的桥
     * @param funcName 函数名
     * @param bundle 数据体 json格式
     * @param callbackId lua回调函数
     */
    public static void msgFromLua(String funcName, String bundle, int callbackId)
	{
        System.out.println("msgFromLua: " + funcName + ", " + bundle);
        singleton.receiveMsg(funcName, bundle, callbackId);
    }
}
