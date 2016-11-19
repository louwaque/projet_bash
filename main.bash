#!/bin/bash

HASH_FILE="/tmp/bighash"
MAIN_FIRST_DIR="$PWD"
FIRST_DIR="dossier_1"
MAIN_SECOND_DIR="$PWD"
SECOND_DIR="dossier_2"

#si l'utilisateur veut comparer des dossiers spécifiques, sinon c'est dossier_1 et dossier_2 qui sont utilisés
if [[ -d "$1" && -d "$2" ]]; then
  MAIN_FIRST_DIR="$(dirname "$(realpath "$1")")"
  FIRST_DIR="$(basename "$1")"
  MAIN_SECOND_DIR="$(dirname "$(realpath "$2")")"
  SECOND_DIR="$(basename "$2")"
fi

export HASH_FILE
export MAIN_FIRST_DIR
export FIRST_DIR
export MAIN_SECOND_DIR
export SECOND_DIR

if [ -f "$HASH_FILE" ]; then
  rm "$HASH_FILE"
fi

#hach tous les fichiers contenuent dans le repertoire donné en parametre et irra meme visiter les sous dossiers !
function make_hash {
  local path
  for path in "$1"/*; do
    if [ -d "$path" ]; then
      echo "" | md5sum | sed "s|-|$path/|g" >> "$HASH_FILE"
      make_hash "$path"
    else
      if [ -f "$path" ]; then
        #si c'est un fichier alors on le hache
        md5sum "$(realpath "$path")" >> "$HASH_FILE"
      fi
    fi
  done
}

function compare_hash {
  #contient la liste des fichiers qui peuvent être modifiés ou qui existent que d'un seul coté
  different_files="$(cat "$HASH_FILE" | sed -e "s|$MAIN_FIRST_DIR/$FIRST_DIR||g" -e "s|$MAIN_SECOND_DIR/$SECOND_DIR||g" | sort | uniq -u)"

  #liste des fichiers modifiés
  modified_files="$(echo "$different_files" | cut -d ' ' -f 3 | sort | uniq -d)"

  #liste des fichiers qui existent que dans un seul des deux repertoires
  new_files="$(echo "$different_files" | cut -d ' ' -f 3 | sort | uniq -u)"

  #new_files avec le dossier parent
  if [[ ! -z "$new_files" ]]; then
    while read line; do
      file_parent="$(cat "$HASH_FILE" | grep "^[[:alnum:]]\{32\}[[:space:]]\{2\}\($MAIN_FIRST_DIR/$FIRST_DIR\|$MAIN_SECOND_DIR/$SECOND_DIR\)$line$" | cut -d ' ' -f 3 | sed -e "s|$MAIN_FIRST_DIR||g" -e "s|$MAIN_SECOND_DIR||g")"
      new_files_parent="$(echo -e "$file_parent\n$new_files_parent")"
    done < <(echo "$new_files")
  fi

  echo "modified_files:"
  echo "$modified_files"

  echo "new_files:"
  echo "$new_files"

  echo "new_files_parent:"
  echo "$new_files_parent"
}

function print_tree {
  local my_path prefix_file prefix_dir previous_prefixes nb_files my_i dir_i dir_path file_list
  my_path="$(realpath "$1")"
  if [ -d "$my_path" ]; then
    my_path="$my_path/"
  fi
  prefix_file="├── "
  prefix_dir="│   "
  previous_prefixes="$3"
  nb_files="$(ls -1 "$(dirname "$my_path")" | wc -l)"
  my_i="$2"
  dir_i=1

  file_name="$(basename "$my_path")"
  if [[ "$modified_files" && "$(echo "$my_path" | grep "$modified_files")" ]]; then
    file_name="\e[33m$file_name\e[0m"
  else
    if [[ "$new_files" && "$(echo "$my_path" | grep "$new_files")" ]]; then
       file_name="\e[32m$file_name\e[0m"
    fi
  fi

  if [ "$my_i" -eq "$nb_files" ]; then
    prefix_file="└── "
    prefix_dir="    "
  fi

  if [ "$previous_prefixes" ]; then
    echo -e "$previous_prefixes$prefix_file$file_name"
  else
    echo -e "$file_name"
    prefix_dir="\0"
  fi

  if [ -d "$my_path" ]; then
    file_list="$(ls "$my_path")"
    for dir_path in $file_list; do
      print_tree "$my_path/$dir_path" "$dir_i" "$previous_prefixes$prefix_dir"
      dir_i=$(expr "$dir_i" + 1)
    done
  fi
}

function print_result {
  if [ -z "$different_files" ]; then
    echo "les dossiers sont identiques"
  fi
  nb_different_files="$(expr "$(echo "$modified_files" | grep -v ".*/$" | wc -l)" "+" "$(echo "$new_files" | grep -v ".*/$" | wc -l)")"
  echo "$nb_different_files fichers diff"
  if [ -f "fichiers_diff" ]; then
    rm "fichiers_diff"
  fi
  for path in $modified_files; do
    echo "$(realpath "$MAIN_FIRST_DIR/$FIRST_DIR/$path")" >> fichiers_diff
    echo "$(realpath "$MAIN_SECOND_DIR/$SECOND_DIR/$path")" >> fichiers_diff
  done
  for path in $new_files_parent; do
    if [ "$(echo "$path" | grep "^/$FIRST_DIR")" ]; then
      echo "$(realpath "$MAIN_FIRST_DIR/$path")" >> fichiers_diff
    fi
    if [ "$(echo "$path" | grep "^/$SECOND_DIR")" ]; then
      echo "$(realpath "$MAIN_SECOND_DIR/$path")" >> fichiers_diff
    fi
  done
}

make_hash "$MAIN_FIRST_DIR/$FIRST_DIR"
make_hash "$MAIN_SECOND_DIR/$SECOND_DIR"

compare_hash
print_result
print_tree "$MAIN_FIRST_DIR/$FIRST_DIR" 1 ""
print_tree "$MAIN_SECOND_DIR/$SECOND_DIR" 1 ""
