// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IBridge.sol";
import "../interfaces/IWrapperBridgedStandardERC20.sol";

contract Bridge is AccessControl, IBridge {
    using SafeERC20 for IERC20;
    using Clones for address;

    address public wallerForFee;

    uint public feeRate;
    uint public constant MAX_BP = 1000;

    IWrapperBridgedStandardERC20 public iWrapperBridgedStandardERC20;

    bytes32 public constant BOT_MESSENGER_ROLE = keccak256("BOT_MESSENGER_ROLE");

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "onlyAdmin");
        _;
    }

    modifier onlyMessengerBot {
        require(hasRole(BOT_MESSENGER_ROLE, _msgSender()), "onlyMessengerBot");
        _;
    }

    constructor (
        address _wrappedICP,
        address _wallerForFee,
        address _botMessenger,
        uint _feeRate,
        uint8 _decimals,
        string memory _name,
        string memory _symbol
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BOT_MESSENGER_ROLE, _botMessenger);
        feeRate = _feeRate;

        if (_wrappedICP != address(0)) {
            iWrapperBridgedStandardERC20 = IWrapperBridgedStandardERC20(_wrappedICP);
        }
        if (_wallerForFee != address(0)) {
            wallerForFee = _wallerForFee;
        }
        _cloneAndInitializeTokenAtEndForTokenAtStart(_name, _symbol, _decimals);
    }

    function evacuateTokens(uint256 _amount, address _to) external onlyAdmin {
        IERC20(address(iWrapperBridgedStandardERC20)).safeTransfer(_to, _amount);
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
    }

    function setFeeRate(uint _feeRate) external onlyAdmin {
        feeRate = _feeRate;
    }

    function setWalletForFee(address _wallerForFee) external onlyAdmin {
        require(_wallerForFee != address(0), "The address must not be null");
        wallerForFee = _wallerForFee;
    }

    function requestBridgingToStart(
        uint _amount
    ) external override {
        uint feeAmount = calcFeeAmount(_amount);
        address sender = _msgSender();
        if (feeAmount == 0) {
            revert("The amount is too small to transfer");
        } else {
            iWrapperBridgedStandardERC20.transferFrom(sender, wallerForFee, feeAmount);
            iWrapperBridgedStandardERC20.burn(sender, _amount - feeAmount);
            emit RequestBridgingToStart(address(iWrapperBridgedStandardERC20), sender, _amount - feeAmount);
        }
    }

    function calcFeeAmount(uint _amount) private view returns(uint){
        return _amount * feeRate / MAX_BP;
    }

    function performBridgingToEnd(
        address _to,
        uint256 _amount,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    )
    external
    override
    onlyMessengerBot
    {
        address token = address(iWrapperBridgedStandardERC20);
        if (token == address(0)) {
            token = _cloneAndInitializeTokenAtEndForTokenAtStart(
                _name,
                _symbol,
                _decimals
            );
        }
        iWrapperBridgedStandardERC20.mint(_to, _amount);
        emit BridgingToEndPerformed(token, _to, _amount);
    }

    function _cloneAndInitializeTokenAtEndForTokenAtStart(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    )
    internal
    returns(address token)
    {
        address _token = address(iWrapperBridgedStandardERC20).clone();
        IWrapperBridgedStandardERC20(_token).configure(
            address(this),
            _name,
            _symbol,
            _decimals
        );
        return _token;
    }
}
