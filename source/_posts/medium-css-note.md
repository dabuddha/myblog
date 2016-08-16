---
title: Medium的CSS编写指南の学习笔记
categories: CSS
date: 2016-08-15 14:21:05
tags:
- Medium
- CSS
- 笔记
- less
- 编码
- 指南
---

最近看了[《Medium的CSS写的真特么好》](https://medium.com/@fat/mediums-css-is-actually-pretty-fucking-good-b8e2a6c78b06#.71ttzygsz)这篇文章，我终于可以为我CSS一直以来杂乱无章的命名思路划上一个圆满的句号了。

<!-- more -->

### Javascript

#### 命名规则为：`js-<targetname>`

将那些被需要被js选择器捕获的class加上js前缀，**这些类绝对不要包含任何样式**

```html
<a href="/login" class="btn btn-primary js-login"></a>
```

### Utility

#### 命名规则为：`u-<utilityName>`
Utility这词我还不太会翻译，姑且叫它"小功能吧"，主要是一些常用的CSS特性，比如：浮动，垂直居中，文字截取什么的。方便复用代码。

```html
<div class="u-clearfix">
  <p class="u-textTruncate">{$text}</p>
  <img class="u-pullLeft" src="{$src}" alt="">
  <img class="u-pullLeft" src="{$src}" alt="">
  <img class="u-pullLeft" src="{$src}" alt="">
</div>
```

### Components

#### 命名规则为：`<componentName>[--modifierName|-descendantName]`

modifier是那些基础组件的派生样式需要的类，使用时要和基础组件的类一起使用,两条横线加上`camelCase`形式的名字。例子如下：
```css
/* Core button */
.btn { /* … */ }
/* Default button style */
.btn--default { /* … */ }
```
```html
<button class="btn btn--primary">…</button>
```

descendantName是指组件跟节点下的子节点的名称，用一个横线加上`camelCase`形式的名字。例子如下：
```html
<article class="tweet">
  <header class="tweet-header">
    <img class="tweet-avatar" src="{$src}" alt="{$alt}">
    …
  </header>
  <div class="tweet-body">
    …
  </div>
</article>
```
#### 命名规则为：componentName.is-stateOfComponent
使用`is-stateName`来描述组件的特定状态，使用`CamelCase`命名。**永远也别给这些类单独的样式，它们只用在和其他类串联的样式上**。
```CSS
.tweet { /* … */ }
.tweet.is-expanded { /* … */ }
```
```html
<article class="tweet is-expanded">
  …
</article>
```
### Variables

#### 命名规则：`<property>-<value>[--componentName]`

Medium用的是less，使用其他的预编译系统也是一样，使用变量是一个可以提升工作效率的方式，

#### Color
推荐全部使用RGB或RGBA的形式。

#### z-index
提前定义好`z-index`变量
形如`@zIndex-1 - @zIndex-9`分别代表100到900，不直接使用数字。

#### Font
提前定义一些字体粗细和大小，使用mixin：`.font-sansI7, .font-sansN7`等
```
N = normal
I = italic
4 = normal font-weight
7 = bold font-weight
```

```css
@fontSize-micro
@fontSize-smallest
@fontSize-smaller
@fontSize-small
@fontSize-base
@fontSize-large
@fontSize-larger
@fontSize-largest
@fontSize-jumbo
```
#### Line Height

```css
@lineHeight-tightest
@lineHeight-tighter
@lineHeight-tight
@lineHeight-baseSans
@lineHeight-base
@lineHeight-loose
@lineHeight-looser
```

`line-height`永远比它的容器的高度少1

```CSS
.btn {
  height: 50px;
  line-height: 49px;
}
```

### Letter spacing

提前预定义一些值：

```css
@letterSpacing-tightest
@letterSpacing-tighter
@letterSpacing-tight
@letterSpacing-normal
@letterSpacing-loose
@letterSpacing-looser
```

### Polyfills

#### 命名规则：`m-<propertyName>`

使用mixin来生成不同浏览器的前缀，或者csshack之类的代码，（如果是用postcss，autoprefixer直接就搞定了✨）
```css
.m-borderRadius(@radius) {
  -webkit-border-radius: @radius;
     -moz-border-radius: @radius;
          border-radius: @radius;
}
```
