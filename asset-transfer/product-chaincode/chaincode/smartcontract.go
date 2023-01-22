package chaincode

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing an Asset
type SmartContract struct {
	contractapi.Contract
}

type Product struct {
	ProductID        string `json:"ProductID"`
	ProductType      string `json:"ProductType"`
	Owner            Owner  `json:"Owner"`
	WithManufacturer bool   `json:"WithManufacturer"`
	WithRetailer     bool   `json:"WithRetailer"`
	WithConsumer     bool   `json:"WithConsumer"`
}

type Owner struct {
	OwnerName    string `json:"OwnerName"`
	OwnerAddress string `json:"OwnerAddress"`
}

// InitLedger adds a base set of assets to the ledger
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	products := []Product{
		{
			Owner:     Owner{OwnerName: "Apollo Pharmacy", OwnerAddress: "DSS 167 sector 25 Panchkula-Haryana-India"},
			ProductID: "product1", ProductType: "paracetamol",
			WithConsumer: false, WithManufacturer: true, WithRetailer: false,
		},
		{
			Owner:     Owner{OwnerName: "Apollo Pharmacy", OwnerAddress: "DSS 167 sector 25 Panchkula-Haryana-India"},
			ProductID: "product2", ProductType: "redinol",
			WithConsumer: false, WithManufacturer: true, WithRetailer: false,
		},
	}
	for _, product := range products {
		productJSON, err := json.Marshal(product)
		if err != nil {
			return err
		}

		err = ctx.GetStub().PutState(product.ProductID, productJSON)
		if err != nil {
			return fmt.Errorf("failed to put to world state. %v", err)
		}
	}

	return nil
}

// CreateAsset issues a new asset to the world state with given details.
func (s *SmartContract) CreateAsset(ctx contractapi.TransactionContextInterface, productId, productType string) error {
	clientIdentity := ctx.GetClientIdentity()
	mspId, err := clientIdentity.GetMSPID()
	if err != nil {
		return err
	}
	if mspId == "ManufacturerMSP" {
		exists, err := s.AssetExists(ctx, productId)
		if err != nil {
			return err
		}
		if exists {
			return fmt.Errorf("the asset %s already exists", productId)
		}

		ownerName, found, err := clientIdentity.GetAttributeValue("user.name")
		if err != nil {
			return err
		}
		if !found {
			return fmt.Errorf("user.name attribute not found, name of the owner is required")
		}

		ownerAddress, found, err := clientIdentity.GetAttributeValue("user.address")
		if err != nil {
			return err
		}
		if !found {
			return fmt.Errorf("user.address attribute not found, name of the owner is required")
		}

		// Create the asset
		asset := Product{
			Owner:     Owner{OwnerName: ownerName, OwnerAddress: ownerAddress},
			ProductID: productId, ProductType: productType,
			WithConsumer: false, WithManufacturer: true, WithRetailer: false,
		}

		assetJSON, err := json.Marshal(asset)
		if err != nil {
			return err
		}

		return ctx.GetStub().PutState(productId, assetJSON)
	} else {
		return fmt.Errorf("only Manufacturer can create product")
	}
}

// ReadAsset returns the asset stored in the world state with given id.
func (s *SmartContract) ReadAsset(ctx contractapi.TransactionContextInterface, productID string) (*Product, error) {
	assetJSON, err := ctx.GetStub().GetState(productID)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if assetJSON == nil {
		return nil, fmt.Errorf("the asset %s does not exist", productID)
	}

	var asset Product
	err = json.Unmarshal(assetJSON, &asset)
	if err != nil {
		return nil, err
	}

	return &asset, nil
}

// UpdateAsset updates an existing asset in the world state with provided parameters.
func (s *SmartContract) UpdateAsset(ctx contractapi.TransactionContextInterface, productID, productType string) error {
	clientIdentity := ctx.GetClientIdentity()
	mspId, err := clientIdentity.GetMSPID()
	if err != nil {
		return err
	}
	if mspId == "ManufacturerMSP" {
		exists, err := s.AssetExists(ctx, productID)
		if err != nil {
			return err
		}
		if !exists {
			return fmt.Errorf("the asset %s does not exist", productID)
		}

		asset, err := s.ReadAsset(ctx, productID)
		if err != nil {
			return err
		}
		asset.ProductType = productType
		assetJSON, err := json.Marshal(asset)
		if err != nil {
			return err
		}
		return ctx.GetStub().PutState(productID, assetJSON)
	} else {
		return fmt.Errorf("only Manufacturer can update product")
	}
}

// DeleteAsset deletes an given asset from the world state.
func (s *SmartContract) DeleteAsset(ctx contractapi.TransactionContextInterface, productID string) error {
	clientIdentity := ctx.GetClientIdentity()
	mspId, err := clientIdentity.GetMSPID()
	if err != nil {
		return err
	}
	if mspId == "ManufacturerMSP" {
		exists, err := s.AssetExists(ctx, productID)
		if err != nil {
			return err
		}
		if !exists {
			return fmt.Errorf("the asset %s does not exist", productID)
		}

		return ctx.GetStub().DelState(productID)
	} else {
		return fmt.Errorf("only Manufacturer can delete product")
	}
}

// AssetExists returns true when asset with given ID exists in world state
func (s *SmartContract) AssetExists(ctx contractapi.TransactionContextInterface, productID string) (bool, error) {
	assetJSON, err := ctx.GetStub().GetState(productID)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	return assetJSON != nil, nil
}

// TransferAssetToRetailer updates the owner field of asset with given id in world state, and returns the old owner.
func (s *SmartContract) TransferAssetToRetailer(ctx contractapi.TransactionContextInterface, productID string, newOwnerName, newOwnerAddress string) (string, error) {
	clientIdentity := ctx.GetClientIdentity()
	mspId, err := clientIdentity.GetMSPID()
	if err != nil {
		return "", err
	}
	if mspId == "ManufacturerMSP" {
		asset, err := s.ReadAsset(ctx, productID)
		if err != nil {
			return "", err
		}

		oldOwner := asset.Owner
		asset.Owner = Owner{OwnerName: newOwnerName, OwnerAddress: newOwnerAddress}
		asset.WithRetailer = true
		asset.WithManufacturer = false
		asset.WithConsumer = false

		assetJSON, err := json.Marshal(asset)
		if err != nil {
			return "", err
		}

		err = ctx.GetStub().PutState(productID, assetJSON)
		if err != nil {
			return "", err
		}

		return "Name: " + oldOwner.OwnerName + " Address: " + oldOwner.OwnerAddress, nil
	} else {
		return "", fmt.Errorf("only Manufacturer can transfer product to retailer")
	}
}

// TransferAssetToConsumer updates the owner field of asset with given id in world state, and returns the old owner.
func (s *SmartContract) TransferAssetToConsumer(ctx contractapi.TransactionContextInterface, productID string) (string, error) {
	clientIdentity := ctx.GetClientIdentity()
	mspId, err := clientIdentity.GetMSPID()
	if err != nil {
		return "", err
	}
	if mspId == "ManufacturerMSP" || mspId == "RetailerMSP" {
		asset, err := s.ReadAsset(ctx, productID)
		if err != nil {
			return "", err
		}

		oldOwner := asset.Owner
		asset.Owner = Owner{OwnerName: "Consumer", OwnerAddress: "Consumer"}
		asset.WithRetailer = false
		asset.WithManufacturer = false
		asset.WithConsumer = true

		assetJSON, err := json.Marshal(asset)
		if err != nil {
			return "", err
		}

		err = ctx.GetStub().PutState(productID, assetJSON)
		if err != nil {
			return "", err
		}

		return "Name: " + oldOwner.OwnerName + " Address: " + oldOwner.OwnerAddress, nil
	} else {
		return "", fmt.Errorf("only Manufacturer and Retailer can transfer product to consumer")
	}
}

// GetAllAssets returns all assets found in world state
func (s *SmartContract) GetAllAssets(ctx contractapi.TransactionContextInterface) ([]*Product, error) {
	// range query with empty string for startKey and endKey does an
	// open-ended query of all assets in the chaincode namespace.
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var assets []*Product
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var asset Product
		err = json.Unmarshal(queryResponse.Value, &asset)
		if err != nil {
			return nil, err
		}
		assets = append(assets, &asset)
	}

	return assets, nil
}
