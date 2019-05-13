---
title: "D言語でLLDも使ってリンクを高速化してみた"
date: 2019-05-13T11:32:01+09:00
thumbnail: "images/dmd.jpeg"
banner: "images/dmd.jpeg"
images: ["images/dmd.jpeg"]
categories: ["D言語"]
tags: ["D言語", "linker"]
---


[GOLD]({{< ref "post/linker-gold/index.md" >}})の続きです。

# LLDとはなんぞや
[LLD](https://lld.llvm.org/)とはリンカーの一種で、色々なアーキテクチャに対応している。goldより速いらしい。  
多分OS標準のpackage managerで普通にインストールできる。

# 今回のモチベーション
前回の記事で「LLDが使えない!」という自体に陥り、仕方なくgoldを使う決意を固めていたのですが、諦めきれずにちょくちょく試しておりました。  
今回D言語でうまく使う方法を無事発見できたのでメモがてら書いておこうと思いました。

# TL;DR
LLDは`ld.lld`という名前の実行ファイルになっている。  
`-fuse-ld=lld`とすれば置き換わると書いてあったので、試しに
```bash
> dmd test.d -L-fuse-ld=lld
```
としてみる。確かにコンパイルは通る。  
しかし本当にLLDが使われているのかわからない。  
LLDの「Using LLD」の項をよく読んでみると、

> LLD leaves its name and version number to a .comment section in an output. If you are in doubt whether you are successfully using LLD or not, run `readelf --string-dump .comment <output-file>` and examine the output. If the string “Linker: LLD” is included in the output, you are using LLD.
>
> LLDを使うと出力されたバイナリの.commentセクションに"Linker: LLD"と載るよ。気になったら`readelf --string-dump .comment <output-file>`すればわかるよ。

と書かれている。どれどれ。
```bash
> readelf --string-dupmp .comment test

セクション '.comment' の文字列ダンプ:
  [     0]  GCC: (GNU) 8.2.1 20181127
  [    1a]  GCC: (GNU) 8.3.0
```

入ってなくね？？？？  
とりあえずdmdの挙動を確認してみる。

```bash
> dmd test.d -L-fuse-ld=lld -v

predefs   DigitalMars Posix linux ELFv1 CRuntime_Glibc CppRuntime_Gcc LittleEndian D_Version2 all D_SIMD D_InlineAsm_X86_64 X86_64 D_LP64 D_PIC assert D_ModuleInfo D_Exceptions D_TypeInfo D_HardFloat
binary    dmd
version   v2.086.0
~~中略~~
cc test.o -o test -m64 -Xlinker -fuse-ld=lld -Xlinker --export-dynamic -L/usr/lib -Xlinker -Bstatic -lphobos2 -Xlinker -Bdynamic -lpthread -lm -lrt -ldl 
```
最後の行を見ると、確かにlinkerに`-fuse-ld=lld`を渡している。**ccを使って。**  
LLDのページには以下のように書かれている。

> If you don’t want to change the system setting, you can use clang’s `-fuse-ld` option. In this way, you want to set -fuse-ld=lld to LDFLAGS when building your programs.  
> システムの設定を変えたくなかったら、**clangの**`-fuse-ld`オプションを使ってね。

よく見たら`clang`で動くことしか書いてない。`cc`はサポート外なのでは？  
実際ccを生で使ってみると
```bash
> cc test.o -fuse-ld=lld
cc: エラー: unrecognized command line option ‘-fuse-ld=lld’; did you mean ‘-fuse-ld=bfd’?
```
と言われる。`dmd`は`lld`へのfuseを握りつぶしているっぽい。  
じゃあccを書き換えてからならどうだろう？  
```bash
> export cc=/usr/local/bin/clang
> dmd test.d -L-fuse-ld=lld -v
predefs   DigitalMars Posix linux ELFv1 CRuntime_Glibc CppRuntime_Gcc LittleEndian D_Version2 all D_SIMD D_InlineAsm_X86_64 X86_64 D_LP64 D_PIC assert D_ModuleInfo D_Exceptions D_TypeInfo D_HardFloat
binary    dmd
version   v2.086.0
~~中略~~
/usr/local/bin/clang test.o -o test -m64 -Xlinker -fuse-ld=lld -Xlinker --export-dynamic -L/usr/lib -Xlinker -Bstatic -lphobos2 -Xlinker -Bdynamic -lpthread -lm -lrt -ldl 
```
ちゃんと`clang`を使ってるっぽい。やったか？？？  
```bash
> readelf --string-dupmp .comment test

セクション '.comment' の文字列ダンプ:
  [     0]  GCC: (GNU) 8.2.1 20181127
  [    1a]  GCC: (GNU) 8.3.0
```

入ってなくね？？？？  
これも`dmd`に握りつぶされるっぽい。  
じゃあ`ldc`はどうだろう？`ldc`には`-linker=lld`とかいうお誂え向きなオプションがあるのだが、デフォルトではやっぱりgccを使うので`-fuse-ld=lld`でキレられる。  
しかしccを設定した今ならいけるのでは？
```bash
> export cc=/usr/local/bin/clang
> ldc test.d -linker=lld
> readelf --string-dupmp .comment test

セクション '.comment' の文字列ダンプ:
  [     0]  ldc version 1.15.0
  [    13]  GCC: (GNU) 8.3.0
  [    24]  Linker: LLD 8.0.0
  [    36]  GCC: (GNU) 8.2.1 20181127
```

やったぜ。

# 結論

- ccに`clang`を指定する
- `LDC`を使う
- `-linker=lld`オプションを使う

で動きます。

# 速度の比較
一応やります。  
比較方法は前回と同様。
```bash
ld   : 2 secs, 982 ms, 825 μs, and 7 hnsecs
gold : 1 sec, 64 ms, 881 μs, and 5 hnsecs
lld : 763 ms, 647 μs, and 5 hnsecs
```
goldよりも1.4倍くらい速いかな？といったかんじ。  
噂ほど速くはなってないかなぁという印象でしたが、少しでも速くしたいので今後はこちらを使っていきたいと思います。  

比較用のコードは[こちら](https://gist.github.com/Sobaya007/b8bee8664529c00bc9316a5d5bcedd77)です。
