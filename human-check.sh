#!/bin/bash

#set -x # WARNING remove before using. This runs code but does not execute for syntax error checks
#export PS4='Line $LINENO: '

# redirect output to log file
exec > >(tee -i log.out) 2>&1

#######################################
#
# Workflow for filtering human reads
#
#######################################

# Author: Nathaniel Cole (nc564@cornell.edu)
# License:
# Version:
# Description: This script performs the steps necessary to detect any human DNA contamination in processed fastq files.
# Usage: ./human-check.sh [options] arg1 arg2 ...

# Last updated: Oct 30 2024

# Output display variables

dim="\033[2m"
sky="\033[38;5;38m"
bold="\033[1m"
red="\033[38;5;203m"

# Reset the colors to the default
reset="\033[0m"

#Print a message in red on a yellow background
# Usage:
#       echo "${RED}${YELLOW}This text is red on a yellow background.${NO_COLOR}"

# Set help variables
SCRIPT_NAME=$(basename "$0")
VER="1.0.0"
home=$(dirname "$0")
home=$(readlink -m "$home")

echo "Home directory set to $home"

########
# Help #
########

# Display the help message and exit
function help() {
  cat << EOF
Usage: $0 [options] --dir <directory> --config <config-file>

This script performs the steps necessary to detect any human DNA contamination in processed fastq files.

  Required parameters:
    -d, --dir            path to working directory
    -c, --config         config.sh file

  Help information:
    -h, --help     Display this help message and exit.
    -v, --version  Display the script version and exit.
EOF
  exit 0
}

##############
# Parameters #
##############

# exit on error

set -e

# show help if run with no parameters

if [[ $# -eq 0 ]]; then
  help
  exit 1
fi

# Display the script version and exit
function version() {
  echo "$SCRIPT_NAME version $VER"
  exit 0
}

# Parse command line options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help ) help; exit 0 ;;
    -v | --version ) version; exit 0 ;;

    -d | --dir ) dir="$2"; 
        shift
        shift ;;
    -c | --config ) CONFIG="$2" 
        shift
        shift ;;

    *) echo "Invalid parameter: $1"
       help; exit 1 ;;
  esac;
done


#########################
# Checking requirements #
#########################

echo "Checking requirements"
# Working directory

if [[ -z "$dir" ]]; then
  echo "Directory not provided. Missing parameter: -d|--dir"
  exit 1
fi

if [[ ! -d "$dir" ]]; then
  echo "Provided directory $dir does not exist."
  exit 1
fi

# get absolute path
dir=$(readlink -m $dir)

echo "# Directory: $dir"

# config file
echo "Checking for config file"

if [[ -z "$CONFIG" ]]; then
  CONFIG="$home"/config.sh
fi

if [[ ! -f "$CONFIG" ]]; then
  echo "Config file $CONFIG does not exist."
  exit 1
fi

CONFIG=$(readlink -m $CONFIG)

if [[ -f $CONFIG ]]; then
  echo "# Config file: $CONFIG"
fi

#########################
# Environment Variables #
#########################

echo "Setting user defined variables"

temp_file=$(mktemp)

head -n -1 "$CONFIG" > "$temp_file"

source "$temp_file"

####################
# Main script body #
####################

cd $home

## `! -d` check if directory DOES NOT exist
## || = OR
## -z check if find command output is empty

: <<'COMMENT'
if [ ! -d "$MINIMAP2_HPRC_INDEX_PATH" ] || [ -z "$(ls -A '$MINIMAP2_HPRC_INDEX_PATH'/*.mmi 2>/dev/null)" ];
then
    echo "Index directory $MINIMAP2_HPRC_INDEX_PATH does not exist, is not a directory, or does not contain any index files (.mmi). Building minimap2 index [$(date)]" then

  # create minimap indexes from reference genomes
  docker1 run -it -v "$dir"/:"$dir" --rm --env "home=$home" --entrypoint /bin/bash biohpc_nc564/human-check -c "source activate $CONDA_ENV_NAME && bash '$home'/scripts/create_minimap2_indexes.sh"

  echo "Indexing complete $(date)"
else
  echo "Pre-exisiting index found in $MINIMAP2_HPRC_INDEX_PATH. Using: $(ls $MINIMAP2_HPRC_INDEX_PATH)"
fi
COMMENT

docker1 run -v "$dir"/:"$dir" --rm --env "home=$home" --entrypoint /bin/bash biohpc_nc564/human-check -c "source activate $CONDA_ENV_NAME && bash '$home'/filter.sh $CONFIG"

rm "$temp_file"

echo "Pipeline complete"
