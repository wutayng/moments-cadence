import FungibleToken from "../../contracts/FungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"

pub fun main(addr: Address): UFix64 {

    let account = getAccount(addr)

    let vaultRef = account
    .getCapability(/public/fusdBalance)!
    .borrow<&FUSD.Vault{FungibleToken.Balance}>()
    ?? panic("Could not borrow Balance capability")

    return vaultRef.balance
}