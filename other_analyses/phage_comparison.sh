# comparing bacillus phage scm10 with B83 and BMBtp14
source /labs/Hird/usr/miniforge3/etc/profile.d/conda.sh
conda activate /labs/Hird/usr/EAGER_sequences/project_tools/fetch_env

# EDIRECT - to pull viral genomes
efetch -db nuccore -id NC_XXXXX -format fasta > B83.fna

conda deactivate
conda activate /labs/Hird/usr/EAGER_sequences/project_tools/phage_env
# run pharokka on B83 and BMBtp14
conda deactivate
conda activate /labs/Hird/usr/EAGER_sequences/project_tools/phold_env
# run phold on B83 and BMBtp14

conda deactivate
conda activate /labs/Hird/usr/EAGER_sequences/project_tools/analysis_env

# DNA Comparisons with MUMmer
dnadiff -p comparison query.fna ref.fna

# BLASTP comparison
# Make database out of ref
makeblastdb -in ref.faa -dbtype prot -out ref_db
blastp \
    -query query.faa \
    -db ref_db \
    -outfmt "6 qseqid sseqid pident length evalue bitscore qcovs stitle" \
    -evalue 1e-5 \
    -max_target_seqs 5 \
    -num_threads 6 \
    -out query_vs_ref.tsv

# PHMMER comparison
phmmer --tblout scm10_vs_B83.tbl   --domtblout scm10_vs_B83.domtbl   scm10.faa B83.faa
phmmer --tblout scm10_vs_BMB.tbl   --domtblout scm10_vs_BMB.domtbl   scm10.faa BMBtp14.faa
phmmer --tblout B83_vs_BMB.tbl  --domtblout B83_vs_BMB.domtbl  B83.faa BMBtp14.faa
conda deactivate
# ORTHOFINDER comparison
# move all 3 protein files into same directory
conda activate /labs/Hird/usr/EAGER_sequences/project_tools/orthofinder_env
orthofinder -f <directory_name>fetch_env
