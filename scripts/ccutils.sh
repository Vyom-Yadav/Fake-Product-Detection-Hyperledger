#!/bin/bash

function installChaincode() {
  ORG=$1
  setGlobals "$ORG"
  set -x
  peer lifecycle chaincode queryinstalled --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^"${PACKAGE_ID}"$ >&log.txt
  if test $? -ne 0; then
    peer lifecycle chaincode install "${CC_NAME}".tar.gz >&log.txt
    res=$?
  fi
  { set +x; } 2>/dev/null
  cat log.txt

  ORG_LOWER=$(echo "$ORG" | tr '[:upper:]' '[:lower:]')
  verifyResult $res "Chaincode installation on peer0.${ORG_LOWER} has failed"
  successln "Chaincode is installed on peer0.${ORG_LOWER}"
}

function queryInstalled() {
  ORG=$1
  setGlobals "$ORG"
  set -x
  peer lifecycle chaincode queryinstalled --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^"${PACKAGE_ID}"$ >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt

  ORG_LOWER=$(echo "$ORG" | tr '[:upper:]' '[:lower:]')
  verifyResult $res "Query installed on peer0.${ORG_LOWER} has failed"
  successln "Query installed successful on peer0.${ORG_LOWER} on channel"
}

function approveForMyOrg() {
  ORG=$1
  setGlobals "$ORG"
  set -x
  peer lifecycle chaincode approveformyorg -o localhost:7050 \
   --ordererTLSHostnameOverride orderer1.orderer.supplychain.com --tls \
   --cafile "$ORDERER_CA" --channelID "$CHANNEL_NAME" --name "${CC_NAME}" \
   --version "${CC_VERSION}" --package-id "${PACKAGE_ID}" \
   --sequence "${CC_VERSION}" --init-required >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt

  ORG_LOWER=$(echo "$ORG" | tr '[:upper:]' '[:lower:]')
  verifyResult $res "Chaincode definition approved on peer0.${ORG_LOWER} on channel '$CHANNEL_NAME' failed"
  successln "Chaincode definition approved on peer0.${ORG_LOWER} on channel '$CHANNEL_NAME'"
}

function checkCommitReadiness() {
  ORG=$1
  ORG_LOWER=$(echo "$ORG" | tr '[:upper:]' '[:lower:]')
  setGlobals "$ORG"
  infoln "Checking the commit readiness of the chaincode definition on peer0.${ORG_LOWER} on channel '$CHANNEL_NAME'..."
  set -x
  peer lifecycle chaincode checkcommitreadiness --channelID "$CHANNEL_NAME" \
   --name "${CC_NAME}" --version "${CC_VERSION}" \
   --sequence "${CC_VERSION}" --init-required --output json >&log.txt
  res=$?
  { set +x; } 2>/dev/null
}

function commitChaincodeDefinition() {
  infoln "Committing chaincode definition on channel '$CHANNEL_NAME'..."
  peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer1.orderer.supplychain.com \
    --tls "$CORE_PEER_TLS_ENABLED" --cafile "$ORDERER_CA" \
    --channelID "$CHANNEL_NAME" --name "${CC_NAME}" \
    --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER0_MANUFACTURER_CA" \
    --peerAddresses localhost:9051 --tlsRootCertFiles "$PEER0_RETAILER_CA" \
    --peerAddresses localhost:11051 --tlsRootCertFiles "$PEER0_CUSTOMER_CA" \
    --version "${CC_VERSION}" --sequence "${CC_VERSION}" --init-required
}

function queryCommitted() {
  ORG=$1
  setGlobals "$ORG"
  ORG_LOWER=$(echo "$ORG" | tr '[:upper:]' '[:lower:]')
  infoln "Querying chaincode definition on peer0.${ORG_LOWER} on channel '$CHANNEL_NAME'..."
  peer lifecycle chaincode querycommitted --channelID "$CHANNEL_NAME" --name "${CC_NAME}"
}

function chaincodeInvokeInit() {
  infoln "Sending invoke transaction on channel '$CHANNEL_NAME'..."
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer1.orderer.supplychain.com \
    --tls "$CORE_PEER_TLS_ENABLED" --cafile "$ORDERER_CA" -C "$CHANNEL_NAME" -n "${CC_NAME}" \
    --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER0_MANUFACTURER_CA" \
    --peerAddresses localhost:9051 --tlsRootCertFiles "$PEER0_RETAILER_CA" \
    --peerAddresses localhost:11051 --tlsRootCertFiles "$PEER0_CUSTOMER_CA" \
    --isInit -c '{"function":"InitLedger","Args":[]}'
}

function chaincodeQuery() {
  ORG=$1
  setGlobals "$ORG"
  ORG_LOWER=$(echo "$ORG" | tr '[:upper:]' '[:lower:]')
  infoln "Querying chaincode on peer0.${ORG_LOWER} on channel '$CHANNEL_NAME'..."
  # Query all assets
  peer chaincode query -C "$CHANNEL_NAME" -n "${CC_NAME}" -c '{"Args":["GetAllAssets"]}'
}