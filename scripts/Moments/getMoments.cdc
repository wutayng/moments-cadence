import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Moments from "../../contracts/Moments.cdc"

// This script returns an array of all the NFTs in an account's collection.

pub fun main(address: Address): [&Moments.NFT?] {
    let account = getAccount(address)

    let  collectionRef = account.getCapability(Moments.CollectionPublicPath)!.borrow<&{Moments.MomentsCollectionPublic}>()
        ?? panic("Could not borrow capability from moments public collection")

    let momentIDs = collectionRef.getIDs()

    var moments: [&Moments.NFT?] = []

    for moment in momentIDs {
        moments.append(collectionRef.borrowMoment(id: moment))
    }

    return moments
}