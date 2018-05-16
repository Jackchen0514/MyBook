# Git学习

### 基础使用
```
git add .   //提交到暂存区

git commit -m "提交记录" //提交commit记录

git push origin HEAD:refs/for/master  //推送到服务器

git reset //撤销暂存区的提交

git checkout . //还原本地修改

git reset --hard commit-id //还原到某个commit提交

git commit --amend //补提交同一笔commit 

git log //查看commit记录

```

### 仓库迁移
仓库迁移不丢失log的方法，使用git push - - mirror

- 从原地址克隆一份裸版本库
  github
  ```
  git clone --bare https://github.com/username/project_name.git
  ```
  本地
  ```
  git clone --bare /home/xxx/project_name.git
  ```
- 在服务器上创建一个新的项目

- 以镜像推送的方式上传代码到服务器
  ```
  cd project_name.git
  git push --mirror 用户名@xxx.xxx.ip:review_site/git/project_name.git
  ```

### 提交status为draft
```
git push origin HEAD:refs/drafts/远程分支
```
如果可以公开review的时候，可以在web界面上点击publish按钮或者直接push到/refs/for/远程分支

### 查看所有操作记录
```
git reflog
```

### 合并多个commit
```
git rebase -i //合并多个commit为一个完整的commit
```

出现下面这个界面

```
pick 3c6d5bc adds xinsi
pick 3267a88 add Android.mk # xinsi
pick 50cb8e2 add README.md # xinsi

# Rebase 71adc47..50cb8e2 onto 71adc47 (3 commands)
#
# Commands:
# p, pick = use commit
# r, reword = use commit, but edit the commit message
# e, edit = use commit, but stop for amending
# s, squash = use commit, but meld into previous commit
# f, fixup = like "squash", but discard this commit's log message
# x, exec = run command (the rest of the line) using shell
# d, drop = remove commit
#
# These lines can be re-ordered; they are executed from top to bottom.
#
# If you remove a line here THAT COMMIT WILL BE LOST.
#
# However, if you remove everything, the rebase will be aborted.
#
# Note that empty commits are commented out
```
改为：
```
pick 3c6d5bc adds xinsi
s 3267a88 add Android.mk # xinsi
s 50cb8e2 add README.md # xinsi
```
保存，然后显示这个界面：
```
# This is a combination of 3 commits.
# This is the 1st commit message:
adds xinsi

Change-Id: I3f0cf4468ae0f13356ca672db27389069c0883ec

# This is the commit message #2:

add Android.mk # xinsi

Change-Id: I4ae4b9192f2a290aa8f58a909cce259cb5200a98

# This is the commit message #3:

add README.md # xinsi

Change-Id: If119c143515e252ed7a31f85e2d2688adc7050a9

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# Date:      Sat Mar 3 18:30:26 2018 +0800
#

```
修改为：
```
# This is a combination of 3 commits.
merge three commit
...

```
git log 查看：
```
commit 3344861d548b8e874e405e7b501ee64d2eb17666
Author: xinsi <chenxinsi2612@163.com>
Date:   Sat Mar 3 18:30:26 2018 +0800

    merge three commit
    
    Change-Id: I88325a453294df3f4ce11685f892fe50379aa26a

commit 940ae1a8b4ee0e57fbca477cc7ad67ab3d401cd4
Author: chenxinsi <chenxinsi@droi.com>
Date:   Sat Mar 3 18:38:11 2018 +0800

    remove all change
    
...

```

# 参考
官方网站：https://git-scm.com/book/zh/v2
