#!/bin/bash
set -e
set -o pipefail

echo "Building human minimap2 databases"
#minimap2 -ax sr -t 12 -d "$home/ref/human-GRC-db.mmi" "$home/ref/GRCh38_latest_genomic.fna"
#minimap2 -ax sr -t 12 -d "$home/ref/human-GCA-phix-db.mmi" "$home/ref/human-GCA-phix.fna"



echo "building pangenome minimap databases"

find "$home/ref/pangenomes" -type f -name "*.fa" > pangenomes.txt

while IFS= read -r file; do echo "$file"; done < pangenomes.txt | parallel -j 15 --eta 'file={}
    if [ -f "$file" ]; then
    echo 'indexing' $file
    filename=$(basename "$file")
    mmi_name="${filename%.*}"
    minimap2 -t 2 -d $home/ref/mmi/$mmi_name.mmi $file
    fi'

echo 'done indexing'

# remove large unneeded files
#rm $home/ref/GCA_009914755.4_T2T-CHM13v2.0_genomic.fna $home/ref/GRCh38_latest_genomic.fna $home/ref/human-GCA-phix.fna
