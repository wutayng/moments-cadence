import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Moments from "../../contracts/Moments.cdc"
import MomentsMarket from "../../contracts/MomentsMarket.cdc"

// This script returns an array of all the NFT IDs in an account's for sale market collection.

pub fun main(address: Address): [{String : AnyStruct}] {
    let account = getAccount(address)
    
    let  marketCollectionRef = account.getCapability<&MomentsMarket.Collection{MomentsMarket.CollectionPublic}>(MomentsMarket.CollectionPublicPath).borrow()
        ?? panic("Could not borrow market collection from market address")

    let momentIDs = marketCollectionRef.getSaleOfferIDs()

    var moments: [{String : AnyStruct}] = []

    for moment in momentIDs {
        let saleOffer = marketCollectionRef.borrowSaleItem(itemID: moment)
                    ?? panic("No item with that ID")

        //moments.insert(key: saleOffer.itemID, saleOffer.price)
        moments.append({"itemID": saleOffer.itemID as AnyStruct, "price": saleOffer.price})
    }
    return moments
}