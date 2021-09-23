// Vivado HLS FIR Filter
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

#include "fir.h"

void fir(inp_data_t *A, out_data_t *B) {
#pragma HLS INTERFACE axis port = A
#pragma HLS INTERFACE axis port = B
	static inp_data_t shift_reg[N];

	acc_t acc = 0;
	acc_t mult;

	for (int i = N - 1; i >= 0; i--) {
		if (i == 0) {
			shift_reg[0] = *A;
		} else {
			shift_reg[i] = shift_reg[i - 1];
		}
		mult = shift_reg[i] * c[i];
		acc += mult;
	}

	*B = (out_data_t) acc;
}
