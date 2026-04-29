@echo off
cd /d "%~dp0"

echo.
echo ========================================
echo   Walmart Entry Program - Git Push
echo ========================================
echo.

git add -A
git status -s

echo.
set /p msg="Commit message (Enter=auto): "
if "%msg%"=="" set msg=update %date% %time:~0,8%

git commit -m "%msg%"
git push origin main

echo.
echo Done! Vercel auto-deploy started.
echo.
pause
