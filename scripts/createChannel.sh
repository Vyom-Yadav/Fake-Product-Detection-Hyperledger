#!/bin/bash

# imports
. scripts/envVar.sh
. scripts/utils.sh

CHANNEL_NAME="supplychain"

createChannelGenesisBlock() {
  infoln "Generating channel genesis block '${CHANNEL_NAME}.block'"
  set -x
  configtxgen -configPath "$FABRIC_CFG_PATH" -profile SupplyChainApplicationGenesis -outputBlock "${PWD}"/channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
  res=$?
  { set +x; } 2>/dev/null
  verifyResult $res "Failed to generate channel configuration transaction..."s
}

createChannel() {
  setGlobals "Manufacturer"

  set -x
  osnadmin channel join --channelID $CHANNEL_NAME --config-block "${PWD}"/channel-artifacts/${CHANNEL_NAME}.block -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY" >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Channel creation failed"
}

setAnchorPeer() {
  ORG=$1
  docker exec cli ./scripts/setAnchorPeer.sh "$ORG" $CHANNEL_NAME
}

# joinChannel ORG
joinChannel() {
  FABRIC_CFG_PATH=${PWD}/config/
  ORG=$1
  setGlobals "$ORG"

  set -x
  peer channel join -b "$BLOCKFILE" >&log.txt
  { set +x; } 2>/dev/null

  cat log.txt
}

#FABRIC_CFG_PATH=${PWD}/configtx/
#createChannelGenesisBlock

FABRIC_CFG_PATH=${PWD}/config/
BLOCKFILE="${PWD}/channel-artifacts/${CHANNEL_NAME}.block"

### Create channel
#infoln "Creating channel ${CHANNEL_NAME}"
#createChannel
#successln "Channel '$CHANNEL_NAME' created"

### Join all the peers to the channel
infoln "Joining manufacturer peer to the channel..."
joinChannel "Manufacturer"

#infoln "Joining retailer peer to the channel..."
#joinChannel "Retailer"
#
#infoln "Joining customer peer to the channel..."
#joinChannel "Customer"
#
### Set the anchor peers for each org in the channel
#infoln "Setting anchor peer for manufacturer..."
#setAnchorPeer "Manufacturer"
#
#infoln "Setting anchor peer for retailer..."
#setAnchorPeer "Retailer"
#
#infoln "Setting anchor peer for customer..."
#setAnchorPeer "Customer"

