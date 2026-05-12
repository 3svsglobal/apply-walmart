@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo.
echo ========================================
echo   Walmart Entry Program - Git Push
echo ========================================
echo.

git add -A
if errorlevel 1 (
  echo [ERROR] git add failed. Aborting.
  pause
  exit /b 1
)

git status -s

echo.
set /p msg="Commit message (Enter=auto): "

REM Guard against shell injection / quote breaking. Disallow CMD specials
REM that can escape the -m quoted argument: " ` ^ % & | < > and CRLF.
echo(%msg%| findstr /R /C:"[\"\^^^&|<>%%]" >nul
if not errorlevel 1 (
  echo [ERROR] Commit message contains forbidden characters. Use letters / digits / spaces / - _ . , : ; only.
  pause
  exit /b 1
)

if "%msg%"=="" set msg=update %date% %time:~0,8%

git commit -m "%msg%"
if errorlevel 1 (
  echo [ERROR] git commit failed - nothing to commit or hook rejected. Not pushing.
  pause
  exit /b 1
)

REM Use the current branch so we never accidentally push to a stale main.
for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD') do set "branch=%%b"

git push origin "%branch%"
if errorlevel 1 (
  echo [ERROR] git push failed. Local commit remains; re-run after fixing.
  pause
  exit /b 1
)

echo.
echo Done. Pushed to origin/%branch%. Vercel auto-deploy started for main pushes.
echo.
pause
