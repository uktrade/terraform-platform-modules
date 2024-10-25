#!/bin/bash

unit_test_files=$(find . -name "*tftest.hcl" | grep -v e2e-tests | sort)
modules=""
IFS=$'\n'
for file in $unit_test_files
do
    # Lose leading ./ and select the part before the tests directory
    module=$(echo "${file#./}" | awk -F "/tests/" '{print $1}')
    # In case we separate the test files, only include each module once
    if [[ ${modules} != *"$module"* ]]; then
        modules+="\"$module\","
    fi
done
echo "[${modules%,}]"
