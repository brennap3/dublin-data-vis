library(rattle)
library(rpart.plot)
library(party)
library(partykit)
library(caret)
library(dplyr)
library(sqldf)
library(rPython) ## don't need this just use the system call to execute the python script
library(rvest)
library(magrittr)
library(stringr)
library(tidyr)
library(lubridate)
library(ggplot2)
library(stringi)
library(RColorBrewer)
library(reshape2)
library(caret)
library(plotrix)
library(cowplot)


system("C:\\Users\\Peter\\Anaconda2\\python.exe  C:\\Users\\Peter\\Anaconda2\\vFeed\\vfeedcli.py  -u")

exploits <-read.csv("https://raw.githubusercontent.com/offensive-security/exploit-database/master/files.csv")

setwd("C:\\Users\\Peter\\Anaconda2\\vFeed")

db <- dbConnect(SQLite(), dbname="vfeed.db") #connect to the vfeed
##


## write the local dataframe to the SQLite database
dbWriteTable(db, "exploits", exploits)

##lets see if we can do anything with the exploits db

##lets mod the db and create a view which will join the cve_cpe to the nvd

## NO CREATE OR REPLACE BOO! USE DROP IF EXISTS INSTEAD

dbSendQuery(conn = db,"DROP VIEW IF EXISTS V_vFeed")

dbSendQuery(conn = db,
            "CREATE VIEW  V_vFeed
            AS
            SELECT
            nvd_db.cveid,
            nvd_db.date_published,
            nvd_db.date_modified,
            nvd_db.summary,
            nvd_db.cvss_base,
            nvd_db.cvss_impact,
            nvd_db.cvss_exploit,
            nvd_db.cvss_access_vector,
            nvd_db.cvss_access_complexity,
            nvd_db.cvss_authentication,
            nvd_db.cvss_confidentiality_impact,
            nvd_db.cvss_integrity_impact,
            nvd_db.cvss_availability_impact,
            cve_cpe.cpeid
            FROM nvd_db AS nvd_db
            LEFT JOIN cve_cpe
            ON cve_cpe.cveid=nvd_db.cveid
            ")
			
			
## create T_vulnerability_detail

dbSendQuery(conn = db,"DROP TABLE IF eXISTS  T_vulnerability_detail")


dbSendQuery(conn = db,
            "
			CREATE TABLE T_vulnerability_detail
			AS
SeLECT
cveid,
CASE  WHEN cvss_base == 'not_defined' THEN 0 ELSE cvss_base END as cvss_base,
CASE  WHEN cvss_impact =='not_defined' THEN 0 ELSE cvss_impact END as cvss_impact,
CASE  WHEN cvss_exploit =='not_defined' THEN 0 ELSE cvss_exploit END as cvss_exploit,
CASE  WHEN cvss_access_vector=='network' THEN 1 ELSE 0 END as network_access,
CASE  WHEN cvss_access_vector=='local' THEN 1 ELSE 0 END as local_access, 
CASE  WHEN cvss_access_vector=='adjacent_network' THEN 1 ELSE 0 END as adjacent_network_access, 
CASE  WHEN cvss_access_vector=='not_defined' THEN 1 ELSE 0 END as not_defined_network_access,
CASE  WHEN cvss_access_complexity=='low' THEN 1 ELSE 0 END as low_access_complexity,
CASE  WHEN cvss_access_complexity=='medium' THEN 1 ELSE 0 END as medium_access_complexity,
CASE  WHEN cvss_access_complexity=='high' THEN 1 ELSE 0 END as high_access_complexity,
CASE  WHEN cvss_access_complexity=='not_defined' THEN 1 ELSE 0 END as not_defined_access_complexity,
CASE  WHEN cvss_authentication=='none' THEN 1 ELSE 0 END as none_cvss_authentication,
CASE  WHEN cvss_authentication=='single_instance' THEN 1 ELSE 0 END as single_instance_cvss_authentication,
CASE  WHEN cvss_authentication=='not_defined' THEN 1 ELSE 0 END as not_defined_instance_cvss_authentication,
CASE  WHEN cvss_authentication=='multiple_instances' THEN 1 ELSE 0 END as multiple_instance_cvss_authentication,
CASE  WHEN cvss_confidentiality_impact=='partial' THEN 1 ELSE 0 END as partial_confiidentiality_impact,
CASE  WHEN cvss_confidentiality_impact=='none' THEN 1 ELSE 0 END as none_confiidentiality_impact,
CASE  WHEN cvss_confidentiality_impact=='complete' THEN 1 ELSE 0 END as complete_confiidentiality_impact,
CASE  WHEN cvss_confidentiality_impact=='not_defined' THEN 1 ELSE 0 END as not_defined_confiidentiality_impact,
CASE  WHEN cvss_integrity_impact=='not_defined' THEN 1 ELSE 0 END as not_defined_cvss_integrity_impact,
CASE  WHEN cvss_integrity_impact=='none' THEN 1 ELSE 0 END as none_cvss_integrity_impact,
CASE  WHEN cvss_integrity_impact=='complete' THEN 1 ELSE 0 END as complete_cvss_integrity_impact,
CASE  WHEN cvss_integrity_impact=='partial' THEN 1 ELSE 0 END as partial_cvss_integrity_impact,
CASE  WHEN cvss_availability_impact=='not_defined' THEN 1 ELSE 0 END as not_defined_cvss_availability_impact,
CASE  WHEN cvss_availability_impact=='partial' THEN 1 ELSE 0 END as partial_cvss_availability_impact,
CASE  WHEN cvss_availability_impact=='complete' THEN 1 ELSE 0 END as complete_cvss_availability_impact,
CASE  WHEN cvss_availability_impact=='none' THEN 1 ELSE 0 END as none_cvss_availability_impact
FROM
nvd_db")

dbSendQuery(conn = db,
            "DROP INDEX IF EXISTS cve_idx_vuln_detail")

dbSendQuery(conn = db,
            "DROP INDEX IF EXISTS cve_idx_cpecvemap")

dbSendQuery(conn = db,
            "CREATE INDEX cve_idx_vuln_detail
  ON T_vulnerability_detail (cveid)")
  
dbSendQuery(conn = db,
            "CREATE INDEX cve_idx_cpecvemap
  ON cve_cpe (cveid)")

dbSendQuery(conn = db,"DROP TABLE IF eXISTS  T_cpe_vulnerability_detail")

dbSendQuery(conn = db,"
CREATE TABLE T_cpe_vulnerability_detail
AS
SeLECT
CVE_CPE.cveid AS cveid,
CVE_CPE.cpeid AS cpeid,
cvss_base,
cvss_impact,
cvss_exploit,
network_access,
local_access, 
adjacent_network_access, 
not_defined_network_access,
low_access_complexity,
medium_access_complexity,
high_access_complexity,
not_defined_access_complexity,
none_cvss_authentication,
single_instance_cvss_authentication,
not_defined_instance_cvss_authentication,
multiple_instance_cvss_authentication,
partial_confiidentiality_impact,
none_confiidentiality_impact,
complete_confiidentiality_impact,
not_defined_confiidentiality_impact,
not_defined_cvss_integrity_impact,
none_cvss_integrity_impact,
complete_cvss_integrity_impact,
partial_cvss_integrity_impact,
not_defined_cvss_availability_impact,
partial_cvss_availability_impact,
complete_cvss_availability_impact,
none_cvss_availability_impact
FROM T_vulnerability_detail JOIN cve_cpe on T_vulnerability_detail.cveid=cve_cpe.cveid
")

##

dbSendQuery(conn = db,"DROP INDEX IF EXISTS c_idx_cveid_T_cpe_vulnerability_detailp")

dbSendQuery(conn = db,"CREATE INDEX c_idx_cveid_T_cpe_vulnerability_detailp  ON T_vulnerability_detail (cveid)")
  
dbSendQuery(conn = db,"DROP INDEX IF EXISTS c_idx_cpeid_T_cpe_vulnerability_detail")  
  
dbSendQuery(conn = db,"CREATE INDEX c_idx_cpeid_T_cpe_vulnerability_detail  ON cve_cpe (cpeid)")

dbSendQuery(conn = db,"DROP TABLE IF EXISTS  T_cpe_vulnerability_agg")

dbSendQuery(conn = db,"
CREATE TABLE T_cpe_vulnerability_agg
AS
SELECT 
	cpeid,
	count(cveid) as cveid_cnt,
	sum(cvss_base) as cvss_base_sum,
	sum(cvss_impact) as cvss_impact_sum,
	sum(cvss_exploit) as cvss_exploit_sum,
	sum(network_access) as  network_access_sum,
	sum(local_access) as local_access_sum,
	sum(adjacent_network_access) as adjacent_network_access_sum,
	sum(not_defined_network_access) as not_defined_network_access_sum,
	sum(low_access_complexity) as low_access_complexity_sum,
	sum(medium_access_complexity) as medium_access_complexity_sum,
	sum(high_access_complexity) as high_access_complexity_sum,
	sum(not_defined_access_complexity) as not_defined_access_complexity_sum,
	sum(none_cvss_authentication) as none_cvss_authentication_sum,
	sum(single_instance_cvss_authentication) as single_instance_cvss_authentication_sum,
	sum(not_defined_instance_cvss_authentication) as not_defined_instance_cvss_authentication_sum,
	sum(multiple_instance_cvss_authentication) as multiple_instance_cvss_authentication_sum,
	sum(partial_confiidentiality_impact) as partial_confiidentiality_impact_sum,
	sum(none_confiidentiality_impact) as none_confiidentiality_impact_sum,
	sum(complete_confiidentiality_impact) as complete_confiidentiality_impact_sum,
	sum(not_defined_confiidentiality_impact) as not_defined_confiidentiality_impact_sum,
	sum(not_defined_cvss_integrity_impact) as not_defined_cvss_integrity_impact_sum,
	sum(none_cvss_integrity_impact) as none_cvss_integrity_impact_sum,
	sum(complete_cvss_integrity_impact) as complete_cvss_integrity_impact_sum,
	sum(partial_cvss_integrity_impact) as partial_cvss_integrity_impact_sum,
	sum(not_defined_cvss_availability_impact) as not_defined_cvss_availability_impact_sum,
	sum(partial_cvss_availability_impact) as partial_cvss_availability_impact_sum,
	sum(complete_cvss_availability_impact) as complete_cvss_availability_impact_sum,
	sum(none_cvss_availability_impact) as none_cvss_availability_impact_sum 
FROM T_cpe_vulnerability_detail  
GROUP BY CPEID")

dbSendQuery(conn = db,"
DROP TABLE IF EXISTS  T_exploit_detail")


dbSendQuery(conn = db,"
CREATE TABLE T_exploit_detail
AS
SELECT 
	id,
	CASE  WHEN TYPE == 'remote' THEN 1 ELSE 0 END as REMOTE_EXPLOIT_TYPE,
	CASE  WHEN TYPE == 'local' THEN 1 ELSE 0 END as LOCAL_EXPLOIT_TYPE,
	CASE  WHEN TYPE == 'webapps' THEN 1 ELSE 0 END as WEBAPPS_EXPLOIT_TYPE,
	CASE  WHEN TYPE == 'dos' THEN 1 ELSE 0 END as DOS_EXPLOIT_TYPE,
	CASE  WHEN TYPE == 'shellcode' THEN 1 ELSE 0 END as SHELLCODE_EXPLOIT_TYPE
FROM EXPLOITS")

dbSendQuery(conn = db,"
DROP TABLE IF EXISTS T_exploit_cve")

dbSendQuery(conn = db,"
CREATE TABLE T_exploit_cve
AS
SELECT 
	id,
	cveid,
	REMOTE_EXPLOIT_TYPE,
	LOCAL_EXPLOIT_TYPE,
	WEBAPPS_EXPLOIT_TYPE,
	DOS_EXPLOIT_TYPE,
	SHELLCODE_EXPLOIT_TYPE
FROM T_EXPLOIT_DETAIL JOIN map_cve_exploitdb on T_EXPLOIT_DETAIL.id=map_cve_exploitdb.exploitdbid")


dbSendQuery(conn = db,"DROP TABLE IF EXISTS T_exploit_cve_cpe")

dbSendQuery(conn = db,"
CREATE TABLE T_exploit_cve_cpe
AS
SELECT 
	id as exploitdbid,
	cve_cpe.cveid as cveid,
	cve_cpe.cpeid  as cpeid,
	REMOTE_EXPLOIT_TYPE,
	LOCAL_EXPLOIT_TYPE,
	WEBAPPS_EXPLOIT_TYPE,
	DOS_EXPLOIT_TYPE,
	SHELLCODE_EXPLOIT_TYPE
FROM T_exploit_cve JOIN cve_cpe on T_exploit_cve.cveid=cve_cpe.cveid")

dbSendQuery(conn = db,"DROP TABLE IF EXISTS T_exploit_cve_cpe_agg")

dbSendQuery(conn = db,"CREATE TABLE T_exploit_cve_cpe_agg
AS
SELECT 
	cpeid,
	count(exploitdbid) as exploit_cnt,
	sum(REMOTE_EXPLOIT_TYPE) as remote_exploit_cnt,
	sum(LOCAL_EXPLOIT_TYPE) as local_exploit_cnt,
	sum(WEBAPPS_EXPLOIT_TYPE) as WEBAPPS_EXPLOIT_TYPE_cnt,
	sum(DOS_EXPLOIT_TYPE) as DOS_EXPLOIT_TYPE_cnt,
	sum(SHELLCODE_EXPLOIT_TYPE) as SHELLCODE_EXPLOIT_TYPE_cnt
FROM T_exploit_cve_cpe
GROUP BY cpeid")
 

###
#####
#####
###



			
