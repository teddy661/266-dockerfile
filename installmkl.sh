#!/bin/bash

tee > /tmp/oneAPI.repo << EOF
[oneAPI]
name=Intel® oneAPI repository
baseurl=https://yum.repos.intel.com/oneapi
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
EOF
mv /tmp/oneAPI.repo /etc/yum.repos.d
# dnf install xsimd-devel intel-oneapi-mkl.x86_64 -y 
dnf install intel-oneapi-mkl.x86_64 -y && dnf clean all
source /opt/intel/oneapi/setvars.sh
cd /tmp
python -m pip install --upgrade pip
