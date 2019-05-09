---
title: "DLSを直した話"
date: 2019-05-09T12:03:42+09:00
thumbnail: "images/dman.png"
banner: "images/dman.png"
categories: ["Language Server"]
tags: ["Language Server", "D言語"]
---

# 動機
私はD言語を書くとき[Neovim](https://neovim.io/)を使っています。  
プラグインとして以前までは[dutyl](https://github.com/idanarye/vim-dutyl)を使っていたのですが、昨今[Language Server](https://langserver.org)/なるものが流行りだしており、[vim-lsp](https://github.com/prabirshrestha/vim-lsp)+[dls](https://github.com/d-language-server/dls)を使うようになりました。  
しかしいざ使ってみるといくつかの機能がうまく動いていないように思われます。  
READMEによると、DLSのサポートしている機能は

- コード補間
- シンボルの定義へジャンプ
- 参照を検索
- シンボルの名前変更
- エラーチェック
- フォーマット
- シンボルの列挙
- シンボルのハイライト
- ホバー時のドキュメント表示

となっています。  
しかしvim-lspで例えば`:LspDocumentFormat`と打っても`Document formatting not supported for d`と言われてしまいます。  
多分バグだと思ったので直してみようと思いました。

# 原因
LSP(Language Server Protocol)において、Language Serverの起動時に`initialize`という命令が飛びます。  
この命令のDLS側のハンドリングに問題(?)があったためうまく動いていないようでした。  

[Micrsoft公式のドキュメント](https://microsoft.github.io/language-server-protocol/specification)によると、initialize時clientが送るデータの中にはcapabilitiesなるものが含まれており、server側が返す値にも同様にcapabilitiesなるものがあるようです。  
ドキュメント内では、clientから送るものは`The capabilities provided by the client (editor or tool)`であり、serverから返すものは`The capabilities the language server provides`らしいです。  
これを見る限り、clientの送るcapabilitiesは「以下のような機能を提供して欲しい」という意味であり、server側からのcapabilitiesは「要求された機能のうち、実際に提供できる機能は以下のものである」という意味であると考えられます。  

しかしながらvim-lspではinitialize時にcapabilitiesをほとんど送っていません。  
これでは先程の解釈によると「何の機能も要求していない」ということになります。したがって、DLSは当然何も返しません。  
その結果vim-lsp側からは「DLSは何の機能も持たない」と解釈されてしまいます。これが`not supported`の原因でした。

この状況を素直に捉えれば、「仕様に則ったrequestを送っていないvim-lsp側に問題がある」となるのでしょうが、試してみたところなぜか他の言語のLanguage Serverは普通に動いてしまっています。
おかしいと思い各種Language Serverのコードを見に行きました。すると...

> [javascript-typescript-langserver](https://github.com/sourcegraph/javascript-typescript-langserver)より引用
>```typescript
>const result: InitializeResult = {
>    capabilities: {
>        // Tell the client that the server works in FULL text document sync mode
>        textDocumentSync: TextDocumentSyncKind.Full,
>        hoverProvider: true,
>        signatureHelpProvider: {
>            triggerCharacters: ['(', ','],
>        },
>        definitionProvider: true,
>        typeDefinitionProvider: true,
>        referencesProvider: true,
>        documentSymbolProvider: true,
>        workspaceSymbolProvider: true,
>        xworkspaceReferencesProvider: true,
>        xdefinitionProvider: true,
>        xdependenciesProvider: true,
>        completionProvider: {
>            resolveProvider: true,
>            triggerCharacters: ['.'],
>        },
>        codeActionProvider: true,
>        renameProvider: true,
>        executeCommandProvider: {
>            commands: [],
>        },
>        xpackagesProvider: true,
>    },
>}
>```
だの  

> [rls](https://github.com/rust-lang/rls)より引用
>```rust
>ServerCapabilities {
>       text_document_sync: Some(TextDocumentSyncCapability::Kind(
>           TextDocumentSyncKind::Incremental,
>       )),
>       hover_provider: Some(true),
>       completion_provider: Some(CompletionOptions {
>           resolve_provider: Some(true),
>           trigger_characters: Some(vec![".".to_string(), ":".to_string()]),
>       }),
>       definition_provider: Some(true),
>       type_definition_provider: None,
>       implementation_provider: Some(ImplementationProviderCapability::Simple(true)),
>       references_provider: Some(true),
>       document_highlight_provider: Some(true),
>       document_symbol_provider: Some(true),
>       workspace_symbol_provider: Some(true),
>       code_action_provider: Some(CodeActionProviderCapability::Simple(true)),
>       document_formatting_provider: Some(true),
>       execute_command_provider: Some(ExecuteCommandOptions {
>           // We append our pid to the command so that if there are multiple
>           // instances of the RLS then they will have unique names for the
>           // commands.
>           commands: vec![
>               format!("rls.applySuggestion-{}", ctx.pid()),
>               format!("rls.deglobImports-{}", ctx.pid()),
>           ],
>       }),
>       rename_provider: Some(RenameProviderCapability::Simple(true)),
>       color_provider: None,
>
>       // These are supported if the `unstable_features` option is set.
>       // We'll update these capabilities dynamically when we get config
>       // info from the client.
>       document_range_formatting_provider: Some(false),
>
>       code_lens_provider: Some(CodeLensOptions { resolve_provider: Some(false) }),
>       document_on_type_formatting_provider: None,
>       signature_help_provider: None,
>
>       folding_range_provider: None,
>       workspace: None,
>   }
>```
だの、みんな**request parameterなんて見ていません**!!!  
つまり、「initialize時に送られてくるパラメータは大部分無視する」というのがどうも半ば標準化しているようです。悲しいなぁ。。。

ということでそこら辺をすっきり無視するようにしたらあっさり解決。  
forkして直したものは[こちら](https://github.com/Sobaya007/dls)の`fix-initialize`ブランチになります。  
PR送るの怖くてやってないけど、送ったほうがいいんだろうか...
