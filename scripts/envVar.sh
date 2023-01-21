#!/bin/bash

# imports
. scripts/utils.sh

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/orderer.supplychain.com/tlsca/tlsca.orderer.supplychain.com-cert.pem
export PEER0_MANUFACTURER_CA=${PWD}/organizations/peerOrganizations/manufacturer.supplychain.com/tlsca/tlsca.manufacturer.supplychain.com-cert.pem
export PEER0_RETAILER_CA=${PWD}/organizations/peerOrganizations/retailer.supplychain.com/tlsca/tlsca.retailer.supplychain.com-cert.pem
export PEER0_CUSTOMER_CA=${PWD}/organizations/peerOrganizations/customer.supplychain.com/tlsca/tlsca.customer.supplychain.com-cert.pem
export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/orderer.supplychain.com/orderers/orderer1.orderer.supplychain.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/orderer.supplychain.com/orderers/orderer1.orderer.supplychain.com/tls/server.key

# Set environment variables for the peer org
setGlobals() {
  local USING_ORG=$1
  infoln "Using organization ${USING_ORG}"
  # if USING_ORG is equal to Manufacturer
  if [ "$USING_ORG" == "Manufacturer" ]; then
    export CORE_PEER_LOCALMSPID="ManufacturerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_MANUFACTURER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/manufacturer.supplychain.com/users/Admin@manufacturer.supplychain.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ "$USING_ORG" == "Retailer" ]; then
    export CORE_PEER_LOCALMSPID="RetailerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_RETAILER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/retailer.supplychain.com/users/Admin@retailer.supplychain.com/msp
    export CORE_PEER_ADDRESS=localhost:9051

  elif [ "$USING_ORG" == "Customer" ]; then
    export CORE_PEER_LOCALMSPID="CustomerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_CUSTOMER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/customer.supplychain.com/users/Admin@customer.supplychain.com/msp
    export CORE_PEER_ADDRESS=localhost:11051
  else
    errorln "ORG Unknown"
  fi
}

# Set environment variables for use in the CLI container
setGlobalsCLI() {
  setGlobals "$1"

  local USING_ORG=$1
  if [ "$USING_ORG" == "Manufacturer" ]; then
    export CORE_PEER_ADDRESS=peer0.manufacturer.supplychain.com:7051
  elif [ "$USING_ORG" == "Retailer" ]; then
    export CORE_PEER_ADDRESS=peer0.retailer.supplychain.com:9051
  elif [ "$USING_ORG" == "Customer" ]; then
    export CORE_PEER_ADDRESS=peer0.customer.supplychain.com:11051
  else
    errorln "ORG Unknown"
  fi
}

verifyResult() {
  if [ "$1" -ne 0 ]; then
    fatalln "$2"
  fi
}
