# NOTE: Run in sudo!
# In client.conf, replace mywebsite.com with your domain/IP
# To create a client certificate, run 'sudo setup_client.sh client_indekkusu'

# References
# https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-an-openvpn-server-on-ubuntu-20-04

WORKING_DIRECTORY=$(pwd)
CLIENT_NAME=$1

KEY_DIR=$WORKING_DIRECTORY/client-config/keys
OUTPUT_DIR=$WORKING_DIRECTORY/client-config/output
BASE_CONFIG=$WORKING_DIRECTORY/client-config/client.conf
mkdir -p $OUTPUT_DIR

# Create client cert
cd /etc/openvpn/easy-rsa
./easyrsa gen-req $CLIENT_NAME nopass
./easyrsa sign-req client $CLIENT_NAME

# Copy client certificate to client-config/keys
cp pki/issued/$CLIENT_NAME.crt $WORKING_DIRECTORY/client-config/keys/
cp pki/private/$CLIENT_NAME.key $WORKING_DIRECTORY/client-config/keys/

# Generate ovpn to output directory
cat ${BASE_CONFIG} \
    <(echo -e '<ca>') \
    ${KEY_DIR}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${KEY_DIR}/${CLIENT_NAME}.crt \
    <(echo -e '</cert>\n<key>') \
    ${KEY_DIR}/${CLIENT_NAME}.key \
    <(echo -e '</key>\n<tls-crypt>') \
    ${KEY_DIR}/ta.key \
    <(echo -e '</tls-crypt>') \
    > ${OUTPUT_DIR}/${CLIENT_NAME}.ovpn