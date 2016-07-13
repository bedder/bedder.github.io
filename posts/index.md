---
layout: default
title: Unsorted thoughts
---

(Very) occassionally I like to attempt to post about some coherent thoughts. Here are my latest attempts

As of 07/2016 there are more posts planned, finishing off post drafts spanning almost half a year. They should emerge eventually!

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