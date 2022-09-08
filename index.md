---
title: Online Hosted Instructions
permalink: index.html
layout: home
---

# Database Administration Exercises

These exercises support Microsoft course [DP-300: Administering Microsoft Azure SQL Solutions](https://docs.microsoft.com/training/courses/dp-300t00).

{% assign labs = site.pages | where_exp:"page", "page.url contains '/Instructions/Labs'" %}
| Module | Exercise |
| --- | --- | 
{% for activity in labs  %}| {{ activity.lab.module }} | [{{ activity.lab.title }}{% if activity.lab.type %} - {{ activity.lab.type }}{% endif %}]({{ site.github.url }}{{ activity.url }}) |
{% endfor %}

