module spec::decimal_summaries;

use cvlm::manifest::{ summary, ghost };
use suilend::decimal::Decimal;

public fun cvlm_manifest() {
    summary(b"from", @suilend, b"decimal", b"from");
    summary(b"from_u128", @suilend, b"decimal", b"from_u128");
    summary(b"from_percent", @suilend, b"decimal", b"from_percent");
    summary(b"from_percent_u64", @suilend, b"decimal", b"from_percent_u64");
    summary(b"from_bps", @suilend, b"decimal", b"from_bps");
    summary(b"mul", @suilend, b"decimal", b"mul");
    summary(b"div", @suilend, b"decimal", b"div");
    summary(b"pow", @suilend, b"decimal", b"pow");
    summary(b"floor", @suilend, b"decimal", b"floor");
    summary(b"ceil", @suilend, b"decimal", b"ceil");

    ghost(b"from");
    ghost(b"from_u128");
    ghost(b"from_percent");
    ghost(b"from_percent_u64");
    ghost(b"from_bps");
    ghost(b"mul");
    ghost(b"div");
    ghost(b"pow");
    ghost(b"floor");
    ghost(b"ceil");
}

public native fun from(_v: u64): Decimal;
public native fun from_u128(_v: u128): Decimal;
public native fun from_percent(_v: u8): Decimal;
public native fun from_percent_u64(_v: u64): Decimal;
public native fun from_bps(_v: u64): Decimal;
public native fun mul(_a: Decimal, _b: Decimal): Decimal;
public native fun div(_a: Decimal, _b: Decimal): Decimal;
public native fun pow(_b: Decimal, _e: u64): Decimal;
public native fun floor(_a: Decimal): u64;
public native fun ceil(_a: Decimal): u64;