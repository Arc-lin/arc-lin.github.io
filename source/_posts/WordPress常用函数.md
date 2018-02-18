title: WordPress常用函数
author: Arclin
tags:
  - PHP
  - WordPress
categories:
  - PHP
date: 2017-03-02 00:00:00
---
wordpress自定义主题的时候需要用到的函数

<!-- more -->

[参考文档](https://codex.wordpress.org/zh-cn:模板标签)


|函数名|作用|
|----|----|
|bloginfo()|可以拿到博客的信息,name,description,version,特别注意bloginfo('stylesheet_url');会直接找到根目录下的style.css文件,这个页面的样式表|
|wp_head()|	一般放在header.php,会有很多东西引入进去|
|wp_title()|网站标题|
|get_header()|检查同目录下是否有header.php,有的话就会调用这个文件作为页面头部|
|get_sidebar()|检查sidebar.php,调用作为侧边栏|
|get_footer()|检查footer.php,调用作为底部栏|
|have_posts()|判断是否有日志|
|the_post()|调用一篇具体的日志,和主循环配合使用|
|the_permalink()|每篇日志地址|
|the_title()|日志标题|
|the_content()|日志内容|
|_e()|框架里面有语言文件,这里是调用语言文件内对应文字,使用类似这样子_e("Archives"),中文页面下显示归档,英文页面下显示Archives|
|the_category()|分类,这个函数里面有一个参数,可以表示用什么符号去分割多个分类名,例如the_category(',')|
|the_author()|作者名|
|the_excerpt()|日志摘要|
|comments_popup_link(‘No Comments »’, ‘1 Comment »’, ‘% Comments »’);|当弹出留言的功能激活的话，comments_popup_link() 调用一个弹出的留言窗口，如果没有激活，comments_popup_link() 则只是简单的显示留言列表。No Comments » 是在没有留言的时候显示的。1 Comment » 是用于当刚好只有1条留言时候。% Comments &187; 是用于当有多于一条留言的时候。比如：8 Comments »。百分号 % 用来显示数字。» 是用来显示一个双层箭头 »。|
|edit_post_link(‘Edit’, ‘&124’, ”);	|这个只有当我们以管理员或者作者身份登录的的时候才可见。|
|edit_post_link()|只是简单显示一个可以用来编辑当前日志的编辑链接，这样就可以让我们不必去管理界面搜寻该日志就能直接编辑。|
|edit_post_link() |有三个参数。第一个是用来确定哪个词你将用在编辑链接的链接标题。如果你使用 Edit post，那么将显示 Edit post 而不是 Edit。第二个参数是用来显示在链接前面的字符，在这里是竖线，代码就是&124;。第三个参数是用于显示在编辑链接后面的字符，在这里没有使用。登录 WordPress 之后，再返回到首页就可以看到“Edit”的链接和一条竖线。|
|posts_nav_link(‘中间页’, ‘<<上一页’, ‘下一页>>’)|调用后一页和前一页的链接,3个参数，分别给链接的中间，前面和后面的设置字符|
|previous_post_link(‘%link’)|上一篇日志|
|next_post_link(‘%link’)|下一篇日志|
|wp_list_pages()|展示页面列表,如果参数里面填`title_li=<h2>Pages</h2>&depth=3`,可以设置title的样式,depth指的是页面的展示深度|
|wp_list_cats()|展示分类列表,参数可填`sort_column=name&optioncount=1&hierarchical=0`,分别是设置排序根据,是否显示文章个数,以分层缩进的方式显示分类列表|
|get_links_list();|友情链接列表,在后台装插件之后就可以用了|
|wp_get_archives()|意思跟上面的差不多,也是有参数,获取的是文章归档列表,参数填type=daily的话就是按日期分,monthly按月分,yearly按年分,format=link以链接形式显示|
|wp_loginout()|退出登录链接|
|wp_register()|注册链接|
|wp_meta()|显示管理员的相关控制信息|
|get_calendar()|显示一个日历|
|include(TEMPLATEPATH . ‘/searchform.php’)|导入某个自定义文件,像左边就是/searchform.php文件|

### 判断是否有日志并循环输出日志
```
<?php if(have_posts()) : ?> <!--检查是否有日志-->
	<?php while(have_posts()) : the_post(); ?> <!--循环输出日志-->
			<div class="post" id="post-<?php the_ID(); ?>">
				<h2><a href="<?php the_permalink(); ?>" title="<?php the_title(); ?>"><?php the_title(); ?></a></h2><!--日志标题-->
				<div class='entry'>
				<?php the_content(); ?>
			</div>
			<p class="postmetadata">
			<?php _e('Filed under&#58;'); ?> <?php the_category(', ') ?> <?php _e('by'); ?> <?php  the_author(); ?><br />
			<?php comments_popup_link('No Comments &#187;', '1 Comment &#187;', '% Comments &#187;'); ?> <?php edit_post_link('Edit', ' &#124; ', ''); ?>
			</p>
			</div>
	<?php endwhile; ?>
	<div class="navigation">
			<?php posts_nav_link('index', '<<上一页', '下一页>>'); ?>
	</div>
	<?php else : ?> <!--如果没有日志-->
	<div class = "post">
		<h2><?php _e("Not Found"); ?></h2>
	</div>
<?php endif; ?>
```

### 搜索框

```
<form method="get" id="searchform" action="<?php bloginfo('home'); ?>/">

<div>

	<input type="text" value="<?php echo wp_specialchars($s, 1); ?>" name="s" id="s" size="15" /><br />

	<input type="submit" id="searchsubmit" value="Search" />

</div>

</form>
```