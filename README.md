# 電通大生のためのいちばんかんたんなLaTeX環境構築 2026版

このリポジトリは、電通大生がLaTeX環境を簡単に構築できるようにするためのスクリプトを提供しています。WindowsとUnix系OS (Linux、macOS) で動作するインストーラーが用意されており、TeX LiveのインストールとVSCodeの設定を自動化します。

このインストーラーでは、[HayaTeX](https://github.com/e-chan1007/hayatex)を使用してTeX Liveのインストールを高速化しています。

```pwsh
# Windows
powershell -NoProfile -ExecutionPolicy Bypass "iwr 'https://e-chan1007.github.io/setup-uec-paper-scripts/windows-wrapper.ps1' | iex"
```

```bash
# Unix系OS
sudo /bin/bash -c "$(curl -fsSL 'https://e-chan1007.github.io/setup-uec-paper-scripts/unix.sh')"
```


### 互換モード
インストール速度が低下する代わりに、TeX Live標準のインストーラーと同等の動作をする互換モードも用意しています。

```pwsh
powershell -NoProfile -ExecutionPolicy Bypass "iwr 'https://e-chan1007.github.io/setup-uec-paper-scripts/windows-wrapper.ps1' | iex -ArgumentList '--compat'"
```

```bash
sudo /bin/bash -c "$(curl -fsSL 'https://e-chan1007.github.io/setup-uec-paper-scripts/unix.sh') --compat"
```
