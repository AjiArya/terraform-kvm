provider "libvirt" {
  uri= "qemu:///system" # For Local Provisioning
}

resource "libvirt_network" "net-example" {
  name = "net-example"
  addresses = ["192.168.10.0/24"]
}

resource "libvirt_volume" "example-img" {
  name = "example-img.qcow2"
  pool = "default"
  source = "/home/arya/Downloads/bionic-server-cloudimg-amd64.img"
}

resource "libvirt_volume" "example-volume" {
  name = "example-volume.qcow2"
  pool = "default"
  base_volume_id = "${libvirt_volume.example-img.id}"
  size = "5368709120" # Size in Bytes, This is 5GB
}

resource "libvirt_cloudinit_disk" "cloudinit-example" {
  name = "cloudinit-example"
  pool = "default"
  user_data = "${data.template_file.user_data.rendered}"
  network_config = "${data.template_file.network_config.rendered}"
}

data "template_file" "user_data" {
    template = "${file("${path.module}/cloud_init.cfg")}"
}

data "template_file" "network_config" {
    template = "${file("${path.module}/network_config.cfg")}"
}

resource "libvirt_domain" "vm-example" {
  name = "vm-example"
  vcpu = "1"
  memory = "2048"
  machine = "pc-i440fx-bionic"
  cloudinit = "${libvirt_cloudinit_disk.cloudinit-example.id}"

  network_interface {
      network_id = "${libvirt_network.net-example.id}"
      network_name = "net-example"
      addresses = ["192.168.10.0/24"]
  }

  console {
      type = "pty"
      target_port = "0"
      target_type = "serial"
  }

  console {
      type = "pty"
      target_port = "0"
      target_type = "virtio"
  }

  disk {
      volume_id = "${libvirt_volume.example-volume.id}"
  }

  graphics {
      type = "vnc"
      listen_type = "address"
      autoport = "true"
  }
}