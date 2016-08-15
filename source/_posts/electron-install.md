---
title: 手动安装electron
date: 2016-08-11 22:18:57
categories: Node
tags:
- Node
- Electron
- install
- 安装
- nightmare
---

天朝这个网络环境真是不说什么了。。在`npm install nightmare`的过程中看到在下载electron结果就是一辈子的0%。后来切到了淘宝的npm镜像还是不管用。然后发现这个玩意还得单独下。

切到淘宝镜像的方法就不说了，[这里有说明](https://npm.taobao.org/)。

### 安装Electron

1、从[淘宝的Electron镜像](https://npm.taobao.org/mirrors/electron/)下载对应的版本，下载到根目录下的`.electron`文件夹下，然后执行`npm install electron-prebuilt`或者其他的需要引入electron的包的命令(比如npm install nightmare)。
