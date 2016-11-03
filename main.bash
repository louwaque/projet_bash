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
      if [ "$(ls -A "$path")" ]; then
        #si c'est un dossier pas vide alors on part hacher les fichiers qui sont à l'interieur
        make_hash "$path"
      else
        #si c'est un dossier vide alors on le rajoute au hach parce qu'il a besoin d'exister
        echo "" | md5sum | sed "s|-|$path/|g" >> "$HASH_FILE"
      fi
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

  echo "modified_files:"
  echo "$modified_files"

  echo "new_files:"
  if [[ ! -z "$new_files" ]]; then
    while read line; do
      cat "$HASH_FILE" | grep "^[[:alnum:]]\{32\}[[:space:]]\{2\}\($MAIN_FIRST_DIR/$FIRST_DIR\|$MAIN_SECOND_DIR/$SECOND_DIR\)$line$" | cut -d ' ' -f 3 | sed -e "s|$MAIN_FIRST_DIR||g" -e "s|$MAIN_SECOND_DIR||g"
    done < <(echo "$new_files")
  fi
}

function print_tree {
  local path
  for path in "$1"/*; do
    echo "! $path"
    if [ -d "$path" ]; then
      print_tree "$path"
    fi
  done
}

function print_result {
  #alex voila là où tu vas faire tes devoirs :)
  #comme je peux pas laisser la fonction qu'avec des com j'affiche un truc
  echo "les dossiers sont identiques"
}

#make_hash "$MAIN_FIRST_DIR/$FIRST_DIR"
#make_hash "$MAIN_SECOND_DIR/$SECOND_DIR"

#compare_hash
#print_result
print_tree "$MAIN_FIRST_DIR/$FIRST_DIR"
