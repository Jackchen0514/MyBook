#!/bin/bash

git add --all
echo "***********请输入提交记录: ***************"
read record
git commit -m "${record}"
git push

echo "*************MyBook上传成功！**************"
echo "                                           "

cd "../book"
git add --all
git commit -m "${record}"
git push

echo "*************book上传成功！****************"
echo "                                           "
