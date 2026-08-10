# HHsearch formatted databases
# This link: http://ftp.tuebingen.mpg.de/pub/ebio/protevo/toolkit/databases/hhsuite_dbs/

 wget http://ftp.tuebingen.mpg.de/pub/ebio/protevo/toolkit/databases/hhsuite_dbs/NCBI_CD_v3.19.tar.gz
 wget http://ftp.tuebingen.mpg.de/pub/ebio/protevo/toolkit/databases/hhsuite_dbs/PfamA_v38_2.tar.gz
 wget http://ftp.tuebingen.mpg.de/pub/ebio/protevo/toolkit/databases/hhsuite_dbs/phrogs_v4.tar.gz
 wget http://ftp.tuebingen.mpg.de/pub/ebio/protevo/toolkit/databases/hhsuite_dbs/uniprot_sprot_vir70_Nov_2021.tar.gz

# After unzipping, the file names need to be reformatted for hhsearch
ls /path/to/project_tools/hhsuite_db/NCBI_CD_v3.19/*_cs219.ffdata | sed 's/_cs219\.ffdata$//'
ls /path/to/project_tools/hhsuite_db/PfamA_v38_2/*_cs219.ffdata | sed 's/_cs219\.ffdata$//'
ls /path/to/project_tools/hhsuite_db/phrogs_v4/*_cs219.ffdata | sed 's/_cs219\.ffdata$//'
ls /path/to/project_tools/hhsuite_db/uniprot_sprot_vir70_Nov_2021/*_cs219.ffdata | sed 's/_cs219\.ffdata$//'
