# Infra-tooling

Terrform will create the following resources will the name provide in the ```variables.tf``` file.

* VPC resources
  * vpc
  * subnet
  * route table
  * route table / subnet association
  * internet gateway

* EC2 resources
  * ec2 instance
  * security group

# Pre-reqs

The following must be installed on laptop/server where developing/lauching the resources
1. python3 
1. pip3
1. awscli
1. terraform v0.12
    ```
    # on mac
    brew install terraform
    ```
1. ansible
    ```
    # on mac
    pip3 install ansible
    pip3 install boto
    # verify
    ansible localhost -m ping 
    ```
1. AWS account with admin access to create resources
1. AWS KeyPair file
1. clone this repo. NOTE local Terraform init and state files are excluded in ```.gitignore``` file

# Terrform
1. Update ```variables.tf``` values for:
  * aws_tag_name - e.g. your last name
  * aws_region
  * aws_creds_profile
  * aws_creds_file
  * aws_keypair_name - assume generate this for AWS and is in the region provisioning ec2 instance
1. run these terraform commands
    ```
    terraform init
    terraform apply
    ```
1. After making the VM, terraform will output the public IP that can be used in the ssh connection
    ```
    Outputs:

    public_ip = [
    "111.222.333.444",
    ]

    ssh -i "jahn-dt-aws.pem" ubuntu@111.222.333.444
    ``` 
# generate password for user for ansible playbook
1. install python library and run script that will prompt for password to encrypt [ansible reference](https://docs.ansible.com/ansible/latest/reference_appendices/faq.html#how-do-i-generate-crypted-passwords-for-the-user-module)
```
pip install passlib
python -c "from passlib.hash import sha512_crypt; import getpass; print(sha512_crypt.using(rounds=5000).hash(getpass.getpass()))"
```
1. copy the encrypted value to ```ansible_variables.yaml```

# Run Ansible Playbook - Using Dynamic Inventory
1. You may need to adjust ```ec2.py``` python interpreter line
    ```
    #!/usr/local/bin/python3   <-- I did this for macOS
    #!/usr/bin/env python      <-- this is the original values in script
    ```
1. **THIS IS IMPORTANT, OTHERWISE RISK RUNNING PLAYBOOK ON WRONG HOSTS**. Adjust ```ec2.ini``` the filters as required, for example:
   * instance_filters = tag:Name=jahn
   * regions = us-east-1
1. Test dynamic inventory with this command
    ```
    ./ec2.py --list
    # on mac if don't have a python alias setup
    python3 ec2.py --list
    ```
1. run playbook
    ```
    ansible-playbook -i ec2.py app.yml --user ubuntu --private-key=jahn-dt-aws.pem
    ```

# Ansible Playbook - Using Static Inventory
1. Adjust ```static_inventory``` file with IP of new host
1. Test playbook with your PEM file
    ```
    ansible-playbook -i static_inventory app.yml --user ubuntu --private-key=jahn-dt-aws.pem 
    ```

# Delete VM
1. Run this terraform command
    ```
    terraform destroy
    ```