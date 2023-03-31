## 效果
![IMAGE](https://github.com/Xuyadongfight/yd_resources/blob/main/ydhotreload/ydhotreload_demo.gif)

## 使用
1. 终端运行`open ~/`命令打开用户目录，在用户目录下创建一个test文件夹(**注意:不要创建在系统默认的几个文件夹下面，否则会遇到权限问题**)
![IMAGE](https://github.com/Xuyadongfight/yd_resources/blob/main/ydhotreload/ydhotreload_1.jpg)
2. 终端运行`cd ~/test`然后运行`git clone https://github.com/Xuyadongfight/YDHotReload.git`
3. clone完成之后。test文件夹中会有YDHotReload文件夹 
![IMAGE](https://github.com/Xuyadongfight/yd_resources/blob/main/ydhotreload/ydhotreload_2.jpg)
4. 运行YDHotReload文件夹中的YDHotReloadDemo项目
![IMAGE](https://github.com/Xuyadongfight/yd_resources/blob/main/ydhotreload/ydhotreload_3.jpg)
5. 运行工程之后会看到file_name_config文件中自动配置了json文件(project_path和sdk_path)
![IMAGE](https://github.com/Xuyadongfight/yd_resources/blob/main/ydhotreload/ydhotreload_4.jpg)
6. 终端运行`sudo chmod 777 /usr/local/bin/hot`
![IMAGE](https://github.com/Xuyadongfight/yd_resources/blob/main/ydhotreload/ydhotreload_5.jpg)
此时会提示输入用户密码，正常输入就好。输入完成回车即可。(注意:输入密码时，终端并不会显示你输入的字符。正常输入即可)
7. 终端运行`cp -R ~/test/YDHotReload/YDHotReloadMac.app /Applications`
成功之后可以在应用程序中找到YDHotReloadMac.app
![IMAGE](https://github.com/Xuyadongfight/yd_resources/blob/main/ydhotreload/ydhotreload_6.jpg)
点击运行。让YDHotReloadMac.app支持辅助功能。
![IMAGE](https://github.com/Xuyadongfight/yd_resources/blob/main/ydhotreload/ydhotreload_7.jpg)
8. 设置完成之后，缩小YDHotReloadMac.app。然后重新运行YDHotReloadDemo工程。此时就可以使用热重载功能了。修改完代码之后，使用command+s进行热重载。
