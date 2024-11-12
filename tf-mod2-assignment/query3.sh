#!/bin/bash

# Define the JSON file path
json_file="terraform_show_output.json"

# Check if the file exists
if [[ ! -f "$json_file" ]]; then
  echo "JSON file not found: $json_file"
  exit 1
fi

# Run jq with the specified query
jq '.values.root_module.resources | map(select(.address == "google_compute_instance.tf-mod2-lab1-vm1")) | .name' "$json_file"
