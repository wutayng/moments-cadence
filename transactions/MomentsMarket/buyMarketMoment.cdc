import FungibleToken from "../../contracts/FungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Moments from "../../contracts/Moments.cdc"
import MomentsMarket from "../../contracts/MomentsMarket.cdc"


// add rake input to send 5% to admin address


transaction(itemID: UInt64, marketCollectionAddress: Address) {
    let paymentVault: @FungibleToken.Vault
    let momentsCollection: &Moments.Collection{NonFungibleToken.Receiver}
    let marketCollection: &MomentsMarket.Collection{MomentsMarket.CollectionPublic}

    prepare(signer: AuthAccount) {
        self.marketCollection = getAccount(marketCollectionAddress)
            .getCapability<&MomentsMarket.Collection{MomentsMarket.CollectionPublic}>(
                MomentsMarket.CollectionPublicPath
            )!
            .borrow()
            ?? panic("Could not borrow market collection from market address")

        let saleItem = self.marketCollection.borrowSaleItem(itemID: itemID)
                    ?? panic("No item with that ID")
        let price = saleItem.price

        let mainFUSDVault = signer.borrow<&FUSD.Vault>(from: /storage/fusdVault)
            ?? panic("Cannot borrow FUSD vault from acct storage")
        self.paymentVault <- mainFUSDVault.withdraw(amount: price)

        self.momentsCollection = signer.borrow<&Moments.Collection{NonFungibleToken.Receiver}>(
            from: Moments.CollectionStoragePath
        ) ?? panic("Cannot borrow Moments collection receiver from acct")
    }

    execute {
        self.marketCollection.purchase(
            itemID: itemID,
            buyerCollection: self.momentsCollection,
            buyerPayment: <- self.paymentVault
        )
    }
}