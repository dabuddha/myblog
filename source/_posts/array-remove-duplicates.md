---
title: js数组去重
categories: Javascript
date: 2016-06-05 20:57:53
tags:
- 数组去重
---

## 最简洁
```js
//利用Array.filter
var arr = ["1", "2", "3", "1", "3"];
arr = arr.filter( function( item, index, inputArray ) {
           return inputArray.indexOf(item) == index;
    });//Output: ["1", "2", "3"]
```
这个写法相对简洁，但是并不怎么效率`O(n^2)`，不适合过长的数组。

<!-- more -->

## 改进版
```js
function uniq(a) {
    var seen = {};
    return arr.filter(function(item) {
        return seen.hasOwnProperty(item) ? false : (seen[item] = true);
    });
}
```
这个写法比上一个效率得多，时间复杂度O(n),但是有两个缺陷：
* 对于`Number`和`String`来说，该算法不能区分，比如：
```js
uniq([1,"1",2,"2"])//返回[1, 2]
```
* 同理，对于对象来说也不能区分，所有对象都被认为相等。
所以使用时要明确使用场景。
```js
uniq([{foo:1},{foo:2}])//返回[{foo:1}]
```

## 最终版
```js
function uniq(a) {
    var prims = {"boolean":{}, "number":{}, "string":{}}, objs = [];

    return a.filter(function(item) {
        var type = typeof item;
        if(type in prims)
            return prims[type].hasOwnProperty(item) ? false : (prims[type][item] = true);
        else
            return objs.indexOf(item) >= 0 ? false : objs.push(item);
    });
}
```

## ES6版本
ES6提供了新的数据结构Set。它类似于数组，但是成员的值都是唯一的，没有重复的值。
这样我们的去重的思路可以变为，将数组转化为集合，再由集合转化为数组。
```js
[...new Set(arr)]
```
配合babel之后，这行代码应该是真正的终极版。
