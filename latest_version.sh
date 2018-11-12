#!/bin/bash

set -e

variables() {
	readonly GOYQ_VERSION=1.1.1
	readonly GOYQ_VERSION_BINARY=go-yq-${GOYQ_VERSION}

	if [ "$(uname)" == "Darwin" ]; then
		echo "OS not supported"
		exit 1
	elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
		GOYQ_VERSION_BINARY_OS="${GOYQ_VERSION_BINARY}-linux"
	elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
		echo "OS not supported"
		exit 1
	elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
		GOYQ_VERSION_BINARY_OS="${GOYQ_VERSION_BINARY}-windows.exe"
	fi

	readonly GOYQ_CHECKSUM_TXT=${GOYQ_VERSION_BINARY_OS}.sha512.txt
}

compare_and_exit_if_required() {
	if [[ "$1" != "$2" ]]; then
		echo "Mismatch: $1 vs. $2"
		exit 1
	fi
}

goyq() {
	readonly EXPECTED_GOYQ_CHECKSUM=$(curl --location https://github.com/030/go-yq/releases/download/${GOYQ_VERSION}/${GOYQ_CHECKSUM_TXT} | awk '{ print $1 }')

	curl --location https://github.com/030/go-yq/releases/download/${GOYQ_VERSION}/${GOYQ_VERSION_BINARY_OS} -o $GOYQ_VERSION_BINARY_OS
	readonly ACTUAL_GOYQ_CHECKSUM=$(sha512sum $GOYQ_VERSION_BINARY_OS | awk '{ print $1 }')

	compare_and_exit_if_required $EXPECTED_GOYQ_CHECKSUM $ACTUAL_GOYQ_CHECKSUM

	chmod +x $GOYQ_VERSION_BINARY_OS
	mv $GOYQ_VERSION_BINARY_OS go-yq
}

compare() {
	readonly LATEST_VERSION=$(curl -s https://product-details.mozilla.org/1.0/firefox_versions.json | jq -r .LATEST_FIREFOX_VERSION)
	readonly VERSION=$(./go-yq -yamlFile defaults/main.yml -key firefox_version)
	readonly LATEST_CHECKSUM=sha512:$(curl https://ftp.mozilla.org/pub/firefox/releases/${LATEST_VERSION}/SHA512SUMS | grep linux-x86_64/en-US/firefox-${VERSION}.tar.bz2 | sed -e "s|  linux-x86_64/en-US/firefox-${LATEST_VERSION}.tar.bz2$||g")
	readonly CHECKSUM=$(./go-yq -yamlFile defaults/main.yml -key firefox_checksum)

	compare_and_exit_if_required $LATEST_VERSION $VERSION
	compare_and_exit_if_required $LATEST_CHECKSUM $CHECKSUM
}

main() {
	variables
	goyq
    compare
}

main
