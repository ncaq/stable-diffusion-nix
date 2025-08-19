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

## 使い方

### 起動

```bash
nix run
```

## ディレクトリ構造

初回起動時に以下のディレクトリがリポジトリ以下に生成されます。

- `extensions/` - ユーザー拡張機能
- `models/` - モデルファイル
- `outputs/` - 生成された画像
