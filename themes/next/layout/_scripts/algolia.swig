{%
  set js_algolia = [
    'src/hao-algolia.js'
  ]
%}

{% for common in js_algolia %}
  <script type="text/javascript" src="{{ url_for(theme.js) }}/{{ common }}?v={{ theme.version }}"></script>
{% endfor %}
  <script src="http://cdn.bootcss.com/instantsearch.js/1.5.1/instantsearch.js"></script>
