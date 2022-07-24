// TODO: Implement withdraw using shares
// TODO: consistency checks
// TODO: For native currency swaps, use the 0x0 address

module Aegean::Amm {
    use Std::Signer;
    use AptosFramework::Table;
    use AptosFramework::Coin;

    struct Pool<phantom TokenType1, phantom TokenType2> has key {
        token1: Coin::Coin<TokenType1>,
        token2: Coin::Coin<TokenType2>,
        k: u64,
        providers: Table::Table<address, Provider>,
    }

    public(script) fun create_pool<TokenType1, TokenType2>(account: signer)
    acquires Pool {
        let account_addr = Signer::address_of(&account);
        if (!exists<Pool<TokenType1, TokenType2>>(account_addr)) {
            move_to(&account, Pool {
                token1: Coin::zero<TokenType1>(),
                token2: Coin::zero<TokenType2>(),
                k: 0,
                providers: Table::new<address, Provider>(),
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

    public(script) fun provide1<TokenType1, TokenType2>
    (account: signer, poolAccountAddr: address, amountToken1: u64)
    acquires Pool {
        let account_addr = Signer::address_of(&account);
        let pool = borrow_global_mut<Pool<TokenType1, TokenType2>>(poolAccountAddr);
        
        let amountToken2 = computeToken2AmountGivenToken1(pool,amountToken1);
        let provider: &mut Provider;
        
        if (Table::contains(&pool.providers, account_addr)) {
            provider = Table::borrow_mut(&mut pool.providers, account_addr);
            provider.amountToken1 + provider.amountToken1 + amountToken1;
            provider.amountToken2 + provider.amountToken2 + amountToken2;
        } else {
            provider = &mut Provider {
                amountToken1,
                amountToken2,
            };
            Table::add(&mut pool.providers, account_addr, *provider);
        };
        
        // The coin is withdrawn from the signer, but added to the pool directly (not the pool owner)
        // This is necessary so that the owner of the account cannot extract the coin through another contract.
        let coin1 = Coin::withdraw<TokenType1>(&account, amountToken1);
        Coin::merge<TokenType1>(&mut pool.token1, coin1);

        let coin2 = Coin::withdraw<TokenType2>(&account, amountToken2);
        Coin::merge<TokenType2>(&mut pool.token2, coin2);
    }

    public(script) fun swap1<TokenType1: key, TokenType2>(account: signer, poolAccountAddr: address, amountToken1: u64)
    acquires Pool {
        let account_addr = Signer::address_of(&account);
        let pool = borrow_global_mut<Pool<TokenType1, TokenType2>>(poolAccountAddr);
        
        let coin1 = Coin::withdraw<TokenType1>(&account, amountToken1);
        Coin::merge<TokenType1>(&mut pool.token1, coin1);

        let amountToken2 = computeToken2AmountGivenToken1(pool, amountToken1);
        let coin2 = Coin::extract<TokenType2>(&mut pool.token2, amountToken2);
        Coin::deposit<TokenType2>(account_addr, coin2);
    }

    fun computeToken2AmountGivenToken1<TokenType1, TokenType2>(pool: &Pool<TokenType1, TokenType2>, amount: u64) : u64 {
        let after1 = Coin::value<TokenType1>(&pool.token1) + amount;
        let after2 = pool.k / after1;
        let amountToken2 = Coin::value<TokenType2>(&pool.token2) - after2;
        amountToken2
    }

    #[test_only]
    use Std::ASCII;
    // use Std::Debug;

    #[test_only]
    struct DelphiCoin {}
    #[test_only]
    struct DelphiCoinCapabilities has key {
        mint_cap: Coin::MintCapability<DelphiCoin>,
        burn_cap: Coin::BurnCapability<DelphiCoin>,
    }
    #[test_only]
    public fun delphi_initialize(account: &signer): (Coin::MintCapability<DelphiCoin>, Coin::BurnCapability<DelphiCoin>) {
        //SystemAddresses::assert_core_resource(core_resource);

        let (mint_cap, burn_cap) = Coin::initialize<DelphiCoin>(
            account,
            ASCII::string(b"Test Coin"),
            ASCII::string(b"TC"),
            6, /* decimals */
            false, /* monitor_supply */
        );

        // Mint the core resource account TestCoin for gas so it can execute system transactions.
        Coin::register_internal<DelphiCoin>(account);
        let coins = Coin::mint<DelphiCoin>(
            18446744073709551615,
            &mint_cap,
        );
        Coin::deposit<DelphiCoin>(Signer::address_of(account), coins);

        move_to(account, DelphiCoinCapabilities {
            mint_cap: copy mint_cap,
            burn_cap: copy burn_cap,
            });
        (mint_cap, burn_cap)
    }


    #[test_only]
    struct AlvatarCoin{}
    #[test_only]
    struct AlvatarCoinCapabilities has key {
        mint_cap: Coin::MintCapability<AlvatarCoin>,
        burn_cap: Coin::BurnCapability<AlvatarCoin>,
    }

    #[test(account = @0x1)]
    public(script) fun computes_amount_correctly(account: signer) {
        let pool = Pool{
            token1: Coin::zero<DelphiCoin>(),
            token2: Coin::zero<AlvatarCoin>(),
            k: 1000 * 500,
            providers: Table::new<address, Provider>(),
        };
        // let (mint_cap1, burn_cap1) = delphi_initialize(
        //     &account,
        //             );

        // Coin::register<DelphiCoin>(&account);
        //let coins_minted1 = Coin::mint<DelphiCoin>(3000, &mint_cap1);
        //Coin::deposit<DelphiCoin>(Signer::address_of(&coin_creator), coins_minted1);

        // let (mint_cap2, burn_cap2) = Coin::initialize<AlvatarCoin>(
        //     &coin_creator,
        //     ASCII::string(b"AlvatarCoin"),
        //     ASCII::string(b"ACC"),
        //     1,
        //     false,
        // );
        // Coin::register<AlvatarCoin>(&coin_creator);
        // let coins_minted1 = Coin::mint<AlvatarCoin>(3000, &mint_cap2);
        // Coin::deposit<AlvatarCoin>(Signer::address_of(&coin_creator), coins_minted1);
        
        // // Debug::print(&pool);
        // assert!(
        //     computeToken2AmountGivenToken1(&pool, 30) == 15u64,
        //     0,
        // );
        move_to(&account, pool);
        // move_to(&account, DelphiCoinCapabilities {
        //     mint_cap: mint_cap1,
        //     burn_cap: burn_cap1,
        // });
        // move_to(&account, AlvatarCoinCapabilities {
        //     mint_cap: mint_cap2,
        //     burn_cap: burn_cap2,
        // });
    }
}
