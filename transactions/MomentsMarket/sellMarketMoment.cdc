import FungibleToken from "../../contracts/FungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Moments from "../../contracts/Moments.cdc"
import MomentsMarket from "../../contracts/MomentsMarket.cdc"

transaction(itemID: UInt64, price: UFix64, rakeAddress: Address, rake: UFix64) {
    let FUSDVault: Capability<&FUSD.Vault{FungibleToken.Receiver}>
    let FUSDRakeVault: Capability<&FUSD.Vault{FungibleToken.Receiver}>
    let MomentsCollection: Capability<&Moments.Collection{NonFungibleToken.Provider, Moments.MomentsCollectionPublic}>
    let MarketCollection: &MomentsMarket.Collection

    prepare(signer: AuthAccount) {
        // we need a provider capability, but one is not provided by default so we create one.
        let MomentsCollectionProviderPrivatePath = /private/MomentsCollectionProvider

        self.FUSDVault = signer.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)!
        assert(self.FUSDVault.borrow() != nil, message: "Missing or mis-typed FUSD receiver")

        let rakeAccount = getAccount(rakeAddress)
        self.FUSDRakeVault = rakeAccount.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)!
        assert(self.FUSDRakeVault.borrow() != nil, message: "Missing or mis-typed FUSD Rake receiver")

        if !signer.getCapability<&Moments.Collection{NonFungibleToken.Provider, Moments.MomentsCollectionPublic}>(MomentsCollectionProviderPrivatePath)!.check() {
            signer.link<&Moments.Collection{NonFungibleToken.Provider, Moments.MomentsCollectionPublic}>(MomentsCollectionProviderPrivatePath, target: Moments.CollectionStoragePath)
        }

        self.MomentsCollection = signer.getCapability<&Moments.Collection{NonFungibleToken.Provider, Moments.MomentsCollectionPublic}>(MomentsCollectionProviderPrivatePath)!
        assert(self.MomentsCollection.borrow() != nil, message: "Missing or mis-typed MomentsCollection provider")

        // check that NFT exists in MomentsCollection
        // borrow a reference to the signer's NFT collection
        let collectionRef = signer.borrow<&Moments.Collection>(from: Moments.CollectionStoragePath)
            ?? panic("Could not borrow a reference to the owner's collection")

        // borrow NFT from the owner's collection
        assert(collectionRef.borrowNFT(id: itemID) != nil, message: "Missing NFT ID from Collection")

        self.MarketCollection = signer.borrow<&MomentsMarket.Collection>(from: MomentsMarket.CollectionStoragePath)
            ?? panic("Missing or mis-typed MomentsMarket Collection")
    }

    execute {
        let offer <- MomentsMarket.createSaleOffer (
            sellerItemProvider: self.MomentsCollection,
            itemID: itemID,
            sellerPaymentReceiver: self.FUSDVault,
            rakePaymentReceiver: self.FUSDRakeVault,
            price: price,
            rake: rake
        )
        self.MarketCollection.insert(offer: <-offer)
    }
}