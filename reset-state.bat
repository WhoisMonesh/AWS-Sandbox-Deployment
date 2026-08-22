@echo off
setlocal EnableExtensions
set "TARGET_ROOT=%~1"
if not defined TARGET_ROOT set "TARGET_ROOT=%~dp0"
if "%TARGET_ROOT:~-1%" neq "\" set "TARGET_ROOT=%TARGET_ROOT%\"

echo Wiping local Terraform state under %TARGET_ROOT%services ...
set COUNT=0
for /r "%TARGET_ROOT%services" %%F in (terraform.tfstate terraform.tfstate.backup) do (
    if exist "%%F" (
        del /f /q "%%F"
        echo   removed %%F
        set /a COUNT+=1
    )
)
if %COUNT%==0 echo   (nothing to remove - state already clean)
echo.
echo Done. Next: tf.bat group-core apply   (or tf.bat ^<service^> apply)
exit /b 0
