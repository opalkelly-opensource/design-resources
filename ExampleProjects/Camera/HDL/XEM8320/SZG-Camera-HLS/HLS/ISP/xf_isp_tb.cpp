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

#include "common/xf_headers.hpp"
#include <stdio.h>
// #include "xf_isp_types.h"
#include "common/xf_axi.hpp"
#include <cstdint>
#include <iostream>
#include <fstream>
#include <strstream>
#include "xf_config_params.h"
#include "hls_stream.h"
#include "ap_int.h"
#include "common/xf_common.hpp"
#include "common/xf_utility.hpp"
#include "common/xf_infra.hpp"
#include "ap_axi_sdata.h"
#include "common/xf_axi_io.hpp"
#include "xf_config_params.h"

using namespace std;

/*********************************************************************************
 * Function:    Mat2MultiBayerAXIvideo
 * Parameters:
 * Return:
 * Description:  Currently fixed for Dual Pixel
 **********************************************************************************/
static void Mat2MultiBayerAXIvideo(cv::Mat& img, InVideoStrm_t& AXI_video_strm, unsigned char InColorFormat) {
    int i, j, k, l;
    unsigned char cv_pix;
    ap_axiu<AXI_WIDTH_IN, 1, 1, 1> axi;
    int depth = 8;

    for (i = 0; i < img.rows; i++) {
        for (j = 0; j < img.cols; j += XF_NPPC) {
            if ((i == 0) && (j == 0)) {
                axi.user = 1;
            } else {
                axi.user = 0;
            }
            if (j == (img.cols - XF_NPPC)) {
                axi.last = 1;
            } else {
                axi.last = 0;
            }
            axi.data = -1;
            for (l = 0; l < XF_NPPC; l++) {
                cv_pix = img.at<unsigned char>(i, j + l); // cvGet2D(img, i, j + l);
                switch (img.channels()) {
                    case 10:
                    case 12:
                    case 16:
                        xf::cv::AXISetBitFields(axi, (l)*depth, depth, (unsigned char)cv_pix);
                        break;
                    case CV_8U:
                    default:
                        xf::cv::AXISetBitFields(axi, (l)*depth, depth, (unsigned char)cv_pix);
                        break;
                }
            }
            axi.keep = -1;
            AXI_video_strm << axi;
        }
    }
}

/*********************************************************************************
 * Function:    MultiPixelAXIvideo2Mat
 * Parameters:  96bit stream with 4 pixels packed
 * Return:      None
 * Description: extract pixels from stream and write to open CV Image
 **********************************************************************************/
static void MultiPixelAXIvideo2Mat(OutVideoStrm_t& AXI_video_strm, cv::Mat& img, unsigned char ColorFormat) {
    int i, j, k, l;
    ap_axiu<AXI_WIDTH_OUT, 1, 1, 1> axi;
    cv::Vec3b cv_pix;
    int depth = 8;
    bool sof = 0;

    for (i = 0; i < img.rows; i++) {
        for (j = 0; j < img.cols / XF_NPPC; j++) { // 4 pixels read per iteration
            AXI_video_strm >> axi;
            if ((i == 0) && (j == 0)) {
                if (axi.user.to_int() == 1) {
                    sof = 1;
                } else {
                    j--;
                }
            }
            if (sof) {
                for (l = 0; l < XF_NPPC; l++) {
                    int num_comp =
                        ((ColorFormat == 0) || (ColorFormat == 1) || (ColorFormat == 4)) ? (img.channels()) : 2;
                    for (k = 0; k < num_comp; k++) {
#if XF_AXI_GBR == 1
                        const int mapComp[5][3] = {
                            {1, 0, 2}, // RGB  //GBR
                            {0, 1, 2}, // 4:4:4
                            {0, 1, 1}, // 4:2:2
                            {0, 1, 1}, // 4:2:0
                            {1, 0, 2},
                        }; // 4:2:0 HDMI
#else
                        const int mapComp[5][3] = {
                            {0, 1, 2}, // RGB  //GBR
                            {0, 1, 2}, // 4:4:4
                            {0, 1, 1}, // 4:2:2
                            {0, 1, 1}, // 4:2:0
                            {1, 0, 2},
                        }; // 4:2:0 HDMI
#endif
                        int kMap = mapComp[ColorFormat][k];
                        switch (depth) {
                            case 10:
                            case 12:
                            case 16: {
                                unsigned short temp;
                                xf::cv::AXIGetBitFields(axi, (kMap + l * num_comp) * depth, depth, temp);
                                cv_pix.val[k] = temp;
                            } break;
                            case CV_8U:
                            default: {
                                unsigned char temp;
                                xf::cv::AXIGetBitFields(axi, (kMap + l * num_comp) * depth, depth, temp);
                                cv_pix.val[k] = temp;
                            } break;
                        }
                    }
                    // cvSet2D(img, i, (XF_NPPC * j + l), cv_pix); // write p0
                    img.at<cv::Vec3b>(i, (XF_NPPC * j + l)) = cv_pix;
                }
            } // if(sof)
        }
    }
}

int main(int argc, char** argv) {
    cv::Mat raw_input, final_output;

    InVideoStrm_t src_axi;
    OutVideoStrm_t dst_axi;
    int result = 0;
    unsigned char InColorFormat = 4;
    // CvSize imgSize;
    cv::Size imgSize;
    int nrFrames = 1;
    // read input image
    raw_input = cv::imread(argv[1],0);
    final_output.create(raw_input.rows, raw_input.cols, CV_8UC3);
    // unsigned int hist[256];
    imwrite("input.png", raw_input);
    uint32_t hist[768];
    for(int i=0;i<768;i++){
            hist[i]=0;}
    uint32_t row=raw_input.rows;
    uint32_t col=raw_input.cols;
    for (int i = 0; i < 2; i++) {
        Mat2MultiBayerAXIvideo(raw_input, src_axi, InColorFormat);
    //     // Call IP Processing function
        ISPPipeline_accel(100,100,100,row,col, src_axi, dst_axi,2,127,hist);
        for(int i=0;i<768;i++){
            printf("%u, ",hist[i]);}
        printf("\n");
        MultiPixelAXIvideo2Mat(dst_axi, final_output, InColorFormat);
    }

    imwrite("output.png", final_output);
    return 0;
}