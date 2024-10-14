#!/bin/bash -e
# Clean all artifacts fetched by fetch-artifacts.sh

REPO_ROOT="$(dirname $0)/.."

files=$(find -E "$REPO_ROOT" \
  -regex ".*-.*\.(jar|zip|amp|tgz|gz|rpm|deb)")

if [ -z "$files" ]; then
  echo "No artifacts found to clean."
  exit 0
fi

echo "The following files will be deleted:"
echo "$files"

read -p "Do you want to delete these files? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "$files" | xargs rm
  echo "All artifacts cleaned up."
else
  echo "Operation cancelled."
fi
