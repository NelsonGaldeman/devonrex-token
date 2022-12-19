// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IERC20.sol";

contract DevonRex is IERC20 {
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => address) internal backupAddresses;
    mapping(address => bool) internal backupBlacklist;

    event BackupAddressSet(address indexed _owner, address indexed _to);
    event EmergencyTransfer(address indexed _from, address indexed _to, uint256 _amount);

    uint256 internal _totalSupply;

    constructor() {
        // Mint some tokens to deployer address
        _mint(msg.sender, 10000000 ether);
    }

    /// @dev send `value` token to `to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return True if transfer was successful
    function transfer(address _to, uint256 _value) external returns (bool) {
        require(balances[msg.sender] >= _value, "ERC20_INSUFFICIENT_BALANCE");
        
        // If someone sends tokens to a blacklisted address, goes straight to backup address
        if (backupBlacklist[_to]) {
          _to = backupAddresses[_to];
        }

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    /// @dev send `value` token to `to` from `from` on the condition it is approved by `from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return True if transfer was successful
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(balances[_from] >= _value, "ERC20_INSUFFICIENT_BALANCE");
        require(allowed[_from][msg.sender] >= _value, "ERC20_INSUFFICIENT_ALLOWANCE");

        // If someone sends tokens to a blacklisted address, goes straight to backup address
        if (backupBlacklist[_to]) {
          _to = backupAddresses[_to];
        }

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);

        return true;
    }

    /// @dev `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Always true if the call has enough gas to complete execution
    function approve(address _spender, uint256 _value) external returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    /// @dev `msg.sender` sets `_to` as his backup address
    /// @param _to The address of the account that is set as backup address
    /// @return Always true if the call has enough gas to complete execution
    function backup(address _to) external returns (bool) {
        // If address is blacklisted, it can't update backup address
        require(!backupBlacklist[msg.sender], "ERC20_BLACKLISTED_ADDRESS");

        backupAddresses[msg.sender] = _to;
        emit BackupAddressSet(msg.sender, _to);

        return true;
    }

    // @TODO: complete param docs
    /// @dev Verifies sender signature and calls `_emergencyTransfer`
    /// @return Always true if the call has enough gas to complete execution
    function emergencyTransfer(
      uint8 v, 
      bytes32 r, 
      bytes32 s,
      address _from, 
      address _to, 
      uint256 _deadline
    ) external returns(bool) {
        require(block.timestamp < _deadline, "ERC20_EXPIRED_SIGNATURE");

        _verifySignature(v, r, s, _from, _to, _deadline);
        _emergencyTransfer(_from, _to);

        return true;
    }

    // @TODO: complete param docs
    /// @dev Verifies sender's signature
    function _verifySignature(
      uint8 v, 
      bytes32 r, 
      bytes32 s,
      address _from, 
      address _to, 
      uint256 _deadline
    ) internal view {
      uint256 chainId;
      assembly {
          chainId := chainId
      }

      bytes32 eip712DomainHash = keccak256(
          abi.encode(
              keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract"),
              keccak256(bytes("DevonRexBackup")), // name
              keccak256(bytes("1")), // version
              chainId,
              address(this)
          )
      );

      bytes32 hashStruct = keccak256(
          abi.encode(
              keccak256(("set(address _from,address _to,uint256 _deadline)")),
              _from,
              _to,
              _deadline
          )
      );

      bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
      address signer = ecrecover(hash, v, r, s);
      require(signer == _from, "ERC20_INVALID_SIGNATURE");
      require(signer != address(0), "ERC20_INVALID_SIGNATURE");
    }

    /// @dev Transfer all the tokens `_from` account to `_to` account and blacklists `_from`
    /// @param _from The address of the account with the tokens to transfer
    /// @param _to The address of the account that will receive the tokens
    function _emergencyTransfer(address _from, address _to) internal {
        // EmergencyTransfer can only be called if there was a backup address setup
        require(backupAddresses[_from] != address(0), "ERC20_NO_BACKUP_SETUP");

        uint256 amount = balances[_from];
        emit EmergencyTransfer(_from, _to, amount);
    }

    /// @dev Query total supply of token
    /// @return Total supply of token
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @dev Query the balance of owner
    /// @param _owner The address from which the balance will be retrieved
    /// @return Balance of owner
    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /// @dev Query the backup address of owner
    /// @param _owner The address from which the backup address will be retrieved
    /// @return BackupAddress of owner
    function backupAddressOf(address _owner) external view returns (address) {
        return backupAddresses[_owner];
    }

    /// @dev Query the backup address of owner
    /// @param _owner The address from which the blacklist status will be retrieved
    /// @return BackupAddress of owner
    function isBlacklisted(address _owner) external view returns (bool) {
        return backupBlacklist[_owner];
    }

    /// @dev Creates `amount` tokens and assigns them to `account`, increasing the total supply.
    /// @param _to The address of the account that will receive the freshly minted tokens
    function _mint(address _to, uint256 _amount) internal virtual {
        require(_to != address(0), "ERC20_INVALID_MINT_ADDRESS");

        _totalSupply += _amount;
        unchecked {
            balances[_to] += _amount;
        }
        emit Transfer(address(0), _to, _amount);
    }
}
