#!/usr/bin/env bash

# ==============================
# Configurable variables
# ==============================
NAMESPACE="${VSPHERE_NAMESPACE}"
MACHINE_PREFIX="${WORKLOAD_CLUSTER_NAME}"
POLL_INTERVAL="${POLL_INTERVAL:-15}"        # seconds
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-1500}"  # optional safety

START_TIME=$(date +%s)

echo "Waiting for machines to become Ready"
echo "Namespace      : $NAMESPACE"
echo "Name prefix    : $MACHINE_PREFIX"
echo "Poll interval  : $POLL_INTERVAL seconds"
echo "⏱Timeout       : $TIMEOUT_SECONDS seconds"
echo "--------------------------------------------"

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$(( CURRENT_TIME - START_TIME ))

    # Timeout protection
    if [[ "$ELAPSED" -ge "$TIMEOUT_SECONDS" ]]; then
        echo "Timeout reached after ${ELAPSED}s"
        echo "Not all matching machines became Ready"
        exit 1
    fi

    # Get machine name + Ready condition, then filter by prefix
    MACHINE_STATUSES=$(kubectl get machines -n "$NAMESPACE" \
        -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' \
        | awk -v prefix="$MACHINE_PREFIX" '$1 ~ "^"prefix')

    # If no matching machines yet, keep waiting
    if [[ -z "$MACHINE_STATUSES" ]]; then
        echo "🔍 No machines found with prefix '$MACHINE_PREFIX' yet"
        sleep "$POLL_INTERVAL"
        continue
    fi

    TOTAL_COUNT=$(echo "$MACHINE_STATUSES" | wc -l | tr -d ' ')
    READY_COUNT=$(echo "$MACHINE_STATUSES" | awk '$2=="True"' | wc -l | tr -d ' ')
    NOT_READY_COUNT=$(( TOTAL_COUNT - READY_COUNT ))

    echo "Elapsed: ${ELAPSED}s | Total: $TOTAL_COUNT | Ready: $READY_COUNT | NotReady: $NOT_READY_COUNT"

    # Per-machine visibility (great for CI logs)
    echo "$MACHINE_STATUSES" | sed 's/^/   - /'

    #Exit ONLY when all matching machines are Ready
    if [[ "$READY_COUNT" -eq "$TOTAL_COUNT" ]]; then
        echo "All machines with prefix '$MACHINE_PREFIX' are Ready"
        echo "Cluster portion created by GitHub Actions is ready!"
        exit 0
    fi

    echo "Waiting for machines to become Ready..."
    sleep "$POLL_INTERVAL"
done
