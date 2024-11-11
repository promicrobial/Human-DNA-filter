#!/bin/bash -l
# author: Lucas Patel (lpatel@ucsd.edu)
# date: 12/22/23
# description: Script to run fastp on arbitrary inputs as part of a full host filtration pipeline. The adapters used are based on manual curation.

#SBATCH -J host_filter
#SBATCH --mail-type=ALL
#SBATCH --mail-user=nc564@cornell.edu
#SBATCH --time=96:00:00
#SBATCH --ntasks=12
#SBATCH --nodes=1
#SBATCH --mem=22500
#SBATCH --output=%x-%A_%a.out
#SBATCH --error=%x-%A_%a.err
#SBATCH --chdir=/local/workdir/nc564/human_host_check/original_filtration_pipeline/human_host_filtration

### !!!#SBATCH --exclusive

source ${config_fn}
echo "Beginning host filtration (job array mode) on directory: ${IN}"

strip_extensions() {
  local file_name="$1"
  local stripped_name="${file_name%.fastq.gz}"
  stripped_name="${stripped_name%.fastq}"
  echo "$stripped_name"
}

process_files() {
  local r1_file="$1"
  local r2_file="${2:-}"  # Second argument is optional
  local base_name
  local base_name_r2

  # Determine base name based on R1 or single-end file
  if [[ -n "$r2_file" ]]; then
    base_name=$(strip_extensions "$r1_file")
    base_name_r2=$(strip_extensions "$r2_file")
    if [[ "${base_name%_R1*}" != "${base_name_r2%_R2*}" ]]; then
      echo "Error: Mismatch in FASTQ file names: $r1_file and $r2_file"
      exit 1
    fi
  else
    base_name=$(strip_extensions "$r1_file")
  fi

  echo "Running FASTP..."
  bash "${file_map['FASTP']}" "$r1_file" "$r2_file" "$config_fn"
  local in_file="${OUT}/fastp/$(basename "$base_name").FASTP.fastq"

  for key in "${METHODS[@]}"; do
    local script="${file_map[$key]}"
    if [[ -f "$script" ]]; then
      echo "Running $key filtration..."
      bash "$script" "$in_file" "$config_fn"
    else
      echo "Key $key not valid or file-path $script not found."
      continue
    fi

    if [ "$SAVE_INTERMEDIATE" -eq 0 ]; then
      mkdir -p "${OUT}/${key,,}"
      mv "${TMPDIR}/$(basename "$base_name").${key}.fastq" "${OUT}/${key,,}/$(basename "$base_name").${key}.fastq"
      in_file="${OUT}/${key,,}/$(basename "$base_name").${key}.fastq"
    else
      in_file="${TMPDIR}/$(basename "$base_name").${key}.fastq"
    fi
  done

  if [[ ! -s "$r2_file" ]]; then #modified logic
    echo "Splitting into R1/R2..."
    bash split_fastq.sh "$in_file" "$config_fn"
  fi
}

line_num=$SLURM_ARRAY_TASK_ID
read -r file <<< $(sed -n "${line_num}p" "$TMPDIR/all_files.txt")
mate=
if [[ "$file" == *"_R1"* ]]; then
  mate="${file/_R1/_R2}"
fi

current_time=$(date +"%T")  # %T format specifier for HH:MM:SS
echo "Time start: $current_time"

process_files "$file" "$mate"

current_time=$(date +"%T")  # %T format specifier for HH:MM:SS
echo "Time end: $current_time"
