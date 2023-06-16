##
## Production Image Below
FROM  nvidia/cuda:11.8.0-cudnn8-runtime-rockylinux8 AS prod
SHELL ["/bin/bash", "-c"]
RUN curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
## 
## TensorRT drags in a bunch of dependencies that we don't need
## tried replacing it with lean runtime, but that didn't work
RUN dnf update --disablerepo=cuda -y && \
    dnf install \
                #tensorrt-8.6.0.12-1.cuda11.8 \
                tensorrt-8.5.3.1-1.cuda11.8 \
                unzip \
                curl \
                wget \
                libcurl-devel \
                gettext-devel \
                expat-devel \
                openssl-devel \
                openssh-server \
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
                findutils -y && \
    dnf clean all
RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa \
    && ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa \
    && ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa -b 521 \
    && ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -N '' -t ed25519
COPY --from=ebrown/python:3.11 /opt/python/py311 /opt/python/py311
COPY --from=ebrown/git:2.41.0 /opt/git /opt/git
COPY --from=ebrown/xgboost:1.7.5 /tmp/bxgboost/xgboost/python-package/dist/xgboost-1.7.5-cp311-cp311-linux_x86_64.whl /tmp/xgboost-1.7.5-cp311-cp311-linux_x86_64.whl
ENV LD_LIBRARY_PATH=/opt/python/py311/lib:${LD_LIBRARY_PATH}
ENV PATH=/opt/git/bin:/opt/python/py311/bin:${PATH}
ENV PYDEVD_DISABLE_FILE_VALIDATION=1
## Fix an odd bug in tensorrt
WORKDIR /usr/local/cuda-11.8/lib64
RUN ln -s libnvrtc.so.11.8.89  libnvrtc.so \
    && mkdir -p /root/.ssh && chmod 700 /root/.ssh \
    && ln  /opt/python/py311/bin/python3.11 /opt/python/py311/bin/python \
    && ln /opt/python/py311/bin/pip3 /opt/python/py311/bin/pip
RUN python3 -m pip install --no-cache-dir --upgrade pip
RUN pip3 install --no-cache-dir \
                certifi \
                networkx \
                Pillow 
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
RUN pip3 install --no-cache-dir /tmp/xgboost-1.7.5-cp311-cp311-linux_x86_64.whl
RUN pip3 install --no-cache-dir \
                # tensorflow requires numpy < 1.24
                # update to pandas-stubs requires numpy > 1.24
                tensorflow \
                tensorflow-text \
                tensorflow-datasets \
                keras-nlp \
                spacy \
                spacy-lookups-data \
                sentence-transformers \
                datasets \
                numba \
                nltk \
                ipython \
                bokeh \
                seaborn \
                aiohttp[speedups] \
                jupyterlab==3.6.4 \
                black[jupyter] \
                matplotlib \
                wheel \
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
                jupyterlab-lsp==4.2.0  \
                jupyter-lsp==2.2.0 \
                python-lsp-server[all] \
                pyyaml \
                yapf \
                nbqa \
                ruff \
                ploomber \
                evaluate \
                rouge_score \
                pipdeptree
RUN jupyter labextension install @jupyterlab/server-proxy
WORKDIR /root
COPY . .
ENV TERM=xterm-256color
ENV SHELL=/bin/bash
CMD ["bash", "-c", "jupyter lab"]