---
title: "DMD2.085.0で謎のエラーが出てビルドできなくなる件について"
date: 2019-04-11T20:59:06+09:00
thumbnail: "images/dmd.jpeg"
banner: "images/dmd.jpeg"
categories: ["D言語"]
tags: ["D言語", "バグ"]

---

実は前から気づいていたが、dmd2.085.0で[とあるプロジェクト](https://github.com/Sobaya007/sbylib-graphics)をビルドしようとしたところ`tym = x27`とかいう謎のエラーを吐いてビルドできなくなってしまった。
ggってみても関連するものが見当たらない。
ブチキレたので調査をしてみた。

とりあえず現状報告。

OSはArch Linux。
dmdが2.085.0になったとき、[エラーが起きた箇所の周辺コードを表示してくれる](https://dlang.org/changelog/2.085.0.html#error-context)とかいう神機能を~~今更~~実装してくれたので試してみようと思い、使ってみたら上記の事態が発生。その時いろいろいじってはみたけどわからず。pacmanでバージョンを上げようとしても上がらなかったので「パッケージ管理者がバグに気づいて止めてるのかな？」と思いとりあえず放置。
ところが本日`pacman -Syu`したところ、dmd2.0850が(バグったまま)入ってきやがった。おい。

ということで見つけた最小コードがこちら↓

>app.d
>```d
>struct A { float e; }
>struct B {
>    this(A[1]) {}
>}
>```

これを**dubのプロジェクトの中で**ビルドしようとすると、少なくとも私の環境では落ちます。ぜひお試しあれ。

ちなみに`A`のメンバーが浮動小数型だとバグりますが、整数型だと通ります。
また、`B`のコンストラクタ引数の配列数を2以上にすると通ります。
意味がわからん...

---

## 追記
2019/5/25

この記事についてツイートをしたところ
<blockquote class="twitter-tweet" data-partner="tweetdeck"><p lang="ja" dir="ltr"><a href="https://t.co/5HGn31UQcD">https://t.co/5HGn31UQcD</a> これでなおるかもしれません、といっても最速で2.085.2リリースになってしまいますが。</p>&mdash; 私にICEが舞い降りた！ (@shitsyndrome) <a href="https://twitter.com/shitsyndrome/status/1117942300892487680?ref_src=twsrc%5Etfw">April 16, 2019</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
とのお知らせが。  
実際にdmd2.086.0で動かしてみると、無事動きました！ありがとうございます！！  
BugzillaとかでIssue立てるのは私なんかにはハードルがめちゃめちゃ高いのでTwitterで反応してこうして直してくださると本当にありがたいですね。
