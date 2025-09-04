#!/usr/bin/env bash
# scan-erb.sh
# Usage: ./scan-erb.sh [directory]

DIR=${1:-.}

# Find all .erb files, extract ERB expressions, sort them uniquely
grep -rho '<%=\?[^%]*%>' "$DIR" \
  | sed 's/^ *//;s/ *$//' \
  | sort \
  | uniq
