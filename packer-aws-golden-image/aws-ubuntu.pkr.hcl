packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  access_key    = "AKIA4IAWSJ5UVPYXWCMZ"
  secret_key    = "80qqjldindsSgomesGjuooseoksgi9"
  ami_name      = "my-first-packer-image"
  instance_type = "t2.micro"
  region        = "us-west-2"
  source_ami    = "ami-0557a15b87f6559cf"
  ssh_username  = "ubuntu"
}

#you can add source blocks for all other cloud platforms as well in a single file for azure, gcp etc.,

build {
  name    = "my-first-build"
  sources = [
    "source.amazon-ebs.ubuntu" #you can add other builds also here.
  ]

  provisioner "shell" {
      inline = [
          "sudo apt update",
          "sudo apt install nginx -y",
          "sudo systemctl enable nginx",
          "sudo systemctl start nginx",
          "sudo ufw allow proto tcp from any to any port 22,80,443",
          "echo 'y' | sudo ufw enable"
      ]
   }

   post-processor "vagrant" {}
   post-processor "compress" {} 
}
 