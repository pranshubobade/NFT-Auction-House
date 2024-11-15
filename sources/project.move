module MyModule::NFTAuction {
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::timestamp;
    use aptos_framework::aptos_coin::AptosCoin;

    /// Error codes
    const E_AUCTION_NOT_ENDED: u64 = 1;
    const E_AUCTION_ENDED: u64 = 2;
    const E_BID_TOO_LOW: u64 = 3;
    const E_NOT_OWNER: u64 = 4;

    /// Struct to store auction information
    struct Auction has key, store {
        nft_creator: address,
        current_bid: u64,
        highest_bidder: address,
        end_time: u64,
        reserve_price: u64,
    }

    /// Create a new auction for an NFT
    public fun create_auction(
        owner: &signer,
        reserve_price: u64,
        duration: u64
    ) {
        let owner_addr = signer::address_of(owner);
        let auction = Auction {
            nft_creator: owner_addr,
            current_bid: 0,
            highest_bidder: @0x0,
            end_time: timestamp::now_seconds() + duration,
            reserve_price,
        };
        move_to(owner, auction);
    }

    /// Place a bid on an active auction
    public fun place_bid(
        bidder: &signer,
        auction_owner: address,
        bid_amount: u64
    ) acquires Auction {
        let auction = borrow_global_mut<Auction>(auction_owner);
        
        // Check auction hasn't ended
        assert!(timestamp::now_seconds() < auction.end_time, E_AUCTION_ENDED);
        // Check bid is higher than current bid and reserve price
        assert!(bid_amount > auction.current_bid && bid_amount >= auction.reserve_price, E_BID_TOO_LOW);

        // Process the bid
        let payment = coin::withdraw<AptosCoin>(bidder, bid_amount);
        
        // Refund previous bidder if exists
        if (auction.highest_bidder != @0x0) {
            coin::deposit(auction.highest_bidder, coin::withdraw<AptosCoin>(bidder, auction.current_bid));
        };

        // Update auction state
        auction.current_bid = bid_amount;
        auction.highest_bidder = signer::address_of(bidder);
        coin::deposit(auction_owner, payment);
    }
}
