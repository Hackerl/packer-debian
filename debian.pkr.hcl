variable "output_dir" {
  type    = string
  default = "output"
}

variable "output_name" {
  type    = string
  default = "debian.qcow2"
}

variable "source_checksum_url" {
  type    = string
  default = "file:https://cdimage.debian.org/cdimage/release/11.3.0/amd64/iso-cd/SHA256SUMS"
}

variable "source_iso" {
  description = <<EOF
* Current images in https://cdimage.debian.org/cdimage/release/
* Previous versions are in https://cdimage.debian.org/cdimage/archive/
EOF

  type    = string
  default = "https://cdimage.debian.org/cdimage/release/11.3.0/amd64/iso-cd/debian-11.3.0-amd64-netinst.iso"
}

variable "ssh_password" {
  type    = string
  default = "r00tme"
}

variable "ssh_username" {
  type    = string
  default = "root"
}


build {
  description = <<EOF
This builder builds a QEMU image from a Debian "netinst" CD ISO file.
It contains a few basic tools and can be use as a "cloud image" alternative.
EOF

  sources = ["source.qemu.debian"]
}


source qemu "debian" {
  iso_url      = "${var.source_iso}"
  iso_checksum = "${var.source_checksum_url}"

  cpus = 1
  # The Debian installer warns with a dialog box if there's not enough memory
  # in the system.
  memory      = 1024
  disk_size   = "16G"
  accelerator = "kvm"

  headless = true

  # Serve the `http` directory via HTTP, used for preseeding the Debian installer.
  http_directory = "http"
  http_port_min  = 9990
  http_port_max  = 9999

  # SSH ports to redirect to the VM being built
  host_port_min = 2222
  host_port_max = 2229
  # This user is configured in the preseed file.
  ssh_password     = "${var.ssh_password}"
  ssh_username     = "${var.ssh_username}"
  ssh_timeout      = "20m"

  shutdown_command = "systemctl poweroff"

  # Builds a compact image
  disk_compression   = true
  disk_discard       = "unmap"
  skip_compaction    = false
  disk_detect_zeroes = "unmap"

  format           = "qcow2"
  output_directory = "${var.output_dir}"
  vm_name          = "${var.output_name}"

  boot_wait = "5s"
  boot_command = [
    "<down><tab>", # non-graphical install
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
    "language=en country=US keymap=us ",
    "hostname=debian domain=localdomain", # Should be overriden after DHCP, if available
    "<enter><wait>",
  ]
}