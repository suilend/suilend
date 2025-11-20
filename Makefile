.PHONY: build lint test

build:
	sui move build --force -p contracts/oracles
	sui move build --force -p contracts/sprungsui
	sui move build --force -p contracts/strategy_wrapper
	sui move build --force -p contracts/suilend
	sui move build --force -p contracts/vaults

lint:
	sui move build --skip-fetch-latest-git-deps --test -p contracts/oracles --lint
	sui move build --skip-fetch-latest-git-deps --test -p contracts/sprungsui --lint
	sui move build --skip-fetch-latest-git-deps --test -p contracts/strategy_wrapper --lint
	sui move build --skip-fetch-latest-git-deps --test -p contracts/suilend --lint
	sui move build --skip-fetch-latest-git-deps --test -p contracts/vaults --lint

test:
	sui move test --skip-fetch-latest-git-deps --no-lint --silence-warnings -p contracts/oracles
	sui move test --skip-fetch-latest-git-deps --no-lint --silence-warnings -p contracts/sprungsui
	sui move test --skip-fetch-latest-git-deps --no-lint --silence-warnings -p contracts/strategy_wrapper
	sui move test --skip-fetch-latest-git-deps --no-lint --silence-warnings -p contracts/suilend
	sui move test --skip-fetch-latest-git-deps --no-lint --silence-warnings -p contracts/vaults
