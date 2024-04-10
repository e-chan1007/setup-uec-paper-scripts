#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "管理者権限を付けて実行してください(sudo)。"
  exit 1
fi

existsCommand () {
  command -v $1 > /dev/null 2>&1
}

isDarwin() {
  return $(test "$(uname)" == "Darwin")
}

labeledEcho () {
  echo -e "\033[37;44;1m $1 \033[m" ${@:2}
}

yesNoPrompt () {
  while true; do
    read -p "$1 [y/n]: " yn
    case $yn in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) echo "y(es) または n(o) で答えてください。";;
    esac
  done
}

userName=${SUDO_USER:-$USER}

texLiveWorkDir="/tmp/install-tl"
texLiveArchiveURL="http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz"
texLiveArchiveName="install-tl-unx.tar.gz"
texLiveProfileName="texlive.profile"
texLiveInstallerName="install-tl"

vscodeWorkDir="/tmp/install-vscode"
vscodeSettingsName="settings.json"

if isDarwin; then
  homeDir=$(dscl . -read /Users/$userName NFSHomeDirectory | cut -d" " -f2)
  vscodeInstallDir="/Applications/Visual Studio Code.app"
  vscodeAppDir="/Applications/Visual Studio Code.app/Contents/Resources/app"
  vscodeArchiveURL="https://update.code.visualstudio.com/latest/darwin-universal/stable"
  vscodeArchivePath="$vscodeWorkDir/vscode.zip"
  vscodeArgvPath="$homeDir/Library/Application Support/Code/argv.json"
  vscodeBinDir="$vscodeAppDir/bin"
  vscodeBinPath="$vscodeBinDir/code"
  vscodeMoveTargetName="Visual Studio Code.app"
  vscodeSettingsDir="$homeDir/Library/Application Support/Code/User"
else
  homeDir=$(getent passwd $userName | cut -d: -f6)
  vscodeInstallDir="/opt/code"
  vscodeAppDir=$vscodeInstallDir
  vscodeArchiveURL="https://update.code.visualstudio.com/latest/linux-x64/stable"
  vscodeArchivePath="$vscodeWorkDir/vscode.tar.gz"
  vscodeArgvPath="$homeDir/.vscode/argv.json"
  vscodeBinDir="$vscodeAppDir/bin"
  vscodeBinPath="$vscodeBinDir/code"
  vscodeMoveTargetName="VSCode-linux-x64"
  vscodeSettingsDir="$homeDir/.config/Code/User"
fi

installTeXLive () {
  mkdir -p $texLiveWorkDir
  pushd $texLiveWorkDir > /dev/null
  rm -rf ./*

  cat <<- EOS >> $texLiveProfileName
  selected_scheme scheme-custom

  collection-langjapanese 1
  collection-latexextra 1
  collection-mathscience 1
  collection-binextra 1

  tlpdbopt_install_docfiles 0
  tlpdbopt_install_srcfiles 0
EOS

  labeledEcho "TeX Live" "インストーラーのダウンロードを開始します"
  curl -#Lo $texLiveArchiveName $texLiveArchiveURL
  tar -zxf $texLiveArchiveName
  installTLDir="$(ls -d * | head -n 1)"

  labeledEcho "TeX Live" "ダウンロードを完了しました"
  labeledEcho "TeX Live" "インストールを開始します"

  "$installTLDir/$texLiveInstallerName" --profile="$texLiveWorkDir/$texLiveProfileName"

  popd > /dev/null
  rm -rf $texLiveWorkDir

  /usr/local/texlive/????/bin/*/tlmgr path add

  labeledEcho "TeX Live" "インストールが完了しました"
}

installVSCode () {
  exampleDir="$homeDir/Desktop/latex-example"
  exampleName="hello.tex"

  user_gecos_field="$(echo "$user_record" | cut -d ':' -f 5)"

  exampleAuthor="$userRealName"

  mkdir -p $vscodeWorkDir
  pushd $vscodeWorkDir > /dev/null
  rm -rf ./*

  labeledEcho "Visual Studio Code" "ダウンロードを開始します"

  curl -#Lo "$vscodeArchivePath" "$vscodeArchiveURL"

  labeledEcho "Visual Studio Code" "ダウンロードを完了しました"
  labeledEcho "Visual Studio Code" "インストールを開始します"

  mkdir -p "$vscodeInstallDir"

  if isDarwin; then
    unzip -q $vscodeArchivePath
    mv -f "$vscodeMoveTargetName"/* "$vscodeInstallDir"
  else
    tar --strip-components 1 -zxf "$vscodeArchivePath" -C "$vscodeInstallDir"
  fi

  sudo -u "$userName" mkdir -p "$vscodeSettingsDir"

  sudo -u "$userName" touch "$vscodeSettingsDir/$vscodeSettingsName"

  cat <<- EOS > "$vscodeSettingsDir/$vscodeSettingsName"
  {
    "security.workspace.trust.enabled": false,
    "latex-workshop.latex.recipe.default": "lastUsed"
    "latex-workshop.latex.recipes": [
      {
        "name": "platex and dvipdfmx",
        "tools": ["platex", "platex", "dvipdfmx"]
      }, {
        "name": "uplatex and dvipdfmx",
        "tools": ["uplatex", "uplatex", "dvipdfmx"]
      }
    ],
    "latex-workshop.latex.tools": [
      {
        "name": "platex",
        "command": "platex",
        "args": [
          "-interaction=nonstopmode",
          "-file-line-error",
          "%DOC%"
        ]
      },
      {
        "name": "uplatex",
        "command": "uplatex",
        "args": [
          "-interaction=nonstopmode",
          "-file-line-error",
          "%DOC%"
        ]
      },
      {
        "name": "dvipdfmx",
        "command": "dvipdfmx",
        "args": ["%DOCFILE%.dvi"]
      }
    ]
  }
EOS

  setProfile() {
    grep -q "export PATH=\$PATH:$vscodeBinDir\$" $1
    if [ $? != 0 ]; then
      echo -e "\nexport PATH=\$PATH:$vscodeBinDir" >> $1
    fi
  }

  if [ -f "$homeDir/.bash_profile" ]; then setProfile "$homeDir/.bash_profile"
  elif [ -f "$homeDir/.bashrc" ]; then setProfile "$homeDir/.bashrc"
  fi

  if [ -f "$homeDirzprofile" ]; then setProfile "$homeDirzprofile"
  elif [ -f "$homeDir/.zshrc" ]; then setProfile "$homeDir/.zshrc"
  fi

  export PATH=$PATH:$vscodeBinDir

  sudo -u "$userName" "$vscodeBinPath" --install-extension MS-CEINTL.vscode-language-pack-ja
  sudo -u "$userName" "$vscodeBinPath" --install-extension James-Yu.latex-workshop

  sudo -u "$userName" "$vscodeBinPath" &> /dev/null
  sleep 5

  if isDarwin; then
    kill -9 $(ps -ef | grep "$vscodeMoveTargetName" | grep -v "grep" | awk '{print $2}')
  else
    killall -9 code
  fi

  sudo -u "$userName" mkdir -p "$homeDir/.vscode"

  cat <<- EOS > "$vscodeArgvPath"
  {
    "locale": "ja",
  }
EOS

  sudo -u "$userName" mkdir -p "$exampleDir"

  sudo -u "$userName" touch "$exampleDir/$exampleName"

  cat <<- EOS > "$exampleDir/$exampleName"
  \documentclass[11pt,a4j]{jsarticle}

  \begin{document}

  \title{Hello \LaTeX\ World!}
  \author{$userName}
  \date{\today}
  \maketitle

  Visual Studio Code + \LaTeX の環境構築が完了しました！

  この文書は、画面右上の右三角マーク(Build LaTeX project)をクリックすることでコンパイルされ、PDFファイルが生成されます。
  \end{document}
EOS

  sudo -u "$userName" "$vscodeBinPath" "$exampleDir" "$exampleDir/$exampleName"

  popd > /dev/null
  sleep 5
  rm -rf $vscodeWorkDir

  labeledEcho "Visual Studio Code" "インストールを完了しました"
}

if existsCommand "tlmgr"; then
  echo "TeX Live はすでにインストールされています。"
  if yesNoPrompt "それでも TeX Live をインストールしますか?"; then
    installTeXLive
  fi
else
  installTeXLive
fi

if existsCommand "code" || ( isDarwin && [ -e "$vscodeInstallDir" ] ); then
  echo "Visual Studio Code はすでにインストールされています。"
  if yesNoPrompt "それでも Visual Studio Code をインストールしますか?"; then
    installVSCode
  fi
else
  installVSCode
fi
