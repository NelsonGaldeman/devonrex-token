const DevonRex = artifacts.require("DevonRex");
const { eip712sign, ERROR_PREFIX } = require('./utils');
/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("DevonRex", function ( accounts ) {
    it("should assert true", async function () {
        await DevonRex.deployed();
        return assert.isTrue(true);
    });
    it("should validate initial minting to deployer address", async function () {
        const contract = await DevonRex.deployed();
        let balance = await contract.balanceOf(accounts[0]);
        return assert.isTrue(balance.toString() == "10000000000000000000000000");
    });
    it("should transfer tokens", async function () {
        const contract = await DevonRex.deployed();
        await contract.transfer(accounts[1], "100000");
        let balance = await contract.balanceOf(accounts[1]);
        return assert.isTrue(balance.toString() == "100000");
    });
    it("should transfer tokens on behalf of another account", async function () {
        const contract = await DevonRex.deployed();
        await contract.approve(accounts[1], "100000");
        
        await contract.transfer(accounts[2], "100000", { from: accounts[1] });
        let balance = await contract.balanceOf(accounts[2]);
        return assert.isTrue(balance.toString() == "100000");
    });
    it("should set backup address", async function () {
        const contract = await DevonRex.deployed();
        await contract.backup(accounts[1]);
        let address = await contract.backupAddressOf(accounts[0]);
        return assert.isTrue(address === accounts[1]);
    });
    it("should execute an emergencyTransfer", async function () {
        const contract = await DevonRex.deployed();

        const { signedMsg, deadline } = await eip712sign(web3, contract.address, accounts[0], accounts[1]);
        
        const signature = signedMsg.substring(2);
        const r = "0x" + signature.substring(0, 64);
        const s = "0x" + signature.substring(64, 128);
        const v = parseInt(signature.substring(128, 130), 16);

        let balance0 = await contract.balanceOf(accounts[0]);
        await contract.emergencyTransfer(v,r,s,accounts[0], accounts[1], deadline, { from: accounts[2] });
        
        let balance1 = await contract.balanceOf(accounts[1]);
        return assert.isTrue(balance0 == balance1);
    });
    it("should revert because deadline was manipulated", async function () {
        const contract = await DevonRex.deployed();
        
        const { signedMsg } = await eip712sign(web3, contract.address, accounts[0], accounts[1]);
        const signature = signedMsg.substring(2);
        const r = "0x" + signature.substring(0, 64);
        const s = "0x" + signature.substring(64, 128);
        const v = parseInt(signature.substring(128, 130), 16);

        await contract.emergencyTransfer(v, r, s, accounts[0], accounts[1], 1681527386);

        try {
            await contract.transfer(accounts[0], "10000", { from: accounts[1] });
            throw null;
        }
        catch (error) {
            assert(error, "Expected an error but did not get one");
            assert(error.message.startsWith(ERROR_PREFIX + "ERC20_BLACKLISTED_ADDRESS"), "Expected an error starting with '" + ERROR_PREFIX + message + "' but got '" + error.message + "' instead");
        }

        return assert.isTrue(true);
    });
    it("should revert on transfer to blacklisted address", async function () {
        const contract = await DevonRex.deployed();
        
        const { signedMsg, deadline } = await eip712sign(web3, contract.address, accounts[0], accounts[1]);
        const signature = signedMsg.substring(2);
        const r = "0x" + signature.substring(0, 64);
        const s = "0x" + signature.substring(64, 128);
        const v = parseInt(signature.substring(128, 130), 16);

        await contract.emergencyTransfer(v, r, s, accounts[0], accounts[1], deadline);

        try {
            await contract.transfer(accounts[0], "10000", { from: accounts[1] });
            throw null;
        }
        catch (error) {
            assert(error, "Expected an error but did not get one");
            assert(error.message.startsWith(ERROR_PREFIX + "ERC20_BLACKLISTED_ADDRESS"), "Expected an error starting with '" + ERROR_PREFIX + message + "' but got '" + error.message + "' instead");
        }

        return assert.isTrue(true);
    });
    it("should revert on backup to blacklisted address", async function () {
        const contract = await DevonRex.deployed();
        
        const { signedMsg, deadline } = await eip712sign(web3, contract.address, accounts[0], accounts[1]);
        const signature = signedMsg.substring(2);
        const r = "0x" + signature.substring(0, 64);
        const s = "0x" + signature.substring(64, 128);
        const v = parseInt(signature.substring(128, 130), 16);

        await contract.emergencyTransfer(v, r, s, accounts[0], accounts[1], deadline);

        try {
            await contract.backup(accounts[0], { from: accounts[1] });
            throw null;
        }
        catch (error) {
            assert(error, "Expected an error but did not get one");
            assert(error.message.startsWith(ERROR_PREFIX + "ERC20_BLACKLISTED_ADDRESS"), "Expected an error starting with '" + ERROR_PREFIX + message + "' but got '" + error.message + "' instead");
        }

        return assert.isTrue(true);
    });
});
