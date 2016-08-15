---
title: 在javascript中，callback和this的那点事儿
date: 2016-07-08 16:47:36
categories: Javascript
tags:
- javascript
- callback
- bind
- 回调
---

js中的this是一个很灵活的东西，可能给你带来便利，也可能让你焦头烂额。尤其在callback中可能会经常出错。下面我结合例子说明一下。

### 反面典型
```js
function MyConstructor(data,callback){
  this.data = data;
  callback.on('data',function(){
    alert(this.data);
  });
}

//callback
var mycallback = {
  on: function(event, callback){
    setTimeout(callback,1000);
  }
};

//调用
var obj = new MyConstructor('hao', mycallback);
```
<!-- more -->
上面代码的返回结果是：`undefined`

this是每个函数中都存在的一个特殊的变量，它的值是取决于函数是如何执行的，**而不是何时何地如何定义的**。它不像其它变量一样，被语义上的作用域所影响。

再给几个例子：
```js
function foo(){
  console.log(this);
}

foo();//此处的this指向window

var obj = {bar: foo};
obj.bar();//此处this指向的是obj

new foo();//这个this会指向继承自'foo.prototype'的实例对象
```
### 如何找到正确的`this`

#### 1、为了让上边的例子变正确，我们可以用另一个变量存储this
```js

function MyConstructor(data,callback){
  this.data = data;
  var self = this;
  callback.on('data',function(){
    alert(self.data);
  });
}

```
#### 2、使用bind()

```js

function MyConstructor(data, callback) {
    this.data = data;
    var boundFunction = (function() { // 最外层括号非必须
        alert(this.data);             // 只是增强阅读性
    }).bind(this); // <- 使用bind()
    callback.on('data', boundFunction);
}

```
这里，我们将回调函数中的this和MyConstructor的this绑定了。

#### 3、es6的箭头函数

es6中的箭头函数中的this对象，它就是定义是所在的对象，而不是使用时所在的对象。
```js
function MyConstructor(data, callback) {
    this.data = data;
    callback.on('data', () => alert(this.data));
}
```
