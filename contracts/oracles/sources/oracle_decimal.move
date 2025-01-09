module oracles::oracle_decimal {

    public struct OracleDecimal has copy, drop, store {
        base: u128,
        expo: u64,
        is_expo_negative: bool,
    }

    public fun new(base: u128, expo: u64, is_expo_negative: bool): OracleDecimal {
        OracleDecimal {
            base,
            expo,
            is_expo_negative
        }
    }

    public fun base(decimal: &OracleDecimal): u128 {
        decimal.base
    }

    public fun expo(decimal: &OracleDecimal): u64 {
        decimal.expo
    }

    public fun is_expo_negative(decimal: &OracleDecimal): bool {
        decimal.is_expo_negative
    }

}
