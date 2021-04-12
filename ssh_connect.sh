#!/bin/bash
ip=$(terraform output -json ipv4_address | jq -r '.')

key_file="ssh_key.pem"
terraform output private_ssh_key >$key_file
chmod 0600 $key_file

ssh -q -o "StrictHostKeyChecking no" -i $key_file root@"$ip" "$@"
