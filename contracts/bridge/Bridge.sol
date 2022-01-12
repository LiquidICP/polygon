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

    IWrappedInternetComputerToken public iWrappedInternetComputerToken;

    uint public commission;
//    bytes32 public constant ICP_ADDRESS = "";
//
//    mapping (byte32 => address) relatedTokens;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "onlyAdmin");
        _;
    }

    constructor (address _wrappedICP, address _wallerForBurning, uint _commission) {
        require(wallerForBurning != address(0), "The wallet address must not be 0 or empty");
        require(_wrapperICP != address(0), "The token address must not be 0 or empty");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        commission = _commission;
        wallerForBurning = _wallerForBurning;
        iWrappedInternetComputerToken = IWrappedInternetComputerToken(_wrappedICP);
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
    }

    function setCommission(uint _commission) external onlyAdmin {
        commission = _commission;
    }
    //нужно ли выделять сбор комиссии в отдельную функцию?
    function forwardTokensFromPolygonToDfinity(uint _amount, bytes32 _address) external {
        uint commissionAmount = calcCommissionAmount(_amount, commission);
        address sender = _msgSender();
        iWrappedInternetComputerToken.safeTransferFrom(sender, address(this), commissionAmount);
        iWrappedInternetComputerToken.burn(sender, _wallerForBurning, _amount - commissionAmount);
        emit ForwardTokensFromPolygonToDfinity(_wallerForBurning, _amount);
    }

    function calcCommissionAmount(uint _amount, uint _commission) internal pure returns(uint){
        return _amount % _commission;
    }

    function mintTokens(address _to, uint _amount) external {
        iWrappedInternetComputerToken.mint(_to, _amount);
        emit ForwardTokensFromPolygonToDfinity(_to, _amount);
    }
}
