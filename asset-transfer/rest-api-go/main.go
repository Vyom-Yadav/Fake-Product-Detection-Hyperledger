package main

import (
	"fmt"
	"rest-api-go/web"
)

func main() {
	//Initialize setup for Manufacturer
	cryptoPath := "../../organizations/peerOrganizations/manufacturer.supplychain.com"
	orgConfig := web.OrgSetup{
		OrgName:      "Manufacturer",
		MSPID:        "ManufacturerMSP",
		CertPath:     cryptoPath + "/users/User1@manufacturer.supplychain.com/msp/signcerts/cert.pem",
		KeyPath:      cryptoPath + "/users/User1@manufacturer.supplychain.com/msp/keystore/",
		TLSCertPath:  cryptoPath + "/peers/peer0.manufacturer.supplychain.com/tls/ca.crt",
		PeerEndpoint: "localhost:7051",
		GatewayPeer:  "peer0.manufacturer.supplychain.com",
	}

	orgSetup, err := web.Initialize(orgConfig)
	if err != nil {
		fmt.Println("Error initializing setup for Org1: ", err)
	}
	web.Serve(*orgSetup)
}
