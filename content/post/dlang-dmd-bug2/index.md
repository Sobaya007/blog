---
title: "D言語のしょうもないバグをまたみつけた"
date: 2019-06-09T20:07:51+09:00
thumbnail: "images/dmd.jpeg"
banner: "images/dmd.jpeg"
categories: ["D言語"]
tags: ["D言語", "バグ"]
---


# いつもの
今回見つけたバグコードはこちらになります

```d
class A {}

void main() {
    auto f = (A a) => 1; // this is acceptable
    auto g = (A) => 1;   // this is not acceptable
}
```
上のラムダ式はただしく型推論されますが、下のラムダ式(引数に名前を与えない)では型がvoidになってしまいます。  
仕様かはわかりませんが、習慣に則ってここに報告しておきます。
