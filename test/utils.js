const ERROR_PREFIX = "Returned error: VM Exception while processing transaction: ";

const eip712sign = async (web3, verifyingContract, from, to, deadline) => {
  if (deadline === 0 || deadline === undefined) {
      let milsec_deadline = Date.now() / 1000 + 10000000;
      deadline = parseInt(String(milsec_deadline).slice(0, 10));
  }

  from = web3.utils.toChecksumAddress(from);
  to = web3.utils.toChecksumAddress(to);

  let chainId = (await web3.eth.getChainId()).toString();
  const msgParams = JSON.stringify({
      types: {
          EIP712Domain: [
              { name: "name", type: "string" },
              { name: "version", type: "string" },
              { name: "chainId", type: "uint256" },
              { name: "verifyingContract", type: "address" }
          ],
          set: [
              { name: "from", type: "address" },
              { name: "to", type: "address" },
              { name: "deadline", type: "uint256" }
          ]
      },
      primaryType: "set",
      domain: { name: "DevonRexBackup", version: "1", chainId, verifyingContract },
      message: { from, to, deadline }
  });

  // let params = [from, msgParams];
  // let method = 'eth_signTypedData_v4';

  // sign is not appropiate, but there is no signTypedData on web3 implementation
  return { signedMsg: await web3.eth.sign(msgParams, from), deadline };
};

module.exports = { eip712sign, ERROR_PREFIX };
