#!/usr/bin/env bash
set -x

# Initialization
SCRIPT_DIR=$(dirname "$0")

# shellcheck disable=SC1091 # Not following.
source "$SCRIPT_DIR"/init-env.sh

# quay.io/deliedit/test:catalog-index-test is a single-arch amd64 image.
# Deploying it on arm64 CrashLoopBackOffs the catalog pod (exec format error).
if [[ "$CPU_ARCH" == "aarch64" || "$CPU_ARCH" == "arm64" ]]; then
	echo "Skipping custom catalog: image is amd64-only (CPU_ARCH=$CPU_ARCH)."
	exit 0
fi

oc create ns "$CUSTOM_CATALOG_NAMESPACE" --dry-run=client --output yaml | oc apply --filename -

# Apply the catalogsource YAML
oc apply --filename ./test-target/custom-catalogsource.yaml --namespace "$CUSTOM_CATALOG_NAMESPACE"

sleep 10

# Patch the custom-catalog service to be IP Family Dual Stack
# This is needed to pass the dual-stack service test
oc patch service custom-catalog --namespace "$CUSTOM_CATALOG_NAMESPACE" --type='json' -p='[{"op": "add", "path": "/spec/ipFamilyPolicy", "value": "PreferDualStack"}]'
sleep 5
oc patch service custom-catalog --namespace "$CUSTOM_CATALOG_NAMESPACE" --type='json' -p='[{"op": "add", "path": "/spec/ipFamilies", "value": ["IPv4", "IPv6"]}]'
sleep 5
