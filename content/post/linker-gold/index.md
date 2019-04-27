---
title: "D言語でgoldを使ってリンクを高速化してみた"
date: 2019-04-27T23:33:31+09:00
thumbnail: "images/dmd.jpeg"
banner: "images/dmd.jpeg"
categories: ["D言語"]
tags: ["D言語", "linker"]
---

# goldとはなんぞや
[gold](https://en.wikipedia.org/wiki/Gold_(linke))とはELFバイナリ用のリンカーで、ldより高速なやつである。binutilsに入っているので、多分インストールしなくてもほぼ勝手に入っている。

# 今回のモチベーション
今回はあんまりD言語は関係ないのですが、D言語でのビルドステップを高速にしたい場面に直面したので「ビルドが遅い→どうせリンクが遅いんじゃね？」という適当な推論によりリンクを速くする術を捜しておりました。

先日[とある密会](https://connpass.com/event/127884/)に参加したところ教えていただいたのでブログに書いておこうとなりました。

ちなみにLLVMと何やら関連の深そうな[LLD](https://lld.llvm.org/)というのもあり、こちらはgoldの2倍速いらしい。リンカ界も日進月歩なんだなぁ。
LLDはなぜかDMDごしに呼び出すのはできなかったのでできたらまた記事書きます。

# 使い方
goldは`ld.gold`という名前の実行ファイルになっている。
gccでもdmdでも、リンカオプションに`-fuse-ld=gold`とすると置き換わる。

`> dmd main.o sub.o -L=-fuse-ld=gold`

# 速度の比較

いったい何回やられたんだよってかんじですが、一応自分でも比較してみました。
適当に10000個関数を`sub.d`に作って`main.d`からそれらを呼び出す、というプログラムのリンク時間を測定しました。
```
ld   : 4 secs, 986 ms, 351 μs, and 6 hnsecs
gold : 1 sec, 699 ms, 670 μs, and 7 hnsecs
```
だいたい4倍くらい速くなっている。すごい。

比較用のコードは[こちら](https://gist.github.com/Sobaya007/fcd6d0eaee61f33e9d22dee112e155b9)にあります。
LLDはもっと速いらしいのでやってみたいなぁ。
