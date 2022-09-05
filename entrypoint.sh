#!/bin/sh

set -e

# ---------
# VARIABLES
# ---------

WEBHOOK_BIN="${WEBHOOK_BIN:-/webhook/hooks}"
WEBHOOK_YML="${WEBHOOK_YML:-/webhook/scs.yml}"
WEBHOOK_OPTS="${WEBHOOK_OPTS:--verbose}"

# ---------
# FUNCTIONS
# ---------

print_du_yml() {
  cat <<EOF
- id: du
  execute-command: '$WEBHOOK_BIN/du.sh'
  command-working-directory: '$WORKDIR'
  response-headers:
  - name: 'Content-Type'
    value: 'application/json'
  http-methods: ['GET']
  include-command-output-in-response: true
  include-command-output-in-response-on-error: true
  pass-arguments-to-command:
  - source: 'url'
    name: 'org'
  - source: 'url'
    name: 'team'
  pass-environment-to-command:
  - source: 'string'
    envname: 'OUTPUT_FORMAT'
    name: 'json'
EOF
}

print_hardlink_yml() {
  cat <<EOF
- id: hardlink
  execute-command: '$WEBHOOK_BIN/hardlink.sh'
  command-working-directory: '$WORKDIR'
  http-methods: ['GET']
  include-command-output-in-response: true
  include-command-output-in-response-on-error: true
EOF
}


print_s3mount_yml() {
  cat <<EOF
- id: s3mount
  execute-command: '$WEBHOOK_BIN/s3mount.sh'
  command-working-directory: '$WORKDIR'
  http-methods: ['POST']
  include-command-output-in-response: true
  include-command-output-in-response-on-error: true
  pass-environment-to-command:
  - source: 'payload'
    envname: 'AWS_KEY'
	name: 'aws.key'
  - source: 'payload'
    envname: 'AWS_SECRET_KEY'
	name: 'aws.secret_key'
  - source: 'payload'
	envname: 'S3_BUCKET'
    name: 's3.bucket'
  - source: 'payload'
	envname: 'S3_REGION'
    name: 's3.region'
EOF
}


print_s3umount_yml() {
  cat <<EOF
- id: s3umount
  execute-command: '$WEBHOOK_BIN/s3umount.sh'
  command-working-directory: '$WORKDIR'
  http-methods: ['GET']
  include-command-output-in-response: true
  include-command-output-in-response-on-error: true
EOF
}


print_token_yml() {
  if [ "$1" ]; then
    cat << EOF
  trigger-rule:
    match:
      type: 'value'
      value: '$1'
      parameter:
        source: 'header'
        name: 'X-Webhook-Token'
EOF
  fi
}

# ----
# MAIN
# ----

# Validate WORKDIR
if [ -z "$WEBHOOK_WORKDIR" ]; then
  echo "Must define the WEBHOOK_WORKDIR variable!" >&2
  exit 1
fi
WORKDIR="$(realpath "$WEBHOOK_WORKDIR" 2>/dev/null)" || true
if [ ! -d "$WORKDIR" ]; then
  echo "The WEBHOOK_WORKDIR '$WEBHOOK_WORKDIR' is not a directory!" >&2
  exit 1
fi

# Get TOKENS, if the DU_TOKEN or HARDLINK_TOKEN is defined that is used, if not
# if the COMMON_TOKEN that is used and in other case no token is checked (that
# is the default)
DU_TOKEN="${DU_TOKEN:-$COMMON_TOKEN}"
HARDLINK_TOKEN="${HARDLINK_TOKEN:-$COMMON_TOKEN}"

# Create webhook configuration
{ 
  print_du_yml
  print_token_yml "$DU_TOKEN"
  echo ""
  print_hardlink_yml
  print_token_yml "$HARDLINK_TOKEN"
}>"$WEBHOOK_YML"

# Run the webhook command
# shellcheck disable=SC2086
exec webhook -hooks "$WEBHOOK_YML" $WEBHOOK_OPTS
