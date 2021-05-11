import MomentsMarket from "../../contracts/MomentsMarket.cdc"

transaction(itemID: UInt64) {
    let marketCollection: &MomentsMarket.Collection

    prepare(signer: AuthAccount) {
        self.marketCollection = signer.borrow<&MomentsMarket.Collection>(from: MomentsMarket.CollectionStoragePath)
            ?? panic("Missing or mis-typed MomentsMarket Collection")
    }

    execute {
        let offer <-self.marketCollection.remove(itemID: itemID)
        destroy offer
    }
}