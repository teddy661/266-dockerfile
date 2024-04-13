# .bashrc

# User specific aliases and functions

# alias rm='rm -i' # been running with scissors for 40 years only stabbed myself once don't need these
# alias cp='cp -i'
# alias mv='mv -i'

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi
. /opt/intel/oneapi/setvars.sh
source "$HOME/.cargo/env"
