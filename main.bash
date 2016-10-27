#!/bin/bash

HASH_FILE=/tmp/bighash
FIRST_DIR="dossier_1"
SECOND_DIR="dossier_2"

export HASH_FILE
export FIRST_DIR
export SECOND_DIR

rm "$HASH_FILE"

function make_hash {
  local path
  for path in "$1"/*; do
    if [ -d "$path" ]; then
      make_hash "$path"
    fi
    if [ -f "$path" ]; then
      md5sum "$(realpath --relative-to="$PWD" "$path")" >> "$HASH_FILE"
    fi
    if [ "$(basename "$path")" == "*" ]; then
      echo "" | md5sum | sed "s|-|$path|g" >> "$HASH_FILE"
    fi
  done
}

function compare_hash {
  different_files="$(cat "$HASH_FILE" | sed -e "s/$FIRST_DIR//g" -e "s/$SECOND_DIR//g" | sort | uniq -u)"

  modified_files="$(echo "$different_files" | cut -d ' ' -f 3 | sort | uniq -d)"

  new_files="$(echo "$different_files" | cut -d ' ' -f 3 | sort | uniq -u)"

  echo "modified_files:"
  echo "$modified_files"

  echo "new_files:"
  while read line; do
    cat "$HASH_FILE" | grep "$line" | cut -d ' ' -f 3
  done < <(echo "$new_files")
}

make_hash "$FIRST_DIR"
make_hash "$SECOND_DIR"

compare_hash
