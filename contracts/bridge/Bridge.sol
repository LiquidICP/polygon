pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IBridge.sol";
import "../interfaces/IWrapperBridgedStandardERC20.sol";
// добавить изменяемую комиссию
// добавить соотношение кошельков
// проработать взятие комиссии
contract Bridge is AccessControl, IBridge {
    using SafeERC20 for IERC20;

    address public wallerForBurning;

    uint public feeRate;
    uint public constant MAX_BP = 1000;

    IWrappedInternetComputerToken public iWrappedInternetComputerToken;

    mapping(address => bool) public allowedTokens;

//    bytes32 public constant ICP_ADDRESS = "";
//
//    mapping (byte32 => address) relatedTokens;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "onlyAdmin");
        _;
    }

    modifier onlyMessangerBot {
        require(hasRole(BOT_MESSANGER_ROLE, _msgSender()), "onlyMessangerBot");
        _;
    }

    modifier tokenIsAllowed(address _token) {
        require(allowedTokens[_token], "invalidToken");
        _;
    }

    constructor (
        address _wrappedICP,
        address _wallerForBurning,
        uint _feeRate, address _botMessanger,
        address _allowedToken,
        string memory _name,
        string memory _symbol
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BOT_MESSANGER_ROLE, _botMessanger);
        feeRate = _feeRate;

        if (_wrappedICP != address(0)) {
            iWrappedInternetComputerToken = IWrapperBridgedStandardERC20(_wrappedICP);
        }
        if (_wallerForBurning != address(0)) {
            wallerForBurning = _wallerForBurning;
        }
        _cloneAndInitializeTokenAtEndForTokenAtStart(_allowedToken, _name, _symbol);
    }

    function evacuateTokens(address _token, uint256 _amount, address _to) external onlyAdmin {
        require(!allowedTokens[_token], "cannotEvacuateAllowedToken");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
    }

    function setFeeRate(uint _feeRate) external onlyAdmin {
        feeRate = _feeRate;
    }

    function requestBridgingToStart(
        address _tokenAtStart,
        address _tokenAtEnd,
        address _to,
        uint _amount
    ) external override onlyAtEnd tokenIsAllowed(_tokenAtEnd) {
        uint feeAmount = calcFeeAmount(_amount);
        address sender = _msgSender();
        iWrappedInternetComputerToken(_tokenAtEnd).safeTransferFrom(sender, address(this), feeAmount);
        iWrappedInternetComputerToken.burn(sender, _wallerForBurning, _amount - feeAmount);
        emit RequestBridgingToStart(_tokenAtStart, _tokenAtEnd, sender, _to, _amount - feeAmount);
    }

    function calcFeeAmount(uint _amount) private pure returns(uint){
        return _amount * feeRate / MAX_BP;
    }

    function performBridgingToEnd(
        address _tokenAtStart,
        address _to,
        uint256 _amount,
        string memory _name,
        string memory _symbol
    )
        external
        override
        onlyAtEnd
        onlyMessangerBot
    {
        address tokenAtEnd = getEndTokenByStartToken(_tokenAtStart);
        if (tokenAtEnd == address(0)) {
            tokenAtEnd = _cloneAndInitializeTokenAtEndForTokenAtStart(
                _tokenAtStart,
                _name,
                _symbol
            );
        }
        iWrappedInternetComputerToken(tokenAtEnd).mint(_to, _amount);
        emit BridgingToEndPerformed(_tokenAtStart, tokenAtEnd, _to, _amount);
    }

}
