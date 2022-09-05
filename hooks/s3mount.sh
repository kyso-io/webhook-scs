#!/bin/ash
set -euo pipefail
set -o errexit
set -o errtrace

export S3_ACL="${S3_ACL:-private}"

if [ -z "$AWS_KEY" ] || [ -z "$AWS_SECRET_KEY" ] || [ -z "$S3_BUCKET" ]; then
  [ "$AWS_KEY" ] || echo "Set the AWS_KEY environment variable"
  [ "$AWS_SECRET_KEY" ] || echo "Set the AWS_SECRET_KEY environment variable"
  [ "$S3_BUCKET" ] || echo "Set the S3_BUCKET environment variable"
  exit 1
fi

MNT_POINT="${MNT_POINT:-/s3data}"
mkdir -p "${MNT_POINT}"

if [ "$S3_REGION" ] && [ "$S3_REGION" != "us-east-1" ]; then
   EP_URL="endpoint=$S3_REGION,url=https://s3.$S3_REGION.amazonaws.com"
else
   EP_URL="endpoint=us-east-1"
fi

echo "${AWS_KEY}:${AWS_SECRET_KEY}" > /etc/passwd-s3fs
chmod 0400 /etc/passwd-s3fs

/usr/bin/s3fs -o dbglevel=info,retries=5 -o "${EP_URL}" "${S3_BUCKET}" \
  "${MNT_POINT}"
