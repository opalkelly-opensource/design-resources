/***************************************************************************
 Copyright (c) 2020, Xilinx, Inc.
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

#include "xf_isp_types.h"
#include <cstdint>
#include <stdio.h>


#define NUM_CHANNELS 3
#define HIST_SIZE 256
#define TARGET_MEAN 128
#define EPSILON 5

// Reduce a 3x256 Matrix to a 1x768 Matrix
void flatten_histogram(uint32_t rgb_hist[3][256], uint32_t flatten_hist[768]) {
    // Calculate the flatten histogram
    #pragma HLS DATAFLOW
    for (int i = 0; i < 3; i++) { // Iterate over each channel
        #pragma HLS loop_flatten
        for (int j = 0; j < 256; j++) { // Iterate over each histogram bin
            #pragma HLS PIPELINE
            // Assign RGB histogram value to the flatten histogram
            flatten_hist[i * 256 + j] = (uint32_t)(rgb_hist[i][j]);
        }
    }
}


static constexpr int __XF_DEPTH_PTR = (768 * (XF_CHANNELS(XF_SRC_T, XF_NPPC)));
static bool flag; 

static uint32_t hist0[3][256];
static uint32_t hist1[3][256];

/************************************************************************************
 * Function:    AXIVideo2BayerMat
 * Parameters:  Multiple bayerWindow.getval AXI Stream, User Stream, Image Resolution
 * Return:      None
 * Description: Read data from multiple pixel/clk AXI stream into user defined stream
 ************************************************************************************/

void ISPpipeline( InVideoStrm_t& s_axis_video,
                 OutVideoStrm_t& m_axis_video,
                 unsigned short height,
                 unsigned short width,
                 uint8_t rgain,
                 uint8_t bgain,
                 uint8_t ggain,
                 uint32_t hist0[3][256],
                 uint32_t hist1[3][256],
                 uint32_t BLACK_LEVEL,
                 uint8_t thresh
                 ) {
// clang-format off
#pragma HLS INLINE OFF
    // clang-format on
    xf::cv::Mat<XF_SRC_T, XF_HEIGHT, XF_WIDTH, XF_NPPC,2> imgInput1(height, width);
    xf::cv::Mat<XF_SRC_T, XF_HEIGHT, XF_WIDTH, XF_NPPC,2> bpc_out(height, width);
    xf::cv::Mat<XF_SRC_T, XF_HEIGHT, XF_WIDTH, XF_NPPC,2> blc_out(height, width);
    xf::cv::Mat<XF_SRC_T, XF_HEIGHT, XF_WIDTH, XF_NPPC,2> gain_out(height, width);
    xf::cv::Mat<XF_DST_T, XF_HEIGHT, XF_WIDTH, XF_NPPC,2> demosaic_out(height, width);
    xf::cv::Mat<XF_DST_T, XF_HEIGHT, XF_WIDTH, XF_NPPC,2> impop(height, width);
    xf::cv::Mat<XF_DST_T, XF_HEIGHT, XF_WIDTH, XF_NPPC,2> awb(height, width);
    xf::cv::Mat<XF_DST_T, XF_HEIGHT, XF_WIDTH, XF_NPPC,2> qnd(height, width);

// clang-format off
#pragma HLS stream variable = bpc_out.data dim = 1 depth = 2
#pragma HLS stream variable = gain_out.data dim = 1 depth = 2
#pragma HLS stream variable = demosaic_out.data dim = 1 depth = 2
#pragma HLS stream variable = imgInput1.data dim = 1 depth = 2
#pragma HLS stream variable = impop.data dim = 1 depth = 2
// clang-format on

// clang-format off
#pragma HLS DATAFLOW
    // Define variables for image processing
    float inputMin = 0.0f;
    float inputMax = 255.0f;
    float outputMin = 0.0f;
    float outputMax = 255.0f;
    uint16_t bformat = XF_BAYER_PATTERN;
    float mul_fact = (inputMax / (inputMax - BLACK_LEVEL)) * 65536;
    XF_CTUNAME(XF_SRC_T, XF_NPPC) bl = XF_CTUNAME(XF_SRC_T, XF_NPPC)(BLACK_LEVEL);
    xf::cv::AXIvideo2xfMat(s_axis_video, imgInput1);
    xf::cv::blackLevelCorrection<XF_SRC_T, XF_HEIGHT, XF_WIDTH, XF_NPPC, 16, 15, 1, 2, 2>(imgInput1, blc_out, BLACK_LEVEL, mul_fact);
    xf::cv::badpixelcorrection<XF_SRC_T, XF_HEIGHT, XF_WIDTH, XF_NPPC, 0, 0>(blc_out, bpc_out);
    xf::cv::gaincontrol<XF_SRC_T, XF_HEIGHT, XF_WIDTH, XF_NPPC>(bpc_out, gain_out, rgain, bgain, ggain, bformat);
    xf::cv::demosaicing<XF_SRC_T, XF_DST_T, XF_HEIGHT, XF_WIDTH, XF_NPPC, 0, 2, 2>(gain_out, demosaic_out, bformat);
    xf::cv::AWBhistogram<XF_DST_T, XF_DST_T, XF_HEIGHT, XF_WIDTH, XF_NPPC, XF_USE_URAM, 1, 256, 2, 2>(demosaic_out, impop, hist0, thresh, inputMin, inputMax, outputMin, outputMax);
    xf::cv::AWBNormalization<XF_DST_T, XF_DST_T, XF_HEIGHT, XF_WIDTH, XF_NPPC, 1, 256, 2, 2>(impop, awb, hist1, thresh, inputMin, inputMax, outputMin, outputMax);
    xf::cv::xf_QuatizationDithering<XF_DST_T, XF_DST_T, XF_HEIGHT, XF_WIDTH, 256, Q_VAL, XF_NPPC, XF_USE_URAM, 2, 2>(awb, qnd);
    xf::cv::xfMat2AXIvideo(qnd, m_axis_video);

}

/*********************************************************************************
 * Function:    ISPPipeline_accel
 * Parameters:  Stream of input/output pixels, image resolution
 * Return:
 * Description:
 **********************************************************************************/


void ISPPipeline_accel( unsigned int rgain,unsigned int ggain, unsigned int bgain,uint32_t  height,uint32_t width, InVideoStrm_t& s_axis_video, OutVideoStrm_t& m_axis_video,uint8_t blackLevelCorrection,uint32_t thresh,uint32_t hist[768]) {

// clang-format off
#pragma HLS INTERFACE axis port = &s_axis_video register
#pragma HLS INTERFACE axis port = &m_axis_video register
#pragma HLS INTERFACE ap_fifo port = hist depth=__XF_DEPTH_PTR



// clang-format off
#pragma HLS ARRAY_PARTITION variable = hist0 complete dim = 1
#pragma HLS ARRAY_PARTITION variable = hist1 complete dim = 1
    // clang-format on
    if (!flag) {
        ISPpipeline(s_axis_video, m_axis_video, height, width,rgain,bgain,ggain, hist0, hist1,blackLevelCorrection,thresh);
        flag = 1;
        flatten_histogram(hist1,hist);

    } else {
        ISPpipeline(s_axis_video, m_axis_video, height, width,rgain,bgain,ggain, hist1, hist0,blackLevelCorrection,thresh);
        flag = 0;
        flatten_histogram(hist0,hist);
    }
}
