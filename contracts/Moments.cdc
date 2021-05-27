import NonFungibleToken from "./NonFungibleToken.cdc"

// Moments
// Moment NFTs for Creators
// Metadata should contain a IPFS link to off-chain content, etc. picture/video
//
pub contract Moments: NonFungibleToken {

    // Events
    //
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64 from: Address?)
    pub event Deposit(id: UInt64 to: Address?)
    pub event Minted(id: UInt64)

    // Named Paths
    //
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    // totalSupply
    // The total number of Moments that have been minted
    //
    pub var totalSupply: UInt64
    pub var totalMomentIDs: UInt64

    // NFT
    // A Moment as an NFT
    //
    pub resource NFT: NonFungibleToken.INFT {
        // The token's ID
        pub let id: UInt64
        // The token's momentID to identify the moment (multiple NFTs with different serial numbers reference the same moment)
        pub let momentid: UInt64
        // The token's serial number (multiple minting)
        pub let serial: Int
        // The total quantity of serial numbers (multiple minting)
        pub let serialCount: Int
        // The token's metadata as a string  mapping
        // Can be changed (var)
        pub var metadata: {String : String}

        // initializer
        //
        init(initID: UInt64, initmomentID: UInt64, initSerial: Int, totalSerials: Int, initMetadata: {String : String}) {
            self.id = initID
            self.momentid = initmomentID
            self.serial = initSerial
            self.serialCount = totalSerials
            self.metadata = initMetadata
        }
    }

    // This is the interface that users can cast their Moments Collection as
    // to allow others to deposit Moments into their Collection. It also allows for reading
    // the details of Moments in the Collection.
    pub resource interface MomentsCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowMoment(id: UInt64): &Moments.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Moment reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection
    // A collection of Moment NFTs owned by an account
    //
    pub resource Collection: MomentsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        // metadataObjs is a dictionary of metadata mapped to NFT IDs
        //
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // withdraw
        // Removes an NFT from the collection and moves it to the caller
        //
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit
        // Takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        //
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Moments.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs
        // Returns an array of the IDs that are in the collection
        //
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT
        // Gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        //
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        // borrowMoment
        // Gets a reference to an NFT in the collection as a Moment,
        // exposing all of its fields (including the typeID).
        // This is safe as there are no functions that can be called on the Moment.
        //
        pub fun borrowMoment(id: UInt64): &Moments.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &Moments.NFT
            } else {
                return nil
            }
        }

        // destructor
        destroy() {
            destroy self.ownedNFTs
        }

        // initializer
        //
        init () {
            self.ownedNFTs <- {}
        }
    }

    // createEmptyCollection
    // public function that anyone can call to create a new empty collection
    //
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // NFTMinter
    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
    pub resource NFTMinter {

        // mintNFTs
        // Mints multiple new NFTs with the same momentid
        // Increments serial number
        // deposits all in the recipients collection using their collection reference
        //
        pub fun mintNFTs(recipient: &{NonFungibleToken.CollectionPublic}, serialQuantity: Int, metadata: {String : String}) {

            var serialNumber = 1

            while serialNumber <= serialQuantity {
                emit Minted(id: Moments.totalSupply)

                // deposit it in the recipient's account using their reference
                recipient.deposit(token: <-create Moments.NFT(initID: Moments.totalSupply, initmomentID: Moments.totalMomentIDs, initSerial: serialNumber, totalSerials: serialQuantity, initMetadata: metadata))

                serialNumber = serialNumber + 1

                Moments.totalSupply = Moments.totalSupply + (1 as UInt64)
            }

            Moments.totalMomentIDs = Moments.totalMomentIDs + (1 as UInt64)
        }
    }

    // fetch
    // Get a reference to a Moments from an account's Collection, if available.
    // If an account does not have a Moments.Collection, panic.
    // If it has a collection but does not contain the itemID, return nil.
    // If it has a collection and that collection contains the itemID, return a reference to that.
    //
    pub fun fetch(_ from: Address, itemID: UInt64): &Moments.NFT? {
        let collection = getAccount(from)
            .getCapability(Moments.CollectionPublicPath)
            .borrow<&Moments.Collection{Moments.MomentsCollectionPublic}>()
            ?? panic("Couldn't get collection")
        // We trust Moments.Collection.borrowMoment to get the correct itemID
        // (it checks it before returning it).
        return collection.borrowMoment(id: itemID)
    }

    // initializer
    //
    init() {
        // Set our named paths
        self.CollectionStoragePath = /storage/c96ac2e4cab43ad7_momentsCollection
        self.CollectionPublicPath = /public/c96ac2e4cab43ad7_momentsCollection
        self.MinterStoragePath = /storage/c96ac2e4cab43ad7_momentsMinter

        // Initialize the total supply
        self.totalSupply = 0

        // Initialize the Moment IDs
        self.totalMomentIDs = 0

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
    }
}
