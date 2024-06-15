#!/bin/bash
set -e
UPLOAD_TOOL={{upload}}
CHIP={{chip}}
BAUD={{baud}}
CODE={{code}}
BEFORE={{before}}
AFTER={{after}}
START_DATA={{start_data}}
DATA={{data}}

check_hash_and_run() {
    set -e
    local file_name=$1
    local cmd=$2
    local file_hash=$(sha256sum "$file_name" | awk '{ print $1 }')
    local known_hash=""
    local sha_file=$(basename "$file_name").sha256

    if [ -f "$sha_file" ]; then
        echo known_hash=$(cat "$sha_file")
    fi
    if [ "$file_hash" == "$known_hash" ]; then
        echo $file_name is unchanged
    else
        echo "Running: $cmd"
        # upload.py doesn't exit with a nonzero exit code on errors.
        # instead we have to look for an error in stderr
        local out=$($cmd 2> >(tee /dev/tty))
        regexp="A[[:space:]]fatal[[:space:]]esptool.py[[:space:]]error"
        if [[ "$out" =~ $regexp ]]; then
            echo
            exit 1
        fi
        echo "$file_hash" >"$sha_file"
    fi
}

if [[ "$DATA" != "" ]]; then
    cmd=""$UPLOAD_TOOL" --chip $CHIP --baud $BAUD $@ write_flash $START_DATA "$DATA""
    check_hash_and_run "$DATA" "$cmd"
fi
cmd=""$UPLOAD_TOOL" --chip $CHIP --baud $BAUD $@ --before $BEFORE --after $AFTER write_flash 0x0 "$CODE""
# check_hash_and_run "$CODE" "$cmd"
echo Done
