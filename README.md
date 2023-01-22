
# Fake Product Detection Using Hyperledger Fabric

Fake products is a big problem in every industry. Blockchain is a technology that can be very helpful in
tackling this problem.

Hyperledger Fabric is an open source enterprise-grade permissioned distributed ledger technology (DLT) platform, designed for use in enterprise contexts, that delivers some key differentiating capabilities over other popular distributed ledger or blockchain platforms.

You can read more about Hyperledger Fabric at https://hyperledger-fabric.readthedocs.io

## Run Locally

### Prerequisites

Make sure you have installed Hyperledger Fabric [Prerequisites](https://hyperledger-fabric.readthedocs.io/en/release-2.5/prereqs.html), especially [Hyperledger Fabric CLI tool binaries](https://hyperledger-fabric.readthedocs.io/en/release-2.5/install.html#install-fabric-and-fabric-samples).

### Install the Fabric Network

Install from command line

```bash
./network.sh install
```
### Remove the Fabric Network (including volumes mounted to docker containers and certificates)
```bash
./network.sh clean
```

After installing the chaincode, you can invoke the chaincode using `peer` binary.

Invoking chaincode through CLI can be tedious, especially if you don't know the about the necessary arguments to be passed in.

Alternatively, you can use the [REST API](https://github.com/Vyom-Yadav/Fake-Product-Detection-Hyperledger/blob/master/asset-transfer/rest-api-go/README.md) to make your life easier. 
