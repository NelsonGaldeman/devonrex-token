// Fetch the DevonRex token contract data from the DevonRex.json file
var DevonRex = artifacts.require("./DevonRex.sol");

// JavaScript export
module.exports = function(deployer) {
    // Deploy the contract to the network
    deployer.deploy(DevonRex);
}
