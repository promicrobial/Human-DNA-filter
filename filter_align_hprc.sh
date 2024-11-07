#!/bin/bash -l
# author: Caitlin Guccione (cguccion@ucsd.edu)
# date: 1/23/2024
# modified: Nathaniel Cole 10/07/2024
# description: Script to run HPRC alignment on single interleaved FASTQ file.

set -x #used for debugging
export PS4='Line $LINENO: '
#set -e
#set -o pipefail

config_fn=$2
source $config_fn

echo "Output directory = $OUT"

f=$1
basename=$(basename "$f" .fastq)
basename=$(basename "$basename" .fastq.gz)

# verify index directory
if [ ! -d "$MINIMAP2_HPRC_INDEX_PATH" ] || [ -z "$(ls -A "$MINIMAP2_HPRC_INDEX_PATH"/*.mmi 2>/dev/null)" ];
then
  echo "Error: Index directory $MINIMAP2_HPRC_INDEX_PATH does not exist, is not a directory, or does not contain *.mmi files."
  exit 1
fi

echo "Saving temporary files to $TMPDIR"

# Determine if the input file is compressed
if [[ "$f" == *.gz ]]; then
  echo "Input file is compressed (.gz)"
  cp "$f" "${TMPDIR}/seqs_${basename}.fastq.gz"
else
  echo "Input file is NOT compressed"
  cp "$f" "${TMPDIR}/seqs_${basename}.fastq"
fi

# run minimap2 and samtools based on the mode (PE or SE or PE+SE)
# Function to run minimap2 and samtools
run_minimap2() {
  local mmi=$1
  local mode=$2
  local out=$3
  local input_file="${TMPDIR}/seqs_${basename}.fastq.gz"
  local output_file="${TMPDIR}/seqs_new_${basename}.fastq.gz"

  # FIXME returns empty variables

  #if [[ "$f" == *.gz ]]; then
    #local input_file="${TMPDIR}/seqs_${basename}.fastq.gz"
    #local output_file="${TMPDIR}/seqs_new_${basename}.fastq.gz"
    #else
    #local input_file="${TMPDIR}/seqs_${basename}.fastq"
    #local output_file="${TMPDIR}/seqs_new_${basename}.fastq"
  #fi

  echo "The input file is $input_file"
  echo "The output file is $output_file"

  # FIXME conditional to work with =- .gz files
  if [[ "$mode" == "PE" ]]; then
    if [[ -f "$input_file" ]]; then
      echo "Running minimap2 (PE) on ${mmi} and ${input_file}"
      minimap2 -2 -ax sr -t "${THREADS}" "${mmi}" "${input_file}" | \
      samtools fastq -@ "${THREADS}" -f 12 -F 256 > "$output_file"
    else
      echo "Error: Input file '${input_file}' not found."
      exit 1
    fi
    elif [[ "$mode" == "SE" ]]; then
      if [[ -f "$input_file" ]]; then
        echo "Running minimap2 (SE) on ${mmi} and ${input_file}"
        minimap2 -ax sr -t "${THREADS}" "${mmi}" "${input_file}" | \
        samtools fastq -@ "${THREADS}" -f 4 -F 256 > "$output_file"
      else
        echo "Error: Input file '${input_file}' not found."
        exit 1
      fi
    else
      echo "Error: Invalid mode '${mode}'."
      exit 1
    fi

    # Move the output file to the specified directory
  #if [[ -v "$out" ]] && [[ -e "$output_file" ]]; then
    mkdir -p $out
    mv "${output_file}" "${out}/$(basename "$output_file")"
  #elif [[ ! -v "$out" ]]; then
  #    echo "Error: Output directory not assigned to variable 'out'."
  #    exit 1
  #elif [[ ! -e "$output_file" ]]; then
  #    echo "Error: Output file '${output_file}' does not exist."
  #    exit 1
  #fi
}

export -f run_minimap2
export TMPDIR basename THREADS OUT

# Run minimap2 and samtools in parallel
if [[ "${MODE}" == *"PE"* ]]; then
  parallel -j 2 run_minimap2 ::: "${MINIMAP2_HPRC_INDEX_PATH}"/*.mmi ::: PE ::: $OUT
fi

#if [[ "${MODE}" == *"SE"* ]]; then
#  parallel -j 2 run_minimap2 ::: "${MINIMAP2_HPRC_INDEX_PATH}"/*.mmi ::: SE ::: $OUT
#fi

#if [[ "${MODE}" == "PE+SE" ]]; then
#  python scripts/pair.py "${TMPDIR}/seqs_${basename}.fastq.gz" "${TMPDIR}/seqs_new_${basename}.fastq.gz"
#  mv "${TMPDIR}/seqs_new_${basename}.fastq.gz" "${TMPDIR}/${basename}.ALIGN-HPRC.fastq.gz"
#else
#  mv "${TMPDIR}/seqs_${basename}.fastq.gz" "${TMPDIR}/${basename}.ALIGN-HPRC.fastq.gz"
#fi