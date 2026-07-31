package www.tianji.finalsdk;

/**
 * Created by ccy on 2017/8/7.
 * SDK 相关的配置函数
 */
public class SDKConfig {
    /**
     * 是否隐藏登录按钮
     */
    final static boolean HIDDEN_LOGIN_BUTTON = false;
    /**
     * 退出登录后，是否清理登出回调函数
     */
    final static String LOGOUT_FUNCNAME = "logout";
    final static boolean CLEAR_LOGOUT_CALLBACK = false;
    /**
     * 登录成功后， 理澡清理登录回调函数
     */
    final static String LOGIN_FUNCNAME= "login";
    final static boolean CLEAR_LOGIN_CALLBACK = true;
}
