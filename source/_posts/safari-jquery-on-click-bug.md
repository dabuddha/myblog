---
title: 移动端safari上jQuery绑定click事件的bug
categories: Javascript
date: 2016-06-01 00:49:36
tags:
- iOS
- jQuery
- Safari
---

之前网站适配pc端的时候发现，在手机端safari上click事件各种没反应，查了一圈看来是有这么个bug。
html如下：
```html
<div id="main">
    <ul>
        <li>1</li>
        <li>2</li>
        <li>3</li>
    </ul>
</div>
```
js代码如下：
```javascript
$('body').on('click','li',function(){
  console.log('blink!');
});
```

如上代码在iOS的safari上毫无反应。
<!-- more -->
几个解决方法：
>* 不将`on`作用于`document`或者`body`上，作用在更小的dom节点上，比如，如下代码是生效的：
```javascript
$('#main').on('click','li',function(){
  console.log('blink!');
});
```
>* 也可以额外在节点上再绑一次事件（添加到代码中）：
```javascript
$('body').children().click(function(){
  //此处什么也不做
});
```
>* 还有不太优雅的方法，可以再元素标签上添加一个`onclick=''`。
>* 在和用户体验不冲突的情况下也可以用CSS解决，给需要响应`click`事件的标签添加`cursor:pointer;`
