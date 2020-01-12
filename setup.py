from setuptools import setup, find_packages
from torch.utils.cpp_extension import BuildExtension, CUDAExtension
import sys

EXT_SRCS = [
    'csrc/hytana_cuda.cpp',
    'csrc/hytana_cpu.cpp',
    'csrc/hytana_kernel.cu',
]
 
if sys.platform.startswith("linux"):
    ext_modules= [
        CUDAExtension(
            'hytana_torch._C',
            EXT_SRCS,
            extra_compile_args={
                'cxx': [],
                'nvcc': ['--expt-extended-lambda', '--use_fast_math']
            },
            include_dirs=['external']
        )
    ]
    cmdclass = {
        'build_ext': BuildExtension
   }
else:
    cmdclass = {}
    ext_modules = []

setup(
    name='hytana_torch',
    version='0.0.1a',
    packages=find_packages('src'),
    package_dir={'': 'src'},
    include_package_data=True,
    zip_safe=False,
    install_requires=['torch>=1.2'],
    ext_modules=ext_modules,
    cmdclass=cmdclass
)
