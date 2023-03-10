package web

import (
	"fmt"
	"net/http"

	"github.com/hyperledger/fabric-gateway/pkg/client"
)

// Invoke handles chaincode invoke requests.
func (setup OrgSetup) Invoke(w http.ResponseWriter, r *http.Request) {
	fmt.Println("Received Invoke request")
	if err := r.ParseForm(); err != nil {
		fmt.Fprintf(w, "ParseForm() err: %s", err)
		return
	}
	function := r.FormValue("function")
	args := r.Form["args"]
	fmt.Printf("channel: supplychain, chaincode: product-chaincode, function: %s, args: %s\n", function, args)
	network := setup.Gateway.GetNetwork("supplychain")
	contract := network.GetContract("product-chaincode")
	txnProposal, err := contract.NewProposal(function, client.WithArguments(args...))
	if err != nil {
		fmt.Fprintf(w, "Error creating txn proposal: %s", err)
		return
	}
	txnEndorsed, err := txnProposal.Endorse()
	if err != nil {
		fmt.Fprintf(w, "Error endorsing txn: %s", err)
		return
	}
	txnCommitted, err := txnEndorsed.Submit()
	if err != nil {
		fmt.Fprintf(w, "Error submitting transaction: %s", err)
		return
	}
	fmt.Fprintf(w, "Transaction ID : %s Response: %s", txnCommitted.TransactionID(), txnEndorsed.Result())
}
