#!/usr/bin/env bash
set -o errexit -o errtrace -o functrace -o nounset -o pipefail

# shellcheck source=/dev/null
root="$(cd "$(dirname "${BASH_SOURCE[0]:-$PWD}")" 2>/dev/null 1>&2 && pwd)/../"

readonly name="${1:-linux}"
shift || true

# Simple no-thrill build tester
if ! "$root/hack/build.sh" \
    --inject registry="ghcr.io/dubo-dubon-duponey" \
    --inject progress=plain \
	  --inject date=2021-08-01 \
	  --inject suite=bullseye \
    --inject platforms=linux/amd64,linux/arm64 \
  	"$name" "$@"; then
  printf >&2 "Failed building\n"
  exit 1
fi
