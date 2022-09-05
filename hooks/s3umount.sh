#!/bin/ash
set -euo pipefail
set -o errexit
set -o errtrace

MNT_POINT="${MNT_POINT:-/s3data}"
if mountpoint "${MNT_POINT}"; then
  umount -f "${MNT_POINT}"
fi
