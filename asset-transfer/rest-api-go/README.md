# Asset Transfer REST API Sample

This is a simple REST server written in golang with endpoints for chaincode invoke and query.

  
## Usage

- Setup fabric test network and deploy the asset transfer chaincode by [following these instructions](https://github.com/Vyom-Yadav/Fake-Product-Detection-Hyperledger/blob/master/README.md).

- cd into rest-api-go directory
- Download required dependencies using `go mod download`
- Run `go run main.go` to run the REST server

## Sending Requests

Invoke endpoint accepts POST requests with chaincode function and arguments. Query endpoint accepts get requests with chaincode function and arguments.

Sample chaincode invoke for the "TransferAssetToRetailer" function. Response will contain transaction ID for a successful invoke.

``` sh
curl --request POST \
  --url http://localhost:3000/invoke \
  --header 'content-type: application/x-www-form-urlencoded' \
  --data = \
  --data channelid=supplychain \
  --data chaincodeid=product-chaincode \
  --data function=TransferAssetToRetailer \
  --data args=product1 \
  --data args='Jain Medicos' \
  --data args='DSS 11 sector 20 Panchkula-Haryana-India'
```
Sample chaincode query for getting all asset details.

``` sh
curl --request GET \
  --url 'http://localhost:3000/query?channelid=supplychain&chaincodeid=product-chaincode&function=GetAllAssets'
```
