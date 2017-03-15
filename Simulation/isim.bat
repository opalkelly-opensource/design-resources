REM DES Simulation Batch File
REM $Rev: 2 $ $Date: 2015-02-06 19:55:07 -0800 (Fri, 06 Feb 2015) $

REM Edit path for settings32/64, depending on architecture
call %XILINX%\..\settings64.bat

del tf_isim.exe

fuse -intstyle ise ^
     -incremental ^
     -lib unisims_ver ^
     -lib unimacro_ver ^
     -lib xilinxcorelib_ver ^
     -i ./oksim ^
     -o tf_isim.exe ^
     -prj isim.prj ^
     work.tf work.glbl
tf_isim.exe -gui -tclbatch isim.tcl -wdb isim.wdb