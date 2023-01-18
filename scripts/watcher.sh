#!/bin/bash

break_time=30
logfile=$(date +%Y%m%d_%k%M%S.log)

function log {
	echo -e "\n------------------------------------------------------------------------------------------------------------------------------------" | tee -a $logfile
    echo -e "[$(date "+%F %T")]: $*" | tee -a $logfile
    echo -e "------------------------------------------------------------------------------------------------------------------------------------" | tee -a $logfile
}

while :
  do
  echo -e "\n====================================================================================================================================" | tee -a $logfile
  # Checking clusterversion
  log "oc get clusterversion"
  oc get clusterversion | tee -a $logfile

  # Checking nodes
  log "oc get nodes"
  oc get nodes | tee -a $logfile

  abnormal_nodes=$(oc get nodes -o jsonpath='{range .items[*]}{.metadata.name} {range .status.conditions[*]} {.type}={.status}{end}{"\n"}{end}' | grep -w -E 'Ready=False|Ready=Unknown' | cut -f 1 -d " ")
  for node in $abnormal_nodes;
    do
      log "oc describe node $node"
      oc describe node $node | tee -a $logfile
  done

  # Checking machineset
  log "oc get machineset -n openshift-machine-api"
  oc get machineset -n openshift-machine-api | tee -a $logfile

  # Checking machines
  log "oc get machines -n openshift-machine-api"
  oc get machines -n openshift-machine-api | tee -a $logfile

  # Checking cluster operators
  log "oc get co"
  oc get co | tee -a $logfile

  abnormal_co=$(oc get co -o jsonpath='{range .items[*]}{.metadata.name} {range .status.conditions[*]} {.type}={.status}{end}{"\n"}{end}' | grep -w -E 'Available=False|Progressing=True|Degraded=True' | cut -f 1 -d " ")
  for co in $abnormal_co;
    do
    log "oc describe co $co"
    oc describe co $co | tee -a $logfile
  done

  sleep $break_time
done