@echo off
chcp 65001 >nul
setlocal

cd /d "%~dp0"

set APP_NAME=FH6Auto
set TEST_ROOT=G:\fh6auto_exe_test
set PROD_EXE=%TEST_ROOT%\FH6Auto.exe

echo.
echo ==============================
echo 打包并部署到 %TEST_ROOT%
echo （仅保留一份 FH6Auto.exe）
echo ==============================
echo.

where python >nul 2>nul
if errorlevel 1 (
    echo [错误] 未找到 python
    pause
    exit /b 1
)

echo [1/5] 清理 PyInstaller 中间产物...
if exist build rmdir /s /q build
if exist dist rmdir /s /q dist
if exist "%APP_NAME%.spec" del /f /q "%APP_NAME%.spec"

echo [2/5] PyInstaller 打包...
python -m PyInstaller ^
    -n "%APP_NAME%" ^
    -F ^
    -w ^
    --uac-admin ^
    main.py ^
    --icon=assets/icon.ico ^
    --add-data "images;images" ^
    --add-data "assets;assets"
if errorlevel 1 (
    echo [错误] 打包失败
    pause
    exit /b 1
)

echo [3/5] 清理旧版测试目录（fh6auto_exe_v*）...
for /d %%D in (G:\fh6auto_exe_v*_test) do (
    echo   删除 %%D
    rmdir /s /q "%%D" 2>nul
)

echo [4/5] 部署到 %TEST_ROOT% ...
if not exist "%TEST_ROOT%" mkdir "%TEST_ROOT%"
if exist "%TEST_ROOT%\images" rmdir /s /q "%TEST_ROOT%\images"
if exist "%TEST_ROOT%\cache" rmdir /s /q "%TEST_ROOT%\cache"
del /f /q "%TEST_ROOT%\FH6Auto*.exe" 2>nul

copy /y "dist\%APP_NAME%.exe" "%PROD_EXE%" >nul
xcopy /e /i /y "images" "%TEST_ROOT%\images" >nul
if exist "G:\fh6auto_exe\config.json" (
    copy /y "G:\fh6auto_exe\config.json" "%TEST_ROOT%\config.json" >nul
) else if not exist "%TEST_ROOT%\config.json" (
    echo [提示] 未找到 config.json，请手动放入 %TEST_ROOT%
)

echo [5/5] 完成
echo   运行: %PROD_EXE%
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "(Get-Content version.json -Raw | ConvertFrom-Json).version"`) do echo   版本: %%V
echo.
pause
