First create a vault,  feature of ansible that allows you to keep sensitive data such as passwords or keys in encrypted files.

ansible-vault create aws_keys.yml

aws_access_key: XXXXXXXXXXXXXXXXXXXXXX
aws_secret_key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

After create file aws_keys.yml  apply command:

ansible-playbook aws_provisioning.yml -i localhost --ask-vault-pass --private-key ./keypair-ldap.pem 

