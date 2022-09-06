#!/bin/ash
set -euo pipefail
set -o errexit
set -o errtrace

MNT_POINT="${MNT_POINT:-/webhook/s3data}"
if mountpoint "${MNT_POINT}"; then
  umount -f "${MNT_POINT}"
  echo "Called umount for '${MNT_POINT}'"
else
  echo "The PATH '${MNT_POINT}' is not a mountpoint"
fi
