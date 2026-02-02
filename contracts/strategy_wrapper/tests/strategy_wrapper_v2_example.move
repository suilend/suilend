/// Example of how to extend the strategy wrapper with dynamic fields
module strategy_wrapper::strategy_wrapper_v2_example {
    use std::ascii::{Self, String};
    use sui::dynamic_field;
    use sui::event;
    use strategy_wrapper::strategy_wrapper::{Self, StrategyOwnerCap};

    // === Errors ===
    const EFeatureNotAvailable: u64 = 2;

    // === Constants ===
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

    // === Events ===
    public struct FeatureEnabled has copy, drop {
        cap_id: address,
        feature_name: String,
        version: u64,
    }

    #[allow(unused_field)]
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
    #[allow(lint(prefer_mut_tx_context))]
    public fun init_auto_rebalance<P>(
        strategy_cap: &mut StrategyOwnerCap<P>,
        threshold_bps: u64,
        max_frequency_hours: u64,
        _ctx: &TxContext
    ) {
        // Auto-migration will happen in borrow_uid_mut
        assert!(strategy_wrapper::get_version(strategy_cap) >= MIN_VERSION_FOR_FEATURES, EFeatureNotAvailable);
        
        let config = RebalanceSettings {
            enabled: true,
            threshold_bps,
            max_frequency_hours,
        };
        
        dynamic_field::add(strategy_wrapper::borrow_uid_mut(strategy_cap), AutoRebalanceConfig {}, config);
        
        event::emit(FeatureEnabled {
            cap_id: object::id_address(strategy_cap),
            feature_name: ascii::string(b"auto_rebalance"),
            version: strategy_wrapper::get_version(strategy_cap),
        });
    }

    /// Initialize performance tracking
    #[allow(lint(prefer_mut_tx_context))]
    public fun init_performance_metrics<P>(
        strategy_cap: &mut StrategyOwnerCap<P>,
        _ctx: &TxContext
    ) {
        // Auto-migration will happen in borrow_uid_mut
        assert!(strategy_wrapper::get_version(strategy_cap) >= MIN_VERSION_FOR_FEATURES, EFeatureNotAvailable);
        
        let metrics = Metrics {
            total_deposits: 0,
            total_withdrawals: 0,
            last_rebalance_timestamp: 0,
            performance_score: 100, // Start at 100%
        };
        
        dynamic_field::add(strategy_wrapper::borrow_uid_mut(strategy_cap), PerformanceMetrics {}, metrics);
        
        event::emit(FeatureEnabled {
            cap_id: object::id_address(strategy_cap),
            feature_name: ascii::string(b"performance_metrics"),
            version: strategy_wrapper::get_version(strategy_cap),
        });
    }

    /// Set custom parameters
    #[allow(lint(prefer_mut_tx_context))]
    public fun set_custom_parameters<P>(
        strategy_cap: &mut StrategyOwnerCap<P>,
        risk_level: u8,
        auto_compound: bool,
        notification_enabled: bool,
        _ctx: &TxContext
    ) {
        // Auto-migration will happen in borrow_uid_mut
        assert!(strategy_wrapper::get_version(strategy_cap) >= MIN_VERSION_FOR_FEATURES, EFeatureNotAvailable);
        assert!(risk_level >= 1 && risk_level <= 10);
        
        let params = CustomParams {
            risk_level,
            auto_compound,
            notification_enabled,
        };
        
        let uid = strategy_wrapper::borrow_uid_mut(strategy_cap);
        if (dynamic_field::exists_(uid, CustomParameters {})) {
            let old_params: CustomParams = dynamic_field::remove(uid, CustomParameters {});
            // clean up old params if needed
            let CustomParams { risk_level: _, auto_compound: _, notification_enabled: _ } = old_params;
        };
        
        dynamic_field::add(uid, CustomParameters {}, params);
    }

    // === View Functions for V2 Features ===

    /// Check if auto-rebalance is enabled
    public fun has_auto_rebalance<P>(strategy_cap: &StrategyOwnerCap<P>): bool {
        strategy_wrapper::get_version(strategy_cap) >= MIN_VERSION_FOR_FEATURES && 
        dynamic_field::exists_(strategy_wrapper::borrow_uid(strategy_cap), AutoRebalanceConfig {})
    }

    /// Get auto-rebalance configuration
    public fun get_auto_rebalance_config<P>(strategy_cap: &StrategyOwnerCap<P>): (bool, u64, u64) {
        assert!(has_auto_rebalance(strategy_cap), EFeatureNotAvailable);
        
        let config = dynamic_field::borrow<AutoRebalanceConfig, RebalanceSettings>(
            strategy_wrapper::borrow_uid(strategy_cap), 
            AutoRebalanceConfig {}
        );
        
        (config.enabled, config.threshold_bps, config.max_frequency_hours)
    }

    /// Check if performance metrics are enabled
    public fun has_performance_metrics<P>(strategy_cap: &StrategyOwnerCap<P>): bool {
        strategy_wrapper::get_version(strategy_cap) >= MIN_VERSION_FOR_FEATURES && 
        dynamic_field::exists_(strategy_wrapper::borrow_uid(strategy_cap), PerformanceMetrics {})
    }

    /// Get performance metrics
    public fun get_performance_metrics<P>(strategy_cap: &StrategyOwnerCap<P>): (u64, u64, u64, u64) {
        assert!(has_performance_metrics(strategy_cap), EFeatureNotAvailable);
        
        let metrics = dynamic_field::borrow<PerformanceMetrics, Metrics>(
            strategy_wrapper::borrow_uid(strategy_cap), 
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
            strategy_wrapper::borrow_uid_mut(strategy_cap), 
            PerformanceMetrics {}
        );
        
        metrics.total_deposits = metrics.total_deposits + deposit_amount;
        metrics.total_withdrawals = metrics.total_withdrawals + withdrawal_amount;
        metrics.performance_score = new_performance_score;
    }

    // === Enhanced Functions with Auto-Migration ===
    
    /// Enhanced entry function that can add new features to any version
    /// Auto-migration will handle version upgrades automatically
    #[allow(lint(public_entry,prefer_mut_tx_context))]
    public entry fun enable_v2_features<P>(
        strategy_cap: &mut StrategyOwnerCap<P>,
        enable_auto_rebalance: bool,
        enable_metrics: bool,
        ctx: &TxContext
    ) {
        // Auto-migration happens automatically when we access mutable functions
        // No need for explicit version checks - auto-migration handles it
        
        // Optionally enable new features
        if (enable_auto_rebalance) {
            init_auto_rebalance(strategy_cap, 500, 24, ctx); // Default: 5% threshold, max once per day
        };
        
        if (enable_metrics) {
            init_performance_metrics(strategy_cap, ctx);
        };
    }
} 
