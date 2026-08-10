# Based on accession numbers from btyper3
source /labs/Hird/usr/miniforge3/etc/profile.d/conda.sh
conda activate /labs/Hird/usr/EAGER_sequences/project_tools/fetch_env

datasets download genome accession GCF_XXXXXXX --include genome #gff3,rna,cds,protein,genome,seq-report
unzip ncbi_dataset.zip

conda deactivate
# Skani triangle for ani matrix
# combine all genomes of interest into same directory
conda activate /labs/Hird/usr/EAGER_sequences/project_tools/taxonomy_env
skani triangle all_genomes/*.fna -o ani_matrix.txt -t 16 --full-matrix

# skani github python script for generating hierarchical clustered ani matrix heatmap
# https://github.com/bluenote-1577/skani/blob/main/scripts/clustermap_triangle.py
