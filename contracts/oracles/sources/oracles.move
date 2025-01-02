module oracles::oracles {
    use sui::clock::{Self, Clock};
    use sui::object::{Self};
    use sui::bag::{Self, Bag};
    use std::type_name::{Self, TypeName};
    use pyth::price_identifier::{PriceIdentifier, Self};
    use pyth::price_info::{PriceInfoObject};
    use oracles::version::{Version, Self};
    use pyth::price::{Self, Price};
    use oracles::pyth::{get_prices};
    use pyth::i64::{I64};

    /* Constants */
    const CURRENT_VERSION: u16 = 1;

    /* Errors */
    const EInvalidAdminCap: u64 = 0;
    const EWrongCoinType: u64 = 1;
    const EInvalidOracleType: u64 = 2;

    public struct OracleRegistry has key, store {
        id: UID,
        config: OracleRegistryConfig,
        oracles: vector<Oracle>,
        version: Version,
        extra_fields: Bag
    }

    public struct AdminCap has key, store {
        id: UID,
        oracle_registry_id: ID
    }

    public struct OracleRegistryConfig has store {
        pyth_max_staleness_threshold_s: u64,
        pyth_max_confidence_interval_pct: u64,

        switchboard_max_staleness_threshold_s: u64,
        switchboard_max_confidence_interval_pct: u64,

        extra_fields: Bag
    }

    public struct Oracle has store {
        type_name: TypeName,
        oracle_type: OracleType,
        extra_fields: Bag
    }

    public enum OracleType has store, drop, copy {
        Pyth {
            price_identifier: PriceIdentifier,
        },
        Switchboard {
            feed_id: ID,
        }
    }

    // hot potato ensures that price is fresh
    public struct OraclePriceUpdate<phantom CoinType> has drop {
        oracle_registry_id: ID,

        base: I64,
        expo: I64,
    }

    // TODO: do we want people to have the ability to create new registries? or should we just have a global one. 
    public fun new_oracle_registry(config: OracleRegistryConfig, ctx: &mut TxContext): (OracleRegistry, AdminCap) {
        let registry = OracleRegistry {
            id: object::new(ctx),
            config,
            oracles: vector::empty(),
            version: version::new(CURRENT_VERSION),
            extra_fields: bag::new(ctx)
        };

        let admin_cap = AdminCap {
            id: object::new(ctx),
            oracle_registry_id: object::id(&registry)
        };

        (registry, admin_cap)
    }

    public fun new_oracle_registry_config(
        pyth_max_staleness_threshold_s: u64,
        pyth_max_confidence_interval_pct: u64,
        switchboard_max_staleness_threshold_s: u64,
        switchboard_max_confidence_interval_pct: u64,
        ctx: &mut TxContext
    ): OracleRegistryConfig {
        OracleRegistryConfig {
            pyth_max_staleness_threshold_s,
            pyth_max_confidence_interval_pct,
            switchboard_max_staleness_threshold_s,
            switchboard_max_confidence_interval_pct,
            extra_fields: bag::new(ctx)
        }
    }

    /// Set a pyth oracle for CoinType
    public fun set_pyth_oracle<CoinType>(
        registry: &mut OracleRegistry,
        admin_cap: &AdminCap,
        price_info_obj: &PriceInfoObject,
        ctx: &mut TxContext
    ) {
        registry.version.assert_version_and_upgrade(CURRENT_VERSION);

        set_oracle<CoinType>(
            registry, 
            admin_cap, 
            OracleType::Pyth { 
                price_identifier: price_info_obj.get_price_info_from_price_info_object().get_price_identifier()
            }, 
            ctx
        );
    }

    public fun get_pyth_price<CoinType>(
        registry: &OracleRegistry,
        price_info_obj: &PriceInfoObject,
        oracle_index: u64,
        clock: &Clock,
    ): OraclePriceUpdate<CoinType> {
        registry.version.assert_version(CURRENT_VERSION);

        let oracle = &registry.oracles[oracle_index];
        assert!(oracle.type_name == type_name::get<CoinType>(), EWrongCoinType);

        match (oracle.oracle_type) {
            OracleType::Pyth { price_identifier } => {
                let (price, _) = get_prices(
                    price_info_obj, 
                    clock, 
                    registry.config.pyth_max_staleness_threshold_s, 
                    registry.config.pyth_max_confidence_interval_pct,
                    price_identifier
                );

                OraclePriceUpdate<CoinType> {
                    oracle_registry_id: object::id(registry),
                    base: price.get_price(),
                    expo: price.get_expo(),
                }
            },
            _ => abort EInvalidOracleType
        }

    }

    /* Public Getters */
    public fun base<CoinType>(price: &OraclePriceUpdate<CoinType>): I64 {
        price.base
    }

    public fun expo<CoinType>(price: &OraclePriceUpdate<CoinType>): I64 {
        price.expo
    }

    /* Private Functions */
    fun set_oracle<CoinType>(
        registry: &mut OracleRegistry,
        admin_cap: &AdminCap,
        oracle_type: OracleType,
        ctx: &mut TxContext
    ) {
        registry.version.assert_version_and_upgrade(CURRENT_VERSION);

        assert!(admin_cap.oracle_registry_id == object::id(registry), EInvalidAdminCap);

        let mut index = registry.oracles.find_index!(|oracle| oracle.type_name == type_name::get<CoinType>());
        if (index.is_some()) {
            registry.oracles[index.extract()].oracle_type = oracle_type;
        } else {
            let oracle = Oracle {
                type_name: type_name::get<CoinType>(),
                oracle_type,
                extra_fields: bag::new(ctx)
            };

            registry.oracles.push_back(oracle);
        };
    }

}

