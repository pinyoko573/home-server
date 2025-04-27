# NOTE: Run in sudo!

# References
# https://ubuntu.com/server/docs/how-to-install-and-use-openvpn

WORKING_DIRECTORY=$(pwd)

# Install OpenVPN and easy-rsa
apt install openvpn easy-rsa

# Setup CA
make-cadir /etc/openvpn/easy-rsa

cd /etc/openvpn/easy-rsa
./easyrsa init-pki
./easyrsa build-ca nopass

# Create server key and cert
./easyrsa --batch gen-req server nopass
./easyrsa gen-dh
./easyrsa --batch sign-req server server
cp pki/dh.pem pki/ca.crt pki/issued/server.crt pki/private/server.key /etc/openvpn/

# Generate TLS Authentication key
cd /etc/openvpn
openvpn --genkey secret ta.key

# Copy server.conf to /etc/openvpn
cp $WORKING_DIRECTORY/server.conf .

# Copy generated CA cert and TLS key to client-config folder
mkdir -p $WORKING_DIRECTORY/client-config/keys
cp ca.crt $WORKING_DIRECTORY/client-config/keys/
cp ta.key $WORKING_DIRECTORY/client-config/keys/

# Enable ip forwarding and reload sysctl
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

# Start openvpn server
systemctl start openvpn@server