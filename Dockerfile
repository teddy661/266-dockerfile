FROM  nvidia/cuda:11.8.0-cudnn8-devel-rockylinux8 AS build
SHELL ["/bin/bash", "-c"]
ENV PY_VERSION=3.11.3
RUN dnf update --disablerepo=cuda -y
RUN dnf install curl \
                gcc \
                cmake \
                openssl-devel \
                bzip2-devel \
                xz xz-devel \
                findutils \
                libffi-devel \
                zlib-devel \
                wget \
                make \
                ncurses ncurses-devel \
                readline-devel \
                uuid \
                tcl-devel tcl tk-devel tk \
                sqlite-devel \
                #tensorrt-8.5.3.1-1.cuda11.8 \
                gcc-toolset-11 \
                gdbm-devel gdbm -y
WORKDIR /tmp/bpython
RUN wget https://www.python.org/ftp/python/${PY_VERSION}/Python-${PY_VERSION}.tar.xz
RUN tar -xf  Python-${PY_VERSION}.tar.xz
WORKDIR /tmp/bpython/Python-${PY_VERSION}
RUN source scl_source enable gcc-toolset-11 && ./configure --enable-shared \
                --enable-optimizations \ 
                --enable-ipv6 \ 
                --with-lto=full \
                --with-ensurepip=upgrade \
                --prefix=/opt/python/py311
RUN source scl_source enable gcc-toolset-11 && make -j 8
RUN source scl_source enable gcc-toolset-11 && make install 
ENV  LD_LIBRARY_PATH=/opt/python/py311/lib:${LD_LIBRARY_PATH}
ENV  PATH=/opt/python/py311/bin:${PATH}
RUN pip3 install --upgrade pip
RUN pip3 install wheel
WORKDIR /tmp/bxgboost
RUN wget https://github.com/dmlc/xgboost/releases/download/v1.7.5/xgboost.tar.gz
RUN tar -xf xgboost.tar.gz
WORKDIR /tmp/bxgboost/xgboost
RUN mkdir build
WORKDIR /tmp/bxgboost/xgboost/build
RUN source scl_source enable gcc-toolset-11 && cmake .. -DUSE_CUDA=ON -DBUILD_WITH_CUDA_CUB=ON
RUN source scl_source enable gcc-toolset-11 && make -j 8
WORKDIR /tmp/bxgboost/xgboost/python-package
RUN python3 setup.py bdist_wheel 
##
## Production Image Below
FROM  nvidia/cuda:11.8.0-cudnn8-runtime-rockylinux8 AS prod
SHELL ["/bin/bash", "-c"]
RUN curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
RUN dnf update --disablerepo=cuda -y && \
    dnf install tensorrt-8.5.3.1-1.cuda11.8 \
                curl \
                wget \
                openssl-devel \
                openssh-server \
                openssh-clients \
                bzip2-devel bzip2 \
                xz-devel xz \
                libffi-devel \
                zlib-devel \
                ncurses ncurses-devel \
                readline-devel \
                uuid \
                tcl-devel tcl \
                tk-devel tk \
                sqlite-devel \
                graphviz \
                gdbm-devel gdbm \
                nodejs \
                procps-ng \
                findutils \
                git -y && \
    dnf clean all
RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa \
    && ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa \
    && ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa -b 521 \
    && ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -N '' -t ed25519
COPY --from=build /opt/python/py311 /opt/python/py311
COPY --from=build /tmp/bxgboost/xgboost/python-package/dist/xgboost-1.7.5-cp311-cp311-linux_x86_64.whl /tmp/xgboost-1.7.5-cp311-cp311-linux_x86_64.whl
ENV LD_LIBRARY_PATH=/opt/python/py311/lib:${LD_LIBRARY_PATH}
ENV PATH=/opt/python/py311/bin:${PATH}
ENV PYDEVD_DISABLE_FILE_VALIDATION=1
## Fix an odd bug in tensorrt
WORKDIR /usr/local/cuda-11.8/lib64
RUN ln -s libnvrtc.so.11.8.89  libnvrtc.so \
    && mkdir -p /root/.ssh && chmod 700 /root/.ssh \
    && ln  /opt/python/py311/bin/python3.11 /opt/python/py311/bin/python
RUN python3 -m pip install --no-cache-dir --upgrade pip
RUN pip install  --no-cache-dir tensorflow \
                nltk \
                ipython \
                bokeh \
                seaborn \
                aiohttp[speedups] \
                jupyterlab==3.6.3 \
                black[jupyter] \
                matplotlib \
                wheel \
                blake3 \
                papermill[all] \
                statsmodels \
                psutil \
                networkx \
                mypy \
                pandas \
                pyarrow \
                polars[all] \
                openpyxl \
                apsw \
                pydot \
                plotly \
                pydot-ng \
                pydotplus \
                graphviz \
                beautifulsoup4 \
                scikit-learn \
                scikit-image \
                sklearn-pandas \
                lxml \
                isort \
                opencv-contrib-python-headless \
                wordcloud \
                dask[complete] \
                ipyparallel \
                mlxtend \
                gensim \
                transformers \
                openai[wandb] \
                wandb \
                tiktoken \
                sentencepiece \
                ipywidgets \
                jupyter_bokeh \
                jupyter-server-proxy \
                jupyterlab-lsp==4.1.0  \
                jupyter-lsp==2.1.0 \
                pyyaml \
                yapf 
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
RUN pip install --no-cache-dir /tmp/xgboost-1.7.5-cp311-cp311-linux_x86_64.whl
RUN jupyter labextension install @jupyterlab/server-proxy Not yet supported in jupyter lab 4
WORKDIR /root
COPY . .
ENV TERM=xterm-256color
ENV SHELL=/bin/bash
CMD ["bash", "-c", "jupyter lab"]