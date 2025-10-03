# Stable Diffusion Nix

## 目的

[AUTOMATIC1111/stable-diffusion-webui: Stable Diffusion web UI](https://github.com/AUTOMATIC1111/stable-diffusion-webui)
などは非常に依存関係が複雑かつリリースプロセスが雑なため、
手順が難しくて思い出すのも大変です。
簡単に再現可能に管理することを目的とします。

## 方法

[Nix Flakes](https://nixos.wiki/wiki/Flakes)
を使って再現可能かつ自動的に管理できるようにします。

## 前提

Nixパッケージマネージャが使えること。

Nix FlakesとNix Commandが有効化されていること。

NVIDIAのGPUを使用していること。
ここは将来的にAMDやIntelのGPUやCPUでの実行も可能にしても良いですが、
私が手元で画像生成を実用的に動かせる環境はNVIDIAのGPUのみなので、
今のところは後回しにしています。
備考までに現在の私の実験環境はNVIDIA GeForce RTX 5090です。

このリポジトリを`~/Desktop/stable-diffusion-nix`に`git clone`していること。

## 使い方

### 起動

```bash
nix run
```

## 状態ディレクトリ

通常のアプリケーションの場合、
`$XDG_DATA_HOME`ディレクトリまたは、
設定されていない場合は`~/.local/share/`以下のディレクトリに出力は配置されるべきです。

しかしgradioの制約でドットで始めるディレクトリ名はsecret fileとして扱われてしまうため、
読み込みができなくなってしまいます。

他に適切な場所も思いつかないため、
このプロジェクトディレクトリの[data](./data)ディレクトリを出力ディレクトリとして扱うことにします。

Nix上のsandboxを乗り越える適切な方法が即座に思いつかなかったので、
リポジトリは`~/Desktop/stable-diffusion-nix`として配置されていることを前提とします。

以下のようなデータを読み書きするためにディレクトリが使われます。

- `models/` - モデルファイル
- `outputs/` - 生成された画像
