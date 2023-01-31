# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
This project provides a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started
1. Clone this repository

2. Setup environment

3. Run packer and terraform builds

4. Enjoy your web application :)

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)
5. Make sure to add packer/bin and terraform/bin to your path variable so you can call the programs from the commandline.
6. Create a service principal (Azure AD) and assign the contributer role (subscription AIM) to it in order to allow packer and terraform to create/update/delete resources in your Azure subscription
7. Configure environment variables: 
	ARM_CLIENT_ID 		(your service principal - called application ID in Azure) 
	ARM_CLIENT_SECRECT	(Secret for the service principal)
	ARM_SUBSCRIPTION_ID	
	ARM_TENANT_ID  		(from Azure AD)
8. Create an Azure resource-group named "udacity-project-webserver-rg". Your packer image will be added to that group.
9. Make sure you have an "id_rsa.pub" file in your ~/.ssh/ directory containing a public key.

### Instructions
1. Call packer: "packer build ubuntu18-webserver-image.json" (Hint: use "packer build -force ubuntu18-webserver-image.json" to force recreation of the image if you have run the build before)
2. Call terraform: "terraform init"
3. Call terraform: "terraform plan -out solution.plan"
4. Call terraform: "terraform apply solution.plan"

### Output
After successfully executing the "terraform apply" your webserver infrastructure ist set up and running. The final output of the script will show you the public ip address of the loadbalancer.
You can access your web application by pasting this ip address in your browser. You see your web application running :)    


## Customization 
Packer image:
	You can edit the resource-group and name of image in the "ubuntu18-webserver-image.json" file by changing the following properties:
		- managed_image_resource_group_name
		- managed_image_name
	In order to change the content of the deployed web application change the "echo 'Hello world :)'" command in the provisioners section of the "ubuntu18-webserver-image.json" file.
	
Terraform template:
	The terraform template is devided into a the files "main.tf" and "vars.tf". In the "vars.tf" file you can add or modify variables used by the template as well as the description for the variables.
		prefix: Prefix to add to all created resources. 
		location: Azure region to assign to the created resource-group and all other resources.
		number_of_vms: The number of virtual linux machines that are created to host webservers. 
		environment: Tag that will be added to all indexable resources and the created resource group, like "test" or "production".
		
	In the "main.tf" file you can modify everything concerning the created infrastructure. If e.g. you would like to allow ssh access to your virtual machines you would need to add "azurerm_lb_rule" rules to 
	route traffic to the virtual machines on specific ports other then port 80. You would also need to define new security rules in the "azurerm_network_security_group" in order to allow this inbound traffic. 