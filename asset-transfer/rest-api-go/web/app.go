package web

import (
	"encoding/json"
	"fmt"
	"github.com/Vyom-Yadav/Fake-Product-Detection-Hyperledger/asset-transfer/product-chaincode/chaincode"
	"github.com/skip2/go-qrcode"
	"net/http"
	"os"

	"github.com/hyperledger/fabric-gateway/pkg/client"
)

// OrgSetup contains organization's config to interact with the network.
type OrgSetup struct {
	OrgName  string
	MSPID    string
	CertPath string
	KeyPath  string

	// TLSCertPath The path to the root TLS certificate
	TLSCertPath  string
	PeerEndpoint string
	GatewayPeer  string
	Gateway      client.Gateway
}

// Serve starts http web server.
func Serve(setups OrgSetup) {
	createQRCodes("http://localhost:3000", setups)
	http.HandleFunc("/query", setups.Query)
	http.HandleFunc("/invoke", setups.Invoke)
	fmt.Println("Listening (http://localhost:3000/)...")
	if err := http.ListenAndServe(":3000", nil); err != nil {
		fmt.Println(err)
	}
}

func createQRCodes(url string, orgSetup OrgSetup) {
	contract := orgSetup.Gateway.GetNetwork("supplychain").GetContract("product-chaincode")
	products, err := getAllAssets(contract)
	if err != nil {
		panic(err)
	}
	for index, product := range products {
		// create a file wit relative path
		file, err := os.Create(fmt.Sprintf("../../qr-codes/qr-%d.png", index))
		err = qrcode.WriteFile(url+"/query?function=ReadAsset&args="+product.ProductID, qrcode.Highest, 256, file.Name())
		if err != nil {
			panic(err)
		}
	}
}

func getAllAssets(contract *client.Contract) ([]chaincode.Product, error) {
	fmt.Println("Evaluate Transaction: GetAllAssets, function returns all the current assets on the ledger")

	evaluateResult, err := contract.EvaluateTransaction("GetAllAssets")
	var products []chaincode.Product
	if err != nil {
		return products, nil
	}
	err = json.Unmarshal(evaluateResult, &products)
	if err != nil {
		return products, err
	}
	return products, nil
}
