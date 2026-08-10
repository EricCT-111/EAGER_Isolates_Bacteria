## HHsearch Remote Homology Detection
Standard HHsearch approach includes:
* Downloading the ~50GB Uniclust30 database, or the much larger full BFD database (~1TB)
* Using HHblits to create MSA sequence alignment files (.a3m)
* Downloading the other databases found at http://ftp.tuebingen.mpg.de/pub/ebio/protevo/toolkit/databases/hhsuite_dbs/
* Running HHsearch against them

Process used in this project
* Run jackhmmer against the Uniref50.fasta in shared hpc databases to create .sto files
* HHsuite reformat command to create .a3m files
* Databases downloaded:
    * NCBI_CD_v3.19 (4.0 GB)
    * PfamA_v38_2 (3.1 GB)
    * phrogs_v4 (3.0 GB)
    * uniprot_sprot_vir70 (3.3 GB)
   
