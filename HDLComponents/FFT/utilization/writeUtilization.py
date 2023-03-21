# ----------------------------------------------------------------------------------------
# This is an auxiliary script to the report_utilization.tcl script.
# This script takes in three parameters. The first being either `fft` or `ifft`
# to specify which function to target. The latter two parameters represent the
# number of stages, and the two input parameters together represent the range of
# reports you wish to pull from the generated outputs of the Vitis tool. 
#
# For example to pull fft reports 6 through 9 you would use the following command:
# python writeUtilization.py fft 6 9
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

import xml.etree.ElementTree as ET
import sys

# This script for converting to markdown was taken from https://stackoverflow.com/a/15445930
# ---------------------------------------------Copy Start---------------------------------------------
# Generates tables for Doxygen flavored Markdown.  See the Doxygen
# documentation for details:
#   http://www.doxygen.nl/manual/markdown.html#md_tables
# Translation dictionaries for table alignment
left_rule = {'<': ':', '^': ':', '>': '-'}
right_rule = {'<': '-', '^': ':', '>': ':'}

def evalute_field(record, field_spec):
    """
    Evalute a field of a record using the type of the field_spec as a guide.
    """
    if type(field_spec) is int:
        return str(record[field_spec])
    elif type(field_spec) is str:
        return str(getattr(record, field_spec))
    else:
        return str(field_spec(record))

def table(file, records, fields, headings, alignment = None):
    """
    Generate a Doxygen-flavor Markdown table from records.

    file -- Any object with a 'write' method that takes a single string
        parameter.
    records -- Iterable.  Rows will be generated from this.
    fields -- List of fields for each row.  Each entry may be an integer,
        string or a function.  If the entry is an integer, it is assumed to be
        an index of each record.  If the entry is a string, it is assumed to be
        a field of each record.  If the entry is a function, it is called with
        the record and its return value is taken as the value of the field.
    headings -- List of column headings.
    alignment - List of pairs alignment characters.  The first of the pair
        specifies the alignment of the header, (Doxygen won't respect this, but
        it might look good, the second specifies the alignment of the cells in
        the column.

        Possible alignment characters are:
            '<' = Left align (default for cells)
            '>' = Right align
            '^' = Center (default for column headings)
    """

    num_columns = len(fields)
    assert len(headings) == num_columns

    # Compute the table cell data
    columns = [[] for i in range(num_columns)]
    for record in records:
        for i, field in enumerate(fields):
            columns[i].append(evalute_field(record, field))

    # Fill out any missing alignment characters.
    extended_align = alignment if alignment != None else []
    if len(extended_align) > num_columns:
        extended_align = extended_align[0:num_columns]
    elif len(extended_align) < num_columns:
        extended_align += [('^', '<')
                           for i in range[num_columns-len(extended_align)]]

    heading_align, cell_align = [x for x in zip(*extended_align)]

    field_widths = [len(max(column, key=len)) if len(column) > 0 else 0
                    for column in columns]
    heading_widths = [max(len(head), 2) for head in headings]
    column_widths = [max(x) for x in zip(field_widths, heading_widths)]

    _ = ' | '.join(['{:' + a + str(w) + '}'
                    for a, w in zip(heading_align, column_widths)])
    heading_template = '| ' + _ + ' |'
    _ = ' | '.join(['{:' + a + str(w) + '}'
                    for a, w in zip(cell_align, column_widths)])
    row_template = '| ' + _ + ' |'

    _ = ' | '.join([left_rule[a] + '-'*(w-2) + right_rule[a]
                    for a, w in zip(cell_align, column_widths)])
    ruling = '| ' + _ + ' |'

    file.write(heading_template.format(*headings).rstrip() + '\n')
    file.write(ruling.rstrip() + '\n')
    for row in zip(*columns):
        file.write(row_template.format(*row).rstrip() + '\n')
# ---------------------------------------------Copy End---------------------------------------------

if sys.argv[1] == "fft":
    inverse = ""
elif sys.argv[1] == "ifft":
    inverse = "i"
else:
    print("ERROR: Second argument must be either 'fft' or 'ifft'")
    quit()
# Now we pull the data from the XML reports produced by Vitis HLS
data=[]
dataline=[]
minRange = int(sys.argv[2])
maxRange = int(sys.argv[3])

for x in range(minRange, maxRange + 1):
    dataline=[]
    string = str(x) + "/syn/report/csynth.xml"
    root = ET.parse(string).getroot()
    avaliableArea = root.find('AreaEstimates/AvailableResources')
    area = root.find('AreaEstimates/Resources')
    performance = root.find('PerformanceEstimates')
    
    dataline.append(2**x)

    EstimatedClockPeriod = performance.find('SummaryOfTimingAnalysis/EstimatedClockPeriod').text
    fmax = 10**3/float(EstimatedClockPeriod)
    dataline.append(str(round(fmax, 2)))

    dataline.append(performance.find('SummaryOfOverallLatency/Average-caseLatency').text)
    dataline.append(performance.find('SummaryOfOverallLatency/Interval-max').text)

    avaliableDSP = float(avaliableArea.find('DSP').text)
    avaliableBRAM_18K = float(avaliableArea.find('BRAM_18K').text)
    avaliableLUT = float(avaliableArea.find('LUT').text)
    avaliableFF = float(avaliableArea.find('FF').text)
    
    usedDSP = float(area.find('DSP').text)
    usedBRAM_18K = float(area.find('BRAM_18K').text)
    usedLUT = float(area.find('LUT').text)
    usedFF = float(area.find('FF').text)

    percentDSP = (usedDSP/avaliableDSP) * 100
    percentBRAM_18K = (usedBRAM_18K/avaliableBRAM_18K) * 100
    percentLUT = (usedLUT/avaliableLUT) * 100
    percentFF = (usedDSP/avaliableFF) * 100

    dataline.append(area.find('DSP').text + " (" + str(round(percentDSP, 4)) + "%)")
    dataline.append(area.find('BRAM_18K').text + " (" + str(round(percentBRAM_18K, 4)) + "%)")
    dataline.append(area.find('LUT').text + " (" + str(round(percentLUT, 4)) + "%)")
    dataline.append(area.find('FF').text + " (" + str(round(percentFF, 4)) + "%)")

    data.append(dataline)
    del dataline


# Here we write the results to an output file
headings = ['Transform Size', 'fmax (MHz)', 'Average Latency (cycles)', 'Max Interval (cycles)', 'DSP', 'BRAM', 'LUT', 'FF']
fields = [0, 1, 2, 3, 4, 5, 6, 7]
align = [('^', '^'),('^', '^'),('^', '^'),('^', '^'),('^', '^'),('^', '^'),('^', '^'),('^', '^')]

f = open(f'../buildfile_{inverse}fftUtilizationTable.md', "w")
table(f, data, fields, headings, align)
f.close()
