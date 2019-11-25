# Hytana

This is a PyTorch CUDA implementation of the HYTANA activation function.

## Installation
It is currently distributed as a source only PyTorch extension. So you need a propely set up toolchain and CUDA compilers to install.
1) _Toolchain_ - In conda the `cxx_linux-64` package provides an appropriate toolchain. However there can still be compatbility issues with this depending on system. You can also try with the system toolchian.
2) _CUDA Toolkit_ - The [nVidia CUDA Toolkit](https://developer.nvidia.com/cuda-toolkit) is required in addition to drivers to provide needed headers and tools. Get the appropriate version for your Linux distro from nVidia or check for distro specific instructions otherwise.

_It is important your CUDA Toolkit matches the version PyTorch is built for or errors can occur. Currently PyTorch builds for v10.0 and v9.2._

`pip install git+https://github.com/andrijdavid/hytana`
## Performance

```
Profiling over 10000 runs after 10 warmup runs.
Profiling on GeForce RTX 2070 SUPER
Testing on torch.float16:
                Mean    ± Std     (Min  -  Max)
 relu_fwd:      177.6µs ± 11.19µs (163.8µs - 205.2µs)
 relu_bwd:      1.801ms ± 1.066ms (292.9µs - 3.810ms)
 softplus_fwd:  268.4µs ± 18.90µs (250.2µs - 319.8µs)
 softplus_bwd:  1.781ms ± 1.028ms (369.2µs - 7.064ms)
 hytana_pt_fwd: 1.004ms ± 33.33µs (953.2µs - 1.100ms)
 hytana_pt_bwd: 1.913ms ± 839.8µs (1.034ms - 4.466ms)
 swish_pt_fwd:  652.9µs ± 16.75µs (645.1µs - 792.4µs)
 swish_pt_bwd:  2.530ms ± 930.7µs (1.431ms - 4.780ms)
 mish_pt_fwd:   692.5µs ± 1.931µs (686.1µs - 712.7µs)
 mish_pt_bwd:   2.320ms ± 899.3µs (1.267ms - 4.651ms)
 swish_fwd:     223.2µs ± 24.39µs (204.8µs - 378.8µs)
 swish_bwd:     1.757ms ± 1.103ms (256.5µs - 6.628ms)
 mish_cuda_fwd: 261.4µs ± 27.77µs (240.1µs - 428.8µs)
 mish_cuda_bwd: 1.769ms ± 1.072ms (319.5µs - 5.143ms)
 hytana_fwd:    220.0µs ± 25.59µs (200.7µs - 408.4µs)
 hytana_bwd:    1.796ms ± 1.090ms (295.6µs - 5.695ms)
Testing on torch.float32:
                Mean    ± Std     (Min  -  Max)
 relu_fwd:      228.9µs ± 1.607µs (225.7µs - 256.9µs)
 relu_bwd:      1.671ms ± 978.3µs (422.0µs - 6.027ms)
 softplus_fwd:  242.6µs ± 11.71µs (232.6µs - 285.6µs)
 softplus_bwd:  1.657ms ± 981.4µs (418.4µs - 7.081ms)
 hytana_pt_fwd: 1.470ms ± 33.19µs (1.418ms - 1.584ms)
 hytana_pt_bwd: 2.298ms ± 632.8µs (1.786ms - 4.024ms)
 swish_pt_fwd:  984.6µs ± 17.46µs (977.8µs - 1.104ms)
 swish_pt_bwd:  3.068ms ± 767.6µs (2.336ms - 6.263ms)
 mish_pt_fwd:   983.7µs ± 1.668µs (981.0µs - 1.002ms)
 mish_pt_bwd:   2.956ms ± 761.3µs (2.218ms - 4.468ms)
 swish_fwd:     245.0µs ± 24.68µs (233.3µs - 383.0µs)
 swish_bwd:     1.748ms ± 1.028ms (426.0µs - 7.153ms)
 mish_cuda_fwd: 271.3µs ± 23.89µs (256.0µs - 511.3µs)
 mish_cuda_bwd: 1.783ms ± 1.009ms (469.0µs - 7.151ms)
 hytana_fwd:    245.5µs ± 22.46µs (233.4µs - 383.0µs)
 hytana_bwd:    1.775ms ± 1.024ms (449.7µs - 5.435ms)
```

## Usage

```python
from hytana_torch import Hytana
hytana = Hytana()
```