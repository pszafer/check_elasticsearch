# check_elasticsearch
 Check_elasticsearch is plugin for Icinga/Nagios to check health of elasticsearch cluster via elasticsearch API.
 
 ## Required parameters:
    
    -H target host/computer FQDN to check.
    -P port of elasticsearch API, default 9200
    -s indicate that this is single node, so yellow status for you is still good health of elasticsearch.
