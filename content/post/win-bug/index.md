---
title: "Win32 + D言語 + DLLで謎のクラッシュ"
date: 2019-12-23T01:09:56+09:00
thumbnail: "images/dman.png"
banner: "images/dman.png"
categories: ["D言語"]
tags: ["D言語", "バグ"]
---

もはやこれはバグなのかすら私にはわからない...

## 環境
- Windows10 64bit
- DMD v2.089.1-dirty

## バグったコード
実際にバグが起きたのは以下のコード。
ざっくり説明すると、

1. 2つの関数をexportするDのコードを作る
2. コンパイルしてDLLにし、読み込む
3. 1つの関数は普通に実行できるが、もう1つは実行できない
4. いかがでしたか？

```d
enum dllSource = q{

import core.sys.windows.windows;
import core.sys.windows.dll;
import core.stdc.stdio;
import std;

__gshared HINSTANCE g_hInst;

export extern(C) void dllprint() { printf("hello dll world\n"); }
export extern(C) int getThree() { return 3; }

extern (Windows)
BOOL DllMain(HINSTANCE hInstance, ULONG ulReason, LPVOID pvReserved)
{
    switch (ulReason)
    {
	case DLL_PROCESS_ATTACH:
	    g_hInst = hInstance;
	    dll_process_attach( hInstance, true );
	    break;

	case DLL_PROCESS_DETACH:
	    dll_process_detach( hInstance, true );
	    break;

	case DLL_THREAD_ATTACH:
	    dll_thread_attach( true, true );
	    break;

	case DLL_THREAD_DETACH:
	    dll_thread_detach( true, true );
	    break;

        default:
    }
    return true;
}
};

import std;
import std.file : fwrite = write, fremove = remove;
import core.thread;
import core.runtime;
import core.sys.windows.windows;
void main()
{
    fwrite("mydll.d", dllSource);
    scope (exit) {
        fremove("mydll.d");
    }
    auto result = executeShell("dmd -ofmydll.dll mydll.d");
    scope (exit) {
        Thread.sleep(2.seconds);
        fremove("mydll.dll");
        fremove("mydll.obj");
    }
    enforce(result.status == 0, result.output);

    auto lib = Runtime.loadLibrary("mydll.dll");
    scope (exit) Runtime.unloadLibrary(lib);

    auto func = cast(void function())GetProcAddress(lib, "dllprint");
    enforce(func);
    func();

    auto func2 = cast(Variant function())GetProcAddress(lib, "getThree");
    enforce(func2);
    func2();  // <-- crash here
}
```
こいつを普通に実行する。

```bash
> dmd -run test.d
hello dll world

object.Error@(0): Access Violation
----------------
```

と、このように**`int`を返す関数は死ぬ**。`void`関数は死なない。は？