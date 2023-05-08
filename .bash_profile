# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs

PATH=/opt/python/py311/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:$PATH:$HOME/bin
export PATH

LD_LIBRARY_PATH=/opt/python/py311/lib:/usr/local/nvidia/lib:/usr/local/nvidia/lib64
export LD_LIBRARY_PATH

TERM=xterm-256color
export TERM