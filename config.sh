#!/bin/bash

# configure experiment parameters
#IN="/local/storage/nc564/raw_seq_QC/depleted_trimmed_files_mumbai_ID14768"
IN="data"
OUT="data/host-filtered"
MODE="PE" # "SE" (single-end) or "PE" (paired-end) or "PE+SE" (paired-end then single-end)
METHODS="ALIGN-HPRC" # any combination of "ALIGN-HG38", "ALIGN-T2T", "ALIGN-HPRC", or "INDEX-HPRC"
SAVE_INTERMEDIATE=1 # 0 for TRUE and 1 for FALSE
THREADS=25

# configure index filtration parameters
METRIC="custom" # "max", "average", or "custom"
THRESHOLD=0.175 # suggested thresholds are __ for "max", __ for "average", and 0.175 for "custom"
MIN_RUN_LENGTH=5

# configure software and reference paths
CONDA_ENV_NAME="human-filtration"
#MOVI_PATH="/path/to/movi-default" # path to movi-default executable
#MOVI_INDEX_PATH="ref/movi" # path to prebuilt movi_index.bin
MINIMAP2_PATH="/programs/minimap2-2.28/minimap2" # path to minimap2 executable
MINIMAP2_HG38_INDEX_PATH="/local/workdir/nc564/human_host_check/human_host_filtration/ref/huma-GRC-db.mmi" # one index
MINIMAP2_T2T_INDEX_PATH="/local/workdir/nc564/human_host_check/human_host_filtration/ref/human-GCA-phix-db.mmi" # one index
MINIMAP2_HPRC_INDEX_PATH="/local/workdir/nc564/human_host_check/human_host_filtration/ref/mmi" # directory of indexes
ADAPTERS="/local/workdir/nc564/human_host_check/human_host_filtration/ref/known_adapters.fna"
TMP="/local/workdir/nc564/human_host_check/human_host_filtration" # path to temporary directory for writing

# END CONFIGURATION

# check variables are valid
if [ -z "$TMP" ]; then
  echo "TMP is not set. Please set TMP to a valid directory."
  exit 1
fi

# check modes are valid
if [[ "$MODE" != "PE" && "$MODE" != "SE" && "$MODE" != "PE+SE" ]]; then
    echo "Error: Invalid MODE. MODE must be 'PE', 'SE', or 'PE+SE'."
    exit 1
fi

# define filtration map
declare -A file_map
file_map["FASTP"]="filter_fastp.sh"
file_map["ALIGN-HG38"]="filter_align_hg38.sh"
file_map["ALIGN-T2T"]="filter_align_t2t.sh"
file_map["ALIGN-HPRC"]="filter_align_hprc.sh"
file_map["INDEX-HPRC"]="filter_index_hprc.sh"

source ~/.bashrc
conda activate $CONDA_ENV_NAME
