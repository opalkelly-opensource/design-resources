# ----------------------------------------------------------------------------------------
# This Python script is used to generate the expected testbench data.
# It takes one parameter, which is the log2(transform size).
#
# For example to generate expected testbench data an fft with a transform size of
# 32768 (15 stages), you would use the following command:
# `python genTBData.py 15`
#
# ----------------------------------------------------------------------------------------
# Copyright (c) 2023 Opal Kelly Incorporated
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# ----------------------------------------------------------------------------------------

import sys
import numpy

try:
    numStages = int(sys.argv[1])
except ValueError:
    print("Please input an integer.")
    quit()

frequencyBinLength = 2**int(numStages)

# Create test data files
inputRealValues   = numpy.array([numpy.random.uniform(-1,1) for i in range(frequencyBinLength)])
numpy.savetxt("inputRealValues.txt", inputRealValues, "%f")

outputExpectedComplexValues = numpy.fft.fft(inputRealValues)
numpy.savetxt("outputExpectedComplexValues.txt", outputExpectedComplexValues, "%f %f")

print("Expected test data generated successfully.")
