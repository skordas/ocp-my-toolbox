#!/bin/bash

red="\e[31m"
green="\e[32m"
reset="\e[0m"

function log {
  echo -e "[$(date "+%F %T")]: $*"
}

function test {
  log "TEST: $*"
}

function pass {
  log "${green}PASS $*${reset}"
}

function fail {
  log "${red}FAIL: $*${reset}"
}

# Test 1 No failed pods - Result should be 0
num_of_invalid_pods=$(oc get pods -A --no-headers | grep -c -v -e "Running\|Completed")

# Test 2 No errors - should be 0
num_of_event_errors=$(oc get events -A --no-headers | grep -c Error)

# Test 1
log "TEST: All pods shoud be running or completed"
if [[ $num_of_invalid_pods -eq 0 ]]; then
  pass "All pods are running or are completed"
else
  fail "There is $num_of_invalid_pods with errors\nRun command:\noc get pods -A --no-headers | grep -v -e 'Running\|Completed'"
fi

# Test 2
log "TEST: No events with errors"
if [[ $num_of_event_errors -eq 0 ]]; then
  pass "No events errors"
else
  fail "There is $num_of_event_errors events with errors\nRun command:\noc get events -A --no-headers | grep Error"
fi

# Test 3
for app in $(oc get templates -n openshift --no-headers | awk '{print $1}' | grep example);
do
  oc new-project $(echo "test-app-$app")
  oc label namespace $(echo "test-app-$app") purpose=test
  oc new-app --template=$app
  sleep 10
done

# Clean up:
oc project default