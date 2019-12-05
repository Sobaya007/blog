---
title: "LDCのバグみつけた"
date: 2019-12-01T23:10:16+09:00
thumbnail: "images/ldc.png"
banner: "images/ldc.png"
images: ["images/ldc.png"]
categories: ["D言語"]
tags: ["D言語", "バグ"]
---

久しぶりにバグ見つけました。

端的に言うと、Linux上かつLDCを使って以下に示すような構成のアプリケーションをビルドしようとすると失敗するというものです。

# 中身
ちょっと複雑です。
[こちら](https://github.com/Sobaya007/LDC-Bug)に出来上がったものを置いておいたので、よければどうぞ。

まず2つパッケージを用意します。
```
├── app
│   ├── dub.sdl
│   └── source
│       └── app.d
└── lib
    ├── dub.sdl
    └── source
        ├── foo
        │   └── main.d
        └── tmp.d
```
ここでは`app`と`lib`としました。
ソースファイルは全部で3つです。

app/source/app.d
```d
import std : writeln;

void main() {}
```

lib/source/foo/main.d
```d
import std.file;
void main() {}
```

lib/source/tmp.d
```d
import std.conv;

enum E { M }

string func(E e) {
    return e.to!string;
}
```

`dub.sdl`の中身はシンプルで、単純に`app`が`lib`に依存しているだけです。

いろいろ試したのですが、これが結構最小に近いです。

# 起きること
これで`app`パッケージをLinux上で実行しようとすると、
```bash
Performing "debug" build using ldc2 for x86_64.
lib ~master: building configuration "library"...
app ~master: building configuration "application"...
Linking...
/usr/bin/ld.gold: エラー: ../lib/.dub/build/library-debug-linux.posix-x86_64-ldc_2089-217E062EC8407754E513C83FC65AD834/liblib.a(main.o): multiple definition of '_d_execBssBegAddr'
/usr/bin/ld.gold: .dub/build/application-debug-linux.posix-x86_64-ldc_2089-963EDD342BD81E418D33E01A7E3025F1/app.o: previous definition here
/usr/bin/ld.gold: エラー: ../lib/.dub/build/library-debug-linux.posix-x86_64-ldc_2089-217E062EC8407754E513C83FC65AD834/liblib.a(main.o): multiple definition of '_d_execBssEndAddr'
/usr/bin/ld.gold: .dub/build/application-debug-linux.posix-x86_64-ldc_2089-963EDD342BD81E418D33E01A7E3025F1/app.o: previous definition here
collect2: エラー: ld はステータス 1 で終了しました
Error: /usr/bin/cc failed with status: 1
ldc2 failed with exit code 1.
```
といった形で`_d_execBssBegAddr`と`_d_execBssEndAddr`というシンボルが多重定義されていてリンクに失敗します。

# 原因について
[LDCのソースコード](https://github.com/ldc-developers/ldc/blob/ad80f004aeede0b1582bf9831133c000fecfef07/driver/codegenerator.cpp#L341)を見ると、Linux上でmainのモジュールをビルドするときにこの謎のシンボルを埋め込むようです。

どうも`lib`パッケージをライブラリとしてビルドしているのに何らかの勘違いを起こしてここを踏んでしまい、`app`パッケージのそれと衝突しているようです。
なぜ勘違いしてしまっているかは不明。

この状況をIssueに上げるのがめんどい...

# 追記
[kubo39](https://twitter.com/shitsyndrome)さんが対応してくださりました！(いつもありがとうございます！！)

[kubo39さんによる解説](https://kubo39.hatenablog.com/entry/2019/12/05/LDC%E3%81%AB%E3%81%8A%E3%81%84%E3%81%A6%E3%82%82%E3%81%AF%E3%82%84%E5%BF%85%E8%A6%81%E3%81%AA%E3%81%8F%E3%81%AA%E3%81%A3%E3%81%9Fcopy-relocation_check%E3%82%92%E6%B6%88%E3%81%97%E3%81%9F%E8%A9%B1)

私なりにまとめると、

- 結局これを引き起こしていた奴はレガシーで要らない子だったっぽい。
- とはいえこの仕様に依存している外部ライブラリの存在が考えられるので、次回リリースにはこのパッチは載らないらしい。

ということっぽい。
自前でビルドしているぶんには問題なさそうなのでとりあえず満足ですね。
