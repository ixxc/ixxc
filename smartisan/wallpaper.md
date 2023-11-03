## 在线壁纸
接口：http://wallpaper-api.smartisan.com/app/index.php?r=paperapi/index/list&client_version=2&source=&limit=20&paper_id=0

## 系统内建壁纸
1、解压：system.img

2、进入路径：system\app\SmartisanWallpapers

3、解压：SmartisanWallpapers.apk

4、进入路径：res\drawable-xxhdpi-v4

## 系统内建壁纸-隐秘部分
解压各种包，仍未找到图片存放的地方，接口也没有返回，用另一种方式提取

1、进入手机设置，依次选定某个壁纸，并确定

2、进入文件管理器，路径：smartisan\wallpapers，这些生成的无后缀文件，就是真实的图片，此时重命名即可得到图片

3、如果想通过接口下载，则提取所有生成的无后缀文件名称，请求地址：http://image.smartisanos.cn/setting/paper/文件名.jpg或文件名.png
