#!/bin/bash
useradd --user-group --groups wheel --create-home --shell /bin/bash teacher
echo 'teacher        ALL=(ALL)       NOPASSWD: ALL' >> /etc/sudoers
mkdir /home/teacher/.ssh
chown teacher:teacher /home/teacher/.ssh
chmod 700 /home/teacher/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCkBIEsfJD6d0J4tqTnVq4z3Ve0bop71b+27j75gncRsLdAHLVg/InhJdrtnVszNGzPIPTXM8jsb/cc0e0JDD7Teoqz0YxJH+ZhY5Y6iy5n8Vx+CCWr5Rra5IpfJclvDPbH+okiUqGyt1fmvS+VkoBWxOFiAOsfdSdTwJWyGs0kplZouOh93cRc/9mp16mNcR5B86+ORLrMZCq3ZGVj2F3YjlhXb1/aUz7Mi1E6Ze9UQQe2oKqf4w8wXIiSejCcrsZ9CT6SX28Kqw2Ilb+7cr84vXIQDKxZySupztn8qMFlDvtoeK4b+RvEtpRmJaC/no9yjTeDTnBYVsV+vQvxiaaeLzkbPRhd0Ovlayoz/gXqI4DOCaQTfISHxG7X+NLfpW6Hmvgf+2i9OStUMJatDx6y1BAj5cjBKo1JRS73U2o5wYYTAlq6jaDAUzWE8Ili7cZ2Qx2dz5uFq6S8NteIt9yR6LsfaHYKG/5WmaA3LOnYAqV+S7nq2WQVQ2Z5bzpJC9s= andrey@MBP-Andrey" > /home/teacher/.ssh/authorized_keys
chown teacher:teacher /home/teacher/.ssh/authorized_keys
chmod 600 /home/teacher/.ssh/authorized_keys
mkdir /root/.aws
echo -e "[default]\noutput = table\nregion = us-east-1" > /root/.aws/config
chmod 600 /root/.aws/config
echo -e "[default]\naws_access_key_id = ****\naws_secret_access_key = ****" > /root/.aws/credentials
chmod 600 /root/.aws/credentials
EC2_ID="`curl http://169.254.169.254/latest/meta-data/instance-id`"
EC2_AWSAVZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
EC2_REGION=${EC2_AWSAVZONE::-1}
VOLUME="`aws ec2 describe-volumes  --filters Name=attachment.device,Values=/dev/xvda Name=attachment.instance-id,Values=$EC2_ID --query 'Volumes[*].{ID:VolumeId}' --region $EC2_REGION --output text`"
aws ec2 modify-volume --region $EC2_REGION --volume-id $VOLUME --size 9 --volume-type gp2
sleep 60
growpart /dev/xvda 1
xfs_growfs -d /
echo -e 'EC2_ID="`curl http://169.254.169.254/latest/meta-data/instance-id`"\nEC2_AWSAVZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)\nEC2_REGION=${EC2_AWSAVZONE::-1}\nVOLUME="`aws ec2 describe-volumes  --filters Name=attachment.device,Values=/dev/xvda Name=attachment.instance-id,Values=$EC2_ID --query 'Volumes[*].{ID:VolumeId}' --region $EC2_REGION --output text`"\naws ec2 modify-volume --region $EC2_REGION --volume-id $VOLUME --size 9 volume-type gp2\nsleep 60\ngrowpart /dev/xvda 1\nxfs_growfs -d /' > /root/readme.txt