---
title: "VimでD言語"
date: 2019-07-30T10:16:11+09:00
thumbnail: "images/vman.png"
banner: "images/vman.png"
categories: ["D言語", "vim"]
tags: ["D言語", "vim", "language-server"]
images: ["images/vman.png"]

---

多分D言語erさんの多くはVSCodeで開発してるんじゃないかと思うんですが、私は敬虔なvim教徒なのでnvimで日夜D言語を書いております。
しかしながらD言語+vimの環境構築の例がなかなかヒットしないのでメモ書き程度に残しておきます。

# 使うもの
## [autozimu/LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim)
言わずと知れたLSPのプラグインです。[coc.nvim](https://github.com/neoclide/coc.nvim)も使ってみたのですが、なぜか補間がうまくいかなかったため断念しました。

## [dls](https://github.com/d-language-server/dls)
D言語のLanguage Serverです。割と活発に活動していていいかんじ。

# dlsのインストール
敬虔なD言語erなら当然DUBはインストールされていますよね？それさえあれば
```bash
> dub fetch dls
> dub run dls:bootstrap
```
で終わりです。

# 設定
私はdeinを使っているので、`plugins.toml`に以下のような記述をしています。
```toml
[[plugins]]
repo = 'autozimu/LanguageClient-neovim'
rev = 'next'
build = 'bash install.sh'
hook_add = '''
let g:LanguageClient_serverCommands = {
    ...
    \ 'd': ['~/.dub/packages/.bin/dls-latest/dls'],
    ...
    \ }
let g:LanguageClient_rootMarkers = {
    ...
    \ 'd': ['dub.json', 'dub.sdl'],
    ...
    \ }

nnoremap <F5> :call LanguageClient_contextMenu()<CR>
nnoremap <silent> K :call LanguageClient#textDocument_hover()<CR>
nnoremap <silent> <C-]> :call LanguageClient#textDocument_definition()<CR>
nnoremap <silent> <F2> :call LanguageClient#textDocument_rename()<CR>
set hidden "ないと失敗する操作が存在する(Renameとか)
```

こんなんで大体動きます。
ショートカット系はお好みで。

ただし`set hidden`はしておかないと(書いてあるとおりですが)いくつかの操作で失敗することがあるのでご注意を。
