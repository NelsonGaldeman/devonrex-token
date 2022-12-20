# DevonRex Token

ERC20 Token that allows to set a backup address and be able to recover funds from a different one if you have a previously EIP712 signed message

# Solution

Adds a 1 to 1 mapping (+getters & setters) to store backup addresses. Then, you can sign a message following EIP712 standard and the following data structure:

`set(address from,address to,uint256 deadline)`

Any given address (except token owner) that can provide EIP712 signature can transfer all the tokens from the `owner` to it's backup address (only if set) by calling `emergencyTransfer` with necesary parameters that can be obtained from the signature (for code examples see unit tests)

# Deployment

Goerli contract address is [0x9DC78833AdD523AE70865C23C2476655b399A108](https://goerli.etherscan.io/address/0x9DC78833AdD523AE70865C23C2476655b399A108)

# Install & Deploy

`$ npm install`

`$ truffle migrate --network {GIVEN_NETWORK}`

# Run tests

`truffle test test/devon_rex.js --network {GIVEN_NETWORK}`

# Known issues

* Tests that require offline EIP712 signatures will fail. That's because web3.eth only provides a `sign` method which is different from the RPC `eth_signTypedData_v4`. For some reason, the methods `send` & `sendAsync` from the provider library do not return a promise but only allow you to pass a callback that will be called async, that makes it impossible to send RPC call `eth_signTypedData_v4` and get the response syncronichally to get the tests working. A workaround would be to implement `eth_signTypedData_v4` logic within the `utils.js` library and use `web3.eth.sign` method
* Ganache crashes when gets `eth_estimateGas` so I wasn't able to make it work there but it's good on Hardhat forks & Goerli.