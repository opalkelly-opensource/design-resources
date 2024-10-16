
/***************************************************************************
Copyright (c) 2016, Xilinx, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors
may be used to endorse or promote products derived from this software
without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

***************************************************************************/

#ifndef _XF_ISP_CONFIG_PARAMS_H_
#define _XF_ISP_CONFIG_PARAMS_H_


#define XF_NPPC XF_NPPC4 // XF_NPPC1 --1PIXEL , XF_NPPC2--2PIXEL ,XF_NPPC4--4 and XF_NPPC8--8PIXEL

#define XF_WIDTH 2304  // MAX_COLS
#define XF_HEIGHT 1296 // MAX_ROWS

#define XF_BAYER_PATTERN XF_BAYER_GR // bayer pattern
#define SIN_CHANNEL_TYPE XF_8UC1

#define XF_SRC_T XF_8UC1
#define XF_DST_T XF_8UC3

#define WB_TYPE XF_WB_SIMPLE

#define XF_AXI_GBR 0

#define XF_USE_URAM 0 // uram enable



// --------------------------------------------------------------------
// Required files
// --------------------------------------------------------------------
#include "hls_stream.h"
#include "ap_int.h"
#include "common/xf_common.hpp"
#include "common/xf_utility.hpp"
#include "common/xf_infra.hpp"
#include "ap_axi_sdata.h"
#include "common/xf_axi_io.hpp"
#include "xf_config_params.h"

// Requried Vision modules
#include "imgproc/xf_bpc.hpp"
#include "imgproc/xf_black_level.hpp"
#include "imgproc/xf_colorcorrectionmatrix.hpp"
#include "imgproc/xf_gammacorrection.hpp"
#include "imgproc/xf_gaincontrol.hpp"
#include "imgproc/xf_histogram.hpp"
#include "imgproc/xf_quantizationdithering.hpp"
// #include "imgproc/xf_cvt_color.hpp"
#include "imgproc/xf_aec.hpp"
#include "imgproc/xf_autowhitebalance.hpp"
#include "imgproc/xf_demosaicing.hpp"

// --------------------------------------------------------------------
// Macros definations
// --------------------------------------------------------------------

// Useful macro functions definations
#define _DATA_WIDTH_(_T, _N) (XF_PIXELWIDTH(_T, _N) * XF_NPIXPERCYCLE(_N))
#define _BYTE_ALIGN_(_N) ((((_N) + 7) / 8) * 8)

#define IN_DATA_WIDTH _DATA_WIDTH_(XF_SRC_T, XF_NPPC)
#define OUT_DATA_WIDTH _DATA_WIDTH_(XF_DST_T, XF_NPPC)

#define AXI_WIDTH_IN _BYTE_ALIGN_(IN_DATA_WIDTH)
#define AXI_WIDTH_OUT _BYTE_ALIGN_(OUT_DATA_WIDTH)

#define NR_COMPONENTS 3
constexpr int Q_VAL = 1 << (XF_DTPIXELDEPTH(XF_SRC_T, XF_NPPC));
// --------------------------------------------------------------------
// Internal types
// --------------------------------------------------------------------
// Input/Output AXI video buses
typedef ap_axiu<AXI_WIDTH_IN, 1, 1, 1> InVideoStrmBus_t;
typedef ap_axiu<AXI_WIDTH_OUT, 1, 1, 1> OutVideoStrmBus_t;

#define MAX_REPRESENTED_VALUE 1 << (XF_DTPIXELDEPTH(XF_SRC_T, XF_NPPCX))

// Input/Output AXI video stream
typedef hls::stream<InVideoStrmBus_t> InVideoStrm_t;
typedef hls::stream<OutVideoStrmBus_t> OutVideoStrm_t;

// HW Registers
typedef struct {
    uint16_t width;
    uint16_t height;
    //    uint16_t video_format;
    uint16_t bayer_phase;
} HW_STRUCT_REG;

// --------------------------------------------------------------------
// Prototype
// --------------------------------------------------------------------
// top level function for HW synthesis

void ISPPipeline_accel(unsigned int rgain,unsigned int ggain, unsigned int bgain,uint32_t  height,uint32_t width, InVideoStrm_t& s_axis_video, OutVideoStrm_t& m_axis_video,uint8_t blackLevelCorrection,uint32_t thresh,uint32_t* hist);

#endif //_XF_ISP_TYPES_H_