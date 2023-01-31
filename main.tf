provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location

  tags = {
	  environment = var.environment
  }
}

resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-public-ip-for-loadbalancer"
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"

  tags = {
	  environment = var.environment
  }
}

resource "azurerm_network_security_group" "main" {
	name                = "${var.prefix}-nsg"
	location            = azurerm_resource_group.main.location
	resource_group_name = azurerm_resource_group.main.name
	
  security_rule {
    name                       = "allow_http_inbound_to_loadbalancer"
    priority                   = 100
    direction                  = "Inbound"
    protocol                   = "Tcp"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "80"    
    access                     = "Allow"
  }

	security_rule {    
		name 					             = "allow_access_within_subnet"
		priority 				           = 101
		direction 				         = "Inbound"
		protocol                   = "Tcp"    
    source_address_prefix      = "10.0.0.0/24"
		source_port_range          = "*"
		destination_address_prefix = "10.0.0.0/24"		
    destination_port_range     = "*"
		access 					           = "Allow"				
	}

	security_rule {
		name 					             = "deny_all_access_from_internet_on_vnet"
		priority 				           = 102
		direction 				         = "Inbound"		
		protocol                   = "Tcp"
		source_address_prefix      = "Internet"
    source_port_range          = "*"
		destination_address_prefix = "10.0.0.0/16"
    destination_port_range     = "*"				
    access 					           = "Deny"
	}

  tags = {
	  environment = var.environment
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
	  environment = var.environment
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-vnet-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/24"]  
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_network_interface" "main" {
  count               = "${var.number_of_vms}"
  name                = "${var.prefix}-nic-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.internal.id
  }
  
  tags = {
	  environment = var.environment
  }
}

resource "azurerm_lb" "main" {
  name                = "${var.prefix}-load-balancer"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  
  frontend_ip_configuration {
	  name                 = "public-ip"
	  public_ip_address_id = azurerm_public_ip.main.id
  }
  
  tags = {
	  environment = var.environment
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  name = "Backend-address-pool"
  loadbalancer_id = azurerm_lb.main.id
}

resource "azurerm_lb_backend_address_pool_address" "main" {
  count                   = var.number_of_vms
  name                    = "address-${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
  virtual_network_id      = azurerm_virtual_network.main.id
  ip_address              = azurerm_network_interface.main[count.index].private_ip_address
}

resource "azurerm_lb_probe" "main" {
  name            = "health-check"
  loadbalancer_id = azurerm_lb.main.id
  protocol        = "Http"
  port            = 80
  request_path    = "/index.html"
}

resource "azurerm_lb_rule" "main" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "lb-rule-http-traffic"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "public-ip"
  probe_id                       = azurerm_lb_probe.main.id
  backend_address_pool_ids       = [ azurerm_lb_backend_address_pool.main.id ]
}

resource "azurerm_managed_disk" "main" {
  count                = var.number_of_vms
  name                 = "${var.prefix}-managed-disk-${count.index}"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "10"

  tags = {
	  environment = var.environment
  }
}

data "azurerm_image" "search" {
  resource_group_name = "udacity-project-webserver-rg"  
  name                = "WebApplicationServer"
}

resource "azurerm_availability_set" "main" {
  name                         = "${var.prefix}-vm-availability-set"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  platform_update_domain_count = min(var.number_of_vms, 5)
  platform_fault_domain_count  = min(var.number_of_vms, 3)

  tags = {
	  environment = var.environment
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  count                           = "${var.number_of_vms}"
  name                            = "${var.prefix}-vm-${count.index}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_D2s_v3"
  disable_password_authentication = true
  source_image_id                 = data.azurerm_image.search.id
  availability_set_id             = azurerm_availability_set.main.id
  admin_username                  = "adminuser"

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  network_interface_ids = [
    azurerm_network_interface.main[count.index].id
  ]
  
  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  
  tags = {
	  environment = var.environment
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "main" {
  count               = "${var.number_of_vms}"
  managed_disk_id     = azurerm_managed_disk.main[count.index].id
  virtual_machine_id  = azurerm_linux_virtual_machine.main[count.index].id
  caching             = "ReadWrite"
  lun                 = "10"
}

output "public_ip_address" {
  value = azurerm_public_ip.main.ip_address
}