##
## Production Image Below
FROM ebrown/python:3.11 as built_python
FROM ebrown/git:latest as built_git
FROM ebrown/xgboost:2.0.3 as built_xgboost
FROM nvidia/cuda:12.2.2-cudnn8-runtime-rockylinux8 AS base
SHELL ["/bin/bash", "-c"]
## 
## TensorRT drags in a bunch of dependencies that we don't need
## tried replacing it with lean runtime, but that didn't work
## The below code appears to resolve that issue.
##
RUN yum install dnf-plugins-core -y && \
    dnf install epel-release -y && \
    /usr/bin/crb enable -y && \
    dnf --disablerepo=cuda update -y && \
    dnf install \
                # tensorrt-8.6.0.12-1.cuda11.8 \
                cuda-command-line-tools-12-2-12.2.2-1 \
                cuda-cudart-devel-12-2-12.2.140-1 \
                cuda-nvcc-12-2-12.2.140-1 \
                cuda-cupti-12-2-12.2.142-1 \
                cuda-nvprune-12-2-12.2.140-1 \
                cuda-nvrtc-12-2-12.2.140-1 \
                libnvinfer-plugin8-8.6.1.6-1.cuda12.0 \
                libnvinfer8-8.6.1.6-1.cuda12.0 \
                unzip \
                curl \
                wget \
                libcurl-devel \
                gettext-devel \
                expat-devel \
                openssl-devel \
                openssh-server \
                openssh-clients \
                bzip2-devel bzip2 \
                xz-devel xz \
                libffi-devel \
                zlib-devel \
                ncurses ncurses-devel \
                readline-devel \
                libgfortran \
                uuid uuid-devel \
                tcl-devel tcl\
                tk-devel tk\
                sqlite-devel \
                graphviz \
                gdbm-devel gdbm \
                procps-ng \
                findutils -y && \
                dnf clean all;
ARG INSTALL_NODE_VERSION=20.10.0
RUN mkdir /opt/nodejs && \
    cd /opt/nodejs && \
    curl -L https://nodejs.org/dist/v${INSTALL_NODE_VERSION}/node-v${INSTALL_NODE_VERSION}-linux-x64.tar.xz | xzcat | tar -xf - && \
        PATH=/opt/nodejs/node-v${INSTALL_NODE_VERSION}-linux-x64/bin:${PATH} && \
        npm install -g npm && npm install -g yarn
RUN mkdir /opt/nvim && \
    cd /opt/nvim && \
    curl -L https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.tar.gz | tar -zxf - 
ENV PATH=/opt/nodejs/node-v${INSTALL_NODE_VERSION}-linux-x64/bin:/opt/nvim/nvim-linux64/bin:${PATH}
RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa \
    && ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa \
    && ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa -b 521 \
    && ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -N '' -t ed25519
COPY --from=built_python /opt/python/py311 /opt/python/py311
COPY --from=built_git /opt/git /opt/git
ARG XGB_VERSION=2.0.3
COPY --from=built_xgboost /tmp/bxgboost/xgboost-${XGB_VERSION}/xgboost-${XGB_VERSION}-py3-none-linux_x86_64.whl /tmp/xgboost-${XGB_VERSION}-py3-none-linux_x86_64.whl
ENV LD_LIBRARY_PATH=/opt/python/py311/lib:${LD_LIBRARY_PATH}
ENV PATH=/opt/git/bin:/opt/python/py311/bin:${PATH}
ENV PYDEVD_DISABLE_FILE_VALIDATION=1
WORKDIR /tmp
COPY installmkl.sh ./installmkl.sh
COPY numpy-1.26.2-cp311-cp311-linux_x86_64.whl ./numpy-1.26.2-cp311-cp311-linux_x86_64.whl
COPY scipy-1.11.4-cp311-cp311-linux_x86_64.whl ./scipy-1.11.4-cp311-cp311-linux_x86_64.whl
RUN ./installmkl.sh
RUN pip3 install --no-cache-dir /tmp/numpy-1.26.2-cp311-cp311-linux_x86_64.whl /tmp/scipy-1.11.4-cp311-cp311-linux_x86_64.whl /tmp/xgboost-${XGB_VERSION}-py3-none-linux_x86_64.whl
RUN pip3 install --no-cache-dir \
                tensorflow==2.15.0.post1 \
                Pillow \
                tensorflow-text \
                tensorflow-datasets \
                keras-nlp \
                spacy \
                spacy-lookups-data \
                sentence-transformers \
                #Pin datasets to 2.10.0 becuase of bug in evaluate
                datasets==2.10.0 \
                git+https://github.com/google-research/bleurt.git \
                nltk \
                ipython \
                bokeh \
                seaborn \
                aiohttp[speedups] \
                jupyterlab>=4.0.9 \
                jupyterlab-lsp==5.0.1 \
                jupyter-lsp==2.2.1 \
                jupyter_server \
                black[jupyter] \
                matplotlib \
                blake3 \
                papermill[all] \
                statsmodels \
                psutil \
                mypy \
                "pandas[performance, excel, computation, plot, output_formatting, html, parquet, hdf5]" \
                tables \
                pyarrow \
                "polars[all]" \
                openpyxl \
                apsw \
                pydot \
                plotly \
                pydot-ng \
                pydotplus \
                graphviz \
                beautifulsoup4 \
                scikit-learn-intelex \
                scikit-learn \
                scikit-image \
                sklearn-pandas \
                lxml \
                isort \
                opencv-contrib-python-headless \
                ipyparallel \
                mlxtend \
                gensim \
                transformers \
                openai \
                wandb \
                tiktoken \
                sentencepiece \
                ipywidgets \
                jupyter_bokeh \
                jupyter-server-proxy \
                jupyter_http_over_ws \
                jupyter-collaboration \
                pyyaml \
                yapf \
                nbqa[toolchain] \
                ruff \
                evaluate[template] \
                pipdeptree \
                hydra-core \
                bottleneck \ 
                pytest \
                zstandard \
                cloudpickle \
                connectorx \
                deltalake \
                gevent \
                xlsx2csv \
                sqlalchemy 

WORKDIR /root
COPY . .
COPY entrypoint.sh /usr/local/bin
RUN chmod 755 /usr/local/bin/entrypoint.sh
ENV TERM=xterm-256color
ENV SHELL=/bin/bash
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash", "-c", "jupyter lab"]