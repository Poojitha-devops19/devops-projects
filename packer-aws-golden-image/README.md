<img width="562" height="269" alt="image" src="https://github.com/user-attachments/assets/a596d70e-27ef-40c6-8751-8d94283185d9" />**📦 Packer Project – Build Custom AMI with Nginx**
    This project demonstrates how to use HashiCorp Packer to build a custom Amazon Machine Image (AMI) on AWS.
    The AMI comes pre‑installed with Nginx and has firewall rules enabled for ports 22 (SSH), 80 (HTTP), and 443   (HTTPS).

**🚀 What This Template Does**
    Uses the Amazon EBS builder to create an AMI in us-west-2.
    Starts from an Ubuntu base AMI (ami-0557a15b87f6559cf).
    Installs and configures Nginx.
    Enables firewall (ufw) with rules for SSH, HTTP, and HTTPS.
    Outputs the image in formats usable by Vagrant and compresses it.

**🛠️ Prerequisites**
AWS account with permissions to create AMIs and EC2 instances.
IAM role or AWS credentials configured.

**Installed tools:**
  Packer
  AWS CLI
  Vagrant (optional, if you want to use the Vagrant box output)

**📋 Usage**
1. Initialize Packer
    packer init .
2. Validate Template
    packer validate .
3. Build the AMI
    packer build .
This will:
  Launch a temporary EC2 instance.
  Run the shell provisioner (install Nginx, configure firewall).
  Create a new AMI named my-first-packer-image.
  Terminate the temporary instance.

**💻 Using the AMI to Create a VM**
    Once the AMI is built, you can launch an EC2 instance from it:

    Option A: Using AWS Console
            Go to EC2 → AMIs.
            Find my-first-packer-image.
            Click Launch instance.
            Choose instance type (e.g., t2.micro).
            Configure networking/security groups.
            Launch and connect via SSH.

   Option B: Using AWS CLI

        aws ec2 run-instances \
       --image-id <ami-id> \
       --count 1 \
       --instance-type t2.micro \
       --key-name <your-keypair> \
       --security-group-ids <sg-id> \
       --subnet-id <subnet-id>
      Replace <ami-id> with the ID of the AMI created by Packer.

**📦 Using the Vagrant Box Output**
   If you want to use the image locally with Vagrant:
   After build, add the box:
      vagrant box add my-first-packer-image ./output.box
   Initialize and run:
      vagrant init my-first-packer-image
   vagrant up

**✅ Summary**
   This project shows how to:
    Build a custom AMI with Packer.
    Preconfigure it with Nginx and firewall rules.
    Launch EC2 instances from the AMI.
    Optionally use the image as a Vagrant box locally.
