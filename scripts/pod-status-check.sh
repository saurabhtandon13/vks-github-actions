#!/usr/bin/env bash

# ==============================
# Configurable variables
# ==============================
NAMESPACE=${NAMESPACE}
POLL_INTERVAL=5  # seconds
TIMEOUT_SECONDS=300                    # 5 minutes (fixed as requested)

START_TIME=$(date +%s)

echo "Waiting for all pods to be in Running state"
echo "Namespace      : $NAMESPACE"
echo "Poll interval  : $POLL_INTERVAL seconds"
echo "Timeout       : $TIMEOUT_SECONDS seconds"
echo "--------------------------------------------"

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$(( CURRENT_TIME - START_TIME ))

    # Timeout check
    if [[ "$ELAPSED" -ge "$TIMEOUT_SECONDS" ]]; then
        echo "Timeout reached after ${ELAPSED}s"
        echo "Not all pods reached Running state"
        kubectl get pods -n "$NAMESPACE"
        exit 1
    fi

    # Get pod name and phase
    POD_STATUSES=$(kubectl get pods -n "$NAMESPACE" \
        --no-headers \
        -o custom-columns="NAME:.metadata.name,PHASE:.status.phase")

    # If no pods yet, keep waiting
    if [[ -z "$POD_STATUSES" ]]; then
        echo "No pods found yet in namespace '$NAMESPACE'"
        sleep "$POLL_INTERVAL"
        continue
    fi

    TOTAL_COUNT=$(echo "$POD_STATUSES" | wc -l | tr -d ' ')
    RUNNING_COUNT=$(echo "$POD_STATUSES" | awk '$2=="Running"' | wc -l | tr -d ' ')
    NOT_RUNNING_COUNT=$(( TOTAL_COUNT - RUNNING_COUNT ))

    echo "Elapsed: ${ELAPSED}s | Total pods: $TOTAL_COUNT | Running: $RUNNING_COUNT | NotRunning: $NOT_RUNNING_COUNT"

    # Print per-pod status (very helpful in CI logs)
    echo "$POD_STATUSES" | sed 's/^/   - /'

    #Success condition
    if [[ "$RUNNING_COUNT" -eq "$TOTAL_COUNT" ]]; then
        echo "All pods are in Running state"
        echo "Pod readiness check completed successfully!"
        exit 0
    fi

    echo "Pods not ready yet… waiting"
    sleep "$POLL_INTERVAL"
done
