dir
:: Activate Python Environment
set PYTHON_PREFIX=3.7
set "CONDA_LIB_PATH=%CONDA_HOME%\envs\%%v\Library\bin"
if not "%ADDITIONAL_PATH%" == "" (
    set "PATH=%ADDITIONAL_PATH%;%CONDA_HOME%\envs\%%v;%CONDA_HOME%\envs\%%v\scripts;%CONDA_HOME%\envs\%%v\Library\bin;%ORIG_PATH%"
) else (
    set "PATH=%CONDA_HOME%\envs\%%v;%CONDA_HOME%\envs\%%v\scripts;%CONDA_HOME%\envs\%%v\Library\bin;%ORIG_PATH%"
)
python setup.py build