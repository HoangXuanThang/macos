###  res

- 所有文件名均由==小写英文字母、数字、下划线==组成，不允许大写，除了`Resources`之外
  - windows下大小写不明感，但android和ios下是敏感，大小写混用容易出现难查的问题
- `Resource`比较特殊的原因在于cocos studio默认使用该名字，需要以mklink软连接的方式链接到相关工程目录
  - ```mklink /d Resources ..\..\UI\Resources```
- `Resource`存静态资源，比如ui json工程，ui资源
- 各目录名和文件名应该全局唯一。比如不该存在`res/img`和`res/Resource/img`，在有搜索路径处理的情况下，容易导致二义性
- 新建文件夹名使用单数形式，如`font`而不是`fonts`，`img`而不是`imgs`

### res/Resource

- UI工程资源存放在`Resources/ui`目录下
- `font` ttf等字体库目录，不管UI上的还是程序特定使用，都扔到这。美术字除外


- `common`公用资源

### spine

- 动画资源

### img

- 存放一些与UI不直接关联的静态资源
- 存在一些大背景图，比如jpg这种特殊格式

