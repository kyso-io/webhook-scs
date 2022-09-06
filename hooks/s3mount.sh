#!/bin/ash
set -euo pipefail
set -o errexit
set -o errtrace
# Check variables
if [ -z "$AWS_KEY" ] || [ -z "$AWS_SECRET_KEY" ] || [ -z "$S3_BUCKET" ]; then
  [ "$AWS_KEY" ] || echo "Set the AWS_KEY environment variable"
  [ "$AWS_SECRET_KEY" ] || echo "Set the AWS_SECRET_KEY environment variable"
  [ "$S3_BUCKET" ] || echo "Set the S3_BUCKET environment variable"
  exit 1
fi
if [ "$S3_REGION" ] && [ "$S3_REGION" != "us-east-1" ]; then
   EP_URL="endpoint=$S3_REGION,url=https://s3.$S3_REGION.amazonaws.com"
else
   EP_URL="endpoint=us-east-1"
fi
# Check moutpoint
MNT_POINT="${MNT_POINT:-/webhook/s3data}"
if [ ! -d "${MNT_POINT}" ]; then
  mkdir -p "${MNT_POINT}"
elif mountpoint "${MNT_POINT}"; then
  echo "There is already something mounted on '${MNT_POINT}', aborting!"
  exit 1
fi
# Create password file
touch "$HOME/.passwd-s3fs"
chmod 0400 "$HOME/.passwd-s3fs"
echo "${AWS_KEY}:${AWS_SECRET_KEY}" >"$HOME/.passwd-s3fs"
# Mount s3 bucket as a filesystem
/usr/bin/s3fs -o dbglevel=info,retries=5 -o "${EP_URL}" "${S3_BUCKET}" \
  "${MNT_POINT}"
echo "Mounted bucket '$S3_BUCKET' on '${MNT_POINT}'"
