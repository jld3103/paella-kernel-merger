#!/bin/bash
output_file=$1
input_files=${*:2}

rm -rf "$output_file"

declare -A config

for input_file in $input_files; do
  while read -r line; do
    if [[ ! "$line" =~ ^# ]]; then
      IFS='=' read -r -a parts <<<"$line"
      key=${parts[0]}
      value=${parts[1]}
      config[$key]=$value
    fi
  done <"$input_file"
done

for key in "${!config[@]}"; do
  echo "$key=${config[$key]}" >>"$output_file"
done
