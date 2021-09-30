Before you start!
Put your credentials instead of stars at:
1. provider "aws" segment in main.tf;
2 /user_files/bastion.sh at next line: echo -e "[default]\naws_access_key_id = ****\naws_secret_access_key = ****" > /root/.aws/credentials
