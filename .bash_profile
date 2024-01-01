# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs

PATH=/opt/git/bin:/opt/python/py311/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}:${HOME}/bin
export PATH

LD_LIBRARY_PATH=/opt/python/py311/lib:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH

PYDEVD_DISABLE_FILE_VALIDATION=1
export PYDEVD_DISABLE_FILE_VALIDATION

TERM=xterm-256color
export TERM
