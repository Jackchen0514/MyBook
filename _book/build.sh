#!/bin/bash

echo "开始build gitbook"

gitbook build

echo "build 完成"

cp -r _book/* ../book/

echo "book 复制成功"

echo "开始代码上传"

git add .

git commit -m "test"

git push

echo "上传结束"
