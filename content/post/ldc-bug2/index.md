---
title: "LDCのバグみつけた - その2 -"
date: 2019-12-05T13:38:33+09:00
thumbnail: "images/ldc.png"
banner: "images/ldc.png"
images: ["images/ldc.png"]
categories: ["D言語"]
tags: ["D言語", "バグ"]
---

またみつけてしまった。。。
今度のやつはまた微妙で、**私が自分でビルドしたLDCでのみ**起きた現象なので、私が悪い可能性も多分にあります。

# 作業環境
- OS: Arch Linux
- LLVM: 9.0.0
- LDC: v1.19.0-beta2(hash = ad80f004aeede0b1582bf9831133c000fecfef07)

# 起こったこと
まず自前でLDCをビルドします。
```bash
> git clone --recursive git@github.com:ldc-developers/ldc.git
> git checkout v1.19.0-beta2
> git submodule update --recursive
> mkdir build
> cd build
> cmake .. -G Ninja
> ninja
> sudo ninja install
```
できあがったLDCはこんなかんじ。
```bash
> ldc2 --version

LDC - the LLVM D compiler (1.19.0-beta2):
  based on DMD v2.089.0 and LLVM 9.0.0
  built with LDC - the LLVM D compiler (1.19.0-beta2)
  Default target: x86_64-pc-linux-gnu
  Host CPU: haswell
  http://dlang.org - http://wiki.dlang.org/LDC

  Registered Targets:
    aarch64    - AArch64 (little endian)
    aarch64_32 - AArch64 (little endian ILP32)
    aarch64_be - AArch64 (big endian)
    amdgcn     - AMD GCN GPUs
    arm        - ARM
    arm64      - ARM64 (little endian)
    arm64_32   - ARM64 (little endian ILP32)
    armeb      - ARM (big endian)
    avr        - Atmel AVR Microcontroller
    bpf        - BPF (host endian)
    bpfeb      - BPF (big endian)
    bpfel      - BPF (little endian)
    hexagon    - Hexagon
    lanai      - Lanai
    mips       - MIPS (32-bit big endian)
    mips64     - MIPS (64-bit big endian)
    mips64el   - MIPS (64-bit little endian)
    mipsel     - MIPS (32-bit little endian)
    msp430     - MSP430 [experimental]
    nvptx      - NVIDIA PTX 32-bit
    nvptx64    - NVIDIA PTX 64-bit
    ppc32      - PowerPC 32
    ppc64      - PowerPC 64
    ppc64le    - PowerPC 64 LE
    r600       - AMD GPUs HD2XXX-HD6XXX
    riscv32    - 32-bit RISC-V
    riscv64    - 64-bit RISC-V
    sparc      - Sparc
    sparcel    - Sparc LE
    sparcv9    - Sparc V9
    systemz    - SystemZ
    thumb      - Thumb
    thumbeb    - Thumb (big endian)
    wasm32     - WebAssembly 32-bit
    wasm64     - WebAssembly 64-bit
    x86        - 32-bit X86: Pentium-Pro and above
    x86-64     - 64-bit X86: EM64T and AMD64
    xcore      - XCore
```
こうしてインストールされたLDCを用いて以下のソースコードをビルドします。
```d
struct Q {
    auto func(uint[3] a, uint[3] b, uint c) {
        return this;
    }
}

void main() {
    Q q;
    q.func([1,1,1],[1,1,1],1);
}
```

すると以下のようなエラーが出ます。

```bash
ldc2: ../gen/abi-x86-64.cpp:305: void X86_64TargetABI::rewriteArgument(IrFuncTy&, IrFuncTyArg&, {anonymous}::RegCount&): Assertion `originalLType->isStructTy()' failed.
 #0 0x00007ff128105b7b llvm::sys::PrintStackTrace(llvm::raw_ostream&) (/usr/lib/libLLVM-9.so+0xb08b7b)
 #1 0x00007ff128103a44 llvm::sys::RunSignalHandlers() (/usr/lib/libLLVM-9.so+0xb06a44)
 #2 0x00007ff128103bd6 (/usr/lib/libLLVM-9.so+0xb06bd6)
 #3 0x00007ff1275df930 __restore_rt (/usr/lib/libpthread.so.0+0x14930)
 #4 0x00007ff1270f3f25 raise (/usr/lib/libc.so.6+0x3bf25)
 #5 0x00007ff1270dd897 abort (/usr/lib/libc.so.6+0x25897)
 #6 0x00007ff1270dd767 _nl_load_domain.cold (/usr/lib/libc.so.6+0x25767)
 #7 0x00007ff1270ec526 (/usr/lib/libc.so.6+0x34526)
 #8 0x000055f8e421b48f X86_64TargetABI::rewriteArgument(IrFuncTy&, IrFuncTyArg&, (anonymous namespace)::RegCount&) (/usr/local/bin/ldc2+0xc9348f)
 #9 0x000055f8e421b7ca X86_64TargetABI::rewriteFunctionType(IrFuncTy&) (/usr/local/bin/ldc2+0xc937ca)
#10 0x000055f8e40a77c8 DtoFunctionType(Type*, IrFuncTy&, Type*, Type*, FuncDeclaration*) (/usr/local/bin/ldc2+0xb1f7c8)
#11 0x000055f8e40a820d DtoFunctionType(FuncDeclaration*) (/usr/local/bin/ldc2+0xb2020d)
#12 0x000055f8e40a875d DtoResolveFunction(FuncDeclaration*) (/usr/local/bin/ldc2+0xb2075d)
#13 0x000055f8e40aa79a DtoDefineFunction(FuncDeclaration*, bool) (/usr/local/bin/ldc2+0xb2279a)
#14 0x000055f8e40983f9 CodegenVisitor::visit(FuncDeclaration*) (/usr/local/bin/ldc2+0xb103f9)
#15 0x000055f8e40977a5 CodegenVisitor::visit(StructDeclaration*) (/usr/local/bin/ldc2+0xb0f7a5)
#16 0x000055f8e4093fdd Declaration_codegen(Dsymbol*, IRState*) (/usr/local/bin/ldc2+0xb0bfdd)
#17 0x000055f8e4093f8a Declaration_codegen(Dsymbol*) (/usr/local/bin/ldc2+0xb0bf8a)
#18 0x000055f8e40d3100 codegenModule(IRState*, Module*) (/usr/local/bin/ldc2+0xb4b100)
#19 0x000055f8e420ce27 ldc::CodeGenerator::emit(Module*) (/usr/local/bin/ldc2+0xc84e27)
#20 0x000055f8e41cc700 codegenModules(Array<Module*>&) (/usr/local/bin/ldc2+0xc44700)
#21 0x000055f8e3f1239a mars_mainBody(Param&, Array<char const*>&, Array<char const*>&) (/usr/local/bin/ldc2+0x98a39a)
#22 0x000055f8e41cc529 cppmain() (/usr/local/bin/ldc2+0xc44529)
#23 0x000055f8e450ef30 _D2rt6dmain212_d_run_main2UAAamPUQgZiZ6runAllMFZv (/usr/local/bin/ldc2+0xf86f30)
#24 0x000055f8e450ed3f _d_run_main2 (/usr/local/bin/ldc2+0xf86d3f)
#25 0x000055f8e450eb9e _d_run_main (/usr/local/bin/ldc2+0xf86b9e)
#26 0x000055f8e420686f args::forwardToDruntime(int, char const**) (/usr/local/bin/ldc2+0xc7e86f)
#27 0x000055f8e41cbd0d main (/usr/local/bin/ldc2+0xc43d0d)
#28 0x00007ff1270df153 __libc_start_main (/usr/lib/libc.so.6+0x27153)
#29 0x000055f8e3e2afee _start (/usr/local/bin/ldc2+0x8a2fee)
fish: 'ldc2 test.d' terminated by signal SIGABRT (Abort)
```

こうなります。
どうもLDCはx86_64をターゲットにしてビルドするとき、最適化のためか関数の呼び出し方法を勝手に変えているっぽいです。
そこで出ているAssertionですね。
`pragma(LDC_verbose)`を`main`につけてもうちょっとちゃんと見てみます。

```bash
CodeGenerator::emit(test)                                                                                                                                                                             
* resetting 2817 Dsymbols                                                                                                                                                                             
* *** Initializing D runtime declarations ***                                                                                                                                                         
* * building runtime module                                                                                                                                                                           
* Import::codegen for test.object                                                                                                                                                                     
* StructDeclaration::codegen: 'test.Q'                                                                                                                                                                
* * Resolving struct type: Q (test.d(1))                                                                                                                                                              
* * * Building type: Q                                                                                                                                                                                
* * * * Building struct type test.Q @ test.d(1)                                                                                                                                                       
* * * * * final struct type: %test.Q = type { [1 x i8] }                                                                                                                                              
* * DtoDefineFunction(test.Q.func): test.d(2)                                                                                                                                                         
* * * isMember = this is: Q                                                                                                                                                                           
* * * DtoFunctionType(pure nothrow @nogc @safe Q(uint[3] a, uint[3] b, uint c))                                                                                                                       
* * * * Building type: Q*                                                                                                                                                                             
* * * * Building type: void                                                                                                                                                                           
* * * * Building type: uint[3]                                                                                                                                                                        
* * * * x86-64 ABI: Transforming argument types                                                                                                                                                       
* * * * * Building type: long                                                                                                                                                                         
* * * * * Building type: int                                                                       
* * * * * Rewriting argument type uint[3]                                                          
* * * * * * [3 x i32] => { i64, i32 }                                                              
* * * * * Rewriting argument type uint[3]                                                          
* * * * * * [3 x i32] => { i64, i32 }                                                              
ldc2: ../gen/abi-x86-64.cpp:305: void X86_64TargetABI::rewriteArgument(IrFuncTy&, IrFuncTyArg&, {anonymous}::RegCount&): Assertion `originalLType->isStructTy()' failed. 
...
```
とのこと。
最初の２つの`uint[3]`は`long`と`int`の構造体として渡されています。
[ソース](https://github.com/ldc-developers/ldc/blob/ad80f004aeede0b1582bf9831133c000fecfef07/gen/abi-x86-64.cpp#L302)を読むと、「渡したい引数の量に対してレジスタの数が微妙に足りないときは、レジスタ渡しとメモリ経由渡し(っていうのか？)が混在しないようにする」といった処理をしているようです。
なんでそれが困るのかというと、ここに構造体が来ることを何故か前提としていて、構造体の実体がバラバラになるのが嫌みたいなことかな？という予想は立ちます。
で、なんでここに構造体以外が来ることになっていないのかは不明。
実際いまは`uint[3]`が来ているのでこれでassertionが起きている。
う〜〜〜ん？？？

# 追記
再現性がシビアみたいなので、環境をちゃんと記載しました。

# 追追記
修正されました！  
https://github.com/ldc-developers/ldc/commit/ff831b9394b8c12595b708902b0bec8a00b5d3a5  
[kubo39](https://twitter.com/shitsyndrome)さんありがとうございます！！！！
