---
title: "Arch Linuxインストールメモ"
date: 2019-12-08T02:49:47+09:00
thumbnail: "images/arch.png"
banner: "images/arch.png"
categories: ["環境構築"]
tags: ["環境構築", "OS"]
---

もう完全に自分用メモ書き。  
ちなみに私はUEFIブートでWin10とArchのデュアルブートにしています。  
CPUはintel製。  
GPUはNvidia製。  
ブートマネージャはsystemd-bootです。  
デスクトップ環境はgnomeです。  
インストール作業中の通信はWi-Fiでした。  
これがベストかはわからないが、できたので良し。  
様々なところを参考にしましたが、どこも通しでは参考にしていません。

1. [Live USBを作る](https://heruwakame.hatenablog.com/entry/2017/09/10/180923)。
私はrufusでやりました。
1. BIOSに行ってSecure Bootを切る。
1. Windowsとデュアルブートする場合は[高速スタートアップを切る](https://121ware.com/qasearch/1007/app/servlet/relatedqa?QID=018214)
1. [Arch用のパーティションを切る](https://heruwakame.hatenablog.com/entry/2017/09/10/180923)
1. Live USBを差してBIOSへ行き、Bootの優先順位のところでUSBっぽいのを最優先にする
1. Live USBからArchを起動
1. `lsblk`で各パーティションの名前を確認
    ```bash
    nvme0n1     259:0    0   477G  0 disk 
    ├─nvme0n1p1 259:1    0   260M  0 part /boot
    ├─nvme0n1p2 259:2    0    16M  0 part 
    ├─nvme0n1p3 259:3    0 257.6G  0 part 
    ├─nvme0n1p4 259:4    0 218.1G  0 part /
    └─nvme0n1p5 259:5    0  1000M  0 part 
    ```
    こんなかんじのノリでした。ここの名前は結構デバイスによって違う。  
1. `parted -l`でパーティションの役割を確認
   ```bash
    1    1049kB  274MB  273MB   fat32             EFI system partition          boot, hidden, esp
    2    274MB   290MB  16.8MB                    Microsoft reserved partition  msftres
    3    290MB   277GB  277GB   ntfs              Basic data partition          msftdata
    4    277GB   511GB  234GB   ext4              Basic data partition          msftdata
    5    511GB   512GB  1049MB  ntfs              Basic data partition          hidden, diag
    ```
    こんなかんじになっていた。  
    1番がEFIパーティション。  
    2番がWindows用の謎領域。  
    3番がWindows10。  
    私はWindows10のメインパーティションを縮小してその後ろに空き領域を作ったので、4番の領域がArch用となった。  
    ということで以下EFIパーティションを`nvme0n1p1`、Arch用パーティションを`nvme0n1p4`としてしまうので、適宜そのときの状況に合わせて読み替えてください。

1. `mkfs.ext4 /dev/nvme0n1p4`でArch用パーティションをフォーマット
1. `mount /dev/nvme0n1p4 /mnt`でArch用パーティションをマウント
1. `mkdir /mnt/boot`でArch用パーティション内にEFIパーティションのマウントポイントを作成
1. `mount /dev/nvme0n1p1 /mnt/boot`でEFIパーティションをマウント
1. `wifi-menu`でwifiにつなぐ
1. `timedatectl set-ntp true`でシステムクロックを合わせる
    これが要るのかは私にはわからない
1. `vim /etc/pacman.d/mirrorlist`で`pacman`の使うミラーを選択する。  
    具体的にはJapanっぽいのを適当に選んで一番上の行に持っていけばよい。
1. `pacstrap /mnt base linux linux-firmware`でディレクトリ構築+ベースシステムのインストール
1. `genfstab -U /mnt >> /mnt/etc/fstab`でfstabを生成
    よくわかっていないけどこれがないとあとで起動したときにマウントの仕方がわからなくなるっぽい。
1. `chroot /mnt`で作ったシステムに侵入
1. `ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime`でタイムゾーンを東京にする
1. `hwclock --systohc --utc`でなんか必要っぽいファイルを生成
1. `vim /etc/locale.gen`で`en_US.UTF-8 UTF-8`と`ja_JP.UTF-8 UTF-8`のコメントを外す
1. `locale-gen`でlocaleっぽいファイルを生成
1. `echo LANG=en_US.UTF-8 > /etc/locale.conf`で使用するlocaleを設定。  
    ちなみに私はここでtypoしたためにめっちゃ面倒を被りました。
1. `echo KEYMAP=jp106 > /etc/vconsole.conf`でキー配置を日本語用に。
1. 適当にコンピュータの名前を決めて`echo hoge > /etc/hostname`
    私は`echo sobaya > /etc/hostname`としました。
1. `vim /etc/hosts`で中身を以下のようにする。
    ```bash
    127.0.0.1	localhost
    ::1		localhost
    127.0.1.1	sobaya.localdomain	sobaya
    ```
1. `pacman -S iputils netctl dhcpcd iw wpa_supplicant dialog`でネット系のいろいろを入れる  
    これで必要十分かは不明だが、とりあえずこんだけ入れとけばなんとかなる
1. `mkinitcpio -P`する
1. `passwd`でrootパスワードを設定
1. `bootctl --path=/boot install`でEFIパーティションに`systemd-boot`を突っ込む
1. `vim /boot/loader/loader.conf`で以下のようなファイルを作成
    ```bash
    default  arch
    timeout  4
    editor   no
    ```
1. `blkid /dev/nvme0n1p1 > /boot/loader/entries/arch.conf`で適当に前準備
1. `vim /boot/loader/entries/arch.conf`で以下のようなファイルを作成
    ```
    title   Arch Linux
    linux   /vmlinuz-linux
    initrd  /intel-ucode.img
    initrd  /initramfs-linux.img
    options root=PARTUUID=hogehoge-foo-baz-hogehogehoge rw
    ```
    hogehogeのところにはすでに書き込まれていた部分を使えば楽。
1. `pacman -S intel-ucode`で`intel-ucode.img`を突っ込む
1. `exit`で一段抜ける
1. `umount -R /mnt`でアンマウント
1. `shutdown now`で電源を落とす
1. Live USBを引っこ抜いて電源を入れる
1. systemd-bootが立ち上がるので、Arch Linuxを選択(or放置)
1. ログインを求められるので、ユーザー名`root`でログイン
1. `wifi-menu`でもっかいWi-Fiに接続
1. `pacman -S gnome gnome-extra`でデスクトップ環境を突っ込む
1. `systemctl enable gdm`でgdmを登録
1. `pacman -S nvidia`でnvidiaドライバを突っ込む
1. `reboot`で再起動
1. gnomeが立ち上がるので、ユーザー名`root`でログイン
1. Superキー(Windowsキー？)を押して`term`とか打つとterminalが選択できるので、起動
1. `systemctl enable NetworkManager`でNetworkManagerを登録  
    これをしないとgnomeのGUIでWi-Fiが設定できない
1. 右上のほうからWi-Fiを接続
1. `useradd -d /home/sobaya -s /bin/bash -m sobaya`とかでユーザー作成  
    ちなみに私はfish派なので`pacman -S fish`してから`-s /usr/bin/fish`しました。
    あとなぜかfishの場所を見ようと思って`which fish`したらwhichが入っていなかったので`pacman -S which`しました。なぜwhichがないんだ。。。
1. `passwd sobaya`でパスワード設定
1. `usermod -aG wheel sobaya`でwheelグループ(sudoできるグループに登録)
1. `pacman -S neovim sudo`
1. `nvim /etc/sudoers`でwheelの行のコメント解除
1. 一度ログアウトして、一般ユーザーで再度ログイン  
    私はここでnvidiaの魔の手にかかり、ログインループ現象をくらいました。  
    解決策として、ログイン画面の歯車ボタンを押してXorgのgnomeからログインするという手があります。
    どうもWaylandと相性が悪いらしい。。。
1. `sudo pacman -S base-devel git go`
1. `git clone https://aur.archlinux.org/yay.git`
1. `cd yay`
1. `makepkg -si`でyayをインストール
1. `yay -S google-chrome`でchromeをインストール
1. `sudo pacman -S noto-fonts-cjk`でとりあえず日本語フォントをインストール
1. `sudo pacman -S fcitx-mozc fcitx-gtk3 fcitx-qt5`で日本語入力をインストール
1. Super押してSettingで歯車を召喚し、「地域と言語」を「日本語」「日本」「日本語」にする
1. Super押してfcitxでペンギン(設定のほう)を召喚し、入力メソッドがMozcになっているのを確認
1. `sudo pacman -S docker`でdockerをインストール
1. `systectl enable docker`でdockerを登録
1. `systemctl start docker`でdockerdを起動
1. `usermod -aG docker sobaya`でユーザーをdockerグループ追加
1. `newgrp docker`でdockerグループを有効化
1. `docker info`が出たら優勝

ここまで来ると

- デスクトップ環境
- ブラウザ
- 日本語表示/入力
- Nvidiaドライバインストール
- 一般ユーザー(sudoerかつdocker権限持ち)の作成

まで行っているのでどうにかなるでしょう。
