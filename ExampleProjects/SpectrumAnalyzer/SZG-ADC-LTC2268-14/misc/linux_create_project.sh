# For instructions on how to execute this build script, see 'How-To Setup the Project'
# at the Spectrum Analyzer sample's documentation located at the link provided
# in this sample's README.md.

if [ $# -eq 0 ]
   then
      echo "Usage: ./linux_create_project.sh [path to FrontPanel Vivado IP]"
      exit 1
fi

vitis_hls ifft/build_ifft_vitis.tcl
vitis_hls fft/build_fft_vitis.tcl
vivado -source misc/create_project_vivado.tcl -tclargs $1
