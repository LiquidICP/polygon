// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IWrapperBridgedStandardERC20.sol";

contract WrapperBridgedStandardERC20 is IWrapperBridgedStandardERC20, ERC20, Initializable {

    address public bridge;

    string internal __name;
    string internal __symbol;

    uint8 internal __decimals;
    uint256 public override burnt = 0;

    constructor() ERC20("", "") {}

    modifier onlyBridge {
        require(_msgSender() == bridge, "onlyBridge");
        _;
    }

    /**
     * @param _bridge Address of the  bridge.
     * @param _name ERC20 name.
     * @param _symbol ERC20 symbol.
     */
    function configure(
        address _bridge,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external override initializer {
        bridge = _bridge;
        __name = _name;
        __symbol = _symbol;
        __decimals = _decimals;
    }

    function name() public view override(ERC20, IWrapperBridgedStandardERC20) returns(string memory) {
        return __name;
    }

    function symbol() public view override(ERC20, IWrapperBridgedStandardERC20) returns(string memory) {
        return __symbol;
    }

    function decimals() public view override(ERC20, IWrapperBridgedStandardERC20) returns(uint8) {
        return __decimals;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (recipient == address(0)) {
            _burn(sender, amount);
            burnt = burnt + amount;
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    function mint(address _to, uint256 _amount) public virtual override onlyBridge {
        _mint(_to, _amount);
        emit Mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public virtual override onlyBridge {
        _burn(_from, _amount);
        emit Burn(_from, _amount);
    }
}
