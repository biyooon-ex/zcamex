#!/bin/sh

#
# set variables
#
: ${MEC_BACKEND:="localhost"}
: ${CLOUD_BACKEND:="localhost"}

#
# start phoenix server
#
echo "exec:
MEC_BACKEND=\"${MEC_BACKEND}\" CLOUD_BACKEND=\"${CLOUD_BACKEND}\" mix phx.server
"

MEC_BACKEND="${MEC_BACKEND}" CLOUD_BACKEND="${CLOUD_BACKEND}" mix phx.server
