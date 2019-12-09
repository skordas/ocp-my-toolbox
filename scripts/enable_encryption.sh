#!/bin/bash

# Usage: ./enable_encryption.sh <enable/disable> <timeout_in_minutes>
# To enable: ./enable_encryption.sh enable 20
# to disable: ./enable_encryption.sh disable 20

red="\e[31m"
green="\e[32m"
reset="\e[0m"

timeout=$(($2*60))

function log {
    echo -e "[$(date "+%F %T")]: $*"
}

function enable_encryption {
    oc patch apiserver/cluster -p '{"spec":{"encryption": {"type":"aescbc"}}}' --type merge
    log "Encryption enabled"
}

function disable_encryption {
    oc patch apiserver/cluster -p '{"spec":{"encryption": {"type":"identity"}}}' --type merge
    log "Encryption disabled"
}

function wait_until_encryption_is_ready {
    start_time=$(date +%s)
    while (( ($(date +%s) - ${start_time}) < ${timeout} ));
    do
        echo -e "Not ready yet. Time from beginning: $(( $(date +%s) - ${start_time} )) seconds"
        echo -e "Retrying in 30 seconds"
        sleep 30

        if [[ $(oc get secret ${oc_secrets_name} -o yaml -n openshift-config-managed | grep -c encryption.apiserver.operator.openshift.io-key) == 0 ]]; then
            log "${red}Missing: encryption.apiserver.operator.openshift.io-key in ${oc_secrets_name} secret.${reset}"
            continue
        else
            log "${green}Founded: encryption.apiserver.operator.openshift.io-key in ${oc_secrets_name} secret.${reset}"
        fi
        if [[ $(oc get secret ${oc_secrets_name} -o yaml -n openshift-config-managed | grep encryption.apiserver.operator.openshift.io/migrated-resources | grep -c '{"Group":"oauth.openshift.io","Resource":"oauthaccesstokens"}') == 0 ]]; then
            log "${red}Missing: encryption.apiserver.operator.openshift.io/migrated-resources - oauthaccesstokens in ${oc_secrets_name} secret.${reset}"
            continue
        else
            log "${green}Founded: encryption.apiserver.operator.openshift.io/migrated-resources - oauthaccesstokens in ${oc_secrets_name} secret.${reset}"
        fi
        if [[ $(oc get secret ${oc_secrets_name} -o yaml -n openshift-config-managed | grep encryption.apiserver.operator.openshift.io/migrated-resources | grep -c '{"Group":"oauth.openshift.io","Resource":"oauthauthorizetokens"}') == 0 ]]; then
            log "${red}Missing: encryption.apiserver.operator.openshift.io/migrated-resources - oauthauthorizetokens in ${oc_secrets_name} secret.${reset}"
            continue
        else
            log "${green}Founded: encryption.apiserver.operator.openshift.io/migrated-resources - oauthauthorizetokens in ${oc_secrets_name} secret.${reset}"
        fi
        if [[ $(oc get secret ${oc_secrets_name} -o yaml -n openshift-config-managed | grep encryption.apiserver.operator.openshift.io/migrated-resources | grep -c '{"Group":"route.openshift.io","Resource":"routes"}') == 0 ]]; then
            log "${red}Missing: encryption.apiserver.operator.openshift.io/migrated-resources - routes in ${oc_secrets_name} secret.${reset}"
            continue
        else
            log "${green}Founded: encryption.apiserver.operator.openshift.io/migrated-resources - routes in ${oc_secrets_name} secret.${reset}"
        fi
        if [[ $(oc get secret ${oc_secrets_name} -o yaml -n openshift-config-managed | grep -c encryption.apiserver.operator.openshift.io/migrated-timestamp) == 0 ]]; then
            log "${red}Missing: encryption.apiserver.operator.openshift.io/migrated-timestamp in ${oc_secrets_name} secret.${reset}"
            continue
        else
            log "${green}Founded: encryption.apiserver.operator.openshift.io/migrated-timestamp in ${oc_secrets_name} secret.${reset}"
        fi
        if [[ $(oc get secret ${kb_secrets_name} -o yaml -n openshift-config-managed | grep -c encryption.apiserver.operator.openshift.io-key) == 0 ]]; then
            log "${red}Missing: encryption.apiserver.operator.openshift.io-keyin ${kb_secrets_name} secret.${reset}"
            continue
        else
            log "${green}Founded: encryption.apiserver.operator.openshift.io-keyin ${kb_secrets_name} secret.${reset}"
        fi
        if [[ $(oc get secret ${kb_secrets_name} -o yaml -n openshift-config-managed | grep encryption.apiserver.operator.openshift.io/migrated-resources | grep -c '{"Group":"","Resource":"configmaps"}') == 0 ]]; then
            log "${red}Missing: encryption.apiserver.operator.openshift.io/migrated-resources - configmaps in ${kb_secrets_name} secret.${reset}"
            continue
        else
            log "${green}Founded: encryption.apiserver.operator.openshift.io/migrated-resources - configmaps in ${kb_secrets_name} secret.${reset}"
        fi
        if [[ $(oc get secret ${kb_secrets_name} -o yaml -n openshift-config-managed | grep encryption.apiserver.operator.openshift.io/migrated-resources | grep -c '{"Group":"","Resource":"secrets"}') == 0 ]]; then
            log "${red}Missing: encryption.apiserver.operator.openshift.io/migrated-resources - secrets in ${kb_secrets_name} secret.${reset}"
            continue
        else
            log "${green}Founded: encryption.apiserver.operator.openshift.io/migrated-resources - secrets in ${kb_secrets_name} secret.${reset}"
        fi
        if [[ $(oc get secret ${kb_secrets_name} -o yaml -n openshift-config-managed | grep -c encryption.apiserver.operator.openshift.io/migrated-timestamp) == 0 ]]; then
            log "${red}Missing: encryption.apiserver.operator.openshift.io/migrated-timestamp in ${kb_secrets_name} secret.${reset}"
            continue
        else
            log "${green}Founded: encryption.apiserver.operator.openshift.io/migrated-timestamp in ${kb_secrets_name} secret.${reset}"
        fi

        log "${green}DONE${reset}"
        echo -e "Time from beginning: $(( $(date +%s) - ${start_time} )) seconds"
        exit 0
    done

    log "${red}Timeout!${reset}"
    exit 1
}

# Getting secrets names.
oc_secrets_num=$(oc get secrets -n openshift-config-managed | grep -c encryption-key-openshift-apiserver)
kb_secrets_num=$(oc get secrets -n openshift-config-managed | grep -c encryption-key-openshift-kube-apiserver)
((oc_secrets_num=${oc_secrets_num}+1))
((kb_secrets_num=${kb_secrets_num}+1))
oc_secrets_name=$(echo -e "encryption-key-openshift-apiserver-${oc_secrets_num}")
kb_secrets_name=$(echo -e "encryption-key-openshift-kube-apiserver-${kb_secrets_num}")
log "Secrets to check:"
log "${oc_secrets_name}"
log "${kb_secrets_name}"

if [[ "$1" == "enable" ]]
then
    enable_encryption
elif [[ "$1" == "disable" ]]
then
    disable_encryption
else
    echo -e "${red}First argument should be 'enable' to enable encryption or 'disable' to disable encryption${reset}"
    exit 1
fi

wait_until_encryption_is_ready
