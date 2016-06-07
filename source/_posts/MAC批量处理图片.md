---
title: MAC批量处理图片
categories: Tips
date: 2016-05-30 17:19:38
tags:
- MAC
- 图片处理
---

最近有个批量改图片尺寸的活，打开photoshop做批处理真心觉得累。搜罗了一圈，发现mac有个命令———`sips`。
再输入如下命令之后：
```
sips --help
```
修改尺寸的就是下面的几个用法。
```Bash
    -z, --resampleHeightWidth pixelsH pixelsW
        --resampleWidth pixelsW
        --resampleHeight pixelsH
    -Z, --resampleHeightWidthMax pixelsWH
```
例如：
```Bash
sips -z 100 200 img.jpg //z为小写，100、200分别是是img.jpg的宽、高
sips -Z 200 img.jpg //Z为大写, 200为img.jpg的最大宽高
sips -Z 200 *.jpg //处理该路径下的所有.jpg文件，最大宽高为200
```
