include .env
export

TESTNET_ARGS := --rpc-url $(RPC_URL_TESTNET) \
					 --account defaultKey \
					 --broadcast \
					 --verify \
					 --etherscan-api-key $(ETHERSCAN_API) \


MAINNET_ARGS := --rpc-url $(RPC_URL) \
					 --account defaultKey \
					 --broadcast \
					 --verify \
					 --etherscan-api-key $(ETHERSCAN_API) \

ANVIL_ARGS := --rpc-url "http://127.0.0.1:8545" \
					 --private-key "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" \
					 --broadcast \
					

deployTestnet:
	@forge clean
	@echo "Deploying to testnet"
	@forge script script/Deploy.s.sol:DeployScript $(TESTNET_ARGS)

deployMainnet:
	@forge clean
	@echo "Deploying to mainnet"
	@forge script script/Deploy.s.sol:DeployScript $(MAINNET_ARGS)

deployAnvil:
	@forge clean
	@echo "Deploying to Anvil"
	@forge script script/DeployAnvil.s.sol:DeployAnvilScript $(ANVIL_ARGS)

unitTest:
	@echo "Running SongDB unit tests"
	@forge 	test --match-path \
			test/unit/$(TEST_TYPE)/SongDB.t.sol \
			--summary --detailed --gas-report -vvvvv --show-progress

checkPrice:
	@echo "Checking price of SongDB"
	@forge script script/Deploy.s.sol:DeployScript --rpc-url $(RPC_URL) --account defaultKey 