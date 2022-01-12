pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IBridge.sol";
import "./interfaces/IWrapperBridgedStandardERC20.sol";

contract Bridge is AccessControl, IBridge {

    using Clones for address;
    using SafeERC20 for IERC20;

    struct Pair {
        address tokenAtStart;
        address tokenAtEnd;
    }

    address payable public feeWallet;

    bytes32 public constant BOT_MESSANGER_ROLE = keccak256("BOT_MESSANGER_ROLE");

    bool public direction; // true - on eth, false - on fantom
    IWrapperBridgedStandardERC20 public wBridgedStandartERC20;

    Pair[] private tokenPairs;

    uint public fee;

    // token => is allowed to bridge
    mapping(address => bool) public allowedTokens;

    modifier onlyAtStart {
        require(direction, "onlyAtStart");
        _;
    }

    modifier onlyAtEnd {
        require(!direction, "onlyAtEnd");
        _;
    }

    modifier onlyMessangerBot {
        require(hasRole(BOT_MESSANGER_ROLE, _msgSender()), "onlyMessangerBot");
        _;
    }

    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "onlyAdmin");
        _;
    }

    modifier tokenIsAllowed(address _token) {
        require(allowedTokens[_token], "invalidToken");
        _;
    }

    constructor(
        bool _direction,
        uint _fee,
        address _wBridgedStandardERC20,
        address _botMessanger,
        address _allowedToken,
        address _feeWallet,
        string memory _name,
        string memory _symbol
    ) {
        direction = _direction;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BOT_MESSANGER_ROLE, _botMessanger);
        if (_fee <= 100) {
            fee = _fee;
        }
        if (_wBridgedStandardERC20 != address(0)) {
            wBridgedStandartERC20 = IWrapperBridgedStandardERC20(_wBridgedStandardERC20);
        }
        if (_feeWallet != address(0)) {
            feeWallet = _feeWallet;
        }
        if (_direction) {
            allowedTokens[_allowedToken] = true;
        } else {
            _cloneAndInitializeTokenAtEndForTokenAtStart(_allowedToken, _name, _symbol);
        }
    }

    function evacuateTokens(address _token, uint256 _amount, address _to) external onlyAdmin {
        require(!allowedTokens[_token], "cannotEvacuateAllowedToken");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
    }

    function setAllowedToken(address _token, bool _status) external onlyAdmin {
        allowedTokens[_token] = _status;
    }

    function setFeeWallet(address _feeWallet) external onlyAdmin {
        require(_feeWallet != address(0), "Invalid address");
        feeWallet = _feeWallet;
    }

    function setfee(uint _fee) external onlyAdmin {
        require(_fee <= 100, "The fee is incorrectly specified");
        fee = _fee;
    }

//  добавить сумму комиссии в emit
    function requestBridgingToStart(
        address _tokenAtStart,
        address _tokenAtEnd,
        address _to,
        uint256 _amount
    ) external override onlyAtEnd tokenIsAllowed(_tokenAtEnd) {
        uint feeAmount = calcfeeAmount(_amount, fee);
        address sender = _msgSender();
        IWrapperBridgedStandardERC20(_tokenAtEnd).transferFrom(_msgSender(), feeWallet, feeAmount);
        IWrapperBridgedStandardERC20(_tokenAtEnd).burn(sender, _amount - feeAmount);
        emit RequestBridgingToStart(_tokenAtStart, _tokenAtEnd, sender, _to, _amount);
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
        IWrapperBridgedStandardERC20(tokenAtEnd).mint(_to, _amount);
        emit BridgingToEndPerformed(_tokenAtStart, tokenAtEnd, _to, _amount);
    }

    function _cloneAndInitializeTokenAtEndForTokenAtStart(
        address _tokenAtStart,
        string memory _name,
        string memory _symbol
    )
        internal
        returns(address tokenAtEnd)
    {
        tokenAtEnd = address(wBridgedStandartERC20).clone();
        tokenPairs.push(Pair({
          tokenAtStart: _tokenAtStart,
          tokenAtEnd: tokenAtEnd
        }));
        allowedTokens[tokenAtEnd] = true;
        IWrapperBridgedStandardERC20(tokenAtEnd).configure(
            address(this),
            _tokenAtStart,
            _name,
            _symbol
        );
    }

    function getEndTokenByStartToken(address _startToken) public view returns(address) {
        for (uint i = 0; i < tokenPairs.length; i++) {
            if (tokenPairs[i].tokenAtStart == _startToken) {
                return tokenPairs[i].tokenAtEnd;
            }
        }
        return address(0);
    }

    function getStartTokenByEndToken(address _endToken) external view returns(address) {
        for (uint i = 0; i < tokenPairs.length; i++) {
            if (tokenPairs[i].tokenAtEnd == _endToken) {
                return tokenPairs[i].tokenAtStart;
            }
        }
        revert('noStartTokenFound');
    }

    function calcFeeAmount(uint _amount, uint _fee) private pure returns(uint){
        return _amount * _fee / 1000; // 1000 - 100%
    }
}
