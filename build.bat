@echo off

:: Build program and stage to target\prefix\bin\ti-evo-tools.exe
echo Compiling program...
cargo install --path . --root target\prefix
echo Deploying Qt modules to program...
windeployqt --qmldir qml target\prefix\bin\ti-evo-tools.exe
echo Built and staged to target\prefix\bin\ti-evo-tools.exe!

:: Run program if --run flag is passed
set RUN=0
:parse
if "%1"=="--run" (
    set RUN=1
)
shift
if not "%1"=="" goto parse
if %RUN%==1 (
    echo Running program...
    target\prefix\bin\ti-evo-tools.exe
)
