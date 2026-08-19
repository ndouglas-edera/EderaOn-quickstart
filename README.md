# EderaOn Quickstart
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

If **[AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)** is not found on your EC2 instance, you'll need to install it. I use **brew**:
```
brew install awscli
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

Here's the install command I've been using my for VMs. Obviously, use your own ```.pem``` file name and ```sg```:
```
aws ec2 run-instances \
    --image-id ami-0c1c30571d2dae5c9 \
    --instance-type m5.large \
    --key-name nigel-edera \
    --security-group-ids sg-08133b77c17ce95b9 \
    --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":20,"VolumeType":"gp3"}}]' \
    --region eu-west-1
```

To exit the page Press ```q``` on your keyboard to quit the JSON view and return to your command prompt.
<br/><br/>
To monitor the instance status and grab its public IP address, run:
```
aws ec2 describe-instances \
    --region eu-west-1 \
    --filters "Name=instance-state-name,Values=pending,running" \
    --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,PublicIP:PublicIpAddress}" \
    --output table
```

You can then proceed to install with your ```pem``` file and correctly-listed public IP from the previous command:
```
ssh -i "nigel-edera.pem" ubuntu@<public-ip>
```

<img width="1060" height="1190" alt="Screenshot 2026-08-19 at 11 10 35" src="https://github.com/user-attachments/assets/639aa238-b121-49b5-9559-f96f8e361008" />


## Installing Edera on your VM
The first tool you will need is Docker. If it's not on your VM by default, install it with the below script:
```
wget https://raw.githubusercontent.com/ndouglas-edera/EderaOn-quickstart/refs/heads/main/install-docker.sh
chmod +x install-docker.sh
sudo ./install-docker.sh
```

Then, grab you license key under the "**My License**" section of the Edera onboarding page. <br/>
Once grabbed, throw it into my custom validation script. This will check if you re using the right key:
```
wget https://raw.githubusercontent.com/ndouglas-edera/EderaOn-quickstart/refs/heads/main/setup-license.sh
chmod +x setup-license.sh
./setup-license.sh
```

Check that you are using a valid Edera license key:
```
cat /var/lib/edera/protect/license.key
```

Authenticate Docker using the license file
```
docker login -u license -p "$(cat /var/lib/edera/protect/license.key)" images.edera.dev
```

Before installing, run **[edera-check](https://docs.edera.dev/reference/configuration/edera-check/)** to confirm your system meets all requirements:
```
sudo docker run --pull always --pid host --privileged \
  ghcr.io/edera-dev/edera-check:stable preinstall \
  | sed -e 's/\([Pp]assed\)/\x1b[32m\1\x1b[0m/g' -e 's/\([Ff]ailed\)/\x1b[31m\1\x1b[0m/g'
```

It's absolutely critical that you are using an EC2 instance with **UEFI bootloader** - or you'll fail on the below error:
<img width="1655" height="1187" alt="Screenshot 2026-08-19 at 10 40 16" src="https://github.com/user-attachments/assets/d83869bc-67f6-4e7f-b0dd-54af30d65054" />

## Pre-flight checks
If the **edera-check** script work successfully, you can skip this section entirely. <br/>
Start an interactive ```bash``` session:
```
bash
```
The quickest way to see both the architecture and the operating system is by running:
```
uname -a
```
This will print your system information in a single line, including:
- Kernel name
- Network node hostname
- Kernel release date
- Operating system
- Machine architecture
(for example: x86_64 or aarch64).

To see the ```Architecture``` only:
```
uname -m
```
Alternatively, you can use lscpu to see full CPU details.
<br/><br/>
To see the Operating System details only:
```
cat /etc/os-release
```
If your system has ```systemd``` installed: <br/>
(common on most modern VMs/servers)
```
hostnamectl
```
This gives you a beautifully formatted layout showing the OS, Kernel, and Architecture all at once.

## Proceeding with the installation

If you meet all the required checks, it should pass. <br/>
If anything fails, address the issue before proceeding. <br/>
EderaOn should be treated as disposable infrastructure only. <br/>
Edera modifies your bootloader and there is no automated uninstall process. <br/>
Please, only install on instances or VMs you can actually terminate or recreate.
```
EDERA_LICENSE_KEY="$(cat /var/lib/edera/protect/license.key)" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/edera-dev/learn/main/getting-started/edera-on-installer/scripts/install.sh)" -- --verbose
```

<img width="1656" height="1190" alt="Screenshot 2026-08-19 at 11 22 34" src="https://github.com/user-attachments/assets/e3488a24-2301-4c13-bb4e-b6214b54b4e9" />

NOTE: You cannot interact with the terminal during reboot. <br/>
Once the VM restarts, it will boot into the Edera hypervisor, and your Ubuntu VM will startup as an Edera-managed guest. <br/>
You'll need to shell back into your EC2 instance to start playing around with Edera:
```
ssh -i "nigel-edera.pem" ubuntu@52.17.147.191
```


## Getting Started with EderaON

Run the ```uname``` command to verify that you are running the custom Edera kernel generated during the installation process: ```Edera/Xen``` kernel
```
uname -r | grep 'edera'
```
Expected: ```6.x.y-edera```
<br/><br/>
Verify the services are running:
```
ps auxww | grep protect
```
#### systemd-detect-virt
I spun up the EC2 instance on ```Amazon AWS```. This utility checks **[CPUID](https://en.wikipedia.org/wiki/CPUID)** & system interfaces to see if the environment is virtualised:
```
systemd-detect-virt | grep -E 'amazon'
```
Edera zones currently run on a **[Xen](https://edera.dev/stories/why-edera-built-on-xen-a-secure-container-foundation)** Hypervisor. Starting recently, the same zone-based isolation will also run on **[KVM](https://docs.edera.dev/technical-overview/architecture/kvm/)** (Kernel-based Virtual Machines), preserving identical security guarantees while meeting teams where their infrastructure already is.

#### Check dmesg for Hypervisor boot logs:
Inspect the ring buffer to see hypervisor handoff messages:
```
dmesg | grep -iE "hypervisor|xen|edera"
```
Look for boot lines indicating kernel is booting as guest <br/>
(like ```booting paravirtualised kernel on Xen``` or ```hvc0``` devices).

#### Check the "Edera Protect" systemd services
The installer enabled several Edera management daemons.
```
systemctl status protect-daemon protect-network
```
Confirm ```Xen``` is present
```
ls /proc/xen
```
Expected: ```capabilities  privcmd  xenbus```

Check the daemon is running:
```
systemctl is-active protect-daemon | grep --color=always -E "active|$"
```
Expected: ```active```
<br/><br/>
```activating``` is not the same as ```active```.<br/>
The daemon should become ```active``` within seconds.<br/>
If everything is active, you can proceed with the lab.
<br/><br/>
If it stays in ```activating```, it failed to start.<br/>
A missing or invalid license key is a common cause.<br/>
Check logs with sudo ```journalctl -u protect-daemon -n 50```.

## Launch a zone
Launching a zone typically takes less than a minute.<br/>
If it takes longer, check logs with:
```sudo journalctl -u protect-daemon -n 50```
```
sudo protect zone launch -n test-zone --min-cpus 1 -C 2 -c 2 --wait
sudo protect zone list
```
To get more info about a specific Zone in YAML output:
```
sudo protect zone list --output yaml | grep --color=always -E "ZONE_VIRTUALIZATION_BACKEND_AUTOMATIC|$"
```
A zone in ```ready``` state is running and available.<br/>
If not, check the logs to see why the activation failed:
```
journalctl -u protect-daemon -n 20 | sed \
  -e 's/\bINFO\b/\x1b[32m&\x1b[0m/g' \
  -e 's/\bWARN\b/\x1b[31m&\x1b[0m/g'
```
**Optional:** Destroy the zone when you are done.<br/>
This releases the lock on the image files so that they can be reused:
```
sudo protect zone destroy test-zone
```
## Run a workload
Launch an interactive shell inside the zone:
```
sudo protect workload launch \
  --zone test-zone \
  --name alpine-shell \
  -t -a \
  docker.io/library/alpine:latest sh
```
Once inside, run ```uname -r``` to confirm you’re running in an isolated zone with its own kernel:
```
uname -r
```
The ```6.18.XX``` output from ```uname -r``` is the version of the dedicated zone kernel that Edera booted specifically for your ```test-zone```.

- Exiting the container and running ```uname -r``` again should show ```6.18.XX-edera``` - proving the container is not on the shared kernel
- In a traditional container, running ```uname -r``` inside a container simply returns the host's kernel version, because all containers share a single host kernel.
- The output confirms that ```6.18.XX``` is not your host's shared kernel, but a completely isolated kernel running inside a **Type-1 hypervisor microVM**.

Type ```exit``` to leave the shell.

#### Create long-lived workloads
```
sudo protect workload launch --zone test-zone --name alpine-long -- docker.io/library/alpine:latest sleep 3600
sudo protect workload launch --zone test-zone --name ubuntu-test docker.io/library/ubuntu:latest sleep 10
```
Check that the workload is running:
```
sudo protect workload list
sudo protect zone list
```
List the ```yaml``` output information associated with running workloads:
```
sudo protect workload list --output yaml
```
