#!/bin/sh

#
# set variables
#
: ${MEC_HTTP_BACKEND_URL:="http://localhost:4444/echo"}
: ${CLOUD_HTTP_BACKEND_URL:="http://localhost:4444/echo"}

#
# start phoenix server
#
echo "exec:
MEC_HTTP_BACKEND_URL=\"${MEC_HTTP_BACKEND_URL}\" CLOUD_HTTP_BACKEND_URL=\"${CLOUD_HTTP_BACKEND_URL}\" \
mix phx.server
"

MEC_HTTP_BACKEND_URL="${MEC_HTTP_BACKEND_URL}" CLOUD_HTTP_BACKEND_URL="${CLOUD_HTTP_BACKEND_URL}" \
mix phx.server
