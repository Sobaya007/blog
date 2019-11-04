---
title: "VimでLSPでC++"
date: 2019-11-04T17:09:47+09:00
thumbnail: "images/llvm.png"
banner: "images/llvm.png"
categories: ["LSP", "vim"]
tags: ["LSP", "C++", "vim"]
---

# やったこと
[neovim](https://neovim.io/)でC++のプロジェクトを読むときに定義ジャンプ等LSPの動作を行えるようにした。

# 環境
- OS: ArchLinux
- プラグイン: [LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim)
- プラグインマネージャ: [dein](https://github.com/Shougo/dein.vim)
- Language Server: clang

なお、[CMake](https://cmake.org/)することを前提にしています。

# deinの設定
```toml
[[plugins]]
repo = 'autozimu/LanguageClient-neovim'
rev = 'next'
build = 'bash install.sh'
hook_add = '''
let g:LanguageClient_serverCommands = {
    \ 'c': ['clangd', '-compile-commands-dir=' . getcwd() . '/build'],
    \ 'cpp': ['clangd', '-compile-commands-dir=' . getcwd() . '/build'],
    ...
    \ }
'''
```
# 使う時
`cmake`するときに、オプションとして`-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`をつける。
