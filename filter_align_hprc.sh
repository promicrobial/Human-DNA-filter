#!/bin/bash -l
# author: Caitlin Guccione (cguccion@ucsd.edu)
# date: 1/23/2024
# description: Script to run HPRC alignment on single interleaved FASTQ file.
# parent: filter.array.sbatch
# modified: Nathaniel Cole 11/11/2024


set -x
#set -e
#set -o pipefail

config_fn=$2
source $config_fn
conda activate $CONDA_ENV_NAME

f=$1
#f="data/50.00p-HG002.maternal_50.00p-FDA-ARGO-41_sim_SUB-h100000-m100000_R1.fastq"
basename=$(basename "$f" _R1.fastq)
echo $basename

# verify index directory
if [ ! -d "$MINIMAP2_HPRC_INDEX_PATH" ] || [ -z "$(ls -A "$MINIMAP2_HPRC_INDEX_PATH"/*.mmi 2>/dev/null)" ]; then
  echo "Error: Index directory $MINIMAP2_HPRC_INDEX_PATH does not exist, is not a directory, or does not contain *.mmi files."
  #exit 1
fi

# run minimap2 and samtools based on the mode (PE or SE or PE+SE)
new_basename="${basename%.*}"
#echo $new_basename

cp "${f}" "${TMPDIR}"/seqs_${new_basename}_R1.fastq
cp "${f/_R1/_R2}" "${TMPDIR}"/seqs_${new_basename}_R2.fastq
#ls $TMPDIR # copy of pre-proceed R1 files

if [[ "${MODE}" == *"PE"* ]]; then
  for mmi in "${MINIMAP2_HPRC_INDEX_PATH}"/*.mmi
  do
    echo "Running minimap2 (PE) on ${mmi}"
    minimap2 -2 -ax sr -t "${THREADS}" "${mmi}" "${TMPDIR}"/seqs_${new_basename}_R1.fastq "${TMPDIR}"/seqs_${new_basename}_R2.fastq | \
      samtools fastq -@ "${THREADS}" -f 12 -F 256 > "${TMPDIR}"/seqs_new_${new_basename}.fastq
    mv "${TMPDIR}"/seqs_new_${new_basename}.fastq "${TMPDIR}"/seqs_${new_basename}.fastq
  done
fi

# MOD to match above
if [[ "${MODE}" == *"SE"* ]]; then
  for mmi in "${MINIMAP2_HPRC_INDEX_PATH}"/*.mmi
  do
    echo "Running minimap2 (SE) on ${mmi}"
    minimap2 -2 -ax sr --no-pairing -t "${THREADS}" "${mmi}" "${TMPDIR}"/seqs_${new_basename}.fastq | \
      samtools fastq -@ "${THREADS}" -f 4 -F 256 > "${TMPDIR}"/seqs_new_${new_basename}.fastq
    mv "${TMPDIR}"/seqs_new_${new_basename}.fastq "${TMPDIR}"/seqs_${new_basename}.fastq
  done
fi

if [[ "${MODE}" == "PE+SE" ]]; then
  python scripts/pair.py "${TMPDIR}"/seqs_${new_basename}.fastq "${TMPDIR}"/seqs_new_${new_basename}.fastq
  mv "${TMPDIR}"/seqs_new_${new_basename}.fastq "${TMPDIR}/${new_basename}.ALIGN-HPRC.fastq"
else
  mv "${TMPDIR}"/seqs_${new_basename}.fastq "${OUT}/${new_basename}.ALIGN-HPRC.fastq"
fi

