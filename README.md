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

## Installing Edera on your VM
The first tool you will need is Docker. If it's not on your VM by default, install it with the below script:
```
wget https://raw.githubusercontent.com/ndouglas-edera/EderaOn-quickstart/refs/heads/main/install-docker.sh
chmod +x install_docker.sh
./install_docker.sh
```

Then, grab you license key under the "**My License**" section of the Edera onboarding page. <br/>
Once grabbed, throw it into my custom validation script. This will check if you re using the right key:
```
wget https://raw.githubusercontent.com/ndouglas-edera/EderaOn-quickstart/refs/heads/main/setup-license.sh
chmod +x setup_license.sh
./setup_license.sh
```

Check that you are using a valid Edera license key:
```
cat /var/lib/edera/protect/license.key
```

Authenticate Docker using the license file
```
docker login -u license -p "$(cat /var/lib/edera/protect/license.key)" images.edera.dev
```

Before installing, run edera-check to confirm your system meets all requirements:
```
docker run --pull always --pid host --privileged \
  ghcr.io/edera-dev/edera-check:stable preinstall \
  | sed -e 's/\([Pp]assed\)/\x1b[32m\1\x1b[0m/g' -e 's/\([Ff]ailed\)/\x1b[31m\1\x1b[0m/g'
```
All Required checks should pass. <br/>
If anything fails, address the issue before proceeding. <br/>
This should be treated as disposable infrastructure only. <br/>
Edera modifies your bootloader and there is no automated uninstall process. <br/>
Please, only install on instances or VMs you can actually terminate or recreate.
```
EDERA_LICENSE_KEY="$(cat /var/lib/edera/protect/license.key)" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/edera-dev/learn/main/getting-started/edera-on-installer/scripts/install.sh)" -- --verbose
```
Once the VM restarts, it will boot into the Edera hypervisor, and your Ubuntu VM will startup as an Edera-managed guest.

