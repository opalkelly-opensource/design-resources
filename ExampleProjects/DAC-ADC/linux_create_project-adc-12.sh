# For instructions on how to execute this build script, see 'How-To Setup the Project'
# at the Spectrum Analyzer sample's documentation located at the link provided
# in this sample's README.md.

if [ $# -eq 0 ]
   then
      echo "Usage: ./linux_create_project.sh [path to FrontPanel Vivado IP]"
      exit 1
fi

cd gateware/adc-12/ifft
vitis_hls build_ifft_vitis.tcl
cd ../fft
vitis_hls build_fft_vitis.tcl
cd ..
vivado -source create_project_vivado.tcl -tclargs $1
