#!/bin/bash -l
# author: Lucas Patel (lpatel@ucsd.edu)
# date: 12/22/23
# modified: Nathaniel Cole 10/31/24
# description: Script to run split an interleaved FASTQ file into separate R1/R2 files. Credit: https://biowize.wordpress.com/2015/03/26/the-fastest-darn-fastq-decoupling-procedure-i-ever-done-seen/
#!/bin/bash

set -x

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <interleaved_fastq> <config_file>"
  exit 1
fi

input_fastq="$1"
config_fn="$2"

if [ ! -f "$input_fastq" ]; then
  echo "Error: Input FASTQ file '$input_fastq' not found."
  exit 1
fi

if [ ! -f "$config_fn" ]; then
  echo "Error: Config file '$config_fn' not found."
  exit 1
fi

source "$config_fn"

if [ -z "$OUT" ]; then
  echo "Error: Output directory 'OUT' not defined in the config file."
  exit 1
fi

unweave() {
  local r1="$1"
  local basename_r1=$(basename "$r1" .fastq.gz)
  local basename_r1=$(basename "$basename_r1" .fastq)
  local basename_r1="${basename_r1%.*}"
  local basename_r2=$(echo "$basename_r1" | sed 's/_R1/_R2/')

  if [[ "$r1" == *.gz ]]; then
    echo "${r1} and ${basename_r1} ${basename_r2}"
    paste - - - - - - - - < "$r1" \
        | tee >(cut -f 1-4 | tr '\t' '\n' > "${OUT}/${basename_r1}.fastq.gz") \
        | cut -f 5-8 | tr '\t' '\n' > "${OUT}/${basename_r2}.fastq.gz"
  else
    echo "${r1} and ${basename_r1} ${basename_r2}"
    paste - - - - - - - - < "$r1" \
      | tee >(cut -f 1-4 | tr '\t' '\n' | gzip > "${OUT}/${basename_r1}.fastq.gz") \
      | cut -f 5-8 | tr '\t' '\n' | gzip > "${OUT}/${basename_r2}.fastq.gz"
  fi

}

unweave "$input_fastq"

