#!/usr/bin/env bash

NAMESPACE=${VSPHERE_NAMESPACE}
POLL_INTERVAL=30  # seconds

echo "Waiting for machines to finish provisioning in namespace: $NAMESPACE"

while true; do
    # Get machine statuses, skip header
    STATUSES=$(kubectl get machines -n "$NAMESPACE" --no-headers | awk '{print $NF}')

    # Count states
    PROVISIONING_COUNT=$(echo "$STATUSES" | grep -c "^Provisioning$")
    RUNNING_COUNT=$(echo "$STATUSES" | grep -c "^Running$")
    TOTAL_COUNT=$(echo "$STATUSES" | wc -l | tr -d ' ')

    echo "Total machines: $TOTAL_COUNT | Provisioning: $PROVISIONING_COUNT | Running: $RUNNING_COUNT"

    # If no machines are provisioning AND all are running
    if [[ "$PROVISIONING_COUNT" -eq 0 && "$RUNNING_COUNT" -eq "$TOTAL_COUNT" ]]; then
        echo "All machines are in Running state."
        echo "Cluster creation is done!"
        exit 0
    fi

    echo "⏸Machines still provisioning... checking again in $POLL_INTERVAL seconds."
    sleep "$POLL_INTERVAL"
done