@echo off
setlocal enabledelayedexpansion
setlocal enableextensions

rem get dependencies > nul 2>&1
dart pub get

rem generate the code > nul 2>&1
dart gen.dart 1.16.5 testPlugin test TestPlugin Kei testdir
rem Usage: dart gen.dart [mc_version] [plugin_name] [package_name] [mainclass_name] [author_name] [outdir] > nul 2>&1
rem mc_version - マインクラフトのバージョン > nul 2>&1
rem plugin_name - プラグイン名 > nul 2>&1
rem package_name - パッケージ名 > nul 2>&1
rem mainclass_name - クラス名 > nul 2>&1
rem author_name - 作者名 > nul 2>&1
rem outdir - 出力(jar / mvn install)ディレクトリ > nul 2>&1

endlocal

pause