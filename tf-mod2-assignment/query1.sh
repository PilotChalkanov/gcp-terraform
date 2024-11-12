#!/bin/bash

# Define the JSON file path
json_file="terraform_show_output.json"

# Check if the file exists
if [[ ! -f "$json_file" ]]; then
  echo "JSON file not found: $json_file"
  exit 1
fi

# Run jq with the specified query
jq '.values.root_module.resources[]
      | select(.type == "google_compute_firewall" and .name == "tf-mod2-lab1-fwrule1").values.allow[][]
      | select(. != "").ports[]' "$json_file"
