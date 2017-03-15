fuse -intstyle ise ^
     -incremental ^
     -lib unisims_ver ^
     -lib unimacro_ver ^
     -lib xilinxcorelib_ver ^
     -L secureip ^
     -i ./oksim ^
     -o tf_isim.exe ^
     -prj isim.prj ^
     work.tf work.glbl