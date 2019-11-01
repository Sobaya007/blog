---
title: "OpenCLと格闘した話"
date: 2019-11-01T10:35:12+09:00
thumbnail: "images/cl.png"
banner: "images/cl.png"
images: ["images/cl.png"]
categories: ["OpenCL", "Intel入ってる"]
tags: ["OpenCL", "GPGPU"]
---

私はArch Linuxを使っているんですが、OpenCLの2.1のAPI、もっと言えばSPIR-Vサポート周りが使えなくって奮闘していました。
[ArchWiki](https://wiki.archlinux.jp/index.php/GPGPU)曰く、`intel-compute-runtime`なるものを入れれば良いということでやってみたけど動かず。
調べてみると、[GitHub](https://github.com/intel/compute-runtime)にサポートバージョンが書いてありました。曰く、第8世代以上のCPUじゃないとダメっぽい。。。
一方私のCPUはというと、
```bash
> lscpu
... 中略 ...
モデル名:                            Intel(R) Core(TM) i7-4600U CPU @ 2.10GHz
...
```
とのこと。どう見ても第4世代です。本当にありがとうございました。
[Intelの対応表](https://www.intel.co.jp/content/www/jp/ja/support/articles/000005524/graphics-drivers.html)を見ても、4600はOpenCL1.2までしか対応していない。完。
