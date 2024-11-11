#!/bin/bash -l
# author: Lucas Patel (lpatel@ucsd.edu)
# date: 12/22/23
# modified: Nathaniel Cole 11/11/2024
# description: Script to run

set -x

config_fn=$1
source ${config_fn}
export config_fn="${config_fn}"

echo "Beginning host filtration (job array mode) on directory: ${IN}"

export TMPDIR="$(basename $(mktemp -d))"
mkdir ${TMPDIR}
echo $TMPDIR

find "$IN" -maxdepth 1 -type f \( -name '*_R1*.fastq' -o -name '*_R1*.fastq.gz' \) -exec sh -c 'for f; do echo "$f"; done >> "$TMPDIR/r1_files.txt"' sh {} +
find "$IN" -maxdepth 1 -type f \( -name '*_R2*.fastq' -o -name '*_R2*.fastq.gz' \) -exec sh -c 'for f; do echo "$f"; done >> "$TMPDIR/r2_files.txt"' sh {} +
find "$IN" -maxdepth 1 -type f \( -name '*.fastq' -o -name '*.fastq.gz' \) | grep -vE '_R[12]' > "$TMPDIR/other_files.txt"

echo "Found $(wc -l < "$TMPDIR/r1_files.txt") R1 FASTQ files" && echo "Found $(wc -l < "$TMPDIR/r2_files.txt") R2 FASTQ files" && [ $(wc -l < "$TMPDIR/r1_files.txt") -eq $(wc -l < "$TMPDIR/r2_files.txt") ] || echo "Warning: The number of R1 and R2 FASTQ files is not the same."
echo "Found $(wc -l < "$TMPDIR/other_files.txt") other files"

cat "$TMPDIR/r1_files.txt" "$TMPDIR/other_files.txt" > "$TMPDIR/all_files.txt"
num_jobs=$(wc -l < "$TMPDIR/all_files.txt")
echo $num_jobs

sbatch --array=1-$num_jobs filter.array.sbatch
