# Install KVM

Before installing KVM, check if your CPU supports hardware virtualisation. A return value **other than 0** shows that you are able to run virtual machines on your server.

`egrep -c '(vmx|svm)' /proc/cpuinfo`

Install KVM and virt-manager from the apt repository. The virt-manager provides an interface to manage your VMs.

```
sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils -y
sudo apt-get install virt-manager
```

# Create an instance
Example of creating a instance with 2 CPU, 8 GB RAM, 128 GB Disk and attaching a Windows 11 iso file
```
sudo virt-install --name win11 --memory 8192 --vcpus 2 --disk size=128 --cdrom /tmp/Win11_24H2_English_x64.iso --graphics vnc,listen=0.0.0.0,port=5900 --network network=default,model=vmxnet3 --osinfo detect=on,require=off
```

To remove the vnc connection, run `sudo virsh edit win11` and delete the vnc block.

# Customisation

## Changing VM disk image default location

By default, VM disk images are stored in `/var/lib/libvirt/images`.

To change the default location, change the path in `/etc/libvirt/storage/default.xml`.

## Autostart

To automatically start the virtual network on boot,
```
sudo virsh net-autostart default
```

To automatically start the virtual machine on boot,
```
sudo virsh autostart <vm_name>
```

## Static IP address

To assign a static IP address to your instance, first find the MAC address using `sudo virsh dumpxml <vm_name>`

```
<interface type='network'>
  <mac address='52:54:00:82:95:b3'/>
  <source network='default'/>
  <model type='vmxnet3'/>
  <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
</interface>
```

Then run `sudo virsh net-edit default` and add the following
```
<network>
  <name>default</name>
  <uuid>7053a811-8ba8-496a-9475-b8a6fd7529d0</uuid>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:53:00:69:7c:b0'/>
  <ip address='192.168.100.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.100.2' end='192.168.100.254'/>
      <host mac='52:53:00:78:53:b3' name='<vm_name>' ip='192.168.100.2'/>
    </dhcp>
  </ip>
</network>
```

Restart the virtual network using
```
sudo virsh net-destroy default
sudo virsh net-start default
```

## Port forwarding using iptables
For example, to allow TCP/UDP port 3389 on 192.168.100.2
```
sudo iptables -I FORWARD -o virbr0 -d 192.168.100.2 -p tcp --dport 3389 -j ACCEPT
sudo iptables -I FORWARD -o virbr0 -d 192.168.100.2 -p udp --dport 3389 -j ACCEPT
sudo iptables -t nat -I PREROUTING -p tcp --dport 3389 -j DNAT --to 192.168.100.2:3389
sudo iptables -t nat -I PREROUTING -p udp --dport 3389 -j DNAT --to 192.168.100.2:3389
```