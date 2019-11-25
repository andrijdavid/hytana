#include <torch/types.h>

#ifdef __CUDACC__
#include <cuda_runtime.h>
#include <c10/util/Half.h>
#define GLOBAL_INLINE __forceinline__ __host__ __device__
#else
#include <cmath>
#define GLOBAL_INLINE __inline__
#endif

#define ALPHA 0.303
#define BETA 0.632

template <typename scalar_t>
GLOBAL_INLINE scalar_t sech(const scalar_t z) {
   return 1.0 / cosh(z);
}

template <typename scalar_t>
GLOBAL_INLINE scalar_t sigmoid(const scalar_t z) {
   return 1.0 / (1 + exp(-z);
}

template <typename scalar_t>
GLOBAL_INLINE
void hytana_fwd_func(scalar_t &out, const scalar_t &inp) {
  out = inp/2 * (1 + tanh(scalar_t(ALPHA) + (scalar_t(BETA) * inp)));
};

template <typename scalar_t>
GLOBAL_INLINE
void hytana_bwd_func(scalar_t &grad_inp, const scalar_t &inp, const scalar_t &grad_out) {
  const scalar_t in = scalar_t(ALPHA) + ( scalar_t(BETA) * inp);
  const scalar_t grad_tsp = sech(in);
  const scalar_t grad = tanh(in) + (scalar_t(BETA) * inp * grad_tsp * grad_tsp) + 1;
  grad_inp = grad_out * grad / 2;
};