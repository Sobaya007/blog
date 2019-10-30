---
title: "LDCビルド方法"
date: 2019-04-27T23:33:31+09:00
thumbnail: "images/ldc.png"
banner: "images/ldc.png"
images: ["images/ldc.png"]
categories: ["D言語"]
tags: ["D言語"]
---

結構難航しているのでまとめ。
一応[Wiki](https://wiki.dlang.org/Building_LDC_from_source)は存在しているので困ったら参考までに。

# 結論
```bash
git clone https://github.com/ldc-developers/ldc --recursive
cd ldc
mkdir build
cd build
cmake .. -DLDC_WITH_LLD=OFF
make
```

# 詰まったところ
## CMakeが「Some (but not all) targets in this export set were already defined」みたいなエラーを出す
- [issue](https://github.com/ldc-developers/ldc/issues/3079)
- [PR](https://github.com/ldc-developers/ldc/pull/3198)
2019年10月31日現在、masterではこのバグは解決済み。
リリースでいうとv1.18.0時点では直っていない。
一部のLLVMコンフィグだとうまくいかないときがあるらしく、それがこれ。

## ビルド(makeとかninjaとか)の途中で「CommandLine Error: Option 'mc-relax-all' registered more than once!」と言われる
`cmake`するときにちゃんと`-DLDC_WITH_LLD=OFF`をつけるといけるらしい。謎。
