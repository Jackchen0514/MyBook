#!/bin/bash

git add --all

echo "请输入提交记录: "
read record
git commit -m "${record}"

git push

echo "MyBook上传成功！"
cd "../book"

echo $(pwd)

git add --all

git commit -m "${record}"

git push

echo "book上传成功！"
