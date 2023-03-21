@echo off

REM USAGE: windows_create_project.bat <path to FrontPanel IP Core>
REM For instructions on how to execute this build script, see 'How-To Setup the Project'
REM at the FFT Signal Generator sample's documentation located at the link provided
REM in this sample's README.md.
REM Copyright (c) 2023, Opal Kelly Incorporated

IF "%~1"=="" GOTO USAGE

set FrontPanelIPRepo=%1
set vivado_separator=/
call set FrontPanelIPRepo=%%FrontPanelIPRepo:\=%vivado_separator%%%
echo %FrontPanelIPRepo%
REM This starts a new cmd window, passing the current env (/i) and waiting for it to stop.
REM /c Carries out the command specified (vitis_hls) by string and then stops.
echo Launching vitis_hls in another cmd prompt to build the IFFT core...
start /wait cmd /c vitis_hls misc/build_ifft_vitis.tcl
if not exist vitis\solution1\impl\export.zip GOTO BUILD_FAIL

vivado -source misc/create_project_vivado.tcl -tclargs %FrontPanelIPRepo%
EXIT /B 0

 :USAGE
@echo on
echo Usage: windows_create_project.bat <path to FrontPanel IP Core>
EXIT /B 1

 :BUILD_FAIL
@echo on
echo IFFT Core build failed. Inspect the vitis_hls.log file for errors.
echo Likely, your path is too long. You may need to move this sample to a shorter base path.
EXIT /B 2
