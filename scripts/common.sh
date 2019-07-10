#!/bin/bash
function version() {
    echo "$@" | awk -F "." '{ printf("%01d%03d\n", $1, $2); }'
}
