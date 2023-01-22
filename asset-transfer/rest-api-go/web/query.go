package web

import (
	"fmt"
	"net/http"
)

// Query handles chaincode query requests.
func (setup OrgSetup) Query(w http.ResponseWriter, r *http.Request) {
	fmt.Println("Received Query request")
	queryParams := r.URL.Query()
	function := queryParams.Get("function")
	args := r.URL.Query()["args"]
	fmt.Printf("channel: supplychain, chaincode: product-chaincode, function: %s, args: %s\n", function, args)
	network := setup.Gateway.GetNetwork("supplychain")
	contract := network.GetContract("product-chaincode")
	evaluateResponse, err := contract.EvaluateTransaction(function, args...)
	if err != nil {
		fmt.Fprintf(w, "Error: %s", err)
		return
	}
	fmt.Fprintf(w, "Response: %s", evaluateResponse)
}
