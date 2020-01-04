@echo off

:: This script parses args, installs required libraries (miniconda, MKL,
:: Magma), and then delegates to cpu.bat, cuda80.bat, etc.

set CUDA_VERSION=10.1


if not "%CUDA_VERSION%" == "cpu" (
    set CUDA_PREFIX=cuda%CUDA_VERSION%
) else (
    set CUDA_PREFIX=cpu
)

if "%DESIRED_PYTHON%" == "" set DESIRED_PYTHON=3.5;3.6;3.7
set DESIRED_PYTHON_PREFIX=%DESIRED_PYTHON:.=%
set DESIRED_PYTHON_PREFIX=py%DESIRED_PYTHON_PREFIX:;=;py%

set SRC_DIR=%~dp0
pushd %SRC_DIR%

:: Install Miniconda3
set "CONDA_HOME=%CD%\conda"
set "tmp_conda=%CONDA_HOME%"
set "miniconda_exe=%CD%\miniconda.exe"
rmdir /s /q conda
del miniconda.exe
curl -k https://repo.continuum.io/miniconda/Miniconda3-latest-Windows-x86_64.exe -o "%miniconda_exe%"
start /wait "" "%miniconda_exe%" /S /InstallationType=JustMe /RegisterPython=0 /AddToPath=0 /D=%tmp_conda%
if ERRORLEVEL 1 exit /b 1
set "ORIG_PATH=%PATH%"
set "PATH=%CONDA_HOME%;%CONDA_HOME%\scripts;%CONDA_HOME%\Library\bin;%PATH%"

:: Create a new conda environment
setlocal EnableDelayedExpansion
FOR %%v IN (%DESIRED_PYTHON%) DO (
    set PYTHON_VERSION_STR=%%v
    set PYTHON_VERSION_STR=!PYTHON_VERSION_STR:.=!
    conda remove -n py!PYTHON_VERSION_STR! --all -y || rmdir %CONDA_HOME%\envs\py!PYTHON_VERSION_STR! /s
    conda create -n py!PYTHON_VERSION_STR! -y -q numpy=1.11 "mkl>=2019" cffi pyyaml boto3 cmake ninja typing python=%%v pytorch torchvision cudatoolkit=10.1 -c pytorch
)
endlocal

:: Install MKL
rmdir /s /q mkl
del mkl_2019.4.245.7z
curl https://s3.amazonaws.com/ossci-windows/mkl_2019.4.245.7z -k -O
7z x -aoa mkl_2019.4.245.7z -omkl
set CMAKE_INCLUDE_PATH=%cd%\mkl\include
set LIB=%cd%\mkl\lib;%LIB%

:: Download MAGMA Files on CUDA builds
set MAGMA_VERSION=2.5.1
if "%CUDA_VERSION%" == "80" set MAGMA_VERSION=2.4.0
if "%CUDA_VERSION%" == "90" set MAGMA_VERSION=2.5.0

if "%DEBUG%" == "1" (
    set BUILD_TYPE=debug
) else (
    set BUILD_TYPE=release
)

if not "%CUDA_VERSION%" == "cpu" (
    rmdir /s /q magma_%CUDA_PREFIX%_%BUILD_TYPE%
    del magma_%CUDA_PREFIX%_%BUILD_TYPE%.7z
    curl -k https://s3.amazonaws.com/ossci-windows/magma_%MAGMA_VERSION%_%CUDA_PREFIX%_%BUILD_TYPE%.7z -o magma_%CUDA_PREFIX%_%BUILD_TYPE%.7z
    7z x -aoa magma_%CUDA_PREFIX%_%BUILD_TYPE%.7z -omagma_%CUDA_PREFIX%_%BUILD_TYPE%
)

:: Install sccache
if "%USE_SCCACHE%" == "1" (
    mkdir %CD%\tmp_bin
    curl -k https://s3.amazonaws.com/ossci-windows/sccache.exe --output %CD%\tmp_bin\sccache.exe
    if not "%CUDA_VERSION%" == "" (
        copy %CD%\tmp_bin\sccache.exe %CD%\tmp_bin\nvcc.exe

        set CUDA_NVCC_EXECUTABLE=%CD%\tmp_bin\nvcc
        set ADDITIONAL_PATH=%CD%\tmp_bin
        set SCCACHE_IDLE_TIMEOUT=1500
    )
)

set PYTORCH_BINARY_BUILD=1
set TH_BINARY_BUILD=1
set INSTALL_TEST=0

for %%v in (%DESIRED_PYTHON_PREFIX%) do (
    :: Activate Python Environment
    set PYTHON_PREFIX=%%v
    set "CONDA_LIB_PATH=%CONDA_HOME%\envs\%%v\Library\bin"
    if not "%ADDITIONAL_PATH%" == "" (
        set "PATH=%ADDITIONAL_PATH%;%CONDA_HOME%\envs\%%v;%CONDA_HOME%\envs\%%v\scripts;%CONDA_HOME%\envs\%%v\Library\bin;%ORIG_PATH%"
    ) else (
        set "PATH=%CONDA_HOME%\envs\%%v;%CONDA_HOME%\envs\%%v\scripts;%CONDA_HOME%\envs\%%v\Library\bin;%ORIG_PATH%"
    )
    pip install ninja
    @setlocal
    :: Set Flags
    if not "%CUDA_VERSION%"=="cpu" (
        set MAGMA_HOME=%cd%\magma_%CUDA_PREFIX%_%BUILD_TYPE%
        set CUDNN_VERSION=7
    )
    call cuda101.bat
    if ERRORLEVEL 1 exit /b 1
    if "%BUILD_PYTHONLESS%" == "" call internal\test.bat
    if ERRORLEVEL 1 exit /b 1
    @endlocal
)

set "PATH=%ORIG_PATH%"

:: 7 zip install  
curl -k https://www.7-zip.org/a/7z1805-x64.exe -O
if errorlevel 1 exit /b 1

start /wait 7z1805-x64.exe /S
if errorlevel 1 exit /b 1

set "PATH=%ProgramFiles%\7-Zip;%PATH%"

:: Vs install

set VS_DOWNLOAD_LINK=https://aka.ms/vs/15/release/vs_buildtools.exe
IF "%VS_LATEST%" == "1" (
   set VS_INSTALL_ARGS= --nocache --norestart --quiet --wait --add Microsoft.VisualStudio.Workload.VCTools
   set VSDEVCMD_ARGS=
) ELSE (
   set VS_INSTALL_ARGS=--nocache --quiet --wait --add Microsoft.VisualStudio.Workload.VCTools ^
                                                --add Microsoft.VisualStudio.Component.VC.Tools.14.11 ^
                                                --add Microsoft.Component.MSBuild ^
                                                --add Microsoft.VisualStudio.Component.Roslyn.Compiler ^
                                                --add Microsoft.VisualStudio.Component.TextTemplating ^
                                                --add Microsoft.VisualStudio.Component.VC.CoreIde ^
                                                --add Microsoft.VisualStudio.Component.VC.Redist.14.Latest ^
                                                --add Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Core ^
                                                --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 ^
                                                --add Microsoft.VisualStudio.Component.VC.Tools.14.11 ^
                                                --add Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Win81
   set VSDEVCMD_ARGS=-vcvars_ver=14.11
)

curl -k -L %VS_DOWNLOAD_LINK% --output vs_installer.exe
if errorlevel 1 exit /b 1

start /wait .\vs_installer.exe %VS_INSTALL_ARGS%
if not errorlevel 0 exit /b 1
if errorlevel 1 if not errorlevel 3010 exit /b 1
if errorlevel 3011 exit /b 1

:: CUDA Install 

set SRC_DIR=%~dp0\..

if not exist "%SRC_DIR%\temp_build" mkdir "%SRC_DIR%\temp_build"

set /a CUDA_VER=%CUDA_VERSION%
set CUDA_VER_MAJOR=%CUDA_VERSION:~0,-1%
set CUDA_VER_MINOR=%CUDA_VERSION:~-1,1%
set CUDA_VERSION_STR=%CUDA_VER_MAJOR%.%CUDA_VER_MINOR%

IF %CUDA_VER% LEQ 90 (
    set "NVCC_PACKAGE=compiler_%CUDA_VERSION_STR%"
) ELSE (
    set "NVCC_PACKAGE=nvcc_%CUDA_VERSION_STR%"
)

IF %CUDA_VER% EQU 80 goto cuda80
IF %CUDA_VER% EQU 90 goto cuda90
IF %CUDA_VER% EQU 91 goto cuda91
IF %CUDA_VER% EQU 92 goto cuda92
IF %CUDA_VER% EQU 100 goto cuda100

echo CUDA %CUDA_VERSION_STR% is not supported
exit /b 1

:cuda80

echo CUDA 8.0 is not supported
exit /b 1

:cuda90
IF NOT EXIST "%SRC_DIR%\temp_build\cuda_9.0.176_windows.7z" (
    curl -k -L https://www.dropbox.com/s/z5b7ryz0zrimntl/cuda_9.0.176_windows.7z?dl=1 --output "%SRC_DIR%\temp_build\cuda_9.0.176_windows.7z"
    if errorlevel 1 exit /b 1
    set "CUDA_SETUP_FILE=%SRC_DIR%\temp_build\cuda_9.0.176_windows.7z"
    set "NVCC_PACKAGE=compiler_%CUDA_VERSION_STR%"
)

IF NOT EXIST "%SRC_DIR%\temp_build\cudnn-9.0-windows7-x64-v7.zip" (
    curl -k -L https://www.dropbox.com/s/6p0xyqh472nu8m1/cudnn-9.0-windows7-x64-v7.zip?dl=1 --output "%SRC_DIR%\temp_build\cudnn-9.0-windows7-x64-v7.zip"
    if errorlevel 1 exit /b 1
    set "CUDNN_SETUP_FILE=%SRC_DIR%\temp_build\cudnn-9.0-windows7-x64-v7.zip"
)

goto cuda_common

:cuda91

IF NOT EXIST "%SRC_DIR%\temp_build\cuda_9.1.85_windows.7z" (
    curl -k -L https://www.dropbox.com/s/7a4sbq0dln6v7t2/cuda_9.1.85_windows.7z?dl=1 --output "%SRC_DIR%\temp_build\cuda_9.1.85_windows.7z"
    if errorlevel 1 exit /b 1
    set "CUDA_SETUP_FILE=%SRC_DIR%\temp_build\cuda_9.1.85_windows.7z"
    set "NVCC_PACKAGE=nvcc_%CUDA_VERSION_STR%"
)

IF NOT EXIST "%SRC_DIR%\temp_build\cudnn-9.1-windows7-x64-v7.zip" (
    curl -k -L https://www.dropbox.com/s/e0prhgsrbyfi4ov/cudnn-9.1-windows7-x64-v7.zip?dl=1 --output "%SRC_DIR%\temp_build\cudnn-9.1-windows7-x64-v7.zip"
    if errorlevel 1 exit /b 1
    set "CUDNN_SETUP_FILE=%SRC_DIR%\temp_build\cudnn-9.1-windows7-x64-v7.zip"
)

goto cuda_common

:cuda92

echo CUDA 9.2 is not supported
exit /b 1

:cuda100

echo CUDA 10.0 is not supported
exit /b 1

:cuda_common

set "CUDA_PREFIX=cuda%CUDA_VERSION%"

IF NOT EXIST "%SRC_DIR%\temp_build\NvToolsExt.7z" (
    curl -k -L https://www.dropbox.com/s/9mcolalfdj4n979/NvToolsExt.7z?dl=1 --output "%SRC_DIR%\temp_build\NvToolsExt.7z"
    if errorlevel 1 exit /b 1
)

echo Installing CUDA toolkit...

7z x %CUDA_SETUP_FILE% -o"%SRC_DIR%\temp_build\cuda"
pushd "%SRC_DIR%\temp_build\cuda"
dir
start /wait setup.exe -s %NVCC_PACKAGE% cublas_%CUDA_VERSION_STR% cublas_dev_%CUDA_VERSION_STR% cudart_%CUDA_VERSION_STR% curand_%CUDA_VERSION_STR% curand_dev_%CUDA_VERSION_STR% cusparse_%CUDA_VERSION_STR% cusparse_dev_%CUDA_VERSION_STR% nvrtc_%CUDA_VERSION_STR% nvrtc_dev_%CUDA_VERSION_STR% cufft_%CUDA_VERSION_STR% cufft_dev_%CUDA_VERSION_STR%
popd
echo Installing VS integration...
xcopy /Y "%SRC_DIR%\temp_build\cuda\_vs\*.*" "c:\Program Files (x86)\MSBuild\Microsoft.Cpp\v4.0\V140\BuildCustomizations"

echo Installing NvToolsExt...
7z x %SRC_DIR%\temp_build\NvToolsExt.7z -o"%SRC_DIR%\temp_build\NvToolsExt"
mkdir "%ProgramFiles%\NVIDIA Corporation\NvToolsExt\bin\x64"
mkdir "%ProgramFiles%\NVIDIA Corporation\NvToolsExt\include"
mkdir "%ProgramFiles%\NVIDIA Corporation\NvToolsExt\lib\x64"
xcopy /Y "%SRC_DIR%\temp_build\NvToolsExt\bin\x64\*.*" "%ProgramFiles%\NVIDIA Corporation\NvToolsExt\bin\x64"
xcopy /Y "%SRC_DIR%\temp_build\NvToolsExt\include\*.*" "%ProgramFiles%\NVIDIA Corporation\NvToolsExt\include"
xcopy /Y "%SRC_DIR%\temp_build\NvToolsExt\lib\x64\*.*" "%ProgramFiles%\NVIDIA Corporation\NvToolsExt\lib\x64"

echo Installing cuDNN...
7z x %CUDNN_SETUP_FILE% -o"%SRC_DIR%\temp_build\cudnn"
xcopy /Y "%SRC_DIR%\temp_build\cudnn\cuda\bin\*.*" "%ProgramFiles%\NVIDIA GPU Computing Toolkit\CUDA\v%CUDA_VERSION_STR%\bin"
xcopy /Y "%SRC_DIR%\temp_build\cudnn\cuda\lib\x64\*.*" "%ProgramFiles%\NVIDIA GPU Computing Toolkit\CUDA\v%CUDA_VERSION_STR%\lib\x64"
xcopy /Y "%SRC_DIR%\temp_build\cudnn\cuda\include\*.*" "%ProgramFiles%\NVIDIA GPU Computing Toolkit\CUDA\v%CUDA_VERSION_STR%\include"

echo Setting up environment...
set "PATH=%ProgramFiles%\NVIDIA GPU Computing Toolkit\CUDA\v%CUDA_VERSION_STR%\bin;%ProgramFiles%\NVIDIA GPU Computing Toolkit\CUDA\v%CUDA_VERSION_STR%\libnvvp;%PATH%"
set "CUDA_PATH=%ProgramFiles%\NVIDIA GPU Computing Toolkit\CUDA\v%CUDA_VERSION_STR%"
set "CUDA_PATH_V%CUDA_VER_MAJOR%_%CUDA_VER_MINOR%=%ProgramFiles%\NVIDIA GPU Computing Toolkit\CUDA\v%CUDA_VERSION_STR%"
set "NVTOOLSEXT_PATH=%ProgramFiles%\NVIDIA Corporation\NvToolsExt\"

echo Cleaning temp files
rd /s /q "%SRC_DIR%\temp_build"
pushd %TEMP%
rd /s /q .
popd

echo Using VS2015 as NVCC compiler
set "CUDAHOSTCXX=%VS140COMNTOOLS%\..\..\VC\bin\amd64\cl.exe"

:: Env fix



:: Caution: Please don't use this script locally
:: It may destroy your build environment.

setlocal

IF NOT EXIST "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" (
    echo Visual Studio 2017 C++ BuildTools is required to compile PyTorch on Windows
    exit /b 1
)

for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -legacy -products * -version [15^,16^) -property installationPath`) do (
    if exist "%%i" if exist "%%i\VC\Auxiliary\Build\vcvarsall.bat" (
        set "VS15INSTALLDIR=%%i"
        set "VS15VCVARSALL=%%i\VC\Auxiliary\Build\vcvarsall.bat"
        goto vswhere
    )
)

:vswhere

IF "%VS15VCVARSALL%"=="" (
    echo Visual Studio 2017 C++ BuildTools is required to compile PyTorch on Windows
    exit /b 1
)

call "%VS15VCVARSALL%" x86_amd64
for /f "usebackq tokens=*" %%i in (`where link.exe`) do move "%%i" "%%i.bak"

endlocal

taskkill /im nvcc.exe /f
taskkill /im sccache.exe /f
taskkill /im cl.exe /f
taskkill /im ninja.exe /f
taskkill /im link.exe /f
taskkill /im cmake.exe /f
taskkill /im conda-build.exe /f