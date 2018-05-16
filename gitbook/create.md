# GitBook搭建

## CentOS + GitBook

### 安装Node.js
```
wget https://nodejs.org/dist/v5.4.1/node-v5.4.1.tar.gz
tar zxvf node-v5.4.1.tar.gz
cd node-v5.4.1
./configure
sudo make
sudo make install
```

### 查看 node.js 是否安装成功
```
node -v
```

执行 ./configure 错误：WARNING: failed to autodetect C++ compiler version (CXX=g++)
需要安装gcc
```
 sudo yum install gcc-c++
```

### 安装GitBook
```
npm install gitbook-cli -g
```

## Ubuntu + GitBook搭建

Install with NPM
```
$ npm install gitbook-cli -g
```

