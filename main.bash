#!/bin/bash

HASH_FILE="/tmp/bighash"
MAIN_FIRST_DIR="$PWD"
FIRST_DIR="dossier_1"
MAIN_SECOND_DIR="$PWD"
SECOND_DIR="dossier_2"
#permet aux boucles for de ne séparer qu'avec un saut à la ligne et pas un espace
IFS=$(echo -en "\n\b")

SHOW_NB_DIFFERENT_FILES=false
SHOW_DIFFERENT_FILES=false
SHOW_MODIFIED_FILES=false
SHOW_NEW_FILES=false
SHOW_NEW_PARENT_FILES=false
SHOW_TREE_FIRST=false
SHOW_TREE_SECOND=false
MAKE_DIFF_FILE=false
MAKE_HTML=false

#si l'utilisateur veut comparer des dossiers spécifiques, sinon c'est dossier_1 et dossier_2 qui sont utilisés
if [[ -d "$1" && -d "$2" ]]; then
  MAIN_FIRST_DIR="$(dirname "$(realpath "$1")")"
  FIRST_DIR="$(basename "$1")"
  MAIN_SECOND_DIR="$(dirname "$(realpath "$2")")"
  SECOND_DIR="$(basename "$2")"
fi

if [ -f "$HASH_FILE" ]; then
  rm "$HASH_FILE"
fi

# met l'empreinte de tous les fichiers dans HASH_FILE
# et met une empreinte vide pour les dossiers
# va aussi visiter les sous-repertoires
function make_hash {
  local path
  for path in "$1"/*; do
    if [ -d "$path" ]; then
      echo "" | md5sum | sed "s|-|$path/|g" >> "$HASH_FILE"
      make_hash "$path"
    else
      if [ -f "$path" ]; then
        md5sum "$(realpath "$path")" >> "$HASH_FILE"
      fi
    fi
  done
}

# traite le fichier HASH_FILE pour créer des variables très utiles
function compare_hash {
  #liste les fichiers qui sont soit modifié ou qui n'existe que d'un seul côté
  different_files="$(cat "$HASH_FILE" \
                    | sed -e "s|$MAIN_FIRST_DIR/$FIRST_DIR/|/|g" \
                          -e "s|$MAIN_SECOND_DIR/$SECOND_DIR/|/|g" \
                    | sort | uniq -u)"

  #une variable intermediaire pour éviter de faire deux fois la même chose
  files_without_hash="$(echo "$different_files" | sed "s|.\{32\}  ||g" | sort)"

  #liste les fichiers modifiés
  #revient à avoir les lignes qui apparaissent deux fois
  modified_files="$(echo "$files_without_hash" | uniq -d)"

  #liste les fichiers qui existent que dans un seul des deux repertoires
  #revient à avoir les lignes qui n'apparaissent qu'une seule fois
  new_files="$(echo "$files_without_hash" | uniq -u)"

  #rajoute le dossier "parent" au chemin des fichiers listés dans new_files
  new_files_parent=""
  if [ "$new_files" ]; then
    for file in $new_files; do
      if [ -e "$MAIN_FIRST_DIR/$FIRST_DIR/$file" ]; then
        new_files_parent+="/$FIRST_DIR$file"$'\n'
      fi
      if [ -e "$MAIN_SECOND_DIR/$SECOND_DIR/$file" ]; then
        new_files_parent+="/$SECOND_DIR$file"$'\n'
      fi
    done
  fi
}

#affiche un arbre avec de jolies couleurs
function print_tree {
  local my_path prefix_file prefix_dir previous_prefixes nb_files \
        my_i dir_i dir_path file_list file_list_nb_files
  #chemin absolu du dossier ou fichier courant
  my_path="$(realpath "$1")"
  if [ -d "$my_path" ]; then
    my_path="$my_path/"
  fi
  prefix_file="├── "
  prefix_dir="│   "
  previous_prefixes="$4"
  #nombre de fichiers dans le dossier
  nb_files="$3"
  #le numéro du fichier ou dossier courant, 1 <= my_i <= nb_files
  my_i="$2"

  # passe de /home/truc/dossier1/machin à /dossier1/machin
  my_path_parent="$(echo "$my_path" \
                  | sed -e "s|^$MAIN_FIRST_DIR/|/|g" \
                        -e "s|^$MAIN_SECOND_DIR/|/|g")"
  #passe de /dossier1/machin à /machin
  my_path_without_parent="$(echo "$my_path_parent" \
                          | sed -e "s|^/$FIRST_DIR/|/|g" \
                                -e "s|^/$SECOND_DIR/|/|g")"

  file_name="$(basename "$my_path")"
  if [ -e "$my_path" ]; then
    if [[ "$modified_files" && "$(echo "$modified_files" | grep "^$my_path_without_parent$")" ]]; then
      #si c'est un fichier modifié
      file_name="\e[33m$file_name\e[0m"
    else
      if [[ "$new_files_parent" && "$(echo "$new_files_parent" | grep "^$my_path_parent$")" ]]; then
        #si c'est un nouveau dossier ou fichier
        file_name="\e[32m$file_name\e[0m"
      fi
    fi
  else
    #si le fichier ou dossier n'existe pas
    #c'est qu'il vient de l'autre arborescence
    file_name="\e[31m$file_name\e[0m"
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

    #passe de /home/truc/dossier1/machin/bidule à dossier2/machin/bidule
    if [ "$(echo "$my_path" | grep "$MAIN_FIRST_DIR/$FIRST_DIR/")" ]; then
      new_path="$(echo "$my_path" \
                | sed "s|$MAIN_FIRST_DIR/$FIRST_DIR|$MAIN_SECOND_DIR/$SECOND_DIR|g")"
      #peut être un prob ici
      new_path="$(realpath --relative-to="$MAIN_FIRST_DIR" "$new_path")"
    fi
    if [ "$(echo "$my_path" | grep "$MAIN_SECOND_DIR/$SECOND_DIR/")" ]; then
      new_path="$(echo "$my_path" \
                | sed "s|$MAIN_SECOND_DIR/$SECOND_DIR|$MAIN_FIRST_DIR/$FIRST_DIR|g")"
      new_path="$(realpath --relative-to="$MAIN_SECOND_DIR" "$new_path")"
    fi

    #ajoute à file_list les fichiers et dossiers qui sont dans l'autre arborescence
    for file in $new_files_parent; do
      #peut être plus mieux
      if [[ "$new_path" && "$(echo "$(dirname "$file")" | grep "$new_path$")" ]]; then
        file_list+=$'\n'"$(basename "$file")"
      fi
    done

    dir_i=1
    file_list_nb_files="$(echo "$file_list" | wc -l)"
    for dir_path in $file_list; do
      print_tree "$my_path/$dir_path" "$dir_i" "$file_list_nb_files" "$previous_prefixes$prefix_dir"
      dir_i=$(expr "$dir_i" + 1)
    done
  fi
}

function print_result {
  if [ -z "$different_files" ]; then
    echo "les dossiers sont identiques"
  fi

  if [ $SHOW_NB_DIFFERENT_FILES = true ]; then
    #la somme des fichiers (pas des dossiers) modifiés et nouveaux
    nb_different_files="$(expr "$(echo "$modified_files" | grep -v ".*/$" | wc -l)" "+" "$(echo "$new_files" | grep -v ".*/$" | wc -l)")"
    echo "$nb_different_files fichers diff"
  fi

  if [ $SHOW_DIFFERENT_FILES = true ]; then
    echo "different_files:"
    echo "$different_files"
  fi

  if [ $SHOW_MODIFIED_FILES = true ]; then
    echo "modified_files:"
    echo "$modified_files"
  fi

  if [ $SHOW_NEW_FILES = true ]; then
    echo "new_files:"
    echo "$new_files"
  fi

  if [ $SHOW_NEW_PARENT_FILES = true ]; then
    echo "new_files_parent:"
    echo "$new_files_parent"
  fi

  if [ $MAKE_DIFF_FILE = true ]; then
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
  fi

  if [ $SHOW_TREE_FIRST = true ]; then
    print_tree "$MAIN_FIRST_DIR/$FIRST_DIR" 1 0 ""
  fi

  if [ $SHOW_TREE_SECOND = true ]; then
    print_tree "$MAIN_SECOND_DIR/$SECOND_DIR" 1 0 ""
  fi
}

make_hash "$MAIN_FIRST_DIR/$FIRST_DIR"
make_hash "$MAIN_SECOND_DIR/$SECOND_DIR"
compare_hash

print_result
