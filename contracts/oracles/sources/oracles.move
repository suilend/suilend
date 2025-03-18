module oracles::oracles {
    use sui::event;
    use sui::clock::Clock;
    use sui::bag::{Self, Bag};
    use pyth::price_identifier::PriceIdentifier;
    use pyth::price_info::{PriceInfoObject};
    use pyth::price_feed::{PriceFeed};
    use oracles::version::{Version, Self};
    use oracles::pyth;
    use switchboard::aggregator::{Aggregator, CurrentResult};
    use oracles::switchboard;
    use oracles::oracle_decimal::OracleDecimal;

    /* Constants */
    const CURRENT_VERSION: u16 = 1;

    /* Errors */
    const EInvalidAdminCap: u64 = 0;
    const EInvalidOracleType: u64 = 1;

    public struct OracleRegistry has key, store {
        id: UID,
        config: OracleRegistryConfig,
        oracles: vector<Oracle>,
        version: Version,
        extra_fields: Bag
    }

    public struct NewRegistryEvent has copy, store, drop {
        registry_id: ID,
        admin_cap_id: ID,
        pyth_max_staleness_threshold_s: u64,
        pyth_max_confidence_interval_pct: u64,
        switchboard_max_staleness_threshold_s: u64,
        switchboard_max_confidence_interval_pct: u64,
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
    public struct OraclePriceUpdate has drop {
        oracle_registry_id: ID,
        oracle_index: u64,
        price: OracleDecimal,
        ema_price: Option<OracleDecimal>,
        metadata: OracleMetadata,
    }

    public enum OracleMetadata has store, drop, copy {
        Pyth {
            price_feed: PriceFeed,
        },
        Switchboard {
            current_result: CurrentResult,
        }
    }

    // == Public Getters ==
    public fun price(price_update: &OraclePriceUpdate): OracleDecimal {
        price_update.price
    }

    public fun ema_price(price_update: &OraclePriceUpdate): Option<OracleDecimal> {
        price_update.ema_price
    }

    public fun oracle_registry_id(price_update: &OraclePriceUpdate): ID {
        price_update.oracle_registry_id
    }

    public fun oracle_index(price_update: &OraclePriceUpdate): u64 {
        price_update.oracle_index
    }

    public fun metadata(price_update: &OraclePriceUpdate): OracleMetadata {
        price_update.metadata
    }

    public use fun metadata_pyth as OracleMetadata.pyth;

    public fun metadata_pyth(oracle_metadata: &OracleMetadata): &PriceFeed {
        match (oracle_metadata) {
            OracleMetadata::Pyth { price_feed } => price_feed,
            _ => abort EInvalidOracleType
        }
    }

    public use fun metadata_switchboard as OracleMetadata.switchboard;

    public fun metadata_switchboard(oracle_metadata: &OracleMetadata): &CurrentResult {
        match (oracle_metadata) {
            OracleMetadata::Switchboard { current_result } => current_result,
            _ => abort EInvalidOracleType
        }
    }

    public fun new(
        config: OracleRegistryConfig,
        ctx: &mut TxContext
    ): (OracleRegistry, AdminCap) {
        let registry = OracleRegistry {
            id: object::new(ctx),
            config: config,
            oracles: vector::empty(),
            version: version::new(CURRENT_VERSION),
            extra_fields: bag::new(ctx)
        };

        let admin_cap = AdminCap {
            id: object::new(ctx),
            oracle_registry_id: object::id(&registry)
        };

        event::emit(NewRegistryEvent {
            registry_id: object::id(&registry),
            admin_cap_id: object::id(&admin_cap),
            pyth_max_staleness_threshold_s: registry.config.pyth_max_staleness_threshold_s,
            pyth_max_confidence_interval_pct: registry.config.pyth_max_confidence_interval_pct,
            switchboard_max_staleness_threshold_s: registry.config.switchboard_max_staleness_threshold_s,
            switchboard_max_confidence_interval_pct: registry.config.switchboard_max_confidence_interval_pct,
        });

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

    public fun add_pyth_oracle(
        registry: &mut OracleRegistry,
        admin_cap: &AdminCap,
        price_info_obj: &PriceInfoObject,
        ctx: &mut TxContext
    ) {
        registry.version.assert_version_and_upgrade(CURRENT_VERSION);
        assert!(admin_cap.oracle_registry_id == object::id(registry), EInvalidAdminCap);

        registry.oracles.push_back(Oracle {
            oracle_type: OracleType::Pyth { 
                price_identifier: price_info_obj.get_price_info_from_price_info_object().get_price_identifier() 
            },
            extra_fields: bag::new(ctx)
        });
    }

    public fun set_pyth_oracle(
        registry: &mut OracleRegistry,
        admin_cap: &AdminCap,
        price_info_obj: &PriceInfoObject,
        oracle_index: u64
    ) {
        registry.version.assert_version_and_upgrade(CURRENT_VERSION);
        assert!(admin_cap.oracle_registry_id == object::id(registry), EInvalidAdminCap);

        registry.oracles[oracle_index].oracle_type = OracleType::Pyth { 
            price_identifier: price_info_obj.get_price_info_from_price_info_object().get_price_identifier() 
        };
    }

    public fun add_switchboard_oracle(
        registry: &mut OracleRegistry,
        admin_cap: &AdminCap,
        aggregator: &Aggregator,
        ctx: &mut TxContext
    ) {
        registry.version.assert_version_and_upgrade(CURRENT_VERSION);
        assert!(admin_cap.oracle_registry_id == object::id(registry), EInvalidAdminCap);

        registry.oracles.push_back(Oracle {
            oracle_type: OracleType::Switchboard { feed_id: aggregator.id() },
            extra_fields: bag::new(ctx)
        });
    }

    public fun set_switchboard_oracle(
        registry: &mut OracleRegistry,
        admin_cap: &AdminCap,
        aggregator: &Aggregator,
        oracle_index: u64
    ) {
        registry.version.assert_version_and_upgrade(CURRENT_VERSION);
        assert!(admin_cap.oracle_registry_id == object::id(registry), EInvalidAdminCap);

        registry.oracles[oracle_index].oracle_type = OracleType::Switchboard { feed_id: aggregator.id() };
    }

    public fun get_pyth_price(
        registry: &OracleRegistry,
        price_info_obj: &PriceInfoObject,
        oracle_index: u64,
        clock: &Clock,
    ): OraclePriceUpdate {
        registry.version.assert_version(CURRENT_VERSION);

        let oracle = &registry.oracles[oracle_index];

        match (oracle.oracle_type) {
            OracleType::Pyth { price_identifier } => {
                let (price, ema_price, price_feed) = pyth::get_prices(
                    price_info_obj, 
                    clock, 
                    registry.config.pyth_max_staleness_threshold_s, 
                    registry.config.pyth_max_confidence_interval_pct,
                    price_identifier
                );

                OraclePriceUpdate {
                    oracle_registry_id: object::id(registry),
                    oracle_index,
                    price,
                    ema_price: option::some(ema_price),
                    metadata: OracleMetadata::Pyth { price_feed }
                }
            },
            _ => abort EInvalidOracleType
        }

    }

    public fun get_switchboard_price(
        registry: &OracleRegistry,
        aggregator: &Aggregator,
        oracle_index: u64,
        clock: &Clock,
    ): OraclePriceUpdate {
        registry.version.assert_version(CURRENT_VERSION);

        let oracle = &registry.oracles[oracle_index];

        match (oracle.oracle_type) {
            OracleType::Switchboard { feed_id } => {
                let (price, current_result) = switchboard::get_price(
                    aggregator, 
                    clock, 
                    registry.config.switchboard_max_staleness_threshold_s, 
                    registry.config.switchboard_max_confidence_interval_pct,
                    feed_id
                );

                OraclePriceUpdate {
                    oracle_registry_id: object::id(registry),
                    oracle_index,
                    price,
                    ema_price: option::none(),
                    metadata: OracleMetadata::Switchboard { current_result }
                }
            },
            _ => abort EInvalidOracleType
        }
    }

    #[test_only]
    public fun new_oracle_registry_for_testing(config: OracleRegistryConfig, ctx: &mut TxContext): (OracleRegistry, AdminCap) {
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
}

