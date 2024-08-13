#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Source the virtual environment
source ./virtualenv/bin/activate

# Install Ansible Galaxy collections
ansible-galaxy collection install -r requirements.yaml

# Run the Ansible playbook with specified options
ansible-playbook ansible/build_rhoai_cluster.yaml --ask-vault-pass --skip-tags "bitwarden"