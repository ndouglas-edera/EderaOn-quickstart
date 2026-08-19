# EderaOn-quickstart
This is an early onboarding repo to get everything for easy enablement

I started off with an ```Ubuntu 26.04```. It has a public address and I can access it via SSH:
```
ssh -i "nigel-edera.pem" ubuntu@ec2-54-216-222-168.eu-west-1.compute.amazonaws.com
```

If you don't have a VM already built, you'll need to create one. <br/>
However, if you have a VM prepared, you can skip on past this next section:

## Creating an appropriate VM for EderaON

This is the **[EderaOn](on-edera.dev)** **EC2 instance installer**. You'll need a valid license key. So sign-up first.
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

This installer will also ask for AWS credentials to be provided. Run the below commmand:
```
aws login --remote
```

You also need to connect to your appropriate region (I'm based in Ireland - ```eu-west-1```):
```
aws configure set region eu-west-1
```

## Creating an appropriate VM for EderaON

