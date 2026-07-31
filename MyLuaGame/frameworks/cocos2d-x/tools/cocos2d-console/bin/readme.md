# 环境安装流程

1. 安装android studio

   有些sdk和环境可以通过studio内嵌的sdk manager来完成下载

   目录在android studio的安装目录里，C:\Program Files (x86)\Android\android-sdk

   其实就是之前eclipse打包的adt-bundle-windows-x86_64-20140702\sdk

   这里adt采用android studio新版本，防止之前eclipse打包自带adt的版本问题

   ?

2. 编辑`local.properties`文件

  ```
  sdk.dir=C\:\\Program Files (x86)\\Android\\android-sdk
  ndk.dir=D\:\\android-ndk-r16b
  ```

  注意android studio优先会读取windows的环境变量，之前打包所定义的`ANDROID_SDK_ROOT`和`NDK_ROOT`会影响。

  使用project defines，而不是system defines

  ?

3. android studio中File -> Sync project with Gradle Files

   在build的窗口中，如果有红字提示缺失或者问题，予以相关解决，一般都是下载相关版本sdk或者build-tools。

   ?

4. 开始make

   ?

5. 复制签名key，修改gradle.properties参数
   ```
   RELEASE_STORE_FILE=../my-release-key.keystore
   RELEASE_STORE_PASSWORD=404875855
   RELEASE_KEY_ALIAS=youmi
   RELEASE_KEY_PASSWORD=404875855
   ```

   ?

6. 在左边条 Build Variants -> release 切换


   




# 问题解决

- ninja: fatal: CreateProcess
  - 好像是偶发问题，重编几次就好。怀疑并发编译有关，或者机器环境。
- apk输出目录
  - proj.android\app\build\outputs\apk
- Could not generate a proxy class for class com.android.build.gradle.tasks.BuildArtifactReportTask.
  - jdk版本不够高，下载安装个最新的
- breakpad的mac下编译问题
  - google官方提供了mk，但cocos2dx新版本使用gradle和cmake，有个汇编文件编译后死活找不大相关符号
  - 转折方式，用ndk-build来编译sample_app下的测试项目，可以得到lib文件，再通过cmake直接链接lib


