---
title: homestead安装配置
categories: 服务器上那点事儿
date: 2016-06-30 11:54:07
tags:
- Vagrant
- No input file specified
- homestead
---

最近所有的事情都在Vagrant的homestead里完成了，以后再也不用没完没了自己折腾服务器环境了。
<!-- more -->

首先我默认Vagrant已经安装好了。

## 安装Homestead

[homestead官方文档](https://laravel.com/docs/5.2/homestead)在此。

速成配置如下:

首先需要用composer安装Homestead
```
composer require laravel/homestead --dev`
```

然后用`make`命令生成`Vagrantfile`和`Homestead.yaml`

Mac/Linux:
```
php vendor/bin/homestead make
```

Windows:
```
vendor\\bin\\homestead make
```

## 配置
在`Homestead.yaml`中的folders是本地和服务器的文件夹映射：
```
folders:
    - map: ~/Code
      to: /home/vagrant/Code
```
sites是用来配置nginx目录的,需要将此地址加入本地的`hosts`中，也可以同时挂多个项目:
```
sites:
    - map: homestead.app
      to: /home/vagrant/Code/some-project/public
    - map: test.app
      to: /home/vagrant/Code/test
```

## 启动
```
Vagrant up
```
进入VM中(启动时已经将你的密钥复制进了虚拟机，所以登陆也不用密码)：
```
vagrant ssh
```

## 结论

现在你可以用这个环境快速开发了，homestead里边php，nodejs，nginx，mysql，radis等等东西都已经妥善安装好了，随便你胡来，弄坏了也太容易恢复了，一身轻松。更详细的教程参见上边提到的[官方文档](https://laravel.com/docs/5.2/homestead)。

## 小问题补充

**No input file specified**

有时候配置完了从浏览器访问会提示`No input file specified`。这意思就是VM上的server没有找到`index.php`文件。
首先你先ssh到homestead中查看文件夹的映射和地址是否正确。如果这些没问题的话，退出虚拟机运行一下下边的命令没准能解决问题：
```
vagrant provision
```
