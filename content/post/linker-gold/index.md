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
```bash
> dmd main.o sub.o -L=-fuse-ld=gold
```

# 速度の比較

いったい何回やられたんだよってかんじですが、一応自分でも比較してみました。
適当に10000個関数を`sub.d`に作って`main.d`からそれらを呼び出す、というプログラムのリンク時間を測定しました。
```bash
ld   : 4 secs, 986 ms, 351 μs, and 6 hnsecs
gold : 1 sec, 699 ms, 670 μs, and 7 hnsecs
```
だいたい4倍くらい速くなっている。すごい。

比較用のコードは[こちら](https://gist.github.com/Sobaya007/fcd6d0eaee61f33e9d22dee112e155b9)にあります。
LLDはもっと速いらしいのでやってみたいなぁ。 

## 追記
<blockquote class="twitter-tweet" data-partner="tweetdeck"><p lang="ja" dir="ltr">LDCコンパイラとかLLDリンカでもやってみたがLLDあまり速くなかった？LDCだとgoldと他が逆転？ <a href="https://t.co/BuiLfhNxYl">https://t.co/BuiLfhNxYl</a> <a href="https://t.co/pijbhHVwHE">pic.twitter.com/pijbhHVwHE</a></p>&mdash; Shigeki Karita (@kari_tech) <a href="https://twitter.com/kari_tech/status/1122335530421612544?ref_src=twsrc%5Etfw">April 28, 2019</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
こんな情報を出していただきまして、もう少し調査してみました。
私の手元でも同様に実行してみたところ、確かにほぼ同じ結果に。そもそも各リンカーは本当に動いているのでしょうか？

### 実証
バイナリ周りは詳しくないのですが、どうもgoldを使うと実行ファイルのnote sectionにそれらしき情報が乗るらしい。

```bash
> dmd main.o sub.o -L-fuse-ld=gold
> readelf -n main

Displaying notes found in: .note.ABI-tag
  所有者            データサイズ	説明
  GNU                  0x00000010	NT_GNU_ABI_TAG (ABI バージョンタグ)
    OS: Linux, ABI: 3.2.0

Displaying notes found in: .note.gnu.build-id
  所有者            データサイズ	説明
  GNU                  0x00000014	NT_GNU_BUILD_ID (一意なビルドID ビット列)
    ビルドID: b4391ac10edb113997363dbda7ddbb14fd635300

Displaying notes found in: .note.gnu.gold-version
  所有者            データサイズ	説明
  GNU                  0x00000009	NT_GNU_GOLD_VERSION (gold バージョン)
    Version: gold 1.16
```
確かに最後の方にGOLDの文字が。
ちなみに普通にldを使うと、
```bash
> dmd main.o sub.o
> readelf -n main

Displaying notes found in: .note.ABI-tag
  所有者            データサイズ	説明
  GNU                  0x00000010	NT_GNU_ABI_TAG (ABI バージョンタグ)
    OS: Linux, ABI: 3.2.0

Displaying notes found in: .note.gnu.build-id
  所有者            データサイズ	説明
  GNU                  0x00000014	NT_GNU_BUILD_ID (一意なビルドID ビット列)
    ビルドID: ec70ebf4a95c16c36399eccb905306bfda8a5c3d
```
確かになにも出ない。
ちなみにlldだと？
```bash
> dmd main.o sub.o -L-fuse-ld=lld
> readelf -n main

Displaying notes found in: .note.ABI-tag
  所有者            データサイズ	説明
  GNU                  0x00000010	NT_GNU_ABI_TAG (ABI バージョンタグ)
    OS: Linux, ABI: 3.2.0

Displaying notes found in: .note.gnu.build-id
  所有者            データサイズ	説明
  GNU                  0x00000014	NT_GNU_BUILD_ID (一意なビルドID ビット列)
    ビルドID: ec70ebf4a95c16c36399eccb905306bfda8a5c3d
```
なんかldのときと同じに見える。もしやこいつ。
```bash
> dmd main.o sub.o -L-fuse-ld=hoge
```
なにも言わない。。。

つまり、**こいつ、指定されたリンカーが見つからなくても何も言わないのでは**??

ということで、私は「dmdごしにはlddは使用できない」という結論に至りました。

ではldcを使った場合はどうなるでしょうか。
```bash
> ldc main.o sub.o -L-lphobos2
> readelf -n main

Displaying notes found in: .note.ABI-tag
  所有者            データサイズ	説明
  GNU                  0x00000010	NT_GNU_ABI_TAG (ABI バージョンタグ)
    OS: Linux, ABI: 3.2.0

Displaying notes found in: .note.gnu.build-id
  所有者            データサイズ	説明
  GNU                  0x00000014	NT_GNU_BUILD_ID (一意なビルドID ビット列)
    ビルドID: 81e4f9de205641adfb2055b3319a88f6fcdf30a0

Displaying notes found in: .note.gnu.gold-version
  所有者            データサイズ	説明
  GNU                  0x00000009	NT_GNU_GOLD_VERSION (gold バージョン)
    Version: gold 1.16
```
あれ...何も指定していないけどgoldが使われる...
どうも他の指定をしても全部goldが使われるっぽい。

結論として、

- dmdではlldは使えない
- ldcではgoldしか使えない

となりました。他の使い方があったら教えてほしい。。。
