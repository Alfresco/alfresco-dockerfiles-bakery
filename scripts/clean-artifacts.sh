#!/bin/bash -e
# Clean all artifacts fetched by fetch-artifacts.sh

REPO_ROOT="$(dirname $0)/.."

FORCE=false
while getopts "f" opt;
do
  case $opt in
    f)
      FORCE=true
      ;;
    *)
      ;;
  esac
done

files=$(find -E "$REPO_ROOT" \
  ! -path '*/artifacts_cache/*' \
  -regex ".*-.*\.(jar|zip|amp|tgz|gz|rpm|deb)" \
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
