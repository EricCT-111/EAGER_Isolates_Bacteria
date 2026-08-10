# EAGER_Isolates
This pipeline assembles and characterizes bacterial isolate genomes from Illumina, Nanopore, or Nanopore/Illumina hybrid reads. It covers de-novo assembly, contamination screening, taxonomy assignment, annotation, and the identification of phage, AMR, virulence, and stress genes, including whether those genes sit on mobilizable elements such as plasmids and insertion sequences.

+It was developed at the Hird Lab to document the analyses performed on a set of cultured wild Neotropical bird intestinal bacterial isolates, and to be reused on new isolates.

## Running the Pipeline
1. Follow `conda_setup.sh` to setup the use newest conda
3. Setup project directory structure and import `env_install.sh` (project independent), `lib.sh`, `run.config`, `paths.config`.

  * Update paths in `env_install.sh` and `paths.config` to match yours
  * Each `script.sh` defaults PIPELINE_DIR to the path inside it, change all `script.sh` PIPELINE_DIR paths to yours with:
    * `sed -i 's|/labs/Hird/usr/EAGER_sequences/scripts|/your/path/scripts|' /your/path/scripts/*.sh`
    * Confirm it worked with `grep -h 'PIPELINE_DIR=' /your/path/scripts/*.sh | sort -u`
     
   * Optional - adjust batch parameters in `run.config`
 
 ```
/labs/Hird/usr/EAGER_sequences/
    |-- samples.csv
    |-- containers/
    |-- databases/
    |-- illumina_samples/
        |-- sample_name/
            |-- sample.fastq
    |-- ont_samples/
        |-- sample_name/
            |-- sample.fastq
    |-- project_tools/
        |-- env_name/
    |-- scripts/
        |-- lib.sh
        |-- paths.config
        |-- run.config
        |-- env_install.sh
        |-- envs/
        |-- install_env_logs/
        |-- logs/
```
    
3. Download environment .yml files into /envs
4. Build environments using `sbatch` `env_install.sh` `name_env`
5. Download environment databases and singularity containers when necessary, see `databases.md` for full information
6. Run scripts, `sbatch script.sh <sample_id>` (sample id found in column 1 of samples.csv), or `sbatch --array=1-<N> script.sh`
   
   Suggested order for scripts:
    * Illumina only samples - `fastp.sh`, `unicycler.sh`, `polish.sh`
    * Hybrid samples - `hybracter.sh`, `nanoq.sh`
    * All samples post assembly/polishing: `fcs_adaptor.sh`, `fcs_gx.sh`, `fcs_clean.sh`, `mapping.sh`, `quast.sh`, `checkm2.sh`, `gtdbtk.sh`, `genomad.sh`, `checkv.sh`, `pharokka.sh`, `taxmyphage.sh`, `bakta.sh`, `amrfinder.sh`, `eggnog.sh`, `mob_recon` (fragmented assemblies only), `mob_typer` (complete plasmid replicons), `mge.sh`
    * Optional:
      * Deeper annotation and proteomic clustering for phages - `phold.sh`, `vcontact.sh`
      * Resolving proteins of interest - (Requires protein extraction into .faa first), `a3m_jackhmmer.sh` + `hhsearch.sh`
    * Optional scripts stored in other_analyses directory, along with other one-off scripts 
    * Per-script details in table below

---

## Script Descriptions
### Main Pipeline Scripts

| Script Name | Function | Tool Parameters |
|---|---|---|
| fastp.sh | trimming / filtering Illumina reads | --detect_adapter_for_pe --correction --cut_front --cut_tail --cut_window_size 4 --cut_mean_quality 20 --qualified_quality_phred 20 --length_required 15 |
| unicycler.sh | de-novo Illumina assembler | default parameters |
| polish.sh | Illumina Polypolish and Pypolca | default parameters | 
| hybracter.sh | Nanopore / Hybrid qc, de-novo assembly, polishing | nano-hq --auto hybrid-single or long-single (nanopore only) |
| nanoq.sh | Nanopore read qc metrics | -f -s -t 5 -vvv |  
| fcs_adaptor.sh | NCBI adaptor/vector contamination screening | --prok --container-engine singularity | 
| fcs_gx.sh | NCBI species level contamination screening | default parameters (requires per sample tax id) |
| fcs_clean.sh | removal of screening findings | default parameters | 
| filter_contigs.sh | removal of contigs <200 bp using seqkit | seqkit seq -m and fx2tab -nl used |
| mapping.sh | read mapping to assemblies, producing samtools stats and coverage | default parameters |
| quast.sh | final assembly correctness metrics | default parameters |
| checkm2 | machine-learning based completeness and contamination | default parameters |
| gtdbtk.sh | taxonomy assignment | classify_wf |
| genomad.sh | prophage, virus, plasmid finder/identifier | end-to-end --conservative --enable-score-calibration |
| checkv.sh | virus/prophage quality, contamination, and completeness | end_to_end |
| pharokka.sh | annotation of phages | -m if multi phages in single fasta |
| taxmyphage.sh | taxonomy assignment of phages | default parameters |
| bakta.sh | annotation | --compliant |
| amrfinder.sh | amr, virulence, and stress identification using the DNA, prot, and gff of bakta | --plus --organism (where applicable) |
| eggnog.sh | functional annotation of bakta protein file and decorate gff | --itype proteins -m diamond --sensmode very-sensitive --decorate_gff --decorate_gff_ID_field locus_tag |
| mob_recon.sh | plasmid reconstruction and typing of fragmented assemblies (Illumina reads in this project) | -g (gives mobile genetic element assessment on plasmids) |
| mob_typer | plasmid typing on assemblies with full plasmid replicons (Nanopore in this project) | --multi --biomarker_report -g |
| mge.sh | integron_finder and isescan to identify IS's, integrons to assess mobilizable genes | default parameters |


### Other Analyses

| Script Name | Description | 
|---|---|
| ani_comparison.sh | tools / code used to retrieve type strain genomes from btyper3 and compare ANI with Skani |
| hhsearch.sh | the workflow used to create a3m files of the phage proteins of interest, and HMMER-HMMER (hhsearch) against databases | 
| phage_comparison.sh | collection of tools / code used for comparing bacillus phage with b83 and bmbtp14 (edirect, mummer, blastp, phmmer, orthofinder) |
| phold.sh | structure/fold based further annotation of phage genomes |
| vcontact.sh | proteomic clustering of phage genomes based on viral refseq 230 database | 











