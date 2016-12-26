#!/bin/bash

HASH_FILE="/tmp/bighash"
HTML_FILE_IN="site_projet_bash.html"
HTML_FILE_OUT="diff.html"
SHOW_NB_DIFFERENT_FILES=false
SHOW_DIFFERENT_FILES=false
SHOW_MODIFIED_FILES=false
SHOW_NEW_FILES=false
SHOW_NEW_PARENT_FILES=false
MAKE_DIFF_FILE=false
MAKE_HTML=false
SHOW_TREE_FIRST=false
SHOW_TREE_SECOND=false
SHOW_TREE_MODIF=true
SHOW_TREE_NEW=true
SHOW_TREE_NONEXISTENT=true
SHOW_TREE_IDENTICALY=true
SHOW_TREE_UNCOLORED=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help|--helpme|--aide)
      echo -e "Usage: main.bash [options...] <dossier_1> <dossier_2>\nOptions:
    --nbficdiff\tPermet d'afficher le nombre de fichiers différents.
    --ficdiff\tPermet d'afficher la liste des fichiers différents.
    --ficmod\tPermet d'afficher la liste des fichiers modifiés.
    --nvfic\tPermet d'afficher la liste des nouveaux fichiers.
    --nvficprnt\tPermet d'afficher la liste des nouveaux fichies ainsi que le dossier parrent.
    --ficfdiff\tPermet d'afficher le fichier contenant la liste des fichiers différents.
    --siteweb\tPermet d'accéder à la page HTML.
    --helpme\tPermet d'accéder à l'aide.
    --arb1\tPermet d'afficher toute l'arborescence du dossier 1.
    --arb2\tPermet d'afficher toute l'arborescence du dossier 2.
    --non-arbmodif\tPermet de masquer les fichiers modifiers dans l'arborescence.
    --non-arbnv\tPermet de masquer les nouveau fichiers de l'arborescence.
    --non-arbinex\tPermet de masquer les fichiers diffétents de l'arborescence.
    --non-arbid\tPermet de masquer les fichiers identiques dans l'arborescence.
    --non-arbclr\tPermet de masquer les couleurs dans l'arborescence."
      exit
    ;;
    --nbficdiff)
      SHOW_NB_DIFFERENT_FILES=true
      shift
    ;;
    --ficdiff)
      SHOW_DIFFERENT_FILES=true
      shift
    ;;
    --ficmod)
      SHOW_MODIFIED_FILES=true
      shift
    ;;
    --nvfic)
      SHOW_NEW_FILES=true
      shift
    ;;
    --nvficprnt)
      SHOW_NEW_PARENT_FILES=true
      shift
    ;;
    --ficfdiff)
      MAKE_DIFF_FILE=true
      shift
    ;;
    --siteinternet|--siteweb)
      MAKE_HTML=true
      shift
    ;;
    --arb1)
      SHOW_TREE_FIRST=true
      shift
    ;;
    --arb2)
      SHOW_TREE_SECOND=true
      shift
    ;;
    --non-arbmodif)
      SHOW_TREE_MODIF=false
      shift
    ;;
    --non-arbnv)
      SHOW_TREE_NEW=false
      shift
    ;;
    --non-arbinex)
      SHOW_TREE_NONEXISTENT=false
      shift
    ;;
    --non-arbid)
      SHOW_TREE_IDENTICALY=false
      shift
    ;;
    --non-arbclr)
      SHOW_TREE_UNCOLORED=true
      shift
    ;;
    *)
      if [ -d "$1" ]; then
        if [ $# -eq 2 ]; then
          MAIN_FIRST_DIR="$(dirname "$(realpath "$1")")"
          FIRST_DIR="$(basename "$1")"
          shift
          continue
        fi
        if [ $# -eq 1 ]; then
          MAIN_SECOND_DIR="$(dirname "$(realpath "$1")")"
          SECOND_DIR="$(basename "$1")"
          shift
          break
        fi
      else
        if [ "$1" ]; then
          echo "option inconue: $1"
        fi
        exit
      fi
    ;;
  esac
done

if [[ -z "$MAIN_FIRST_DIR" || -z "$MAIN_SECOND_DIR" ]]; then
  echo "dossier_1 et/ou dossier_2 non renseigné(s)"
  exit
fi

#permet aux boucles for de ne séparer qu'avec un saut à la ligne et pas un espace
IFS=$(echo -en "\n\b")

if [ -f "$HASH_FILE" ]; then
  rm "$HASH_FILE"
fi

if [ $MAKE_HTML = true ]; then
  cp "$HTML_FILE_IN" "$HTML_FILE_OUT"
  sed -i "/\/\/style/a $(tr -d '\n' < css_projet_bash.css)" "$HTML_FILE_OUT"
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
  different_files="$(sed -e "s|$MAIN_FIRST_DIR/$FIRST_DIR/|/|g" \
                         -e "s|$MAIN_SECOND_DIR/$SECOND_DIR/|/|g" \
                         "$HASH_FILE" \
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

function print_tree_file {
  if [ "$previous_prefixes" ]; then
    echo -e "$previous_prefixes$prefix_file\e[${term_color}m$file_name\e[0m"
  else
    echo -e "$file_name"
    prefix_dir="\0"
  fi

  if [ $MAKE_HTML = true ]; then
    if [ -d "$my_path" ]; then
      ID="$RANDOM"
      sed -i "s|\(<!-- arborescence -->\)|<li><input type=\"checkbox\" id=\"$ID\" checked/>\n<i class=\"fa fa-angle-double-right\"></i>\n<i class=\"fa fa-angle-double-down\"></i>\n<label for=\"$ID\"><font color=\"$html_color\">$file_name</font></label>\n\n<ul>\n\1|g" "$HTML_FILE_OUT"
    else
      sed -i "s|\(<!-- arborescence -->\)|<li><a href=\"$my_path\"><font color=\"$html_color\">$file_name</font></a></li>\n\1|g" "$HTML_FILE_OUT"
    fi
  fi
}

#affiche un arbre avec de jolies couleurs
function print_tree {
  local my_path prefix_file prefix_dir previous_prefixes nb_files \
        my_i dir_i dir_path file_list file_list_nb_files term_color html_color
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

  if [ "$my_i" -eq "$nb_files" ]; then
    prefix_file="└── "
    prefix_dir="    "
  fi

  # passe de /home/truc/dossier1/machin à /dossier1/machin
  my_path_parent="$(echo "$my_path" \
                  | sed -e "s|^$MAIN_FIRST_DIR/|/|g" \
                        -e "s|^$MAIN_SECOND_DIR/|/|g")"
  #passe de /dossier1/machin à /machin
  my_path_without_parent="$(echo "$my_path_parent" \
                          | sed -e "s|^/$FIRST_DIR/|/|g" \
                                -e "s|^/$SECOND_DIR/|/|g")"

  file_name="$(basename "$my_path")"
  term_color="0"
  html_color=""
  if [ -e "$my_path" ]; then
    if [[ $SHOW_TREE_MODIF = true || -d "$my_path" && "$modified_files" ]] && echo "$modified_files" | grep -q "^$my_path_without_parent"; then #..parent$ peut être plus sur
      #si c'est un fichier modifié
      if [ $SHOW_TREE_UNCOLORED = false ]; then
        term_color="33"
        html_color="#ff9900"
      else
        file_name="$file_name ≈"
      fi
      print_tree_file
    else
      if [[ $SHOW_TREE_NEW = true && "$new_files_parent" ]] && echo "$new_files_parent" | grep -q "^$my_path_parent$"; then
        #si c'est un nouveau dossier ou fichier
        if [ $SHOW_TREE_UNCOLORED = false ]; then
          term_color="32"
          html_color="#43d231"
        else
          file_name="$file_name +"
        fi
        print_tree_file
      else
        if [ $SHOW_TREE_IDENTICALY = true ]; then
          print_tree_file
        fi
      fi
    fi
  else
    #si le fichier ou dossier n'existe pas
    #c'est qu'il vient de l'autre arborescence
    if [ $SHOW_TREE_NONEXISTENT = true ]; then
      if [ $SHOW_TREE_UNCOLORED = false ]; then
        term_color="31"
        html_color="#ff0909"
      else
        file_name="$file_name -"
      fi
      print_tree_file
    fi
  fi

  if [ -d "$my_path" ]; then
    if [ $SHOW_TREE_IDENTICALY = true ]; then
      file_list="$(ls "$my_path")"$'\n'
    else
      for file in $(ls "$my_path"); do
        if [ $SHOW_TREE_MODIF = true ] && echo "$modified_files" | grep -q "$file"; then
          file_list+="$file"$'\n'
        fi
        if [ $SHOW_TREE_NEW = true ] && echo "$new_files_parent" | grep -q "$file"; then
          file_list+="$file"$'\n'
        fi
      done

    fi

    if [ $SHOW_TREE_NONEXISTENT = true ]; then
      #passe de /home/truc/dossier1/machin/bidule à dossier2/machin/bidule
      new_path="$(echo "$my_path" | sed -e "s|$MAIN_FIRST_DIR/$FIRST_DIR/|$SECOND_DIR/|g" -e "s|$MAIN_SECOND_DIR/$SECOND_DIR/|$FIRST_DIR/|g")"      #ajoute à file_list les fichiers et dossiers qui sont dans l'autre arborescence
      new_path=${new_path::-1}
      
      for file in $new_files_parent; do
        #peut être plus mieux
        if dirname "$file" | grep -q "$new_path$"; then
          file_list+=$'\n'"$(basename "$file")"
        fi
      done
    fi

    dir_i=1
    file_list="$(echo "$file_list" | sed '/^$/d')"
    file_list_nb_files="$(echo "$file_list" | wc -l)"
    for dir_path in $file_list; do
      print_tree "$my_path/$dir_path" "$dir_i" "$file_list_nb_files" "$previous_prefixes$prefix_dir"
      dir_i=$((dir_i+1))
    done
  fi

  if [[ $MAKE_HTML = true && "$my_i" -eq "$nb_files" ]]; then
      sed -i "s|\(<!-- arborescence -->\)|</ul></li>\n\n\1|g" "$HTML_FILE_OUT"
  fi
}

function print_result {
  if [ -z "$different_files" ]; then
    echo "les dossiers sont identiques"
  fi

  nb_different_files=$(($(echo "$modified_files" | grep -cv ".*/$")+$(echo "$new_files" | grep -cv ".*/$")))
  if [ $SHOW_NB_DIFFERENT_FILES = true ]; then
    #la somme des fichiers (pas des dossiers) modifiés et nouveaux
    echo "$nb_different_files fichers diff"
  fi
  if [ $MAKE_HTML = true ]; then
    sed -i "s|<!-- nb_fichiers -->|$nb_different_files|g" "$HTML_FILE_OUT"
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
      realpath "$MAIN_FIRST_DIR/$FIRST_DIR/$path" >> fichiers_diff
      realpath "$MAIN_SECOND_DIR/$SECOND_DIR/$path" >> fichiers_diff
    done
    for path in $new_files_parent; do
      if echo "$path" | grep -q "^/$FIRST_DIR"; then
        realpath "$MAIN_FIRST_DIR/$path" >> fichiers_diff
      fi
      if echo "$path" | grep -q "^/$SECOND_DIR"; then
        realpath "$MAIN_SECOND_DIR/$path" >> fichiers_diff
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
