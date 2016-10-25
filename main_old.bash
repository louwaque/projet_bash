#!/bin/bash

HASH_FILENAME="HASH"
export HASH_FILENAME

FIRST_SOURCE_DIR="$(realpath ./dossier_1)"
FIRST_TMP_DIR=/tmp/hash/hash_1

SECOND_SOURCE_DIR="$(realpath ./dossier_2)"
SECOND_TMP_DIR=/tmp/hash/hash_2

#function do_file {
  #SOURCE="/bin"
  #TMP_DIR=/tmp/hash_1

  #echo ": $SOURCE_DIR : $TMP_DIR"

  #c'est débile comme idé comme on reste tout le temps dans le meme dossier et que la fonction est rapeler à chaque nouveau dossier
  # directories=()
  # echo "p $PWD"
  #
  # for path in "$@"; do
  #   local_path="$PWD/$path"
  #   #realpath remove useless absolute directories
  #   tmp_path="$TMP_DIR/$(realpath --relative-to="$SOURCE_DIR" "$local_path")"
  #    echo "path:  $path"
  #    echo "local_path:  $local_path"
  #    echo "tmp_path:  $tmp_path"
  #   if [ -d "$local_path" ]; then
  #     #echo "is dir"
  #     mkdir -p "$tmp_path"
  #   else
  #     md5sum "$path" >> "$(dirname "$tmp_path")/HASH"
  #
  #     in_array=0
  #     for (( i = 0; i < "${#directories[@]}"; i++ )); do
  #       if [ "${directories[i]}" == "$(dirname "$tmp_path")" ]; then
  #         in_array=1
  #       fi
  #     done
  #
  #     if [ "$in_array" -eq 0 ]; then
  #       directories+=("$(dirname "$tmp_path")")
  #     fi
  #   fi

    #autre code

    #tmp_path="$TMP_DIR/${path:2}"
    # tmp_path="$TMP_DIR/${path:2}"
    # echo "$PWD"
    # echo "? $tmp_path"
    # if [ -d "$path" ]; then
    #   mkdir -p "$tmp_path"
    #   directories+=("$tmp_path")
    # else
    #   md5sum "$path" >> "$(dirname "$tmp_path")/HASH"
    # fi

    #autre code

#   done
#
#   for (( i=${#directories[@]}-1 ; i>=0 ; i-- )) ; do
#     path="${directories[i]}"
#
#     echo "d $path"
#     if [ "$(realpath $path)" != "$(realpath $tmp_path)" ]; then
#       echo "d hash $path/HASH to $(dirname "$path")/HASH"
#       date >> "$(dirname "$path")/HASH"
#       md5sum "$path/HASH" >> "$(dirname "$path")/HASH"
#     fi
#   done
# }
#export -f do_file

function fait_hash {
  local path
  for path in *; do
    local source_path
    source_path=$(realpath --relative-to="$SOURCE_DIR" "$path")
    echo "source: $source_path"
    if [ -d $path ]; then

      mkdir -p "$TMP_DIR/$source_path"

      cd "$path" || return
      fait_hash
      #ATTENTION path et source_path sont modifier par fait_hash
      cd ..

      echo "!!! $path $source_path"
      echo "!! $TMP_DIR/$source_path/$HASH_FILENAME $TMP_DIR/$(dirname "$source_path")/$HASH_FILENAME"
      md5sum "$TMP_DIR/$source_path/$HASH_FILENAME" >> "$TMP_DIR/$(dirname "$source_path")/$HASH_FILENAME"

    else
      md5sum "$path" >> "$TMP_DIR/$(dirname "$source_path")/$HASH_FILENAME"
    fi
  done
}

function test_hash {
  first_file_hash="$1"
  second_file_hash="$2"

  local line
  while read line; do
    original_hash=$(echo "$line" | cut -d ' ' -f1)
    original_file=$(echo "$line" | cut -d ' ' -f3)
    file=$(echo "$original_file" | sed "s/$first_file_hash//g")
    second_hash=$(cat "$second_file_hash" | grep "$file" | cut -d ' ' -f1)
    #echo "$original_file $original_hash $second_hash"

    if [ -z "$second_hash" ]; then
      echo "! not exist $file"
    fi

    if [ "$original_hash" != "$second_hash" ]; then
      echo "! $file $path"
      #if dir rentre dedans !
    fi
  done < "$first_file_hash"
}

function compare_hash {
  local path

  if [ -f "HASH1" ]; then
    if [ -f "HASH2" ]; then
      # local line
      # while read line; do
      #   original_hash=$(echo "$line" | cut -d ' ' -f1)
      #   original_file=$(echo "$line" | cut -d ' ' -f3)
      #   file=$(echo "$original_file" | sed 's/HASH1//g')
      #   second_hash=$(cat "HASH2" | grep "$file" | cut -d ' ' -f1)
      #   #echo "$original_file $original_hash $second_hash"
      #
      #   if [ -z "$second_hash" ]; then
      #     echo "! not exist $file"
      #   fi
      #
      #   if [ "$original_hash" != "$second_hash" ]; then
      #     echo "! $file $path"
      #     #if dir rentre dedans !
      #   fi
      # done < "HASH1"
      test_hash "HASH1" "HASH2"
      test_hash "HASH2" "HASH1"
    fi
  fi

  for path in *; do
    if [ -d "$path" ]; then
      cd "$path" || return
      compare_hash
      cd ..
    fi
  done
}

rm -r "$FIRST_TMP_DIR"
rm -r "$SECOND_TMP_DIR"

export SOURCE_DIR="$FIRST_SOURCE_DIR"
export TMP_DIR="$FIRST_TMP_DIR"
HASH_FILENAME="HASH1"
cd "$SOURCE_DIR" || return
fait_hash
#find "$SOURCE_DIR" -execdir bash -c 'do_file "$@";' -- {} +

export SOURCE_DIR="$SECOND_SOURCE_DIR"
#export TMP_DIR="$SECOND_TMP_DIR"
HASH_FILENAME="HASH2"
cd "$SOURCE_DIR" || return
fait_hash
#find "$SOURCE_DIR" -execdir bash -c 'do_file "$@";' -- {} +


cd "$TMP_DIR" || return
compare_hash
