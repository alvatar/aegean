// TODO: Move from numbers to coins
// TODO: Implement withdraw using shares
// TODO: consistency checks

module Aegean::Amm {
    use Std::Signer;
    use AptosFramework::Table;

    struct Pool has key {
        amountToken1: u64,
        amountToken2: u64,
        k: u64,
        providers: Table::Table<address, Provider>,
    }

    public(script) fun create_pool(account: signer)
    acquires Pool {
        let account_addr = Signer::address_of(&account);
        if (!exists<Pool>(account_addr)) {
            move_to(&account, Pool {
                amountToken1: 0,
                amountToken2: 0,
                k: 0,
                providers: Table::new<address, Provider>(),
            })
        } else {
            // Needs to be acquired regardless
            let _ = borrow_global_mut<Pool>(account_addr);
        }
    }

    struct Provider has key, store, drop, copy {
        amountToken1: u64,
        amountToken2: u64,
    }

    public(script) fun provide_given_token1_amount(poolAccountAddr: address, account: signer, amountToken1: u64)
    acquires Pool {
        let pool = borrow_global_mut<Pool>(poolAccountAddr);
        let account_addr = Signer::address_of(&account);
        
        // TODO: taken tokens from account, for now it's just numbers
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
        };
        
        pool.amountToken1 = pool.amountToken1 + amountToken1;
        pool.amountToken2 = pool.amountToken2 + amountToken2;

        Table::add(&mut pool.providers, account_addr, *provider);
    }

    public(script) fun swap1(poolAccountAddr: address, amountToken1: u64)
    acquires Pool {
        let pool = borrow_global_mut<Pool>(poolAccountAddr);
        let amountToken2 = computeToken2AmountGivenToken1(pool, amountToken1);
        
    }

    fun computeToken2AmountGivenToken1(pool: &Pool, amountToken1: u64) : u64 {
        let after1 = pool.amountToken1 + amountToken1;
        let after2 = pool.k / after1;
        let amountToken2 = pool.amountToken2 - after2;
        amountToken2
    }

    // #[test_only]
    // use Std::Debug;

    #[test(account = @0x1)]
    public(script) fun computes_amount_correctly(account: signer) {
        let pool = Pool{
            amountToken1: 1000,
            amountToken2: 500,
            k: 1000 * 500,
            providers: Table::new<address, Provider>(),
        };
        // Debug::print(&pool);
        assert!(
            computeToken2AmountGivenToken1(&pool, 30) == 15u64,
            0,
        );
        move_to(&account, pool)
    }
}
