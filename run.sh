source .env

# Create Resource Group - if not exist 
# Create Azure DNS Zone (Public DNS NS) - if not exist
# Create Storage Account - if not exist

# Generate SP Secret Certificate
go run ./hack/genkey -client arm
mv arm.* secrets


## AAD Applications
# Create SP for "Fake" ARM Layer
# Later this application will be granted:
#
# User Access Administrator on your subscription.
# 
AZURE_ARM_CLIENT_ID="$(az ad app create \
  --display-name aro-v4-arm-shared \
  --identifier-uris "https://$(uuidgen)/" \
  --query appId \
  -o tsv)"
az ad app credential reset \
  --id "$AZURE_ARM_CLIENT_ID" \
  --cert "$(base64 -w0 <secrets/arm.crt)" >/dev/null
az ad sp create --id "$AZURE_ARM_CLIENT_ID" >/dev/null

# Create SP for "Fake" 1st Party App
# Later this application will be granted:
# 
# ARO v4 FP Subscription on your subscription.
# DNS Zone Contributor on the DNS zone in RESOURCEGROUP.
# Network Contributor on RESOURCEGROUP.
#
go run ./hack/genkey -client firstparty
mv firstparty.* secrets

AZURE_FP_CLIENT_ID="$(az ad app create \
  --display-name aro-v4-fp-shared \
  --identifier-uris "https://$(uuidgen)/" \
  --query appId \
  -o tsv)"
az ad app credential reset \
  --id "$AZURE_FP_CLIENT_ID" \
  --cert "$(base64 -w0 <secrets/firstparty.crt)" >/dev/null
az ad sp create --id "$AZURE_FP_CLIENT_ID" >/dev/null

## Create SP for "Fake" RP Identity
#Later this application will be granted:
#
# Reader on RESOURCEGROUP.
# Secrets / Get on the key vault in RESOURCEGROUP.
# DocumentDB Account Contributor on the CosmosDB resource in RESOURCEGROUP.
AZURE_RP_CLIENT_SECRET="$(uuidgen)"
AZURE_RP_CLIENT_ID="$(az ad app create \
  --display-name aro-v4-rp-shared \
  --end-date '2299-12-31T11:59:59+00:00' \
  --identifier-uris "https://$(uuidgen)/" \
  --key-type password \
  --password "$AZURE_RP_CLIENT_SECRET" \
  --query appId \
  -o tsv)"
az ad sp create --id "$AZURE_RP_CLIENT_ID" >/dev/null

## Create SP for "Fake" Azure Gateway Identity
AZURE_GATEWAY_CLIENT_SECRET="$(uuidgen)"
AZURE_GATEWAY_CLIENT_ID="$(az ad app create \
  --display-name aro-v4-gateway-shared \
  --end-date '2299-12-31T11:59:59+00:00' \
  --identifier-uris "https://$(uuidgen)/" \
  --key-type password \
  --password "$AZURE_GATEWAY_CLIENT_SECRET" \
  --query appId \
  -o tsv)"
az ad sp create --id "$AZURE_GATEWAY_CLIENT_ID" >/dev/null

## Create SP for E2E tooling
#Later this application will be granted:
#
# Contributor on your subscription.
# User Access Administrator on your subscription.
AZURE_CLIENT_SECRET="$(uuidgen)"
AZURE_CLIENT_ID="$(az ad app create \
  --display-name aro-v4-tooling-shared \
  --end-date '2299-12-31T11:59:59+00:00' \
  --identifier-uris "https://$(uuidgen)/" \
  --key-type password \
  --password "$AZURE_CLIENT_SECRET" \
  --query appId \
  -o tsv)"
az ad sp create --id "$AZURE_CLIENT_ID" >/dev/null