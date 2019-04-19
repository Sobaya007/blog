---
title: "D言語で継承+配列のバグがずっと残ってる件について"
date: 2019-04-19T22:38:06+09:00
thumbnail: "images/dman.png"
banner: "images/dman.png"
categories: ["D言語"]
tags: ["D言語", "バグ"]
---


またバグの話ですね。
このバグは結構前に発見していて、issueも投げた...気がするんですが、一向に直りませんね。かなり頻繁に出くわすんですが、他の環境だと違うのでしょうか？

今回のバグはこんなかんじで発生します。
```c++
interface I {
    int x();
}

class C : I {
    int x() { return 10; }
}

void main(){

    I[] iList;
    C[] cList = [new C];

    iList ~= cList;

    import std.stdio : writeln;
    writeln(iList[0].x); //私の環境では6と出た。
}
```
つまり、

- あるインターフェース`I`とそれを継承したクラス`C`がある。
- `I[]`に対して、`C[]`を結合する(`C`でなく`C[]`!)。
- `I[]`から取り出した`I`越しに仮想関数を呼ぶと、だいたい壊れている(変な値を返したり、SEGVしたりする)。

というもの。
いかがでしたか？
よくわかりませんが、バグっていることがわかりました！
最後まで見ていただきありがとうございます。
