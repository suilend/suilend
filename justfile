[private]
default:
    @just -l

build:
    sui move build --force -p contracts/oracles
    sui move build --force -p contracts/sprungsui
    sui move build --force -p contracts/strategy_wrapper
    sui move build --force -p contracts/suilend

lint:
    sui move build --skip-fetch-latest-git-deps --test -p contracts/oracles --lint
    sui move build --skip-fetch-latest-git-deps --test -p contracts/sprungsui --lint
    sui move build --skip-fetch-latest-git-deps --test -p contracts/strategy_wrapper --lint
    sui move build --skip-fetch-latest-git-deps --test -p contracts/suilend --lint

test:
    sui move test --skip-fetch-latest-git-deps --no-lint --silence-warnings -p contracts/oracles
    sui move test --skip-fetch-latest-git-deps --no-lint --silence-warnings -p contracts/sprungsui
    sui move test --skip-fetch-latest-git-deps --no-lint --silence-warnings -p contracts/strategy_wrapper
    sui move test --skip-fetch-latest-git-deps --no-lint --silence-warnings -p contracts/suilend
