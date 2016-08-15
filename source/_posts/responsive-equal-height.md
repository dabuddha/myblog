---
title: 在响应式布局下，保证不同元素的相同高度
date: 2016-07-11 15:50:55
categories: CSS
tags:
- 响应式
- 高度
- 相等
---

在响应式布局中限制不同元素的高度依靠单纯的css应该是无能为力了，翻了翻[CSS-TRICKS](https://css-tricks.com/equal-height-blocks-in-rows/)找到了解决方案。

依赖jQuery的[matchHeight.js](http://brm.io/jquery-match-height/)可以将全部所选元素等高。

再有就是将处在同一行的元素等高。原理就是在在同一行元素中选择最高的，然后将所有元素的高度设置成该数值，代码如下：

<!-- more -->

```js

equalheight = function(container){

var currentTallest = 0,
     currentRowStart = 0,
     rowDivs = new Array(),
     $el,
     topPosition = 0;
 $(container).each(function() {

   $el = $(this);
   $($el).height('auto')
   topPostion = $el.position().top;

   if (currentRowStart != topPostion) {
     for (currentDiv = 0 ; currentDiv < rowDivs.length ; currentDiv++) {
       rowDivs[currentDiv].height(currentTallest);
     }
     rowDivs.length = 0; // empty the array
     currentRowStart = topPostion;
     currentTallest = $el.height();
     rowDivs.push($el);
   } else {
     rowDivs.push($el);
     currentTallest = (currentTallest < $el.height()) ? ($el.height()) : (currentTallest);
  }
   for (currentDiv = 0 ; currentDiv < rowDivs.length ; currentDiv++) {
     rowDivs[currentDiv].height(currentTallest);
   }
 });
}

//例子，比如想具有相同的class的元素有相等的高度
$(window).load(function() {
  equalheight('.eqheight');
});


$(window).resize(function(){
  equalheight('.eqheight');
});
```

[codepen上的例子](https://codepen.io/micahgodbolt/pen/FgqLc)。
