#!/bin/bash

HASH_FILE=/tmp/bighash
MAIN_DIR="$PWD"

FIRST_DIR="dossier_1"
SECOND_DIR="dossier_2"

export HASH_FILE
export MAIN_DIR
export FIRST_DIR
export SECOND_DIR

rm "$HASH_FILE"

# function make_hash {
#   for path in "$2"/*; do
#     if [ -d "$path" ]; then
#       #cd "$path" || return
#       make_hash "$1" "$PWD/$path"
#       #cd ..
#     else
#       if [ -f "$path" ]; then
#         md5sum "$(realpath --relative-to="$1" "$path")" >> "$HASH_FILE"
#       fi
#     fi
#   done
# }
#
# function compare_hash {
#   cat $HASH_FILE | sort | uniq -u
# }

# cd dossier_1 || return
# make_hash "$(realpath ../dossier_1)" ./
# cd ..
#
# cd dossier_2 || return
# make_hash "$(realpath ../dossier_2)" ./
# cd ..

function make_hash {
  local path
  for path in "$1"/*; do
    if [ -d "$path" ]; then
      make_hash "$path"
    else
      if [ -f "$path" ]; then
        md5sum "$(realpath --relative-to="$PWD" "$path")" >> "$HASH_FILE"
      fi
    fi
  done
}

function compare_hash {
  res=$(cat "$HASH_FILE" | sed -e "s/$FIRST_DIR//g" -e "s/$SECOND_DIR//g" | sort | uniq -u)

  #afficher fichier existe dans les deux dossier mais différents
  autre_res=$(echo "$res" | cut -d ' ' -f3 | sort | uniq -d)

  truc=$(echo "$res" | sed 's/.*\ \(.*\)/\1/g' | uniq -u)

  echo "existe dans deux"
  echo "$autre_res"
  echo "existe un seul"

  while read line; do
    cat "$HASH_FILE" | grep "$line" | cut -d ' ' -f3
  done < <(echo "$truc")

  # while read ligne; do
  #   hash="$(echo "$ligne" | cut -d ' ' -f1)"
  #   filename="$(echo "$ligne" | cut -d ' ' -f3)"
  #   cat "$HASH_FILE" | grep "$hash" | sed "s/\(.*\)\ \(.*\)/\2/g" | sort
  # done < <(echo "$res")
  # echo "$res"
}

make_hash "$FIRST_DIR"
make_hash "$SECOND_DIR"


compare_hash
