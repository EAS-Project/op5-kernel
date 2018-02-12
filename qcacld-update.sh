#!/bin/bash

#
# joshuous's lazy way of updating qcacld drivers.
#
# How to use: ./qcacld-update.sh <CAF tag>
#

if [ -z "$1" ]; then
echo "Please specify a CAF tag as an argument."
echo "How to use: ./qcacld-update.sh <CAF tag>"
exit 1
fi

CAF_TAG=$1

# Remove repos first
echo "Removing old qcacld-3.0 directories first..."
rm -rf drivers/staging/fw-api > /dev/null 2>&1
rm -rf drivers/staging/qcacld-3.0 > /dev/null 2>&1
rm -rf drivers/staging/qca-wifi-host-cmn > /dev/null 2>&1

# Clone latest tag
echo "Cloning fw-api, qcacld-3.0 and qca-wifi-host-cmn..."
git clone --quiet https://source.codeaurora.org/quic/la/platform/vendor/qcom-opensource/wlan/fw-api --branch $CAF_TAG --single-branch drivers/staging/fw-api > /dev/null 2>&1 && \
git clone --quiet https://source.codeaurora.org/quic/la/platform/vendor/qcom-opensource/wlan/qcacld-3.0 --branch $CAF_TAG --single-branch drivers/staging/qcacld-3.0 > /dev/null 2>&1 && \
git clone --quiet https://source.codeaurora.org/quic/la/platform/vendor/qcom-opensource/wlan/qca-wifi-host-cmn --branch $CAF_TAG --single-branch drivers/staging/qca-wifi-host-cmn > /dev/null 2>&1

if [ $? -ne 0 ]; then
echo ""
echo "Failed to clone qcacld repositories. Please specify a valid CAF tag."
echo "Performing git reset --hard to return to original state."
git reset --hard HEAD >/dev/null
exit 1
fi

echo "Repos cloned..."

# Delete git files
find drivers/staging/ -name ".git*" | xargs rm -rf

# Commit
git add -A && \
git commit -m "drivers: staging: Update qcacld-3.0 drivers to $CAF_TAG" >/dev/null
echo "Applying fix for Kconfig..."
git am -3 < patch/qcacld-kconfig-patch && \
git reset --soft HEAD~1 >/dev/null && \
git commit --amend --signoff -m "drivers: staging: Update qcacld-3.0 to $CAF_TAG" >/dev/null

if [ $? -ne 0 ]; then
echo ""
echo "Failed to apply qcacld-kconfig-patch. Please resolve the issue manually."
exit 1
fi

echo "Committing update..."
echo "qcacld-3.0 drivers updated!"
