@echo off
setlocal EnableExtensions
chcp 65001 >nul
cd /d "%~dp0.."

echo ============================================================
echo MEDIRESERVA - REPARAR EL ERROR DE ECLIPSE/BUILDSHIP EN VS CODE
echo ============================================================
echo.
echo Aviso que repara (panel Problemas de VS Code, sobre
echo android\build.gradle.kts, origen "Java"):
echo   Cannot add nature org.eclipse.buildship.core.gradleprojectnature
echo   to Eclipse project app.
echo   Could not set the project description for 'app' because the
echo   project description file (.project) is out of sync with the file
echo   system.
echo.
echo Causa: las extensiones Java de VS Code (redhat.java y "Gradle for
echo Java") importan la carpeta android como proyecto Eclipse/Buildship y
echo dejan una cache desincronizada en:
echo   %%APPDATA%%\Code\User\workspaceStorage\^<id^>\redhat.java
echo.
echo Este script:
echo   1. borra esa cache Java/Eclipse (guarda una copia en %%TEMP%%);
echo   2. quita metadatos Eclipse sueltos (.project, .classpath, .settings).
echo La importacion queda desactivada en .vscode\settings.json, asi que el
echo aviso no vuelve a aparecer al reabrir el editor.
echo.
echo Si prefieres no cerrar VS Code, dentro del editor ejecuta:
echo   Ctrl+Shift+P -^> "Java: Clean Workspace Cache..." -^> Restart and delete
echo.
echo IMPORTANTE: cierra VS Code antes de continuar.
echo.

rem --- 1. Ubicar la cache del workspace de VS Code de este proyecto -----
set "RUTAPROY=%CD%"
for %%I in ("%RUTAPROY%") do set "NOMBREPROY=%%~nxI"
for %%I in ("%RUTAPROY%\..") do set "PADRE=%%~nxI"
set "PATRON=/%PADRE%/%NOMBREPROY%"
rem VS Code codifica el espacio de la ruta como %20, que son tres caracteres.
rem En findstr /r el punto matchea UNO solo, asi que hay que usar .*
set "PATRON=%PATRON: =.*%"
set "ALMACEN="
for /d %%D in ("%APPDATA%\Code\User\workspaceStorage\*") do (
    if exist "%%D\workspace.json" (
        findstr /i /r /m /c:"%PATRON%" "%%D\workspace.json" >nul 2>nul
        if not errorlevel 1 set "ALMACEN=%%D"
    )
)

if defined ALMACEN goto :CACHE
echo [AVISO] No se encontro la cache de VS Code de este proyecto:
echo         %RUTAPROY%
echo         Usa dentro del editor:
echo         Ctrl+Shift+P -^> "Java: Clean Workspace Cache..."
echo.
goto :METADATOS

:CACHE
echo [OK] Cache del workspace:
echo      %ALMACEN%
echo.
if /i "%~1"=="solo-verificar" (
    echo [MODO VERIFICACION] No se borra nada.
    goto :FIN
)
if exist "%ALMACEN%\redhat.java" goto :CERRAR
echo [INFO] Este workspace no tiene cache Java/Eclipse: nada que borrar.
echo.
goto :METADATOS

rem --- 2. Comprobar que VS Code este cerrado ---------------------------
:CERRAR
tasklist /fi "IMAGENAME eq Code.exe" | find /i "Code.exe" >nul
if not errorlevel 1 (
    echo [ERROR] Visual Studio Code esta abierto; la cache esta en uso.
    echo         Cierra todas las ventanas de VS Code y vuelve a ejecutar
    echo         este script, o usa dentro del editor:
    echo         Ctrl+Shift+P -^> "Java: Clean Workspace Cache..."
    echo.
    goto :METADATOS
)

rem --- 3. Respaldar y borrar la cache Java/Eclipse ---------------------
set "RESPALDO=%TEMP%\medireserva_jdt_%RANDOM%%RANDOM%"
echo [1/2] Respaldando la cache en:
echo       %RESPALDO%
mkdir "%RESPALDO%" >nul 2>nul
move "%ALMACEN%\redhat.java" "%RESPALDO%\redhat.java" >nul 2>nul
if not exist "%ALMACEN%\redhat.java" goto :CACHEOK
echo [ERROR] No se pudo mover la cache ^(sigue en uso^).
echo         Cierra VS Code, espera unos segundos y reintenta.
echo.
goto :METADATOS

:CACHEOK
echo       Cache eliminada: VS Code la regenerara limpia.
echo.
rem --- 4. Metadatos Eclipse sueltos dentro del proyecto ----------------
:METADATOS
echo [2/2] Buscando metadatos Eclipse dentro del proyecto...
set "BORRADOS=0"
call :LIMPIAR "%CD%"
call :LIMPIAR "%CD%\android"
call :LIMPIAR "%CD%\android\app"
if not "%BORRADOS%"=="0" goto :METADATOSOK
echo       No habia metadatos Eclipse sueltos.
goto :FIN

:METADATOSOK
echo       Elementos eliminados: %BORRADOS%

:FIN
echo.
echo ============================================================
echo Pasos finales
echo   1. Abre VS Code en la carpeta del proyecto.
echo   2. El aviso ya no debe aparecer: .vscode\settings.json desactiva la
echo      importacion Gradle/Maven y excluye android/ del analisis Java.
echo   3. Si aun apareciera: Ctrl+Shift+P -^> "Java: Clean Workspace
echo      Cache..." y acepta el reinicio del editor.
echo ============================================================
if "%~1"=="" pause
exit /b 0

:LIMPIAR
set "CARPETA=%~1"
if not exist "%CARPETA%" exit /b 0
if exist "%CARPETA%\.project" (
    del /q /f "%CARPETA%\.project" >nul 2>nul
    echo       Borrado: %CARPETA%\.project
    set /a BORRADOS+=1
)
if exist "%CARPETA%\.classpath" (
    del /q /f "%CARPETA%\.classpath" >nul 2>nul
    echo       Borrado: %CARPETA%\.classpath
    set /a BORRADOS+=1
)
if exist "%CARPETA%\.settings" (
    rd /s /q "%CARPETA%\.settings" >nul 2>nul
    echo       Borrado: %CARPETA%\.settings
    set /a BORRADOS+=1
)
exit /b 0

