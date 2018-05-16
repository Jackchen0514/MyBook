# GitBook基本使用

## GitBook初始化
```
gitbook --version 
```
执行 gitbook --version 错误：Error: Cannot find module 'config-chain'

cannot find module 模块, 安装该模块即可
```
npm install -g config-chain
```
## 创建项目
```
mkdir book
cd book
gitbook init
```
创建好的项目目录包含一下文件
```
ovirt-branding.md  README.md  SUMMARY.md
```

1 README.md，简单的电子书介绍。

```
# 简介

这是使用 GitBook 制作的电子书。
```
2 SUMMARY.md，电子书的导航目录文件。
```
# Summary

* [简介](README.md)
* [第一章](section1/README.md)
* [第二章](section2/README.md)
```
3 子章节，使用 Tab 缩进实现（最多支持三级标题）。
```
# Summary 
* [第一章](section1/README.md) 
    * [第一节](section1/example1.md) 
    * [第二节](section1/example2.md) 
* [第二章](section2/README.md) 
    * [第一节](section2/example1.md)
```
4 Glossary.md，电子书内容中需要解释的词汇可在此文件中定义。词汇表会被放在电子书末尾。

5 book.json，电子书的配置文件。
```
{
    "title": "我的第一本電子書",
    "description": "用 GitBook 制作的第一本電子書！",
    "isbn": "978-3-16-148410-0",
    "language": "zh-tw",
    "direction": "ltr"
}
```


