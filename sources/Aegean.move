// TODO: Implement withdraw using shares
// TODO: consistency checks
// TODO: For native currency swaps, use the 0x0 address

module Aegean::Amm {
    use std::signer;
    use aptos_framework::table;
    use aptos_framework::coin;

    struct Pool<phantom TokenType1, phantom TokenType2> has key {
        token1: coin::Coin<TokenType1>,
        token2: coin::Coin<TokenType2>,
        k: u64,
        providers: table::Table<address, Provider>,
    }

    public entry fun create_pool<TokenType1, TokenType2>(account: signer)
    acquires Pool {
        let account_addr = signer::address_of(&account);
        if (!exists<Pool<TokenType1, TokenType2>>(account_addr)) {
            move_to(&account, Pool {
                token1: coin::zero<TokenType1>(),
                token2: coin::zero<TokenType2>(),
                k: 0,
                providers: table::new<address, Provider>(),
            })
        } else {
            // Needs to be acquired regardless
            let _ = borrow_global_mut<Pool<TokenType1, TokenType2>>(account_addr);
        }
    }

    struct Provider has key, store, drop, copy {
        amountToken1: u64,
        amountToken2: u64,
    }

    public entry fun provide1<TokenType1, TokenType2>
    (account: signer, poolAccountAddr: address, amountToken1: u64)
    acquires Pool {
        let account_addr = signer::address_of(&account);
        let pool = borrow_global_mut<Pool<TokenType1, TokenType2>>(poolAccountAddr);
        
        let amountToken2 = computeToken2AmountGivenToken1(pool,amountToken1);
        let provider: &mut Provider;
        
        if (table::contains(&pool.providers, account_addr)) {
            provider = table::borrow_mut(&mut pool.providers, account_addr);
            provider.amountToken1 + provider.amountToken1 + amountToken1;
            provider.amountToken2 + provider.amountToken2 + amountToken2;
        } else {
            provider = &mut Provider {
                amountToken1,
                amountToken2,
            };
            table::add(&mut pool.providers, account_addr, *provider);
        };
        
        // The coin is withdrawn from the signer, but added to the pool directly (not the pool owner)
        // This is necessary so that the owner of the account cannot extract the coin through another contract.
        let coin1 = coin::withdraw<TokenType1>(&account, amountToken1);
        coin::merge<TokenType1>(&mut pool.token1, coin1);

        let coin2 = coin::withdraw<TokenType2>(&account, amountToken2);
        coin::merge<TokenType2>(&mut pool.token2, coin2);
    }

    public entry fun swap1<TokenType1: key, TokenType2>(account: signer, poolAccountAddr: address, amountToken1: u64)
    acquires Pool {
        let account_addr = signer::address_of(&account);
        let pool = borrow_global_mut<Pool<TokenType1, TokenType2>>(poolAccountAddr);
        
        let coin1 = coin::withdraw<TokenType1>(&account, amountToken1);
        coin::merge<TokenType1>(&mut pool.token1, coin1);

        let amountToken2 = computeToken2AmountGivenToken1(pool, amountToken1);
        let coin2 = coin::extract<TokenType2>(&mut pool.token2, amountToken2);
        coin::deposit<TokenType2>(account_addr, coin2);
    }

    fun computeToken2AmountGivenToken1<TokenType1, TokenType2>(pool: &Pool<TokenType1, TokenType2>, amount: u64) : u64 {
        let after1 = coin::value<TokenType1>(&pool.token1) + amount;
        let after2 = pool.k / after1;
        let amountToken2 = coin::value<TokenType2>(&pool.token2) - after2;
        amountToken2
    }

    #[test_only]
    use std::string;
    // use Std::Debug;

    #[test_only]
    struct DelphiCoin {}
    #[test_only]
    struct DelphiCoinCapabilities has key {
        mint_cap: coin::MintCapability<DelphiCoin>,
        burn_cap: coin::BurnCapability<DelphiCoin>,
    }

    // #[test_only]
    // public fun delphi_initialize(account: &signer): (coin::MintCapability<Delphicoin>, coin::BurnCapability<Delphicoin>) {
    //     //SystemAddresses::assert_core_resource(core_resource);

    //     let (mint_cap, burn_cap) = coin::initialize<Delphicoin>(
    //         account,
    //         string::utf8(b"Test coin"),
    //         string::utf8(b"TC"),
    //         6, /* decimals */
    //         false, /* monitor_supply */
    //     );

    //     // Mint the core resource account Testcoin for gas so it can execute system transactions.
    //     coin::register_internal<Delphicoin>(account);
    //     let coins = coin::mint<Delphicoin>(
    //         18446744073709551615,
    //         &mint_cap,
    //     );
    //     coin::deposit<Delphicoin>(signer::address_of(account), coins);

    //     move_to(account, DelphicoinCapabilities {
    //         mint_cap: copy mint_cap,
    //         burn_cap: copy burn_cap,
    //         });
    //     (mint_cap, burn_cap)
    // }


    #[test_only]
    struct AlvatarCoin{}
    #[test_only]
    struct AlvatarCoinCapabilities has key {
        mint_cap: coin::MintCapability<AlvatarCoin>,
        burn_cap: coin::BurnCapability<AlvatarCoin>,
    }

    #[test(account = @0x1)]
    public entry fun computes_amount_correctly(account: signer) {
        let pool = Pool{
            token1: coin::zero<DelphiCoin>(),
            token2: coin::zero<AlvatarCoin>(),
            k: 1000 * 500,
            providers: table::new<address, Provider>(),
        };

        let (mint_cap1, burn_cap1) = coin::initialize<DelphiCoin>(
            &account,
            string::utf8(b"Test coin"),
            string::utf8(b"TC"),
            6, /* decimals */
            false, /* monitor_supply */
        );

        // coin::register<Delphicoin>(&account);
        //let coins_minted1 = coin::mint<Delphicoin>(3000, &mint_cap1);
        //coin::deposit<Delphicoin>(signer::address_of(&coin_creator), coins_minted1);

        // let (mint_cap2, burn_cap2) = coin::initialize<Alvatarcoin>(
        //     &coin_creator,
        //     ASCII::string(b"Alvatarcoin"),
        //     ASCII::string(b"ACC"),
        //     1,
        //     false,
        // );
        // coin::register<Alvatarcoin>(&coin_creator);
        // let coins_minted1 = coin::mint<Alvatarcoin>(3000, &mint_cap2);
        // coin::deposit<Alvatarcoin>(signer::address_of(&coin_creator), coins_minted1);
        
        // // Debug::print(&pool);
        // assert!(
        //     computeToken2AmountGivenToken1(&pool, 30) == 15u64,
        //     0,
        // );
        move_to(&account, pool);
        move_to(&account, DelphiCoinCapabilities {
            mint_cap: mint_cap1,
            burn_cap: burn_cap1,
        });
        // move_to(&account, AlvatarcoinCapabilities {
        //     mint_cap: mint_cap2,
        //     burn_cap: burn_cap2,
        // });
    }
}
