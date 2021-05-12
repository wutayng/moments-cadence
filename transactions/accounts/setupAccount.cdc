import FungibleToken from "../../contracts/FungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Moments from "../../contracts/Moments.cdc"
import MomentsMarket from "../../contracts/MomentsMarket.cdc"

// This transaction configures an account to hold Moments and SaleOffer items
// Also configures FUSD Vault

transaction {
    prepare(signer: AuthAccount) {
        // if the account doesn't already have a regular Moment collection
        if signer.borrow<&Moments.Collection>(from: Moments.CollectionStoragePath) == nil {

            // create a new empty collection
            let collection <- Moments.createEmptyCollection()
            
            // save it to the account
            signer.save(<-collection, to: Moments.CollectionStoragePath)

            // create a public capability for the collection
            signer.link<&Moments.Collection{NonFungibleToken.CollectionPublic, Moments.MomentsCollectionPublic}>(Moments.CollectionPublicPath, target: Moments.CollectionStoragePath)
        }

        // if the account doesn't already have a SaleOffer collection
        if signer.borrow<&MomentsMarket.Collection>(from: MomentsMarket.CollectionStoragePath) == nil {

            // create a new empty collection
            let collection <- MomentsMarket.createEmptyCollection() as! @MomentsMarket.Collection
            
            // save it to the account
            signer.save(<-collection, to: MomentsMarket.CollectionStoragePath)

            // create a public capability for the collection
            signer.link<&MomentsMarket.Collection{MomentsMarket.CollectionPublic}>(MomentsMarket.CollectionPublicPath, target: MomentsMarket.CollectionStoragePath)
        }

        // If the account is already set up that's not a problem, but we don't want to replace it
        if signer.borrow<&FUSD.Vault>(from: /storage/fusdVault) == nil {
            // Create a new FUSD Vault and put it in storage
            signer.save(<-FUSD.createEmptyVault(), to: /storage/fusdVault)

            // Create a public capability to the Vault that only exposes
            // the deposit function through the Receiver interface
            signer.link<&FUSD.Vault{FungibleToken.Receiver}>(
            /public/fusdReceiver,
            target: /storage/fusdVault
            )

            // Create a public capability to the Vault that only exposes
            // the balance field through the Balance interface
            signer.link<&FUSD.Vault{FungibleToken.Balance}>(
            /public/fusdBalance,
            target: /storage/fusdVault
            )
        }
    }
}