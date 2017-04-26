---
layout: default
title: Unsorted thoughts
css: |
  #posts{padding:0}.postEntry{padding:.5em;margin-bottom:-1px;border:1px solid #ddd}.postEntry .date,.postEntry .subtitle{margin:0}.postEntry:nth-child(2n+1){background-color:#eee}.postEntry .title{margin:0;font-size:200%}
---

# POSTS

I don't really write anything here, but here's an archive of some of the things I've written in the past.

<ul id="posts">
{% for post in site.posts %}<div class="postEntry">
	<a href="{{ post.url }}">
		<p class="date">{{ post.date | date: "%d %b %Y" }}</p>
		<p class="title">{{ post.title }}</p>
		<p class="subtitle">{{ post.subtitle }}</p>
	</a>
</div>
{% endfor %}
</ul>