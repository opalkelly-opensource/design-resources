Utilization
===========
The provided `reportUtilization.tcl` script is used to generate designs of varying sizes. It then calls
the `writeUtilization.py` script to parse the Vitis HLS generated XML reports and formats the performance
and utilization metrics into a markdown table format.

This script takes in three parameters. The first being either `fft` or `ifft` to specify which function to
target. The latter two parameters represent the number of stages, and the two input
parameters together represent the range of reports you wish to generate from Vitis HLS.

For example to generate reports for the fft with a transform size 4 (2 stages) through 32768 (15 stages) you
would use the following command:

`vitis_hls -f reportUtilization.tcl fft 2 15`

The `reportUtilization.tcl` synthesizes reports targeting the Artix UltraScale+ AU25P chip. The reported
percentages of utilization are calculated from the total number of available resources for the `xcau25p-ffvb676-2-e`
part:

|    DSP    |    BRAM    |   LUT   |     FF     |
| :-------: | :--------: | :-----: | :--------: |
|   1200    |     600    | 141000  |   282000   |

The resulting markdown tables are shown below built using Vivado and Vitis_HLS 2022.2:

## FFT
| Transform Size | fmax (MHz) | Average Latency (cycles) | Max Interval (cycles) |      DSP      |      BRAM      |      LUT       |       FF       |
| :------------: | :--------: | :----------------------: | :-------------------: | :-----------: | :------------: | :------------: | :------------: |
|       4        |   453.1    |            22            |           9           |  4 (0.3333%)  |    0 (0.0%)    | 796 (0.5645%)  | 836 (0.0014%)  |
|       8        |   451.06   |            45            |          11           |  8 (0.6667%)  |    0 (0.0%)    | 1271 (0.9014%) | 1423 (0.0028%) |
|       16       |   440.33   |            88            |          16           |   12 (1.0%)   |    0 (0.0%)    | 1804 (1.2794%) | 2059 (0.0043%) |
|       32       |   443.46   |           175            |          32           | 16 (1.3333%)  |    0 (0.0%)    | 2415 (1.7128%) | 2723 (0.0057%) |
|       64       |   297.8    |           358            |          64           | 20 (1.6667%)  |  44 (7.3333%)  | 2777 (1.9695%) | 2447 (0.0071%) |
|      128       |   297.8    |           749            |          128          |   24 (2.0%)   | 68 (11.3333%)  | 3129 (2.2191%) | 2635 (0.0085%) |
|      256       |   297.8    |           1588           |          256          | 28 (2.3333%)  |   78 (13.0%)   | 3635 (2.578%)  | 3122 (0.0099%) |
|      512       |   297.8    |           3387           |          512          | 32 (2.6667%)  | 88 (14.6667%)  | 4152 (2.9447%) | 3593 (0.0113%) |
|      1024      |   297.8    |           7234           |         1024          |   36 (3.0%)   | 98 (16.3333%)  | 4684 (3.322%)  | 4106 (0.0128%) |
|      2048      |   297.8    |          15440           |         2048          | 40 (3.3333%)  |  156 (26.0%)   | 5241 (3.717%)  | 5375 (0.0142%) |
|      4096      |   297.8    |          32856           |         4096          | 44 (3.6667%)  | 328 (54.6667%) | 5805 (4.117%)  | 6058 (0.0156%) |
|      8192      |   297.8    |          69728           |         8192          |   48 (4.0%)   |  708 (118.0%)  | 6380 (4.5248%) | 6764 (0.017%)  |
|     16384      |   297.8    |          147550          |         16384         | 52 (4.3333%)  | 1584 (264.0%)  | 7912 (5.6113%) | 6531 (0.0184%) |
|     32768      |   141.0    |          311364          |         32768         | 100 (8.3333%) | 3384 (564.0%)  | 8559 (6.0702%) | 3995 (0.0355%) |

## IFFT
| Transform Size | fmax (MHz) | Average Latency (cycles) | Max Interval (cycles) |      DSP      |      BRAM      |      LUT       |       FF       |
| :------------: | :--------: | :----------------------: | :-------------------: | :-----------: | :------------: | :------------: | :------------: |
|       4        |   453.1    |            22            |           9           |  4 (0.3333%)  |    0 (0.0%)    | 796 (0.5645%)  | 836 (0.0014%)  |
|       8        |   451.06   |            45            |          11           |  8 (0.6667%)  |    0 (0.0%)    | 1271 (0.9014%) | 1423 (0.0028%) |
|       16       |   440.33   |            88            |          16           |   12 (1.0%)   |    0 (0.0%)    | 1804 (1.2794%) | 2059 (0.0043%) |
|       32       |   443.46   |           175            |          32           | 16 (1.3333%)  |    0 (0.0%)    | 2415 (1.7128%) | 2723 (0.0057%) |
|       64       |   297.8    |           358            |          64           | 20 (1.6667%)  |  44 (7.3333%)  | 2777 (1.9695%) | 2447 (0.0071%) |
|      128       |   297.8    |           749            |          128          |   24 (2.0%)   | 68 (11.3333%)  | 3129 (2.2191%) | 2635 (0.0085%) |
|      256       |   297.8    |           1588           |          256          | 28 (2.3333%)  |   78 (13.0%)   | 3635 (2.578%)  | 3122 (0.0099%) |
|      512       |   297.8    |           3387           |          512          | 32 (2.6667%)  | 88 (14.6667%)  | 4152 (2.9447%) | 3593 (0.0113%) |
|      1024      |   297.8    |           7234           |         1024          |   36 (3.0%)   | 98 (16.3333%)  | 4684 (3.322%)  | 4106 (0.0128%) |
|      2048      |   297.8    |          15440           |         2048          | 40 (3.3333%)  |  156 (26.0%)   | 5241 (3.717%)  | 5375 (0.0142%) |
|      4096      |   297.8    |          32856           |         4096          | 44 (3.6667%)  | 328 (54.6667%) | 5805 (4.117%)  | 6058 (0.0156%) |
|      8192      |   297.8    |          69728           |         8192          |   48 (4.0%)   |  708 (118.0%)  | 6380 (4.5248%) | 6764 (0.017%)  |
|     16384      |   297.8    |          147550          |         16384         | 52 (4.3333%)  | 1584 (264.0%)  | 7912 (5.6113%) | 6531 (0.0184%) |
|     32768      |   141.0    |          311364          |         32768         | 100 (8.3333%) | 3384 (564.0%)  | 8559 (6.0702%) | 3995 (0.0355%) |

## Analysis
We compare the utilization of our FFT library to that of AMD-Xilinx's. We compare against [AMD-Xilinx's](https://www.xilinx.com/htmldocs/ip_docs/pru_files/xfft.html) 
FFT IP's [Pipelined Streaming I/O architecture](https://docs.xilinx.com/r/en-US/pg109-xfft/Pipelined-Streaming-I/O). We generate the core for a comparable design in
Vivado 2022.2 and inspect the utilization. We generate the IP Core with the following parameters, which mimic the configuration for our core when generating
the utilization report tables listed above:
|        Parameter        |           Value          |
|:-----------------------:|:------------------------:|
|   **Transform Length**  |           1024           |
| **Architecture Choice** | Pipelined, Streaming I/O |
|     **Data Format**     |        Fixed Point       |
|   **Scaling Options**   |         Unscaled         |
| **Input Data Width**    |            14            |
| **Phase Factor Width**  |            18            |
| **Output Ordering**     |       Natural Order      |

### Utilization Comparison
| Resource | Opal Kelly | AMD-Xilinx |
|:--------:|:----------:|:------:|
|  **LUT** |    4736    |  2479  |
|  **FF**  |    4008    |  4687  |
|  **DSP** |     34     |   21   |
| **BRAM** |     104    |    7   |

The high use of BRAM is likely a result of our DATAFLOW and PIPELINE #PRAGMAs which result in optimizations
for pipelining. A step to reduce BRAM usage would be to eliminate the multiple pipeline copies of the
full range of twiddle factor constants used by the DIF algorithm. It is in the nature of the algorithm
that any subsequent butterfly stage only uses half the range of twiddle factor constants from the stage
before it. This optimization would cut 4/5ths of our current BRAM usage for twiddle factor constants
for a 1024 bin FFT. Although this may only account for a small portion of the total BRAM usage. A deeper
investigation would be required to rectify this issue.

### Performance Comparison
|         Metic         | Opal Kelly | AMD-Xilinx |
|:---------------------:|:----------:|:--------:|
|     **fmax (MHz)**    |    297.8   | ~600   |
|  **Latency (cycles)** |    7234    | 3192   |
| **Interval (cycles)** |    1024    | 1024   |

Vitis HLS reports that our implementation has an Fmax of 297.8 Mhz, while AMD-Xilinx reports an Fmax of ~600 Mhz. 
The Fmax relates to the MSPS speed of ADC that can be used with either core. You can use a ~300 MSPS ADC 
with our implementation, while you could use a ~600 MSPS ADC with AMD-Xilinx’s.
