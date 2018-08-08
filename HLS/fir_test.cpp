// Vivado HLS FIR Filter Test
//
// This design is based heavily on the Xilinx HLS FIR example.
//
//------------------------------------------------------------------------
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// 
//------------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include "fir.h"

#define SAMPLES 4410 // Only test 0.1s worth to keep cosim short

#define DATA_DIR "../../../../../octave/"

int main() {
	inp_data_t signal[SAMPLES];
	out_data_t output[SAMPLES], reference[SAMPLES];

	FILE *input_f, *out_ref_f, *sim_out_f;
	int i, ret_value;
	float input, ref;
	float diff, tot_diff;

	tot_diff = 0;

	input_f = fopen(DATA_DIR"input.dat", "r");
	if (input_f == NULL) {
		printf("Failed to open input data!\n");
		return -1;
	}

	out_ref_f = fopen(DATA_DIR"output.dat", "r");
	if (out_ref_f == NULL) {
		printf("Failed to open output reference file!\n");
		return -1;
	}

	sim_out_f = fopen(DATA_DIR"sim_out.dat", "w");
	if (sim_out_f == NULL) {
		printf("Failed to open simulation output file!\n");
		return -1;
	}

	for (i = 0; i < SAMPLES; i++) {
		fscanf(input_f, "%f\n", &input);
		signal[i] = input;

		fscanf(out_ref_f, "%f\n", &ref);
		reference[i] = ref;
	}
	fclose(input_f);
	fclose(out_ref_f);

	// Call design under test
	for (i = 0; i < SAMPLES; i++) {
		fir(&signal[i], &output[i]);
	}

	// Check results
	for (i = 0; i < SAMPLES; i++) {
		diff = output[i].to_double() - reference[i].to_double();

		fprintf(sim_out_f, "%f\n", output[i].to_double());

		if ((i < 16) || (i > SAMPLES-16)) {
			printf(
				"output[%4d]=%10.5f \t reference[%4d]=%10.5f\n",
				i,
				output[i].to_double(),
				i,
				reference[i].to_double()
			);
		}
		diff = fabs(diff);
		tot_diff += diff;
	}
	printf("TOTAL ERROR = %f\n", tot_diff);

	fclose(sim_out_f);

	if (tot_diff < 10.0) {
		printf("\nTEST PASSED!\n");
		ret_value = 0;
	} else {
		printf("\nTEST FAILED!\n");
		ret_value = 1;
	}
	return ret_value;
}
