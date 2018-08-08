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

#ifndef _H_FIR_H_
#define _H_FIR_H_

#define N 16

#define DB_FIXED_POINT

#ifdef DB_FIXED_POINT
#include "ap_fixed.h"

typedef ap_fixed<18,2>	coef_t;
typedef ap_fixed<48,12>	out_data_t;
typedef ap_fixed<18,2>	inp_data_t;
typedef ap_fixed<48,12>	acc_t;

// Coefficients for a basic 8kHz low pass filter, assuming a sample rate
// of 44.1kHz.
const coef_t c[N] = {
	0.042153588198237606,
	0.09254487085124112,
	0.08627292857696542,
	-0.0066099899662500515,
	-0.09647274861311855,
	-0.03655279492291376,
	0.1889147108950072,
	0.4024647831036765,
	0.4024647831036765,
	0.1889147108950072,
	-0.03655279492291376,
	-0.09647274861311855,
	-0.0066099899662500515,
	0.08627292857696542,
	0.09254487085124112,
	0.042153588198237606
};

#else
typedef           int coef_t;
typedef long long int out_data_t;
typedef           int inp_data_t;
typedef long long int acc_t;

#endif

void fir(inp_data_t *A, out_data_t *B);

#endif // _H_FIR_H_
