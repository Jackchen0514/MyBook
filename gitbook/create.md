# GitBook搭建

## CentOS + GitBook

### 安装Node.js
```bash
wget https://nodejs.org/dist/v5.4.1/node-v5.4.1.tar.gz
tar zxvf node-v5.4.1.tar.gz
cd node-v5.4.1
./configure
sudo make
sudo make install
```

### 查看 node.js 是否安装成功
```bash
node -v
```

执行 ./configure 错误：WARNING: failed to autodetect C++ compiler version (CXX=g++)
需要安装gcc
```bash
 sudo yum install gcc-c++
```

### 安装GitBook
```bash
npm install gitbook-cli -g
```

## Ubuntu + GitBook搭建

### 安装Node.js
```bash
wget https://nodejs.org/dist/v5.4.1/node-v5.4.1.tar.gz
tar zxvf node-v5.4.1.tar.gz
cd node-v5.4.1
./configure
sudo make
sudo make install
```

### 查看 node.js 是否安装成功
```bash
node -v
```

Install with NPM
```bash
$ npm install gitbook-cli -g
```

## 安装插件

左侧章节目录可折叠
插件地址： https://plugins.gitbook.com/plugin/toggle-chapters

安装：
```bash
$ npm install gitbook-plugin-toggle-chapters
```

add this to book.json :
```json
{
   "plugins": ["toggle-chapters"]
}
```

为文字加上底色
插件地址： https://plugins.gitbook.com/plugin/emphasize

add this to book.json :
```json
"plugins": [
    "emphasize"
]
```

使用如下：

```python
This text is {% em %}highlighted !{% endem %}

This text is {% em %}highlighted with **markdown**!{% endem %}

This text is {% em type="green" %}highlighted in green!{% endem %}

This text is {% em type="red" %}highlighted in red!{% endem %}

This text is {% em color="#ff0000" %}highlighted with a custom color!{% endem %}
```

支持ace

插件地址： https://plugins.gitbook.com/plugin/ace

add this to book.json :
```json
"plugins": [
    "ace"
]
```

支持prism

插件地址: https://plugins.gitbook.com/plugin/prism

```bash
npm install gitbook-plugin-prism
```

add this to book.json :
```json
"plugins": [
  "ace",
  "toggle-chapters",
  "prism"
],

"pluginsConfig": {
  "prism": {
    "css": [
      "prismjs/themes/prism-solarizedlight.css"
    ]
  }
}
```

支持语法高亮highlight

```bash
npm install gitbook-plugin-highlight
```





