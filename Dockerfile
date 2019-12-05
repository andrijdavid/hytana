FROM pytorch/manylinux-cuda101

# Install Miniconda
RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh \
  && chmod +x miniconda.sh \
  && ./miniconda.sh -b -p ~/local/miniconda \
  && rm ./miniconda.sh

# Symlink the Miniconda activation script to /activate
RUN ln -s ~/local/miniconda/bin/activate /activate
# Install PyTorch
RUN . /activate && conda install pytorch -c pytorch
RUN pip3 install auditwheel
# Download LibTorch
#RUN wget https://download.pytorch.org/libtorch/nightly/cpu/libtorch-shared-with-deps-latest.zip
#RUN unzip libtorch-shared-with-deps-latest.zip && rm libtorch-shared-with-deps-latest.zip

WORKDIR /home
