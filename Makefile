.PHONY: build lint test

build:
	sui move build --force -p contracts/oracles
	sui move build --force -p contracts/sprungsui
	sui move build --force -p contracts/strategy_wrapper
	sui move build --force -p contracts/suilend

lint:
	sui move build --test -p contracts/oracles --lint
	sui move build --test -p contracts/sprungsui --lint
	sui move build --test -p contracts/strategy_wrapper --lint
	sui move build --test -p contracts/suilend --lint

test:
	sui move test --no-lint --silence-warnings -p contracts/oracles
	sui move test --no-lint --silence-warnings -p contracts/sprungsui
	sui move test --no-lint --silence-warnings -p contracts/strategy_wrapper
	sui move test --no-lint --silence-warnings -p contracts/suilend -i 20000000
