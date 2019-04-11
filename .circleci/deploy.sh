#!/usr/bin/env bash

# エラー時、実行を止める
set -e

DEPLOY_DIR=deploy

ls
ls content/post

hugo version
hugo

# gitの諸々の設定
git config --global push.default simple
git config --global user.email "sobaya007@gmail.com"
git config --global user.name "sobaya"

echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config

git clone -q "git@github.com:Sobaya007/Sobaya007.github.io.git" $DEPLOY_DIR

# rsyncでhugoで生成したHTMLをコピー
cd $DEPLOY_DIR
rsync -arv --delete ../public/* .

git add -f .
git commit -m "Deploy #$CIRCLE_BUILD_NUM from CircleCI [ci skip]"
git push -f
