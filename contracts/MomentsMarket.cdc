import FUSD from "./FUSD.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"
import Moments from "./Moments.cdc"
import FungibleToken from "./FungibleToken.cdc"

/*
    This is a Moments initial sale contract for the DApp to use
    in order to list and sell Moments. It includes a rake for sales.

    Derived from the KittyItems sample DApp smart contracts

    "
    Its structure is neither what it would be if it was the simplest possible
    market contract or if it was a complete general purpose market contract.
    Rather it's the simplest possible version of a more general purpose
    market contract that indicates how that contract might function in
    broad strokes. This has been done so that integrating with this contract
    is a useful preparatory exercise for code that will integrate with the
    later more general purpose market contract.

    It allows:
    - Anyone to create Sale Offers and place them in a collection, making it
      publicly accessible.
    - Anyone to accept the offer and buy the item.

    It notably does not handle:
    - Multiple different sale NFT contracts.
    - Multiple different payment FT contracts.
    - Splitting sale payments to multiple recipients.
    "
 */

pub contract MomentsMarket {
    // SaleOffer events.
    //
    // A sale offer has been created.
    pub event SaleOfferCreated(itemID: UInt64, price: UFix64, rake: UFix64)
    // Someone has purchased an item that was offered for sale.
    pub event SaleOfferAccepted(itemID: UInt64)
    // A sale offer has been destroyed, with or without being accepted.
    pub event SaleOfferFinished(itemID: UInt64)
    
    // Collection events.
    //
    // A sale offer has been removed from the collection of Address.
    pub event CollectionRemovedSaleOffer(itemID: UInt64, owner: Address)

    // A sale offer has been inserted into the collection of Address.
    pub event CollectionInsertedSaleOffer(
      itemID: UInt64, 
      owner: Address, 
      price: UFix64
    )

    // Named paths
    //
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    // SaleOfferPublicView
    // An interface providing a read-only view of a SaleOffer
    //
    pub resource interface SaleOfferPublicView {
        pub let itemID: UInt64
        pub let price: UFix64
    }

    // SaleOffer
    // A Moments NFT being offered to sale for a set fee paid in FUSD.
    //
    pub resource SaleOffer: SaleOfferPublicView {
        // Whether the sale has completed with someone purchasing the item.
        pub var saleCompleted: Bool

        // The Moments NFT ID for sale.
        pub let itemID: UInt64

        // The sale payment price.
        pub let price: UFix64

        // The sale rake.
        pub let rake: UFix64

        // The collection containing that ID.
        access(self) let sellerItemProvider: Capability<&Moments.Collection{NonFungibleToken.Provider}>

        // The FUSD vault that will receive rake payment if the sale completes successfully.
        access(self) let rakePaymentReceiver: Capability<&FUSD.Vault{FungibleToken.Receiver}>

        // The FUSD vault that will receive that payment if the sale completes successfully.
        access(self) let sellerPaymentReceiver: Capability<&FUSD.Vault{FungibleToken.Receiver}>

        // Called by a purchaser to accept the sale offer.
        // If they send the correct payment in FUSD, and if the item is still available,
        // the Moments NFT will be placed in their Moments.Collection .
        //
        pub fun accept(
            buyerCollection: &Moments.Collection{NonFungibleToken.Receiver},
            buyerPayment: @FungibleToken.Vault,
        ) {
            pre {
                buyerPayment.balance == self.price: "payment does not equal offer price"
                self.saleCompleted == false: "the sale offer has already been accepted"
            }

            self.saleCompleted = true

            let rakeWallet <- buyerPayment.withdraw(amount: self.price * self.rake)

            // Deposit rake into the rake vault
            self.rakePaymentReceiver.borrow()!.deposit(from: <-rakeWallet)

            // Deposit remaining into the receiver vault
            self.sellerPaymentReceiver.borrow()!.deposit(from: <-buyerPayment)

            let nft <- self.sellerItemProvider.borrow()!.withdraw(withdrawID: self.itemID)
            buyerCollection.deposit(token: <-nft)

            emit SaleOfferAccepted(itemID: self.itemID)
        }

        // destructor
        //
        destroy() {
            // Whether the sale completed or not, publicize that it is being withdrawn.
            emit SaleOfferFinished(itemID: self.itemID)
        }

        // initializer
        // Take the information required to create a sale offer, notably the capability
        // to transfer the Moments NFT and the capability to receive FUSD in payment.
        //
        init(
            sellerItemProvider: Capability<&Moments.Collection{NonFungibleToken.Provider}>,
            itemID: UInt64,
            sellerPaymentReceiver: Capability<&FUSD.Vault{FungibleToken.Receiver}>,
            rakePaymentReceiver: Capability<&FUSD.Vault{FungibleToken.Receiver}>,
            price: UFix64,
            rake: UFix64
        ) {
            pre {
                sellerItemProvider.borrow() != nil: "Cannot borrow seller"
                sellerPaymentReceiver.borrow() != nil: "Cannot borrow sellerPaymentReceiver"
                rakePaymentReceiver.borrow() != nil: "Cannot borrow rakePaymentReceiver"
            }

            self.saleCompleted = false

            self.sellerItemProvider = sellerItemProvider
            self.itemID = itemID
            self.sellerPaymentReceiver = sellerPaymentReceiver
            self.rakePaymentReceiver = rakePaymentReceiver
            self.price = price
            self.rake = rake

            emit SaleOfferCreated(itemID: self.itemID, price: self.price, rake: self.rake)
        }
    }

    // createSaleOffer
    // Make creating a SaleOffer publicly accessible.
    //
    pub fun createSaleOffer (
        sellerItemProvider: Capability<&Moments.Collection{NonFungibleToken.Provider}>,
        itemID: UInt64,
        sellerPaymentReceiver: Capability<&FUSD.Vault{FungibleToken.Receiver}>,
        rakePaymentReceiver: Capability<&FUSD.Vault{FungibleToken.Receiver}>,
        price: UFix64,
        rake: UFix64
    ): @SaleOffer {
        return <-create SaleOffer(
            sellerItemProvider: sellerItemProvider,
            itemID: itemID,
            sellerPaymentReceiver: sellerPaymentReceiver,
            rakePaymentReceiver: rakePaymentReceiver,
            price: price,
            rake: rake
        )
    }

    // CollectionManager
    // An interface for adding and removing SaleOffers to a collection, intended for
    // use by the collection's owner.
    //
    pub resource interface CollectionManager {
        pub fun insert(offer: @MomentsMarket.SaleOffer)
        pub fun remove(itemID: UInt64): @SaleOffer 
    }

        // CollectionPurchaser
    // An interface to allow purchasing items via SaleOffers in a collection.
    // This function is also provided by CollectionPublic, it is here to support
    // more fine-grained access to the collection for as yet unspecified future use cases.
    //
    pub resource interface CollectionPurchaser {
        pub fun purchase(
            itemID: UInt64,
            buyerCollection: &Moments.Collection{NonFungibleToken.Receiver},
            buyerPayment: @FungibleToken.Vault
        )
    }

    // CollectionPublic
    // An interface to allow listing and borrowing SaleOffers, and purchasing items via SaleOffers in a collection.
    //
    pub resource interface CollectionPublic {
        pub fun getSaleOfferIDs(): [UInt64]
        pub fun borrowSaleItem(itemID: UInt64): &SaleOffer{SaleOfferPublicView}?
        pub fun purchase(
            itemID: UInt64,
            buyerCollection: &Moments.Collection{NonFungibleToken.Receiver},
            buyerPayment: @FungibleToken.Vault
        )
   }

    // Collection
    // A resource that allows its owner to manage a list of SaleOffers, and purchasers to interact with them.
    //
    pub resource Collection : CollectionManager, CollectionPurchaser, CollectionPublic {
        pub var saleOffers: @{UInt64: SaleOffer}

        // insert
        // Insert a SaleOffer into the collection, replacing one with the same itemID if present.
        //
         pub fun insert(offer: @MomentsMarket.SaleOffer) {
            let itemID: UInt64 = offer.itemID
            let price: UFix64 = offer.price

            // add the new offer to the dictionary which removes the old one
            let oldOffer <- self.saleOffers[itemID] <- offer
            destroy oldOffer

            emit CollectionInsertedSaleOffer(
              itemID: itemID,
              owner: self.owner?.address!,
              price: price
            )
        }

        // remove
        // Remove and return a SaleOffer from the collection.
        pub fun remove(itemID: UInt64): @SaleOffer {
            emit CollectionRemovedSaleOffer(itemID: itemID, owner: self.owner?.address!)
            return <-(self.saleOffers.remove(key: itemID) ?? panic("missing SaleOffer"))
        }
 
        // purchase
        // If the caller passes a valid itemID and the item is still for sale, and passes a FUSD vault
        // typed as a FungibleToken.Vault (FUSD.deposit() handles the type safety of this)
        // containing the correct payment amount, this will transfer the Moment to the caller's
        // Moments collection.
        // It will then remove and destroy the offer.
        // Note that is means that events will be emitted in this order:
        //   1. Collection.CollectionRemovedSaleOffer
        //   2. Moments.Withdraw
        //   3. Moments.Deposit
        //   4. SaleOffer.SaleOfferFinished
        //
        pub fun purchase(
            itemID: UInt64,
            buyerCollection: &Moments.Collection{NonFungibleToken.Receiver},
            buyerPayment: @FungibleToken.Vault
        ) {
            pre {
                self.saleOffers[itemID] != nil: "SaleOffer does not exist in the collection!"
            }
            let offer <- self.remove(itemID: itemID)
            offer.accept(buyerCollection: buyerCollection, buyerPayment: <-buyerPayment)
            //FIXME: Is this correct? Or should we return it to the caller to dispose of?
            destroy offer
        }

        // getSaleOfferIDs
        // Returns an array of the IDs that are in the collection
        //
        pub fun getSaleOfferIDs(): [UInt64] {
            return self.saleOffers.keys
        }

        // borrowSaleItem
        // Returns an Optional read-only view of the SaleItem for the given itemID if it is contained by this collection.
        // The optional will be nil if the provided itemID is not present in the collection.
        //
        pub fun borrowSaleItem(itemID: UInt64): &SaleOffer{SaleOfferPublicView}? {
            if self.saleOffers[itemID] == nil {
                return nil
            } else {
                return &self.saleOffers[itemID] as &SaleOffer{SaleOfferPublicView}
            }
        }

        // destructor
        //
        destroy () {
            destroy self.saleOffers
        }

        // constructor
        //
        init () {
            self.saleOffers <- {}
        }
    }

    // createEmptyCollection
    // Make creating a Collection publicly accessible.
    //
    pub fun createEmptyCollection(): @Collection {
        return <-create Collection()
    }

    init () {
        self.CollectionStoragePath = /storage/c96ac2e4cab43ad7_momentsMarketCollection
        self.CollectionPublicPath = /public/c96ac2e4cab43ad7_momentsMarketCollection
    }
}