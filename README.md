# How it works

## AuthN/AuthZ

- the aws provider has the ability to be configured with;
  - an Access Key and Secret Key for your AWS account placed directly in the provider configuration located `/tf-rosa-hcp/providers.tf`
      ```bash
      provider "aws" {
        region     = "us-west-2"
        access_key = "my-access-key"
        secret_key = "my-secret-key"
      }
      ```
  - Environment Variables `AWS_ACCESS_KEY_ID="anaccesskey"` `AWS_SECRET_ACCESS_KEY="asecretkey"` `AWS_REGION="us-west-2"`
  - Shared Config or Credentials file `$HOME/.aws/config` and `$HOME/.aws/credentials` on Linux and macOS, and `"%USERPROFILE%\.aws\config"` and `"%USERPROFILE%\.aws\credentials"` on Windows.
  - Container credentials with IRSA (IAM Roles for Service Accounts), based on the underlying `AWS_ROLE_ARN` and `AWS_WEB_IDENTITY_TOKEN_FILE` environment variables being automatically set by Kubernetes or manually for advanced usage.
  - Instance Profile Credentials 

## ROSA Module Role creation

- The upstream ROSA module used here sets your role prefix to `role_prefix = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}"`
- The Role ARNs for the Installer, Support, Worker and Master roles are then configured for you with the role prefix set above and passed into cluster creation


# How to use as of 8/8/24

## Create a Virtual Env for the Ansible execution

```bash
 make venv
```
## Run ansible playbook
  
  **for now you need to run the build and install rhoai_components plays separately**

- I have one implementation for using bitwarden as a password manager which dynamically pulls the ocp_api token and the cluster admin user's password. Use the following command if you want to set up something similar. 
- One caveat is the /vars/bw_creds.yaml file will need to be replaced with your own vault file containing the your bitwarden's master password
 
```bash
ansible-vault create ansible/roles/build_hcp/vars/bw_creds.yaml
```
- then set a vault password for your vault file, add your bitwarden creds as a variable named `bw_pass`, and in the bitwarden_auth task file, youll need to set your ocp_api token record in bitwarden with the key of `ocm-api` 

- Then you can run the following command
```bash
ansible-playbook ansible/build_hcp.yaml --ask-vault-pass --tags "bitwarden"
```

- Otherwise, you need to add your admin_password and ocm_api token as varibales in your own vault file in group_vars

```bash
ansible-vault create ansible/group_vars/all/vault.yaml
```
  - set your vault password when prompted 
  - add two variables
    1. `terraform_token` with your ocm_api token
    2. `admin_password` with your cluster admin password

- Run the ansible playbook without tags to use local vault for all sensitive variables

```bash
ansible-playbook ansible/build_hcp.yaml --ask-vault-pass
```

## Destroy Resources

- There is a `destroy_hcp` role that runs the same way the build role does with the state set to absent

```bash
ansible-playbook ansible/destroy_hcp.yaml --ask-vault-pass --tags "bitwarden"
```

```bash
ansible-playbook ansible/destroy_hcp.yaml --ask-vault-pass 
```

- this will destroy ALL terraform managed resources in the terraform state file located in `tf-rosa-hcp`

*it is possible to extend the terraform ansible module used here with a different backend to store state, please refer [here]("https://docs.ansible.com/ansible/latest/collections/community/general/terraform_module.html")


# TODO
- create a destroy task 
- link the create and install plays into one 
