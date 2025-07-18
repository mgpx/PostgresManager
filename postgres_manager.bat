@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

:: Configurações
set "POSTGRES_ROOT=C:\PostgreSQL"
set "DEFAULT_USER=postgres"

:: Função para verificar versões em execução
echo Verificando versões do PostgreSQL em execução...
echo ================================================

set "running_found=0"
for /f "tokens=1,2 delims==" %%A in (
    'wmic process where "name='postgres.exe'" get ProcessId^,ExecutablePath /value 2^>nul ^| find "="'
) do (
    if "%%A"=="ExecutablePath" if not "%%B"=="" (
        set "exe_path=%%B"
        set "current_pid="
    )
    if "%%A"=="ProcessId" if not "%%B"=="" (
        set "current_pid=%%B"
        if defined exe_path (
            call :check_version "!exe_path!" "!current_pid!"
        )
    )
)

if !running_found! equ 0 (
    echo ℹ️  Nenhuma versão do PostgreSQL está em execução.
)
echo ================================================
echo.

:: Lista versões disponíveis
echo Versões do PostgreSQL encontradas em %POSTGRES_ROOT%:
echo ------------------------------------------------
set counter=0
for /d %%i in ("%POSTGRES_ROOT%\*") do (
    set /a counter+=1
    set "versions[!counter!]=%%~nxi"
    echo !counter!. %%~nxi
)
echo ------------------------------------------------

:: Seleciona versão
set /p version_choice="Escolha o número da versão: "
if "!version_choice!"=="" (
    echo Nenhuma versão selecionada. Saindo.
    pause
    exit /b
)

if !version_choice! lss 1 (
    echo Escolha inválida.
    pause
    exit /b
)

if !version_choice! gtr !counter! (
    echo Escolha inválida.
    pause
    exit /b
)

set "selected_version=!versions[%version_choice%]!"
set "PG_PATH=%POSTGRES_ROOT%\!selected_version!\pgsql"
set "DATA_DIR=%PG_PATH%\data"

:: Verifica se o PostgreSQL já está em execução
set "postgres_running=0"
for /f "tokens=2 delims==" %%A in (
    'wmic process where "name='postgres.exe'" get ExecutablePath /value ^| find "="'
) do (
    if not "%%A"=="" (
        echo %%A | find /i "%PG_PATH%" >nul
        if !errorlevel! == 0 set "postgres_running=1"
    )
)

if !postgres_running! equ 1 (
    echo ⚠️  O PostgreSQL !selected_version! já está em execução.
    echo.
    echo Caminho: %PG_PATH%
    echo.
    
    :ask_stop
    set /p stop_postgres="Deseja parar o PostgreSQL? (S/N): "
    
    if /i "!stop_postgres!"=="S" (
        echo.
        echo Parando o PostgreSQL...
        "%PG_PATH%\bin\pg_ctl.exe" -D "%DATA_DIR%" stop -m fast
        if errorlevel 1 (
            echo ❌ Falha ao parar o PostgreSQL.
            set /p retry="Tentar novamente? (S/N): "
            if /i "!retry!"=="S" goto ask_stop
            pause
            exit /b
        )
        echo ✅ PostgreSQL parado com sucesso!
        timeout /t 2 >nul
        set "postgres_running=0"
    ) else if /i "!stop_postgres!"=="N" (
        echo Operação cancelada.
        pause
        exit /b
    ) else (
        echo Opção inválida.
        goto ask_stop
    )
)

:: Verifica se o cluster existe
if not exist "%DATA_DIR%" (
    echo Cluster não encontrado em %DATA_DIR%.
    set /p create_cluster="Deseja criar um novo cluster? (S/N): "
    if /i "!create_cluster!"=="S" (
        "%PG_PATH%\bin\initdb.exe" -D "%DATA_DIR%" -U %DEFAULT_USER% --encoding=UTF8 --locale=Portuguese_Brazil.1252 --pwprompt
        if errorlevel 1 (
            echo Erro ao criar o cluster.
            pause
            exit /b
        )
        echo Cluster criado com sucesso!
    ) else (
        echo Operação cancelada.
        pause
        exit /b
    )
)

:ask_port
echo Digite a porta para iniciar o PostgreSQL (ex: 5433): 
set /p "pg_port=>" || (
    echo.
    echo Operação cancelada pelo usuário.
    exit /b
)

:: Se vazio, usa padrão 5432
if "%pg_port%"=="" set "pg_port=5432"

:: Remove espaços extras
set "pg_port=%pg_port: =%"

:: Tenta converter para número
set "test_port="
set /a test_port=%pg_port% 2>nul

:: Verifica se foi possível converter
if not defined test_port (
    echo Entrada inválida. Digite apenas números.
    goto ask_port
)

:: Verifica intervalo da porta
if %test_port% lss 1 (
    echo A porta deve ser maior que 0.
    goto ask_port
)

if %test_port% gtr 65535 (
    echo A porta deve ser menor ou igual a 65535.
    goto ask_port
)

set "pg_port=%test_port%"
echo Porta válida: %pg_port%

echo Iniciando PostgreSQL (!selected_version!) na porta !pg_port!...
"%PG_PATH%\bin\pg_ctl.exe" -o "-F -p !pg_port!" -D "%DATA_DIR%" -l "%PG_PATH%\logfile" start

if errorlevel 1 (
    echo ❌ Falha ao iniciar o PostgreSQL. Verifique o log: %PG_PATH%\logfile
) else (
    echo ✅ PostgreSQL iniciado com sucesso!
    echo    Versão: !selected_version!
    echo    Porta: !pg_port!
    echo    Dados: %DATA_DIR%
)

pause
goto :eof

:: Função para verificar versão e porta
:check_version
set "exe_path=%~1"
set "pid=%~2"

:: Verifica se é do diretório PostgreSQL configurado
echo %exe_path% | find /i "%POSTGRES_ROOT%" >nul
if errorlevel 1 goto :eof

:: Extrai a versão do caminho
for %%i in ("%exe_path%") do set "full_path=%%~dpi"
set "version_path=!full_path:%POSTGRES_ROOT%\=!"
for /f "tokens=1 delims=\" %%j in ("!version_path!") do set "version=%%j"

:: Busca a porta usando netstat
set "port=Desconhecida"
for /f "tokens=2 delims=:" %%k in (
    'netstat -ano ^| find "!pid!" ^| find ":54" ^| find "LISTENING"'
) do (
    for /f "tokens=1" %%l in ("%%k") do (
        set "temp_port=%%l"
        if !temp_port! geq 5432 if !temp_port! leq 5499 (
            set "port=!temp_port!"
            goto :port_found
        )
    )
)

:: Se a porta não foi encontrada, não exibe a entrada
goto :eof

:port_found
echo ✅ !version! - Porta: !port! (PID: !pid!)
set "running_found=1"
goto :eof