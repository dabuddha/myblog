---
title: 在Next主题下使用Algolia搜索
date: 2016-06-06 23:23:19
categories: Hexo
tags:
- Algolia
- Next
- swiftype
---
Swiftype悄无声息的就取消了免费模式，新用户注册只能免费试用14天，老用户好像还能继续免费用(好在我下手早╮(╯▽╰)╭ )。
未雨绸缪吧，免得哪天我也不能用了，推一个新的第三方搜索----algolia。
<!-- more -->

## 官网注册
1、 [官网地址](http://www.algolia.com)注册帐号。
2、 新建一个INDEX如图。
{% asset_img algolia-index.png %}
3、 来到[API-KEYS](https://www.algolia.com/api-keys)页面，上面有后面需要的信息（记得还有上面的INDEX名）。
{% asset_img algolia-api-keys.png %}

## 第二步：上传数据到Algolia
1、 在Hexo主目录下执行
```
npm install hexo-algolia --save
```
2、 在根目录的_config.yml中加入如下配置，使用前边注册成果的数据
```
algolia:
  applicationID: 'your applicationID'
  apiKey: 'your apiKey'
  adminApiKey: 'your adminApiKey'
  indexName: 'your indexName'
  chunkSize: 5000
```
3、 接着执行，确保提交成功提示
```
hexo algolia
```
## 第三步：修改Hexo主题集成Algolia
1、 确保在head.swig文件中加入如下配置，注意改成自己的
```
<script type="text/javascript" id="hexo.configuration">
  var CONFIG = {
    root: '/',
    algolia: {
          applicationID: 'your applicationID',
          apiKey: 'your apiKey',
          indexName: ''your indexName',
          hits: {"per_page":10},
          labels: {"input_placeholder":"搜索...","hits_empty":"未发现与 「${query}」相关的内容","hits_stats":"${hits} 条相关条目，使用了 ${time} 毫秒"}
        }
  };
</script>
```
2、 在主题配置文件_config.yml中加入,作为开启关闭的开关
```
# Algolia
algolia: true
```
> 以Next为例，修改主题目录下`layout/search.swig`为：
```
{% if theme.swiftype_key %}
  {% include 'search/swiftype.swig' %}
{% elseif theme.tinysou_Key %}
  {% include 'search/tinysou.swig' %}
{% elseif config.search.path %}
  {% include 'search/localsearch.swig' %}
{% elseif theme.algolia %}
  {% include 'search/algolia.swig' %}
{% endif %}

```
3、 在要搜索的页面加入下面html,Next主题中在`layout/_partials/search/`中添加algolia.swig文件，写入如下内容：
```html
<div class="site-search">
  <div class="algolia-popup popup">
    <div class="algolia-search">
      <div class="algolia-search-input-icon">
        <i class="fa fa-search"></i>
      </div>
      <div class="algolia-search-input" id="algolia-search-input"></div>
    </div>

    <div class="algolia-results">
      <div id="algolia-stats"></div>
      <div id="algolia-hits"></div>
      <div id="algolia-pagination" class="algolia-pagination"></div>
    </div>

    <span class="popup-btn-close">
      <i class="fa fa-times-circle"></i>
    </span>
  </div>
</div>
```
4、 触发搜索的HTML节点中加入class名为`popup-trigger`的标签，如下：
```
<a href="#" class="popup-trigger">
```
> Next为例：在`layout/_partials/header.swig`修改如下（注释位置）：
```html
<nav class="site-nav">
  {% set hasSearch = theme.swiftype_key || theme.tinysou_Key || config.search || theme.algolia %}
  <!-- 添加algolia判断条件 -->
  {% if theme.menu %}
    <ul id="menu" class="menu">
      {% for name, path in theme.menu %}
        {% set itemName = name.toLowerCase() %}
        <li class="menu-item menu-item-{{ itemName }}">
          <a href="{{ url_for(path) }}" rel="section">
            {% if theme.menu_icons.enable %}
              <i class="menu-item-icon fa fa-fw fa-{{theme.menu_icons[itemName] | default('question-circle') | lower }}"></i> <br />
            {% endif %}
            {{ __('menu.' + itemName) }}
          </a>
        </li>
      {% endfor %}

      {% if hasSearch %}
        <li class="menu-item menu-item-search">
          {% if theme.swiftype_key %}
            <a href="#" class="st-search-show-outputs">
          {% elseif config.search %}
            <a href="#" class="popup-trigger">
            <!-- 判断algolia -->
          {% elseif theme.algolia %}
            <a href="#" class="popup-trigger">
          {% endif %}
            {% if theme.menu_icons.enable %}
              <i class="menu-item-icon fa fa-search fa-fw"></i> <br />
            {% endif %}
            {{ __('menu.search') }}
          </a>
        </li>
      {% endif %}
    </ul>
  {% endif %}

  {% if hasSearch %}
    <div class="site-search">
      {% include 'search.swig' %}
    </div>
  {% endif %}
</nav>
```
5、 需要确保页面包含如下JS代码（可以单独建立一个.swig文件，然后在整体layout的swig文件中加入）
```js
<script src="http://cdn.bootcss.com/instantsearch.js/1.5.1/instantsearch.js"></script>

<script type="text/javascript">
$(document).ready(function () {
  var algoliaSettings = CONFIG.algolia;
  var isAlgoliaSettingsValid = algoliaSettings.applicationID &&
    algoliaSettings.apiKey &&
    algoliaSettings.indexName;

  if (!isAlgoliaSettingsValid) {
    window.console.error('Algolia Settings are invalid.');
    return;
  }

  var search = instantsearch({
    appId: algoliaSettings.applicationID,
    apiKey: algoliaSettings.apiKey,
    indexName: algoliaSettings.indexName,
    searchFunction: function (helper) {
      var searchInput = $('#algolia-search-input').find('input');

      if (searchInput.val()) {
        helper.search();
      }
    }
  });

  // Registering Widgets
  [
    instantsearch.widgets.searchBox({
      container: '#algolia-search-input',
      placeholder: algoliaSettings.labels.input_placeholder
    }),

    instantsearch.widgets.hits({
      container: '#algolia-hits',
      hitsPerPage: algoliaSettings.hits.per_page || 10,
      templates: {
        item: function (data) {
          return (
            '<a href="' + CONFIG.root + data.path + '" class="algolia-hit-item-link">' +
            data._highlightResult.title.value +
            '</a>'
          );
        },
        empty: function (data) {
          return (
            '<div id="algolia-hits-empty">' +
            algoliaSettings.labels.hits_empty.replace(/\$\{query}/, data.query) +
            '</div>'
          );
        }
      },
      cssClasses: {
        item: 'algolia-hit-item'
      }
    }),

    instantsearch.widgets.stats({
      container: '#algolia-stats',
      templates: {
        body: function (data) {
          var stats = algoliaSettings.labels.hits_stats
            .replace(/\$\{hits}/, data.nbHits)
            .replace(/\$\{time}/, data.processingTimeMS);
          return (
            stats +
            '<span class="algolia-powered">' +
            '  <img src="' + CONFIG.root + 'images/algolia_logo.svg" alt="Algolia" />' +
            '</span>' +
            '<hr />'
          );
        }
      }
    }),

    instantsearch.widgets.pagination({
      container: '#algolia-pagination',
      scrollTo: false,
      showFirstLast: false,
      labels: {
        first: '<i class="fa fa-angle-double-left"></i>',
        last: '<i class="fa fa-angle-double-right"></i>',
        previous: '<i class="fa fa-angle-left"></i>',
        next: '<i class="fa fa-angle-right"></i>'
      },
      cssClasses: {
        root: 'pagination',
        item: 'pagination-item',
        link: 'page-number',
        active: 'current',
        disabled: 'disabled-item'
      }
    })
  ].forEach(search.addWidget, search);

  search.start();

  $('.popup-trigger').on('click', function(e) {
    e.stopPropagation();
    $('body').append('<div class="popoverlay">').css('overflow', 'hidden');
    $('.popup').toggle();
    $('#algolia-search-input').find('input').focus();
  });

  $('.popup-btn-close').click(function(){
    $('.popup').hide();
    $('.popoverlay').remove();
    $('body').css('overflow', '');
  });

});
</script>

<script type="text/javascript">
  $(document).ready(function () {
    if ( $('#local-search-input').size() === 0) {
      return;
    }

    // Popup Window;
    var isfetched = false;
    // Search DB path;
    var search_path = "search.xml";
    if (search_path.length == 0) {
      search_path = "search.xml";
    }
    var path = "/" + search_path;
    // monitor main search box;

    function proceedsearch() {
      $("body").append('<div class="popoverlay">').css('overflow', 'hidden');
      $('.popup').toggle();

    }
    // search function;
    var searchFunc = function(path, search_id, content_id) {
      'use strict';
      $.ajax({
        url: path,
        dataType: "xml",
        async: true,
        success: function( xmlResponse ) {
          // get the contents from search data
          isfetched = true;
          $('.popup').detach().appendTo('.header-inner');
          var datas = $( "entry", xmlResponse ).map(function() {
            return {
              title: $( "title", this ).text(),
              content: $("content",this).text(),
              url: $( "url" , this).text()
            };
          }).get();
          var $input = document.getElementById(search_id);
          var $resultContent = document.getElementById(content_id);
          $input.addEventListener('input', function(){
            var matchcounts = 0;
            var str='<ul class=\"search-result-list\">';
            var keywords = this.value.trim().toLowerCase().split(/[\s\-]+/);
            $resultContent.innerHTML = "";
            if (this.value.trim().length > 1) {
              // perform local searching
              datas.forEach(function(data) {
                var isMatch = true;
                var content_index = [];
                var data_title = data.title.trim().toLowerCase();
                var data_content = data.content.trim().replace(/<[^>]+>/g,"").toLowerCase();
                var data_url = data.url;
                var index_title = -1;
                var index_content = -1;
                var first_occur = -1;
                // only match artiles with not empty titles and contents
                if(data_title != '' && data_content != '') {
                  keywords.forEach(function(keyword, i) {
                    index_title = data_title.indexOf(keyword);
                    index_content = data_content.indexOf(keyword);
                    if( index_title < 0 && index_content < 0 ){
                      isMatch = false;
                    } else {
                      if (index_content < 0) {
                        index_content = 0;
                      }
                      if (i == 0) {
                        first_occur = index_content;
                      }
                    }
                  });
                }
                // show search results
                if (isMatch) {
                  matchcounts += 1;
                  str += "<li><a href='"+ data_url +"' class='search-result-title'>"+ data_title +"</a>";
                  var content = data.content.trim().replace(/<[^>]+>/g,"");
                  if (first_occur >= 0) {
                    // cut out 100 characters
                    var start = first_occur - 20;
                    var end = first_occur + 80;
                    if(start < 0){
                      start = 0;
                    }
                    if(start == 0){
                      end = 50;
                    }
                    if(end > content.length){
                      end = content.length;
                    }
                    var match_content = content.substring(start, end);
                    // highlight all keywords
                    keywords.forEach(function(keyword){
                      var regS = new RegExp(keyword, "gi");
                      match_content = match_content.replace(regS, "<b class=\"search-keyword\">"+keyword+"</b>");
                    });

                    str += "<p class=\"search-result\">" + match_content +"...</p>"
                  }
                  str += "</li>";
                }
              })};
            str += "</ul>";
            if (matchcounts == 0) { str = '<div id="no-result"><i class="fa fa-frown-o fa-5x" /></div>' }
            if (keywords == "") { str = '<div id="no-result"><i class="fa fa-search fa-5x" /></div>' }
            $resultContent.innerHTML = str;
          });
          proceedsearch();
        }
      });}

    // handle and trigger popup window;
    $('.popup-trigger').mousedown(function(e) {
      e.stopPropagation();
      if (isfetched == false) {
        searchFunc(path, 'local-search-input', 'local-search-result');
      } else {
        proceedsearch();
      };

    });

    $('.popup-btn-close').click(function(e){
      $('.popup').hide();
      $(".popoverlay").remove();
      $('body').css('overflow', '');
    });
    $('.popup').click(function(e){
      e.stopPropagation();
    });
  });
</script>
```
> Next中可以新建一个js文件，`myalgolia.js`存放上述代码，然后存入主题的`source/js/src`中，然后修改主题的`layout/_layout.swig`,添加如下内容：
```
{% if theme.algolia %}
  {% include '_scripts/algolia.swig' %}
{% endif %}
```
>然后在`layout/_scripts`中新建`algolia.swig`，内容如下：
```
{%
  set js_algolia = [
    'src/myalgolia.js'
  ]
%}

{% for common in js_algolia %}
  <script type="text/javascript" src="{{ url_for(theme.js) }}/{{ common }}?v={{ theme.version }}"></script>
{% endfor %}
  <script src="http://cdn.bootcss.com/instantsearch.js/1.5.1/instantsearch.js"></script>

```
6、确保要搜索页包含如下CSS代码（可以单独建立一个.styl文件，然后在整体css的styl文件中加入，注意确保生成正确，必要时可以执行hexo clean）
```css
ul.search-result-list {
  padding-left: 0px;
  margin: 0px 5px 0px 8px;
}
p.search-result {
  border-bottom: 1px dashed #ccc;
  padding: 5px 0;
}
a.search-result-title {
  font-weight: bold;
}
a.search-result {
  border-bottom: transparent;
  display: block;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.search-keyword {
  border-bottom: 1px dashed #4088b8;
  font-weight: bold;
}
#local-search-result {
  height: 90%;
  overflow: auto;
}
.popup {
  display: none;
  position: fixed;
  top: 10%;
  left: 50%;
  width: 700px;
  height: 80%;
  margin-left: -350px;
  padding: 3px 0 0 10px;
  background: #fff;
  color: #333;
  z-index: 9999;
  border-radius: 5px;
}
@media (max-width: 767px) {
  .popup {
    padding: 3px;
    top: 0;
    left: 0;
    margin: 0;
    width: 100%;
    height: 100%;
    border-radius: 0px;
  }
}
.popoverlay {
  position: fixed;
  width: 100%;
  height: 100%;
  top: 0px;
  left: 0px;
  z-index: 2080;
  background-color: rgba(0,0,0,0.3);
}
#local-search-input {
  margin-bottom: 10px;
  width: 50%;
}
.popup-btn-close {
  position: absolute;
  top: 6px;
  right: 14px;
  color: #4ebd79;
  font-size: 14px;
  font-weight: bold;
  text-transform: uppercase;
  cursor: pointer;
}
#no-result {
  position: absolute;
  left: 44%;
  top: 42%;
  color: #ccc;
}
.busuanzi-count:before {
  content: " ";
  float: left;
  width: 260px;
  min-height: 25px;
}
@media (min-width: 768px) and (max-width: 991px) {
  .busuanzi-count {
    width: auto;
  }
  .busuanzi-count:before {
    display: none;
  }
}
@media (max-width: 767px) {
  .busuanzi-count {
    width: auto;
  }
  .busuanzi-count:before {
    display: none;
  }
}
.site-uv,
.site-pv,
.page-pv {
  display: inline-block;
}
.site-uv .busuanzi-value,
.site-pv .busuanzi-value,
.page-pv .busuanzi-value {
  margin: 0 5px;
}
.site-uv {
  margin-right: 10px;
}
.site-uv::after {
  content: "|";
  padding-left: 10px;
}
.algolia-popup {
  overflow: hidden;
  padding: 0;
}
.algolia-popup .popup-btn-close {
  padding-left: 15px;
  border-left: 1px solid #eee;
  top: 10px;
}
.algolia-popup .popup-btn-close .fa {
  color: #999;
  font-size: 18px;
}
.algolia-popup .popup-btn-close:hover .fa {
  color: #222;
}
.algolia-search {
  padding: 10px 15px 5px;
  max-height: 50px;
  border-bottom: 1px solid #ccc;
  background: #f5f5f5;
  border-top-left-radius: 5px;
  border-top-right-radius: 5px;
}
.algolia-search-input-icon {
  display: inline-block;
  width: 20px;
}
.algolia-search-input-icon .fa {
  font-size: 18px;
}
.algolia-search-input {
  display: inline-block;
  width: calc(90% - 20px);
}
.algolia-search-input input {
  padding: 5px 0;
  width: 100%;
  outline: none;
  border: none;
  background: transparent;
}
.algolia-powered {
  float: right;
}
.algolia-powered img {
  display: inline-block;
  height: 18px;
  vertical-align: middle;
}
.algolia-results {
  position: relative;
  overflow: auto;
  padding: 10px 30px;
  height: calc(100% - 50px);
}
.algolia-results hr {
  margin: 10px 0;
}
.algolia-results .highlight {
  font-style: normal;
  margin: 0;
  padding: 0 2px;
  font-size: inherit;
  color: #f00;
}
.algolia-hits {
  margin-top: 20px;
}
.algolia-hit-item {
  margin: 15px 0;
}
.algolia-hit-item-link {
  display: block;
  border-bottom: 1px dashed #ccc;
  transition-duration: 0.2s;
  transition-timing-function: ease-in-out;
  transition-delay: 0s;
}
.algolia-pagination .pagination {
  margin-top: 40px;
  border-top: none;
  padding: 0;
}
.algolia-pagination .pagination-item {
  display: inline-block;
}
.algolia-pagination .page-number {
  border-top: none;
}
.algolia-pagination .page-number:hover {
  border-bottom: 1px solid #222;
}
.algolia-pagination .disabled-item {
  visibility: hidden;
}
```
7、将如下图片放入主题的`source/images`下
{% asset_img algolia_logo.svg %}

## 大功告成~，可以参考本站搜索功能。





>写作时参考[《Hexo集成Algolia搜索插件》](http://kuwoku.com/2016/05/30/Hexo%E9%9B%86%E6%88%90Algolia%E6%90%9C%E7%B4%A2%E6%8F%92%E4%BB%B6/)
