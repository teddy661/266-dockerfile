#!/bin/bash 

. /opt/intel/oneapi/setvars.sh
. /app/venv/bin/activate
exec "$@"
