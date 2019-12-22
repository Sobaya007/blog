---
title: "Win32 + D言語 + DLLで謎のクラッシュ"
date: 2019-12-23T01:09:56+09:00
thumbnail: "images/dman.png"
banner: "images/dman.png"
categories: ["D言語"]
tags: ["D言語", "バグ"]
---

もはやこれはバグなのかすら私にはわからない...

※追記: 全然違うコード張ってました。

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
export extern(C) Variant getThree() { 
    int i = 3;
    return Variant(i);
}

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
0x1000331A
0x0019FD9C
0x004023E6 in core.memory.__ModuleInfo
0x004060FF in std.internal.windows.advapi32.__ModuleInfo
0x00406079 in std.internal.windows.advapi32.__ModuleInfo
0x00405F14 in rt.monitor_.__ModuleInfo
0x0040454A in std.datetime.timezone.__ModuleInfo
0x00402513 in std.concurrency.__ModuleInfo
0x75746359 in BaseThreadInitThunk
0x77AD7B74 in RtlGetAppContainerNamedObjectPath
0x77AD7B44 in RtlGetAppContainerNamedObjectPath
----------------
```

と、このように**`Variant`を返す関数は死ぬ**。`void`関数は死なない。
ちなみに`Tuple`とか別の構造体だと死なない。