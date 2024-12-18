#!/bin/bash -e
# Clean all artifacts fetched by fetch-artifacts.py

REPO_ROOT="$(dirname $0)/.."

FORCE=false
while getopts "f" opt; do
  case $opt in
  f)
    FORCE=true
    ;;
  *) ;;
  esac
done

FIND_OPTS=""
FIND_MAC_OPTS=""
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  FIND_OPTS="-regextype egrep"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  FIND_MAC_OPTS="-E"
else
  echo "Unsupported OS for find command."
  exit 1
fi

files=$(
  find $FIND_MAC_OPTS "$REPO_ROOT" $FIND_OPTS \
    ! -path '*/artifacts_cache/*' \
    -regex ".*-.*\.(jar|zip|amp|tgz|gz|rpm|deb)"
)

if [ -z "$files" ]; then
  echo "No artifacts found to clean."
  exit 0
fi

echo "The following files will be deleted:"
echo "$files"

if [ "$FORCE" = 'false' ]; then
  read -p "Do you want to delete these files? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 0
  fi
fi

echo "$files" | xargs rm
echo "All artifacts deleted."
