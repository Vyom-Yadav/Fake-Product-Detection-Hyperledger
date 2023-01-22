#!/bin/bash

# import utils
. scripts/envVar.sh
. scripts/ccutils.sh
. scripts/utils.sh

CHANNEL_NAME="supply-chain"
CC_RUNTIME_LANGUAGE="golang"
CC_VERSION="1"
CC_SRC_PATH="./asset-transfer/product-chaincode/"
CC_NAME="product-chaincode"

packageChaincode() {
  set -x
  peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION} >&log.txt
  res=$?
  PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CC_NAME}.tar.gz)
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode packaging has failed"
  successln "Chaincode is packaged"
}

packageChaincode

infoln "Installing chaincode on peer0.manufacturer..."
installChaincode "Manufacturer"
infoln "Install chaincode on peer0.retailer..."
installChaincode "Retailer"
infoln "Install chaincode on peer0.customer..."
installChaincode "Customer"

queryInstalled "Manufacturer"

approveForMyOrg "Manufacturer"

checkCommitReadiness "Manufacturer"
checkCommitReadiness "Retailer"
checkCommitReadiness "Customer"

approveForMyOrg "Retailer"

checkCommitReadiness "Manufacturer"
checkCommitReadiness "Retailer"
checkCommitReadiness "Customer"

approveForMyOrg "Customer"

checkCommitReadiness "Manufacturer"
checkCommitReadiness "Retailer"
checkCommitReadiness "Customer"

commitChaincodeDefinition "Manufacturer"

queryCommitted "Manufacturer"
queryCommitted "Retailer"
queryCommitted "Customer"

chaincodeInvokeInit
sleep 5
chaincodeQuery "Manufacturer"