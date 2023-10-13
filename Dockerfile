##
## Production Image Below
FROM ebrown/python:3.11 as built_python
FROM ebrown/git:latest as built_git
FROM ebrown/xgboost:1.7.6 as built_xgboost
FROM nvidia/cuda:11.8.0-cudnn8-runtime-rockylinux8 AS prod
SHELL ["/bin/bash", "-c"]
## 
## TensorRT drags in a bunch of dependencies that we don't need
## tried replacing it with lean runtime, but that didn't work
## The below code appears to resolve that issue.
##
RUN dnf update --disablerepo=cuda -y && \
    dnf install \
                # tensorrt-8.6.0.12-1.cuda11.8 \
                cuda-command-line-tools-11-8 \
                cuda-cudart-devel-11-8 \
                cuda-nvcc-11-8 \
                cuda-cupti-11-8 \
                cuda-nvprune-11-8 \
                cuda-nvrtc-11-8 \
                libnvinfer-plugin8-8.6.0.12-1.cuda11.8 \
                libnvinfer8-8.6.0.12-1.cuda11.8 \
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
                uuid \
                tcl-devel tcl \
                tk-devel tk \
                sqlite-devel \
                graphviz \
                gdbm-devel gdbm \
                procps-ng \
                findutils -y && \
    dnf clean all
WORKDIR /opt/nodejs
RUN curl https://nodejs.org/dist/v18.18.0/node-v18.18.0-linux-x64.tar.xz | xzcat | tar -xf -
ENV PATH=/opt/nodejs/node-v18.18.0-linux-x64/bin:${PATH}
RUN npm install -g npm && \
    npm install -g yarn
RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa \
    && ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa \
    && ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa -b 521 \
    && ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -N '' -t ed25519
COPY --from=built_python /opt/python/py311 /opt/python/py311
COPY --from=built_git /opt/git /opt/git
COPY --from=built_xgboost /tmp/bxgboost/xgboost/python-package/dist/xgboost-1.7.6-cp311-cp311-linux_x86_64.whl /tmp/xgboost-1.7.6-cp311-cp311-linux_x86_64.whl
ENV LD_LIBRARY_PATH=/opt/python/py311/lib:${LD_LIBRARY_PATH}
ENV PATH=/opt/git/bin:/opt/python/py311/bin:${PATH}
ENV PYDEVD_DISABLE_FILE_VALIDATION=1
## Fix an odd bug in tensorrt
WORKDIR /usr/local/cuda-11.8/lib64
RUN ln -s libnvrtc.so.11.8.89  libnvrtc.so \
    && mkdir -p /root/.ssh && chmod 700 /root/.ssh 
RUN python3 -m pip install --no-cache-dir --upgrade pip
RUN pip3 install --no-cache-dir \
                certifi \
                networkx \
                Pillow \
                numpy==1.26.0 \
                bottleneck \
                cmake 
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
RUN pip3 install --no-cache-dir /tmp/xgboost-1.7.6-cp311-cp311-linux_x86_64.whl
RUN pip3 install --no-cache-dir \
                # tensorflow requires numpy <= 1.24.3
                # update to pandas-stubs requires numpy > 1.24
                tensorflow==2.14.0 \
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
                jupyterlab \
                black[jupyter] \
                matplotlib \
                blake3 \
                papermill[all] \
                statsmodels \
                psutil \
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
                jupyter_http_over_ws \
                jupyter-collaboration \
                pyyaml \
                yapf \
                nbqa[toolchain] \
                ruff \
#                ploomber \
                evaluate[template] \
                pipdeptree \
                hydra-core
WORKDIR /root
COPY . .
ENV TERM=xterm-256color
ENV SHELL=/bin/bash
CMD ["bash", "-c", "jupyter lab"]