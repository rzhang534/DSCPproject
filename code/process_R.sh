#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Error: Usage: $0 <state_csv_file>" 1>&2 # Write error to stderr
    exit 1
fi

# Get the state name from the input file
input_csv=$1
state_name=$(basename "$input_csv" .csv)

# Check if the input file exists
if [[ ! -f "$input_csv" ]]; then
    echo "Error: Input file $input_csv does not exist." 1>&2 # Write error to stderr
    exit 1
fi

Rscript ARIMA.R $input_csv
echo "Current directory contents:"
ls -l



