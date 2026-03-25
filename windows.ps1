#Requires -RunAsAdministrator

function Find-Executable (
  [string] $command
) {
  $null -ne (Get-Command -Name $command -ErrorAction SilentlyContinue)
}

function Get-HayaTeXURL() {
  $hayatexArch = "x86_64"
  if ($env:PROCESSOR_ARCHITECTURE.ToLower() -eq "arm64") {
    $hayatexArch = "arm64"
  }
  return "https://github.com/e-chan1007/hayatex/releases/latest/download/hayatex_Windows_$hayatexArch.zip"
}

function Show-YesNoPrompt([string] $title, [string] $message) {
  $options = [System.Management.Automation.Host.ChoiceDescription[]](
    (New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "実行する"),
    (New-Object System.Management.Automation.Host.ChoiceDescription "&No", "実行しない")
  )
  $defaultChoice = 1
  $Host.UI.PromptForChoice($title, $message, $options, $defaultChoice) -eq 0
}

function Write-LabeledOutput (
  [string] $label,
  [string] $message
) {
  $esc = [char]27
  Write-Host "$esc[37;44;1m $label $esc[m $message"
}

$texLiveArchiveURL = Get-HayaTeXURL
$texLiveArchiveName = "hayatex.zip"
$texLiveProfileName = "texlive.profile"
$texLiveInstallerName = "hayatex.exe"
$workDir = "$env:TEMP/install-tl"

$vscodeLocalExePath = "$env:LOCALAPPDATA/Programs/Microsoft VS Code/Code.exe"
$vscodeExePath = "$env:ProgramFiles/Microsoft VS Code/Code.exe"
$vscodeCmdPath = "$env:ProgramFiles/Microsoft VS Code/bin/code.cmd"
$vscodeInstallerURL = "https://update.code.visualstudio.com/latest/win32-x64/stable"
$vscodeSettingsDir = "$env:APPDATA/Code/User"
$vscodeSettingsName = "settings.json"
$vscodeArgvPath = "$env:USERPROFILE/.vscode/argv.json"

$texLiveAdditionalArgs = ""
foreach ($arg in $args) {
  if ($arg -eq "--compat") {
    $texLiveAdditionalArgs = "--compat"
    break
  }
}

function Install-TeXLive () {
  New-Item -ItemType Directory -Path "$workDir" -Force > $null
  Push-Location "$workDir"
  Remove-Item -Recurse *

  @"
selected_scheme scheme-custom

collection-langjapanese 1
collection-latexextra 1
collection-mathscience 1
collection-binextra 1

tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0
"@ | Out-File $texLiveProfileName -Encoding ascii

  Write-LabeledOutput "TeX Live" "HayaTeX インストーラーのダウンロードを開始します"
  Start-BitsTransfer -Source $texLiveArchiveURL -Destination $texLiveArchiveName
  Expand-Archive -LiteralPath $texLiveArchiveName -DestinationPath .

  Write-LabeledOutput "TeX Live" "ダウンロードを完了しました"
  Write-LabeledOutput "TeX Live" "インストールを開始します"

  $env:LANG = "C"
  Start-Process -Wait -NoNewWindow -FilePath "./$texLiveInstallerName" -Args "--profile=`"$workDir/$texLiveProfileName`" $texLiveAdditionalArgs"

  Pop-Location
  Remove-Item -Recurse $workDir

  Write-LabeledOutput "TeX Live" "インストールを完了しました"
}

function Install-VSCode() {
  $workDir = "$env:TEMP/install-vscode";

  $vscodeInstallerPath = "$workDir/VSCodeUserSetup.exe"

  $exampleDir = "$env:USERPROFILE/Desktop/latex-example"
  $exampleName = "hello.tex"
  $exampleAuthor = (Get-WMIObject Win32_UserAccount | Where-Object caption -eq $(whoami)).FullName
  if (-not $exampleAuthor) {
    $exampleAuthor = $env:USERNAME
  }

  New-Item -ItemType Directory -Path "$workDir" -Force > $null
  Push-Location "$workDir"
  Remove-Item -Recurse *

  Write-LabeledOutput "Visual Studio Code" "インストーラーのダウンロードを開始します"

  Start-BitsTransfer -Source "$vscodeInstallerURL" -Destination "$vscodeInstallerPath"

  Write-LabeledOutput "Visual Studio Code" "ダウンロードを完了しました"
  Write-LabeledOutput "Visual Studio Code" "インストールを開始します"


  Start-Process -Wait -NoNewWindow -FilePath "$vscodeInstallerPath" -Args "/VERYSILENT /NORESTART /MERGETASKS=!runcode,desktopicon,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"

  New-Item -ItemType Directory -Path "$vscodeSettingsDir" -Force > $null

  @"
{
  "security.workspace.trust.enabled": false,
  "latex-workshop.latex.recipe.default": "lastUsed",
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

"@ | Out-File -FilePath "$vscodeSettingsDir/$vscodeSettingsName" -Encoding ascii

  Start-Process -Wait -NoNewWindow -FilePath "$vscodeCmdPath" -Args "--install-extension MS-CEINTL.vscode-language-pack-ja"
  Start-Process -Wait -NoNewWindow -FilePath "$vscodeCmdPath" -Args "--install-extension James-Yu.latex-workshop"


  $vscodeProcess = Start-Process -WindowStyle Hidden -FilePath "$vscodeExePath" -PassThru
  Start-Sleep -Seconds 5
  Stop-Process -Force -InputObject $vscodeProcess


  @"
{
  "locale": "ja"
}
"@ | Out-File -FilePath "$vscodeArgvPath" -Encoding ascii

  New-Item -ItemType Directory -Path "$exampleDir" -Force > $null
  @"
\documentclass[11pt,a4j]{jsarticle}

\begin{document}

\title{Hello \LaTeX\ World!}
\author{$exampleAuthor}
\date{\today}
\maketitle

VSCode + \LaTeX の環境構築が完了しました！

この文書は、画面右上の右三角マーク(Build LaTeX project)をクリックすることでコンパイルされ、PDFファイルが生成されます。

\end{document}
"@ | ForEach-Object { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path "$exampleDir/$exampleName" -Encoding Byte

  $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

  runas /machine:$(${env:PROCESSOR_ARCHITECTURE}.ToLower()) /trustlevel:0x20000 "$vscodeExePath `"$exampleDir`" `"$exampleDir/$exampleName`""

  Pop-Location
  Start-Sleep -Seconds 5
  Remove-Item -Recurse "$workDir"

  Write-LabeledOutput  "Visual Studio Code" "インストールを完了しました"
}

if (Find-Executable "tlmgr") {
  if (Show-YesNoPrompt "TeX Live はすでにインストールされています。" "それでも TeX Live をインストールしますか?") {
    Install-TeXLive
  }
}
else {
  Install-TeXLive
}

if ((Test-Path "$vscodeLocalExePath") -or (Test-Path "$vscodeExePath")) {
  if (Show-YesNoPrompt "Visual Studio Code はすでにインストールされています。" "それでも Visual Studio Code をインストールしますか?") {
    Install-VSCode
  }
}
else {
  Install-VSCode
}
