
source ~/.ssh/opentlc_credentials.rc

./order_svc.sh -y -c 'OPENTLC Automation' -i 'Ansible Advanced' -t 1 -d 'dialog_expiration=7;region=na;nodes=1;dialog_runtime=8'
