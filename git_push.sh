#!/bin/bash

git add --all

echo "请输入提交记录: "
read record
git commit -m "${record}"

echo "commit successful "

