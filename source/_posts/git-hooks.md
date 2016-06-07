---
title: 利用Git Hooks自动化开发和部署
categories: 服务器上那点事儿
date: 2016-05-18 15:28:25
tags:
- Git
- hook
---

>翻译自[How To Use Git Hooks To Automate Development and Deployment Tasks
](https://www.digitalocean.com/community/tutorials/how-to-use-git-hooks-to-automate-development-and-deployment-tasks)
>

## 介绍
版本控制在现代软件开发中变成了一个核心的要求。它使得项目可以安全的记录变更，恢复，完整性检查，多人协作等等。`git`在这些年里被广泛的接纳，得益于其分布式的架构和它在向各方传递变更的速度。

虽然`git`的工具套件提供了很多现成的特性，其中最实用的就是它的灵活性。通过对钩子系统的使用，git允许开发者或者管理员通过让git根据不同的events和actions的触发来运行自己的脚本，从而对git的功能进行扩展。

这篇文章中，我会介绍git钩子的原理和如何实现自动化任务。我们将会使用Ubuntu 14.04，不过所有系统运行git都大同小异。

<!-- more -->

## 准备工作
开始之前，你需要先在你的运行环境中安装好git。你可以参考这篇教程[Ubuntu14.04安装git](https://www.digitalocean.com/community/tutorials/how-to-install-git-on-ubuntu-14-04)。

你应该简要了解git的使用。如果你需要入门，可以看看这个教程[Git介绍：安装，使用，分支](https://www.digitalocean.com/community/tutorial_series/introduction-to-git-installation-usage-and-branches)

如果上边的都没有问题，继续往下看。

## Git Hooks的基本原理
Git Hooks是一个相当简单的概念，它为了满足特定的需求。当开发者开发一个协作的项目，维护代码风格，或者部署项目（这些都是使用git常见的情况）时，经常有有些重复性任务在每次完成一个动作时都要执行。

Git钩子是基于事件的。当你运行了特定的git命令，git会检查git仓库中`hooks`路径下有没有相关脚本要执行。

有的脚本在git指令之前执行，这可以用来确保代码的完整（进行一些完整性检查）或者提前部署一下环境。那些在git事件之后执行的脚本，一般就是用来部署代码，重新建立权限（一些git不能很好记录的事情）等等。

使用git的这些功能，就可以强制实施策略，确保一致性，和控制你的环境，甚至处理部署任务。

Scott Chacon写的[Pro Git](http://git-scm.com/book)这本书试图将钩子归类，他是这样写的：

* 客户端钩子：在提交者计算机上被调用和执行的钩子。这些可以进一步分为一些小的类别：
	* 提交工作流钩子：提交钩子是用来检测那些需要在提交的前后需要执行的动作。他们可以用来运行完整性检查,预填充提交信息和验证消息详情。你也可以基于提交来推送通知。

	* 邮件工作流的钩子：这一类的钩子包含了当你使用邮件补丁时触发的动作。类似Linux内核提交和通过邮件方法回看补丁。这些都和提交钩子是一样的，但是邮件钩子可以被负责申请提交代码的管理员所使用。

	* 其它：其它客户端钩子包括那些在merge,check out,rebase,rewrite,clean时执行的钩子。
* 服务端钩子：这些钩子在那些用来接收推送代码的服务器上执行。通常，这就是项目的主要git仓库。同样，Chacon也把这些细分成一下几类。
	* `pre-receive`和`post-receive`: 这两个在服务器收到push操作时执行，比如检查项目一致性和在push之后立即部署项目。
	* `update`:这个和`pre-receive`很像，但是它是一个分支接着一个分支的运作的基础上,在每个分支被更新之前执行。

这些分类能使我们对可以建立钩子的事件有了一个大体的认识。但是为了确切了解他们是怎么运作的，最好还是亲身试验来找出你想要实现的方案。

某些钩子还需要参数。这意味着，当git为某个钩子调用脚本，它会传入脚本会用到的一些相关的数据，以便完成相应的任务。所有的hooks如下表所示。

Hook 名称   |     触发命令      |    描述     |     参数（数量和描述）  
--------- | -------------| -------------| -------------
applypatch-msg|`git am`|可以编辑提交信息，常用于验证或者标准化补丁信息。非零状态会放弃这次提交|1个参数，包含被建议提交信息的临时文件名
pre-applypatch | `git am`| 在补丁被运用之后，但是提交之前运行。非零退出，修改仍为未提交状态。可以用来在正式提交之前检查状态树 | 无
post-applypatch|`git am`|这个钩子在补丁应用和提交之后运行。因此它无法阻止打补丁的过程，主要用于创建通知。|无
pre-commit|`git commit`|这个钩子在获取提交信息之前运行。返回非零值时放弃此次提交，它是用来检查提交本身(而不是提交信息）|无
prepare-commit-msg|`git commit`|在接受到默认提交信息之后，在提交信息编辑器显示之前运行。返回非零值退出，放弃这次提交。它可以用来以一种不可被取消的方式编辑信息。|(1到3个参数)文件名连同提交信息，原始提交信息（`message`,`template`,`merge`,`squash`,`commit`),和提交的SHA-1校验和(当对已有信息进行操作时)。
commit-msg|`git commit`|可以被用来在信息被编辑之后调整信息，以便确保它符合标准，或者依照标准驳回此信息。如果该hook脚本以非零退出，`Git`放弃提交。|1个参数，存放提交信息的文件。
post-commit| `git commit`|在整个提交过程完成后运行。因此，它不能中断提交。这个hook主要用来允许通知。|无
pre-rebase| `git rebase`| 当rebase一个分支的时候执行。主要用于在不可取的时候中止rebase。|(1到2个参数)上游分支的节点，需要被rebase的分支(在rebase分支为当前时不设置)
post-checkout|`git checkout`和`git clone`|在更新工作树之后执行checkout或者clone之后运行。它主要用于验证状态，展示区别和在必要时配置环境。|(3个参数)之前`HEAD`的引用，新`HEAD`的引用，是否为一个检出的分支的标记。（1个参数）或者一个检出的文件（0）
post-merge| `git merge`或`git pull`|在merge之后执行。因此，它不能中止merge操作，它可以用来存储或者申请权限或者其他不属于git的数据。| (1个参数)merge是否为squash的标记。
pre-push| `git push`| 在push到远程服务器之前执行。再加上参数，额外的信息，以`<本地ref> <本地sha1> <远程ref> <远程sha1>`的形式。解析输入可以获得可以用来检验的额外信息。比如说，如果`local sha1`是40个零的长度，push是一个删除操作，如果`remote sha1`是40个零，那么它是一个新的分支。这个特性可以将已经提交的refs和当前状况做很多比较。非零退出，将会中止这次提交。|(2个参数)远程地址名称，远程地址
pre-receive| 远程仓库`git-receive-pack`|在更新提交的refs之前，在远程仓库上运行。非零的状态中止。虽然不接受参数，它为每一个ref传递一个标准输入的字符串，以`<旧的值> <新的值> <ref的名称>`的形式。|无
update| 远程仓库`git-receive-pack`| 在远程仓库上，每一个ref被提交运行一次，而不是每次提交都运行。非零的状态会中止。这可以用来确保所有的提交都只用fast forward模式|(三个参数)被更新的ref名称，旧的对象名，新的对象名。
post-receive|远程仓库`git-receive-pack`|在所有的ref更新后运行。不需要参数，但是通过标准输入接受信息，格式为`<旧的值> <新的值> <ref的名称>`。因为在更新后运行，所以不能被中止。|无
post-update|远程仓库`git-receive-pack`|在所有的refs都已经被push之后只运行一次。它在这方面和post-receive很相似，但是不接受之前和之后的值。它主要用来根据被推送的refs实现通知。| 每一个被推送的包含它名字的refs。
pre-auto-gc|`git gc --auto`|在`clean`仓库之前自动做一些检查|无
post-rewrite|`git commit --amend`,`git-rebase`|当git命令重写已经提交的数据时执行。除了接受的参数，它还以`<旧sha1><新sha1>`的格式接受标准输入的字符串。|(1个参数)触发这个钩子的命令名称(amend或者rebase)

现在你已经有了大体的概念，我们可以在几个场景下试验一下。

## 建立一个仓库
一开始，我们需要先建立一个新的空仓库，在我们的主目录下。我们可以给它命名为`proj`。

```Bash
mkdir ~/proj
cd ~/proj
git init
```
```Bash
Initialized empty Git repository in /home/demo/proj/.git/
```
现在，我们在这个在git控制下的空目录内。在我们开始之前，我们先看看目录中的隐藏文件，它们在`.git`目录下：
```Bash
cd .git
ls -F
```
```Bash
branches/  config  description  HEAD  hooks/  info/  objects/  refs/
```
我们可以看到一些文件和目录。我们感兴趣的就是这个`hooks`目录：
```Bash
cd hooks
ls -l
```
```Bash
total 40
-rwxrwxr-x 1 demo demo  452 Aug  8 16:50 applypatch-msg.sample
-rwxrwxr-x 1 demo demo  896 Aug  8 16:50 commit-msg.sample
-rwxrwxr-x 1 demo demo  189 Aug  8 16:50 post-update.sample
-rwxrwxr-x 1 demo demo  398 Aug  8 16:50 pre-applypatch.sample
-rwxrwxr-x 1 demo demo 1642 Aug  8 16:50 pre-commit.sample
-rwxrwxr-x 1 demo demo 1239 Aug  8 16:50 prepare-commit-msg.sample
-rwxrwxr-x 1 demo demo 1352 Aug  8 16:50 pre-push.sample
-rwxrwxr-x 1 demo demo 4898 Aug  8 16:50 pre-rebase.sample
-rwxrwxr-x 1 demo demo 3611 Aug  8 16:50 update.sample
```
在这儿，我们可以看到。首先，每一个文件都标记成了可执行。因为这些脚本都是按照名称执行的，他们必须是可执行的，而且它们的第一行必须是[Shebang(`#!`)](http://en.wikipedia.org/wiki/Shebang_(Unix)#Magic_number)指向正确的脚本解释器。比较常见的是bash，perl，python等。

你还会注意到的是，所有文件都是以`.sample`结尾的。这是因为git只是简单的看文件名来查找要执行的hook文件。文件名和git想要查找的出现偏差，这样可以达到禁用的目的。想启用任意一个脚本，只需要去掉结尾的`.sample`后缀。

让我们退回到我们的工作目录。
```Bash
cd ../..
```
## 第一个例子：用一个post-commit Hook来部署一个web服务。
我们第一个例子，使用`post-commit`hook来展示，如何在每一次提交之后在本地web服务器中部署代码。这不是在生产环境中使用的hook，但是可以让你验证一些重要的，文档里没怎么体现的东西，他们是你在使用hooks的时候应该知道的。

首先，我们安装一个Apache web server。

```Bash
sudo apt-get update
sudo apt-get install apache2
```
为了让我们的脚本可以修改web根目录`/var/www/html`(这是Ubuntu14.04的文档根目录。可以按需修改)，我们需要有写权限。我们给我们的普通用户这个目录的所有权。输入以下命令：
```Bash
sudo chown -R `whoami`:`id -gn` /var/www/html
```
现在，在我们的项目根目录下，创建`index.html`文件
```Bash
cd ~/proj
nano index.html
```
在文件中，我们添加一小段HTML主要用做论证我们的观点。不用太复杂：
```Html
<h1>Here is a title!</h1>
<p>Please deploy me!</p>
```
添加这个文件到git：
```Bash
git add .
```
在提交之前，我们将要为这个仓库建立我们的`post-commit`钩子。在`.git/hooks`中创建文件
```Bash
vim .git/hooks/post-commit
```
在我们在文件中添加脚本之前，我们需要知道git在运行钩子时如何建立环境。

## 关于git钩子环境变量的一些题外话
在我们开始写脚本之前，我们需要知道git钩子运行时建立的环境变量。为了让我们的脚本工作，我们最终需要解除一个git调用`post-commit`钩子时设置的环境变量。

如果你希望写一个运行稳定的git钩子，你需要先理解一个很重要的知识点。git根据你调用哪个钩子来建立不同的环境变量。这意味着git获取信息的环境会根据钩子的不同而不同。

第一个状况是，会使得你的脚本运行环境不可预测，如果你不知道哪个变量被自动设置了。第二个状况就是那个被设置的变量在git自身的文档里几乎没有体现。

幸运的是，Mark Longair开发了当运行钩子时[检测git设置的每一个变量的方法](http://longair.net/blog/2011/04/09/missing-git-hooks-documentation/)。它涉及到在git钩子脚本中添加下列内容：
```Bash
#!/bin/bash
echo Running $BASH_SOURCE
set | egrep GIT
echo PWD is $PWD
```
他的篇文章是2011年写的，当时git的版本是1.7.1，所以现在已经有了一些变化。我的这篇文章是2014年8月写的，当前git版本是1.9.1。

在此git版本下的测试结果如下（包括工作目录）。测试用的本地工作目录为`/home/demo/test_hooks`和一个裸的远程仓库`/home/demo/origin/test_hooks.git`:

* 钩子：`applypatch-msg`, `pre-applypatch`, `post-applypatch`
	* 环境变量：
	* `GIT_AUTHOR_DATE='Mon, 11 Aug 2014 11:25:16 -0400'`
	* `GIT_AUTHOR_EMAIL=demo@example.com`
	* `GIT_AUTHOR_NAME='Demo User'`
	* `GIT_INTERNAL_GETTEXT_SH_SCHEME=gnu`
	* `GIT_REFLOG_ACTION=am`
	* 工作目录：`/home/demo/test_hooks`

* 钩子：`pre-commit`, `prepare-commit-msg`, `commit-msg`, `post-commit`
	* 环境变量：
	* `GIT_AUTHOR_DATE='@1407774159 -0400'`
	* `GIT_AUTHOR_EMAIL=demo@example.com`
	* `GIT_AUTHOR_NAME='Demo User'`
	* `GIT_DIR=.git`
	* `GIT_EDITOR=:`
	* `GIT_INDEX_FILE=.git/index`
	* `GIT_PREFIX=`
	* 工作目录：`/home/demo/test_hooks`
* 钩子：`pre-rebase`
	* 环境变量：
	* `GIT_INTERNAL_GETTEXT_SH_SCHEME=gnu`
	* `GIT_REFLOG_ACTION=rebase`
	* 工作目录：`/home/demo/test_hooks`
* 钩子：`post-checkout`
	* 环境变量：
	* `GIT_DIR=.git`
	* `GIT_PREFIX=`
	* 工作目录：`/home/demo/test_hooks`
* 钩子：`post-merge`
	* 环境变量：
	* `GITHEAD_4b407c...`
	* `GIT_DIR=.git`
	* `GIT_INTERNAL_GETTEXT_SH_SCHEME=gnu`
	* `GIT_PREFIX=`
	* `GIT_REFLOG_ACTION='pull other master'`
	* 工作目录：`/home/demo/test_hooks`
* 钩子：`pre-push`
	* 环境变量：
	* `GIT_PREFIX=`
	* 工作目录：`/home/demo/test_hooks`
* 钩子：`pre-receive·`, `update`, `post-receive`, `post-update`
	* 环境变量：
	* `GIT_DIR=.`
	* 工作目录：`/home/demo/origin/test_hooks.git`
* 钩子：`pre-auto-gc`
	* (未知，因为这个钩子很难可靠地触发)
* 钩子：`post-rewrite`
	* 环境变量：
	* `GIT_AUTHOR_DATE='@1407773551 -0400'`
	* `GIT_AUTHOR_EMAIL=demo@example.com`
	* `GIT_AUTHOR_NAME='Demo User'`
	* `GIT_DIR=.git`
	* `GIT_PREFIX=`
	* 工作目录：`/home/demo/test_hooks`

这些变量暗示了git如何查看自己的环境。我们将利用上述关于变量的信息来确保我们的脚本正确考虑了它的环境。

## 回到脚本

现在你对所需的环境有了一定概念（看一下为`post-commit`钩子所设置的变量），我们可以开始我们的脚本了。

由于git钩子是标准脚本，我们需要告诉git，我们用什么解释器：
```
 #!/bin/bash
```

在这个之后，我们只要在提交后使用git取出最新版本的仓库，放到web目录下。要完成这件事儿，我们需要把我们的工作目录设置到apache的文件根目录。我们也需要把我们的git目录设置为仓库的地址。

我们想要强制操作来保证每一次都成功，即使当前工作目录中存在冲突。脚本应该这样：
```
 #!/bin/bash
git --work-tree=/var/www/html --git-dir=/home/demo/proj/.git checkout -f
```
这时，我们已经几乎完成了。然而，我们需要更仔细查看每次`post-commit`钩子运行时的环境变量。尤其是`GIT_INDEX_FILE`被设置成`.git/index`。

这个路径与工作目录相关，在我们的例子中是`/var/www/html`。由于git的index文件不存在，脚本会失效，如果我们保留当前的设置。为了避免这种情况，我们可以手动设置这个变量，这将导致git相对于仓库目录去搜索。我们需要在脚本中的`checkout`之前添加一行:
```Bash
 #!/bin/bash
unset GIT_INDEX_FILE
git --work-tree=/var/www/html --git-dir=/home/demo/proj/.git checkout -f
```
这些冲突正是git钩子出的问题经常很难诊断的原因。你必须清楚git是怎么构建它的运行环境的。

当你编辑结束后，保存并退出这个文件。

因为这是一个常规的脚本文件，我们需要让它有可执行权限：
```Bash
chmod +x .git/hooks/post-commit
```
现在，我们最终准备好在我们的git仓库中提交变更。确保你退到了正确的目录，并且提交这些变更：
```Bash
cd ~/proj
git commit -m "here we go..."
```
现在，如果你使用浏览器访问服务器的域名或者IP地址，你讲看到你刚刚创建的这个index.html文件：
```
http://server_domain_or_IP
```
{% asset_img first_deploy.png  %}

正如你所见，我们最近的变更在提交之后被自动的推送到了服务器根目录下。我们可以再做一些改变来证明，钩子在每次提交之后都正确工作了。
```Bash
echo "<p>Here is a change.</p>" >> index.html
git add .
git commit -m "First change"
```
当我们刷新浏览器，我们可以直接看到新的变化：
{% asset_img deploy_changes.png %}

如你所见，这种配置比较方便本地测试，然而，你可能永远不希望在生产环境中这样提交。还是在经过测试后确保没问题了再提交，这样比较安全。

## 利用Git钩子在另外的生产环境中部署

在第二个例子中，我们将要示范一个更新生产服务器更好的方式。我们可以通过使用push-to-deploy模型以便当我们推送到裸仓库时更新我们的web服务器。

我们可以沿用上面的服务器当作开发机。这是我们做改动工作的地方。我们可以在每次提交之后看到改变。

在我们的生产机器上，我们将会配置另一个web服务器，一个裸的仓库用来推送我们的变更，还有一个git钩子在每次接受到推送都会执行。以普通用户身份，用sudo，完成系列步骤。

## 建立生产环境的post-receive钩子
现在生产环境中安装web服务器：
```Bash
sudo apt-get update
sudo apt-get install apache2
```
然后，我们再更改目录拥有者给当前用户：
```Bash
sudo chown -R `whoami`:`id -gn` /var/www/html
```
我们还需要在服务器上安装git：
```Bash
sudo apt-get install git
```
现在我们可以在home目录下创建一个目录，来存放我们的仓库。然后我们进入这个目录来初始化一个裸的仓库。裸仓库不包含工作目录，这对于服务器来说更好，因为我们不在上面直接工作：
```Bash
mkdir ~/proj
cd ~/proj
git init --bare
```
这是一个裸仓库，所以没有工作目录并且所有文件都在`.git`文件夹下，该文件夹通常在根目录下。

我们需要创建另一个git钩子，这一次，我们感兴趣的是post-receive钩子，它是在服务器端接收到`git push`时执行。在编辑器中打开这个文件：
```Bash
nano hooks/post-receive
```
在脚本的开始，我们需要指定我们脚本的类型，然后我们可以写和`post-commit`一样的checkout命令，修改成这台机器使用的目录：
```Bash
 #!/bin/bash
git --work-tree=/var/www/html --git-dir=/home/demo/proj checkout -f
```
由于这是一个裸仓库，`--git-dir`应该指向仓库目录的顶层。其它都和之前一样。

然后，我们需要在脚本里增加一些额外的逻辑。如果我们不小心推送了`test-feature`分支到服务器上，我们不希望它被部署。我们想确保只部署`master`分支。

关于`post-receive`钩子，你在之前的表格里可能已经注意到，git传递旧版本的提交hash，新版本的提交hash还有作为标准输入到脚本被推送的引用。我们可以通过它检查，该引用是否为`master`分支。

首先我们需要读取这个标注输入。每一个被推送的引用，它的三部分信息（旧版本，新版本，引用）被提供给脚本，作为标准输入，之间用空格分开。我们可以用一个`while`循环包住这条`git`命令。
```Bash
 #!/bin/bash
while read oldrev newrev ref
do
    git --work-tree=/var/www/html --git-dir=/home/demo/proj checkout -f
done
```
现在，我们将根据你被提交的内容产生了3个变量。对于master分支的推送，`ref`对象将包含像是`refs/heads/master`的东西。我们可以通过使用`if`检查一下服务器接收到的`ref`是否为这种格式：

```Bash
#!/bin/bash
while read oldrev newrev ref
do
    if [[ $ref =~ .*/master$ ]];
    then
        git --work-tree=/var/www/html --git-dir=/home/demo/proj checkout -f
    fi
done
```
对于服务器端的钩子，git实际上可以将信息传回客户端。任何发送到标准输出的东西都会跳转到客户端。这给了我们机会显式通知用户做了什么样的决策。

我们应该增加一些文字，描述我们检测到的情况，和我们执行的动作。我们应该添加一个`else`代码，在一个非`master`分支被成功接收时通知用户，即使这个动作并不触发部署：
```Bash
 #!/bin/bash
while read oldrev newrev ref
do
    if [[ $ref =~ .*/master$ ]];
    then
        echo "Master ref received.  Deploying master branch to production..."
        git --work-tree=/var/www/html --git-dir=/home/demo/proj checkout -f
    else
        echo "Ref $ref successfully received.  Doing nothing: only the master branch may be deployed on this server."
    fi
done
```

结束之后，保存并关闭这个文件。

切记，我们必须给这个脚本可执行的权限。

```Bash
chmod +x hooks/post-receive
```
现在我们可以在我们本地对这个远程服务器建立访问了。

## 在本地机器上配置远程服务器

回到我们的本地机器（开发机）,进入我们项目的工作目录：
```Bash
cd ~/proj
```
在文件夹内，添加远程服务器，命名为`production`。你需要知道声场服务器的用户名，IP地址或者域名。你还需要知道你裸仓库对于home目录的相对路径。

你输入的命令应该是大体这个样子：
```Bash
git remote add production demo@server_domain_or_IP:proj
```
现在我们推送我们本地分支到生产服务器：
```Bash
git push production master
```
如果你没配置SSH的key，那你可能必须输入生产服务器的用户密码。你会看到类似下面的显示：
```
Counting objects: 8, done.
Delta compression using up to 2 threads.
Compressing objects: 100% (3/3), done.
Writing objects: 100% (4/4), 473 bytes | 0 bytes/s, done.
Total 4 (delta 0), reused 0 (delta 0)
remote: Master ref received.  Deploying master branch...
To demo@107.170.14.32:proj
   009183f..f1b9027  master -> master
```

如你所见，来自我们`post-receive`钩子的文本出现在命令行的输出中。如果我们使用浏览器访问我们生产服务器的域名或者IP地址，我们可以看到我们项目的当前版本：
{% asset_img pushed_prod.png  %}

看起来钩子收到信息时成功将我们的代码推送到生产服务器。

现在，让我们测试我们的新代码。回到开发机上，我们将创建一个新分支并进行一些改变。这样，我们可以确保在我们部署到生产环境之前，一切就绪。

建立一个叫`test_feature`的新分支，然后checkout：
```Bash
git checkout -b test_feature
```

我们现在处于`test_feature`分支中，让我们做一些改变，稍后推送到生产服务器中。我们将提交到这个分支中：
```Bash
echo "<h2>New Feature Here</h2>" >> index.html
git add .
git commit -m "Trying out new feature"
```
这时候，如果你访问开发机的IP地址或者域名，你将看到你的做的修改。
{% asset_img devel_commit.png  %}

这是因为开发机仍在每次提交后部署。这个工作流很棒，它可以让我们在部署生产环境之前测试我们的修改。

我们可以推送我们的`test_feature`分支到远程生产服务器：
```Bash
git push production test_feature
```

在`post-receive`钩子的输出中应该有其它的信息：
```
Counting objects: 5, done.
Delta compression using up to 2 threads.
Compressing objects: 100% (2/2), done.
Writing objects: 100% (3/3), 301 bytes | 0 bytes/s, done.
Total 3 (delta 1), reused 0 (delta 0)
remote: Ref refs/heads/test_feature successfully received.  Doing nothing: only the master branch may be deployed on this server
To demo@107.170.14.32:proj
   83e9dc4..5617b50  test_feature -> test_feature
```
如果我们在浏览器中查看生产服务器，你将看到什么都没有改变。
这就是我们所希望的，因为我们的改变不在master分支中。

现在我们已经在开发机器上测试了我们的修改，我们确定要合并这个修改到master分支上。我们可以checkout到master分支，然后在开发机上merge`test_feature`分支。

```
git checkout master
git merge test_feature
```
现在，你已经将新分支合并到主分支。推送到生产服务器将部署这个修改：
```Bash
git push production master
```
如果我们在浏览器查看生产服务器，我们将看到我们的改变：

{% asset_img new_prod.png  %}

使用这个工作流，我们可以在开发机上直接显示提交的修改。生产机器只在master分支被推送时候被更新。

## 结论
如果你跟着我的步骤做完，你应该已经了解了git钩子有多种方法将我们一部分工作自动化。它们可以帮你部署代码，可以通过拒绝不符合要求的修改和提交，来控制代码质量。

然而，git钩子的效用很难讨论，它实际的实现非常复杂。练习实现多种配置，试验解析参数，标准输入，跟踪git如何构建钩子的环境将会带你慢慢了解如何写有效的钩子脚本。从长远上看，时间的投入通常是值得的，它可以很简单的节省你和你团队在项目工作中很多手动操作的负担。
