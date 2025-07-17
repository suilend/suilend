/// Example of how to extend the strategy wrapper with dynamic fields
module strategy_wrapper::strategy_wrapper_v2_example {
    use std::ascii::{Self, String};
    use sui::dynamic_field;
    use sui::event;
    use suilend::lending_market::{Self, ObligationOwnerCap};

    // === Errors ===
    const EIncorrectVersion: u64 = 1;
    const EFeatureNotAvailable: u64 = 2;
    const EInvalidStrategyType: u64 = 3;

    // === Constants ===
    const CURRENT_VERSION: u64 = 2;
    const MIN_VERSION_FOR_FEATURES: u64 = 2;

    // === Strategy Type Constants ===
    const STRATEGY_SUI_LOOPING_SSUI: u8 = 1;
    const STRATEGY_BTC_LOOPING_WBTC: u8 = 2;

    // === Dynamic Field Keys ===
    public struct AutoRebalanceConfig has copy, drop, store {}
    public struct PerformanceMetrics has copy, drop, store {}
    public struct CustomParameters has copy, drop, store {}

    // === New Structs for V2 Features ===
    public struct RebalanceSettings has store {
        enabled: bool,
        threshold_bps: u64,  
        max_frequency_hours: u64,
    }

    public struct Metrics has store {
        total_deposits: u64,
        total_withdrawals: u64,
        last_rebalance_timestamp: u64,
        performance_score: u64,
    }

    public struct CustomParams has store {
        risk_level: u8,  // 1-10 scale
        auto_compound: bool,
        notification_enabled: bool,
    }

    public struct StrategyOwnerCap<phantom P> has key, store {
        id: UID,
        version: u64,
        inner_cap: ObligationOwnerCap<P>,
        strategy_type: u8,
    }

    // === Events ===
    public struct FeatureEnabled has copy, drop {
        cap_id: address,
        feature_name: String,
        version: u64,
    }

    public struct AutoRebalanceTriggered has copy, drop {
        cap_id: address,
        threshold_reached: u64,
        timestamp: u64,
    }

    // === Strategy Type Validation ===
    public fun is_valid_strategy_type(strategy_type: u8): bool {
        strategy_type == STRATEGY_SUI_LOOPING_SSUI ||
        strategy_type == STRATEGY_BTC_LOOPING_WBTC
    }

    // === V2 Feature Functions ===

    /// Initialize auto-rebalance configuration
    public fun init_auto_rebalance<P>(
        strategy_cap: &mut StrategyOwnerCap<P>,
        threshold_bps: u64,
        max_frequency_hours: u64,
        _ctx: &TxContext
    ) {
        assert!(strategy_cap.version >= MIN_VERSION_FOR_FEATURES, EFeatureNotAvailable);
        
        let config = RebalanceSettings {
            enabled: true,
            threshold_bps,
            max_frequency_hours,
        };
        
        dynamic_field::add(&mut strategy_cap.id, AutoRebalanceConfig {}, config);
        
        event::emit(FeatureEnabled {
            cap_id: object::id_address(strategy_cap),
            feature_name: ascii::string(b"auto_rebalance"),
            version: strategy_cap.version,
        });
    }

    /// Initialize performance tracking
    public fun init_performance_metrics<P>(
        strategy_cap: &mut StrategyOwnerCap<P>,
        _ctx: &TxContext
    ) {
        assert!(strategy_cap.version >= MIN_VERSION_FOR_FEATURES, EFeatureNotAvailable);
        
        let metrics = Metrics {
            total_deposits: 0,
            total_withdrawals: 0,
            last_rebalance_timestamp: 0,
            performance_score: 100, // Start at 100%
        };
        
        dynamic_field::add(&mut strategy_cap.id, PerformanceMetrics {}, metrics);
        
        event::emit(FeatureEnabled {
            cap_id: object::id_address(strategy_cap),
            feature_name: ascii::string(b"performance_metrics"),
            version: strategy_cap.version,
        });
    }

    /// Set custom parameters
    public fun set_custom_parameters<P>(
        strategy_cap: &mut StrategyOwnerCap<P>,
        risk_level: u8,
        auto_compound: bool,
        notification_enabled: bool,
        _ctx: &TxContext
    ) {
        assert!(strategy_cap.version >= MIN_VERSION_FOR_FEATURES, EFeatureNotAvailable);
        assert!(risk_level >= 1 && risk_level <= 10, 3);
        
        let params = CustomParams {
            risk_level,
            auto_compound,
            notification_enabled,
        };
        
        if (dynamic_field::exists_(&strategy_cap.id, CustomParameters {})) {
            let old_params: CustomParams = dynamic_field::remove(&mut strategy_cap.id, CustomParameters {});
            // clean up old params if needed
            let CustomParams { risk_level: _, auto_compound: _, notification_enabled: _ } = old_params;
        };
        
        dynamic_field::add(&mut strategy_cap.id, CustomParameters {}, params);
    }

    // === View Functions for V2 Features ===

    /// Check if auto-rebalance is enabled
    public fun has_auto_rebalance<P>(strategy_cap: &StrategyOwnerCap<P>): bool {
        strategy_cap.version >= MIN_VERSION_FOR_FEATURES && 
        dynamic_field::exists_(&strategy_cap.id, AutoRebalanceConfig {})
    }

    /// Get auto-rebalance configuration
    public fun get_auto_rebalance_config<P>(strategy_cap: &StrategyOwnerCap<P>): (bool, u64, u64) {
        assert!(has_auto_rebalance(strategy_cap), EFeatureNotAvailable);
        
        let config = dynamic_field::borrow<AutoRebalanceConfig, RebalanceSettings>(
            &strategy_cap.id, 
            AutoRebalanceConfig {}
        );
        
        (config.enabled, config.threshold_bps, config.max_frequency_hours)
    }

    /// Check if performance metrics are enabled
    public fun has_performance_metrics<P>(strategy_cap: &StrategyOwnerCap<P>): bool {
        strategy_cap.version >= MIN_VERSION_FOR_FEATURES && 
        dynamic_field::exists_(&strategy_cap.id, PerformanceMetrics {})
    }

    /// Get performance metrics
    public fun get_performance_metrics<P>(strategy_cap: &StrategyOwnerCap<P>): (u64, u64, u64, u64) {
        assert!(has_performance_metrics(strategy_cap), EFeatureNotAvailable);
        
        let metrics = dynamic_field::borrow<PerformanceMetrics, Metrics>(
            &strategy_cap.id, 
            PerformanceMetrics {}
        );
        
        (metrics.total_deposits, metrics.total_withdrawals, 
         metrics.last_rebalance_timestamp, metrics.performance_score)
    }

    /// Update performance metrics
    public(package) fun update_metrics<P>(
        strategy_cap: &mut StrategyOwnerCap<P>,
        deposit_amount: u64,
        withdrawal_amount: u64,
        new_performance_score: u64
    ) {
        if (!has_performance_metrics(strategy_cap)) {
            return
        };
        
        let metrics = dynamic_field::borrow_mut<PerformanceMetrics, Metrics>(
            &mut strategy_cap.id, 
            PerformanceMetrics {}
        );
        
        metrics.total_deposits = metrics.total_deposits + deposit_amount;
        metrics.total_withdrawals = metrics.total_withdrawals + withdrawal_amount;
        metrics.performance_score = new_performance_score;
    }

    // === Migration Function from V1 to V2 ===
    
    /// Enhanced migration that can add new features
    public entry fun migrate_to_v2<P>(
        strategy_cap: &mut StrategyOwnerCap<P>,
        enable_auto_rebalance: bool,
        enable_metrics: bool,
        ctx: &TxContext
    ) {
        assert!(strategy_cap.version == 1, EIncorrectVersion);
        
        // Update version
        strategy_cap.version = 2;
        
        // Optionally enable new features during migration
        if (enable_auto_rebalance) {
            init_auto_rebalance(strategy_cap, 500, 24, ctx); // Default: 5% threshold, max once per day
        };
        
        if (enable_metrics) {
            init_performance_metrics(strategy_cap, ctx);
        };
    }

    /// Clean up dynamic fields when ejecting
    public entry fun eject_v2<P>(
        mut strategy_cap: StrategyOwnerCap<P>,
        ctx: &TxContext
    ) {
        assert!(strategy_cap.version == CURRENT_VERSION, EIncorrectVersion);
        
        // clean up any dynamic fields before destructuring
        if (dynamic_field::exists_(&strategy_cap.id, AutoRebalanceConfig {})) {
            let config: RebalanceSettings = dynamic_field::remove(&mut strategy_cap.id, AutoRebalanceConfig {});
            let RebalanceSettings { enabled: _, threshold_bps: _, max_frequency_hours: _ } = config;
        };
        
        if (dynamic_field::exists_(&strategy_cap.id, PerformanceMetrics {})) {
            let metrics: Metrics = dynamic_field::remove(&mut strategy_cap.id, PerformanceMetrics {});
            let Metrics { 
                total_deposits: _, 
                total_withdrawals: _, 
                last_rebalance_timestamp: _, 
                performance_score: _ 
            } = metrics;
        };
        
        if (dynamic_field::exists_(&strategy_cap.id, CustomParameters {})) {
            let params: CustomParams = dynamic_field::remove(&mut strategy_cap.id, CustomParameters {});
            let CustomParams { risk_level: _, auto_compound: _, notification_enabled: _ } = params;
        };
        
        let StrategyOwnerCap { id, version: _, inner_cap, strategy_type: _ } = strategy_cap;
        let cap_id_addr = object::uid_to_address(&id);
        let obligation_id_addr = object::id_to_address(&lending_market::obligation_id(&inner_cap));
        object::delete(id);
        transfer::public_transfer(inner_cap, tx_context::sender(ctx));
    }
} 