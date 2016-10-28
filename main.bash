#!/bin/bash

HASH_FILE="/tmp/bighash"
MAIN_DIR="$PWD"
FIRST_DIR="dossier_1"
SECOND_DIR="dossier_2"

if [[ -d "$1" && -d "$2" && "$(dirname "$1")" = "$(dirname "$2")" ]]; then
  MAIN_DIR="$(dirname "$(realpath "$1")")"
  FIRST_DIR="$(basename "$1")"
  SECOND_DIR="$(basename "$2")"
fi

export HASH_FILE
export MAIN_DIR
export FIRST_DIR
export SECOND_DIR

if [ -f "$HASH_FILE" ]; then
  rm "$HASH_FILE"
fi

function make_hash {
  local path
  for path in "$1"/*; do
    if [ -d "$path" ]; then
      if [ "$(ls -A "$path")" ]; then
        make_hash "$path"
      else
        echo "" | md5sum | sed "s|-|$path/|g" >> "$HASH_FILE"
      fi
    else
      if [ -f "$path" ]; then
        md5sum "$(realpath "$path")" >> "$HASH_FILE"
      fi
    fi
  done
}

function compare_hash {
  different_files="$(cat "$HASH_FILE" | sed -e "s|$MAIN_DIR/$FIRST_DIR||g" -e "s|$MAIN_DIR/$SECOND_DIR||g" | sort | uniq -u)"

  modified_files="$(echo "$different_files" | cut -d ' ' -f 3 | sort | uniq -d)"

  new_files="$(echo "$different_files" | cut -d ' ' -f 3 | sort | uniq -u)"

  echo "modified_files:"
  echo "$modified_files"

  echo "new_files:"
  while read line; do
    cat "$HASH_FILE" | grep "$line$" | cut -d ' ' -f 3
  done < <(echo "$new_files")
}

make_hash "$MAIN_DIR/$FIRST_DIR"
make_hash "$MAIN_DIR/$SECOND_DIR"

compare_hash
