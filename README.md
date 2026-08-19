# EderaOn-quickstart
This is an early onboarding repo to get everything for easy enablement

## Creating an appropriate VM for EderaON

I started off with an ```Ubuntu 26.04```. It has a public address and I can access it via SSH:
```
ssh -i "nigel-edera.pem" ubuntu@ec2-54-216-222-168.eu-west-1.compute.amazonaws.com
```

This is the **[EderaOn](on-edera.dev)** installer. You'll need a valid license key. So sign-up first.
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/edera-dev/learn/refs/heads/main/getting-started/edera-on-installer/scripts/ec2-setup.sh)"
```

If AWS CLI is not found on your EC2 instance, you'll need to install this:
```
sudo apt update && sudo apt install -y unzip curl
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

Check that it is installed successfully:
```
aws --version
```
