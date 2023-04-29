FROM  nvidia/cuda:11.8.0-cudnn8-devel-rockylinux8 AS build
ENV PY_VERSION=3.11.3
RUN dnf update --disablerepo=cuda -y
RUN dnf install curl \
                gcc \
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
                gdbm-devel gdbm -y
WORKDIR /tmp/bpython
RUN wget https://www.python.org/ftp/python/${PY_VERSION}/Python-${PY_VERSION}.tar.xz
RUN tar -xf  Python-${PY_VERSION}.tar.xz
WORKDIR /tmp/bpython/Python-${PY_VERSION}
RUN ./configure --enable-shared \
                --enable-optimizations \ 
                --enable-ipv6 \ 
                --with-lto=full \
                --with-ensurepip=upgrade \
                --prefix=/opt/python/py311
RUN make -j 4
RUN make install 
ENV  LD_LIBRARY_PATH=/opt/python/py311/lib:${LD_LIBRARY_PATH}
ENV  PATH=/opt/python/py311/bin:${PATH}
##
## Production Image Below
FROM  nvidia/cuda:11.8.0-cudnn8-runtime-rockylinux8 AS prod
RUN curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
RUN dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y &&\
    dnf update --disablerepo=cuda -y && \
    dnf install tensorrt-8.5.3.1-1.cuda11.8 \
                curl \
                wget \
                openssl-devel \
                bzip2-devel \
                xz-devel xz \
                libffi-devel \
                zlib-devel \
                ncurses ncurses-devel \
                readline-devel \
                uuid \
                tcl-devel tcl \
                sqlite-devel \
                graphviz \
                gdbm-devel gdbm \
                nodejs \
                neovim -y && \
    dnf clean all
COPY --from=build /opt/python/py311 /opt/python/py311
ENV  LD_LIBRARY_PATH=/opt/python/py311/lib:${LD_LIBRARY_PATH}
ENV  PATH=/opt/python/py311/bin:${PATH}
RUN python3 -m pip install --no-cache-dir --upgrade pip
RUN pip install  --no-cache-dir tensorflow \
                nltk \
                ipython \
                bokeh \
                seaborn \
                aiohttp[speedups] \
                jupyterlab \
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
                isort
CMD ["bash", "-c", "source /etc/bash.bashrc && jupyter lab --notebook-dir=/tf --ip 0.0.0.0 --no-browser --allow-root"]