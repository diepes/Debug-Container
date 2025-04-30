#!/usr/bin/env bash
version="0.2.1_20250430"

# 20250430 v0.2.0 - Added support for SANs
# 20250430 v0.1.0 - Initial version
# ToDo: move certificate to Hashicorp Vault and retrieve using Vault TF provider.
# See README.md for usage
# This script generates a selfsigned CA certificate and key, and a .pfx file
# The .pfx file is password protected, and the password is printed to the console
# Save the key and .pfx in secretserver
#      under Azure/ApplicationGateway/"${var.env}-appgw-tf-<VM_NAME>"

DEFAULT_PASS="pfx-pwd-$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9')"
# --- Parse arguments ---
CERT_PASS="$DEFAULT_PASS"
SAN_LIST=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --password)
            CERT_PASS="$2"
            shift 2
            ;;
        -h|--help)
            echo "# Usage: $0 [--password CERT_PASS] <CN> [SAN1 SAN2 ...]"
            echo "# Example: $0 --password mysecretpass example.com www.example.com \"*.example.com\""
            exit 0
            ;;
        *)
            SAN_LIST+=("$1")
            shift
            ;;
    esac
done

if [[ ${#SAN_LIST[@]} -eq 0 ]]; then
    echo "# ERROR: At least one DNS name (the CN) must be provided."
    echo "# Run with --help for usage."
    exit 1
fi


DOMAIN="${SAN_LIST[0]}"
BASE="CERT_${DOMAIN}_$(date +%Y%m%d)"
SAN_LIST=("${SAN_LIST[@]}")  # Preserve all SANs, CN is just the first

# Check if there are any files starting with $BASE
if find . -maxdepth 1 -name "${BASE}*" | grep -q .; then
    echo "# Found existing files. matching BASE=$BASE"
    find . -maxdepth 1 -name "${BASE}*"
    echo "# ERROR: Please remove them first."
    exit 1
else
    echo "# Good to go. no files matching BASE=$BASE"
    echo
fi

echo "# Generating a new selfsigned CA certificate and key  ${SAN_LIST[@]}"
# Generate a new selfsigned CA certificate and key, 100y lifetime
# add -outform der for Azure App Gateway compatibility
openssl req \
-x509 \
-newkey rsa:4096 \
-sha256 \
-days "$(( 365 * 100 ))" \
-nodes \
-keyout $BASE.key \
-out $BASE.crt \
-subj "/CN=${DOMAIN}" \
-extensions v3_ca \
-extensions v3_req \
-config <( \
  echo '[req]'; \
  echo 'default_bits= 4096'; \
  echo 'distinguished_name=req'; \
  echo 'x509_extension = v3_ca'; \
  echo 'req_extensions = v3_req'; \
  echo '[v3_req]'; \
  echo 'basicConstraints = CA:FALSE'; \
  echo 'keyUsage = nonRepudiation, digitalSignature, keyEncipherment'; \
  echo 'subjectAltName = @alt_names'; \
  echo '[ alt_names ]'; \
  i=1; for san in "${SAN_LIST[@]}"; do echo "DNS.$i = $san"; ((i++)); done; \
  echo '[ v3_ca ]'; \
  echo 'subjectKeyIdentifier=hash'; \
  echo 'authorityKeyIdentifier=keyid:always,issuer'; \
  echo 'basicConstraints = critical, CA:TRUE, pathlen:0'; \
  echo 'keyUsage = critical, cRLSign, keyCertSign'; \
  echo 'extendedKeyUsage = serverAuth, clientAuth')

echo; echo "# Verify text info of the generated certificate"
openssl x509 -noout -text -in $BASE.crt

echo; echo "# Generate der cert format from pem. \"$BASE.der.cer\""
openssl x509 -outform der -in $BASE.crt -out $BASE.der.cer

echo; echo "# Generate pfx file. \"$BASE.pfx\""; echo
# To get a .pfx, use the following command:
openssl pkcs12 -export -out $BASE.pfx -inkey $BASE.key -in $BASE.crt -passout pass:$CERT_PASS

echo
echo "# Done. generated. crt+key and pfx(both with password)"
if [[ "$CERT_PASS" == "$DEFAULT_PASS" ]]; then
    echo "#   WARNING: Default random password used. CERT_PASS=\"${CERT_PASS}\""
fi
echo "$CERT_PASS" > $BASE.pfx.passwd
echo
ls $BASE.*
echo
echo "# Next move $BASE.crt to \"terraform/<env>/.\" and update the appgw config to use it as CA."
echo "# the $BASE.pfx or key+crt to be used on VM or pfx can be used for AppGW frontend cert."
