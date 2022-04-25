variable "iso_url" {
  description = <<EOF
* Current images in https://cdimage.debian.org/cdimage/release/
* Previous versions are in https://cdimage.debian.org/cdimage/archive/
EOF

  type    = string
  default = "https://cdimage.debian.org/cdimage/release/11.3.0/amd64/iso-cd/debian-11.3.0-amd64-netinst.iso"
}

variable "iso_checksum" {
  type    = string
  default = "file:https://cdimage.debian.org/cdimage/release/11.3.0/amd64/iso-cd/SHA256SUMS"
}

variable "output_dir" {
  type    = string
  default = "output"
}

variable "output_name" {
  type    = string
  default = "debian.qcow2"
}

variable "password" {
  type    = string
  default = "9toE!r00tme"
}

variable "hostname" {
  type    = string
  default = "debian"
}

variable "domain" {
  type    = string
  default = "localdomain"
}

variable "cpus" {
  type    = number
  default = 1
}

variable "vnc_bind_address" {
  type    = string
  default = "127.0.0.1"
}


build {
  description = <<EOF
This builder builds a QEMU image from a Debian "netinst" CD ISO file.
It contains a few basic tools and can be use as a "cloud image" alternative.
EOF

  sources = ["source.qemu.debian"]

  provisioner "shell" {
    inline = [
      "echo 'root:${var.password}' | chpasswd"
    ]
  }

  post-processor "shell-local" {
    inline = [
      "virt-sparsify --in-place ${var.output_dir}/${var.output_name}"
    ]
  }

  post-processor "checksum" {
    checksum_types = ["sha256"]
    output         = "${var.output_dir}/${var.output_name}.{{.ChecksumType}}"
  }
}


source qemu "debian" {
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  cpus        = var.cpus
  memory      = 1024
  disk_size   = "16G"
  accelerator = "kvm"

  headless         = true
  http_directory   = "http"
  vnc_bind_address = var.vnc_bind_address

  ssh_username = "root"
  ssh_password = "r00tme"
  ssh_timeout  = "20m"

  shutdown_command = "systemctl poweroff"
  skip_compaction  = true

  format           = "qcow2"
  output_directory = var.output_dir
  vm_name          = var.output_name

  boot_wait = "5s"
  boot_command = [
    "<down><tab>",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
    "language=en country=US keymap=us ",
    "hostname=${var.hostname} domain=${var.domain}",
    "<enter><wait>"
  ]
}