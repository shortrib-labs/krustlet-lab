resource "random_id" "worker" {
  count       = var.workers
  byte_length = 4
}

resource "vsphere_virtual_machine" "worker" {
  name     = "${local.vm_prefix}-worker-${random_id.worker[count.index].hex}"
  count    = var.workers

  datacenter_id    = data.vsphere_datacenter.datacenter.id
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.resource_pool.id
  host_system_id   = data.vsphere_host.host.id
  folder           = var.vsphere_folder

  num_cpus = var.cpus
  memory   = var.memory
  guest_id = "ubuntu64Guest"

  network_interface {
    network_id     = data.vsphere_network.network.id
  }

  disk {
    label            = "disk0"
    size             = var.disk_size
    unit_number      = 0

    io_share_count   = 1000

    thin_provisioned = true
  }

  cdrom {
    client_device = true
  }

  vapp {
    properties = {
      "instance-id" = "id-${local.vm_prefix}-worker-${random_id.worker[count.index].hex}"
      "hostname"    = "${local.vm_prefix}-worker-${random_id.worker[count.index].hex}"
      "password"    = random_pet.default_password.id
      "user-data"   = base64encode(<<-DATA
                      #cloud-config
                      hostname: ${local.vm_prefix}-worker-${random_id.worker[count.index].hex}
                      fqdn: ${local.vm_prefix}-worker-${random_id.worker[count.index].hex}.${var.domain}
                      ${data.carvel_ytt.user_data.result}
                      DATA
                      )
    }
  }

  ovf_deploy { 
    remote_ovf_url = var.remote_ovf_url 
    allow_unverified_ssl_cert = true

    ip_protocol          = "IPV4"
    ip_allocation_policy = "DHCP"
    disk_provisioning    = "thin"
  }

  extra_config = {
    "isolation.tools.copy.disable"         = "FALSE"
    "isolation.tools.paste.disable"        = "FALSE"
    "isolation.tools.SetGUIOptions.enable" = "TRUE"
  }

  provisioner "remote-exec" { 
    inline = [
      data.external.join_script.result["script"]
    ] 
    connection {
      user = "ubuntu"
      host = self.default_ip_address
    }
  }

  provisioner "remote-exec" { 
    inline = [ 
      "echo '# limit who can use SSH\nAllowGroups ssher' | sudo tee /etc/ssh/sshd_config.d/02-limit-to-ssher.conf"
    ] 
    connection {
      user = "ubuntu"
      host = self.default_ip_address
    }
  }
}

