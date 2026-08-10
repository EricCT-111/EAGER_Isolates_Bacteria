# Databases Reference

This document describes where each shared database is located and how local databases are downloaded.

---

## Databases
| Environment / Container | Main Tool(s) | Database | Source |
|---|---|---|---|
| amrfinder_env | amrfinderplus | amrfinder_db | `amrfinder_update -d /path` |
| analysis_env | biopython, mmseq2, hmmer, diamond, blast, mummer4, seqkit | None | NA |
| assembly_env | unicycler, flye, dnaapler, ragtag | None | NA | 
| bakta_env | bakta | 2025.02.24 | `/isg/shared/databases/bakta/v2025.02.24/db/` |
| checkm2_env | checkm2 | checkm2 DIAMOND database | `checkm2 database --download --path /path` |
| fcs_adaptor | fcs_adaptor | NCBI UniVec | `module load singularity/3.5.2` `cd /path/containers` `curl -LO https://github.com/ncbi/fcs/raw/main/dist/run_fcsadaptor.sh` `chmod 755 run_fcsadaptor.sh` `curl https://ftp.ncbi.nlm.nih.gov/genomes/TOOLS/FCS/releases/latest/fcs-adaptor.sif -Lo fcs-adaptor.sif` `curl -LO https://github.com/ncbi/fcs/raw/main/dist/fcs.py` `curl https://ftp.ncbi.nlm.nih.gov/genomes/TOOLS/FCS/releases/latest/fcs-gx.sif -Lo fcs-gx.sif`|
| fcs_gx_env | fcs_gx | fcs_gx databse | `/isg/shared/databases/fcs-gx/v2023.01.24` |
| fetch_env | entrez-direct, ncbi-datasets-cli, sra-tools, seqkit, pigz | None | NA |
| final_qc_env | quast, busco | busco_odb12 | there is a shared db but the naming structure breaks, `busco --download_path /path` |
| genomad_env | genomad | genomad marker database | `genomad download-database /path` |
| hhsearch_env | hhsuite, mmseq2, hmmer, mafft, famsa | Used in this project (NCBI_CD_v3.19 PfamA_v38_2, phrogs_v4, uniprot_sprot_vir70,) | `wget` <[link](http://ftp.tuebingen.mpg.de/pub/ebio/protevo/toolkit/databases/hhsuite_dbs/)>, see https://github.com/soedinglab/hh-suite for more database info, post download processing discussed in /other_analyses/hhsearch/build_hhsearch_db.sh |
| hybracter_env | hybracter | plassembler | `hybracter install -d /path` |
| metabolism_env | eggnog-mapper, kegganog | eggnog_db | `/isg/shared/databases/eggnog/v5.0.2/` |
| mge_env | integron_finder, isescan | None | NA | 
| mobsuite_env | mobsuite | mobsuite_db | `mob_init -d /path` |
| orthofinder_env | orthofinder, entrez-direct, fasttree, iqtree, mafft, | None | NA |
| phage_env | pharokka, checkv | pharokka (phrogs, card, vfdb), checkv | `pharokka install -o /path` `checkv download_database /path` | 
| phold_env | phold | ColabFold, ESMFold of PHROG, efam, enVhog | `phold install -d /path` or `phold install --extended_db /path` | 
| polish_env | polypolish, pypolca | None | NA |
| qc_env | fastp, fastqc, nanoq, chopper, filtlong, porechop_abi, minimap2, bwa-mem2, samtools, seqkit | None | NA |
| submission_env | table2asn, biopython | None | NA |
| taxmyphage_env | taxmyphage | ICTV VMR MSL41.v1 | `taxmyphage install -db /path` |
| taxonomy_env | GTDB-Tk, Skani | r226 | `/isg/shared/databases/gtdb/v226.0/release226/` |
| vcontact3_env | vcontact3 | virus refseq database v230 | `vcontact3 prepare_databases -s /path` |
