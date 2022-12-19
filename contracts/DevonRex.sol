// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IERC20.sol";

contract DevonRex is IERC20 {
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => address) internal backupAddresses;

    event BackupAddressSet(address indexed _owner, address indexed _to);

    uint256 internal _totalSupply;

    constructor() {
      _mint(msg.sender, 10000000 ether);
    }

    /// @dev send `value` token to `to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return True if transfer was successful
    function transfer(address _to, uint256 _value) external returns (bool) {
        require(balances[msg.sender] >= _value, "ERC20_INSUFFICIENT_BALANCE");
        require(balances[_to] + _value >= balances[_to], "UINT256_OVERFLOW");

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
        require(balances[_to] + _value >= balances[_to], "UINT256_OVERFLOW");

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
        backupAddresses[msg.sender] = _to;
        emit BackupAddressSet(msg.sender, _to);
        return true;
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

    // @TODO: UPDATE COMMENTS NOTATION
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20_INVALID_MINT_ADDRESS");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }
}
