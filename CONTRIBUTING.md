# Contributionについて

## はじめに

このガイドをみて追加したいことや修正したい、となった場合は以下の流れにそって対応いただければと思います。

- GitHubでFork
- Issue 作成
- Pull request

Issueで議論後に対応をする方針で勧めます。

## 手順

コンテンツを修正・追加した場合の流れは以下の通りです。

``` console

$ cd docs/LevelXX
$ # コンテンツの追加・編集を実施
$ utils/autobuild.sh
```

sphinx auto-build が実行され、``localhost:8000`` でリアルタイムプレビューが可能です。

ここで使っているDockerイメージは[makotow/sphinxdocker](https://github.com/makotow/sphinxdocker/blob/master/README.ja.md)で公開しているイメージを使用しています。

## ディレクトリレイアウト

コンテンツは ``docs/source/`` 以下のLvelXX を編集する形で追加します。

```
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE
├── README.md
└── docs
    ├── Makefile
    ├── build
    ├── make.bat
    ├── package-lock.json
    ├── package.json
    ├── source
    │   ├── Level0
    │   ├── Level1
    │   ├── Level2
    │   ├── Level3
    │   ├── Level4
    │   ├── Level5
    │   ├── _static
    │   ├── conf.py
    │   ├── images
    │   ├── index.rst
    │   └── others
    └── utils
        ├── autobuild.sh
        ├── clean.sh
        ├── devstrategy.md
        └── preview.sh
```