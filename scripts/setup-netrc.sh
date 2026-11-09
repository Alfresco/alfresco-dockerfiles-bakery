#!/usr/bin/env bash
# Write ~/.netrc from host-keyed credential entries.
# Usage: setup-netrc.sh "host1 login1 password1" "host2 login2 password2"

set -euo pipefail

netrc="$HOME/.netrc"
umask 077
: > "$netrc"
chmod 600 "$netrc"

# netrc bare tokens can't hold whitespace, quotes, backslashes or '#'.
unsupported='["\\#]'

for entry in "$@"; do
  read -r host login password extra <<< "$entry" || true
  [ -n "$host" ] && [ -n "$login" ] && [ -n "$password" ] || continue
  if [ -n "$extra" ] || [[ "$login$password" =~ $unsupported ]]; then
    echo "::error::Credentials for '$host' contain whitespace, a quote, a backslash or '#', which are not supported" >&2
    exit 1
  fi
  {
    printf 'machine %s\n' "$host"
    printf '  login %s\n' "$login"
    printf '  password %s\n' "$password"
  } >> "$netrc"
done
