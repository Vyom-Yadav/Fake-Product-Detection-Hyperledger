#!/bin/bash

# imports
. scripts/utils.sh

SOCK="${DOCKER_HOST:-/var/run/docker.sock}"
export DOCKER_SOCK="${SOCK##unix://}"

function up() {
  # generate artifacts if they don't exist
  if [ ! -d "organizations/peerOrganizations" ]; then
    createOrgs
  fi

  docker compose -f compose/compose-net.yaml up -d

  docker ps -a
  if [ $? -ne 0 ]; then
    fatalln "Unable to start network"
  fi
}

function createOrgs() {
  if [ -d "organizations/peerOrganizations" ]; then
    rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
  fi

  infoln "Generating certificates using Fabric CA"
  docker compose -f compose/compose-ca.yaml up -d

  . organizations/fabric-ca/registerEnroll.sh

  while :
  do
    if [ ! -f "organizations/fabric-ca/manufacturerOrg/tls-cert.pem" ]; then
      sleep 1
    else
      break
    fi
  done

  infoln "Creating ManufacturerOrg Identities"

  createManufacturerOrg

  infoln "Creating RetailerOrg Identities"

  createRetailerOrg

  infoln "Creating CustomerOrg Identities"

  createCustomerOrg

  infoln "Creating Orderer Org Identities"

  createOrderer

  infoln "Generating CCP files for ManufacturerOrg, RetailerOrg and CustomerOrg"
  ./organizations/ccp-generate.sh
}

function clean() {
  pushd ./organizations/fabric-ca/ordererOrg || exit
  ls | sudo xargs rm -rf
  popd || exit

  pushd ./organizations/fabric-ca/manufacturerOrg || exit
  ls | sudo xargs rm -rf
  popd || exit

  pushd ./organizations/fabric-ca/retailerOrg || exit
  ls | sudo xargs rm -rf
  popd || exit

  pushd ./organizations/fabric-ca/customerOrg || exit
  ls | sudo xargs rm -rf
  popd || exit

  rm -rf ./organizations/peerOrganizations ./organizations/ordererOrganizations ./channel-artifacts/
  rm ./log.txt ./product-chaincode.tar.gz

  docker compose -f compose/compose-net.yaml -f compose/compose-ca.yaml down --volumes --remove-orphans
}

function createChannel() {
  ./scripts/createChannel.sh
}

function deployCC() {
  ./scripts/deployCC.sh
}

$1