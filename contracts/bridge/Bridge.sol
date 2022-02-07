pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IBridge.sol";
import "../interfaces/IWrapperBridgedStandardERC20.sol";

contract Bridge is AccessControl, IBridge {
    using SafeERC20 for IERC20;

    address public wallerForBurning;

    uint public feeRate;
    uint public constant MAX_BP = 1000;

    IWrappedInternetComputerToken public iWrappedInternetComputerToken;

    uint public commission;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "onlyAdmin");
        _;
    }

    constructor (address _wrappedICP, address _wallerForBurning, uint _feeRate) {
        require(wallerForBurning != address(0), "The wallet address must not be 0 or empty");
        require(_wrapperICP != address(0), "The token address must not be 0 or empty");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        feeRate = _feeRate;
        wallerForBurning = _wallerForBurning;
        iWrappedInternetComputerToken = IWrappedInternetComputerToken(_wrappedICP);
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
    }

    function setFeeRate(uint _feeRate) external onlyAdmin {
        feeRate = _feeRate;
    }

    function forwardTokensFromPolygonToDfinity(uint _amount, bytes32 _address) external {
        uint feeAmount = calcFeeAmount(_amount);
        address sender = _msgSender();
        iWrappedInternetComputerToken.safeTransferFrom(sender, address(this), feeAmount);
        iWrappedInternetComputerToken.burn(sender, _wallerForBurning, _amount - feeAmount);
        emit ForwardTokensFromPolygonToDfinity(_wallerForBurning, _amount - feeAmount);
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
