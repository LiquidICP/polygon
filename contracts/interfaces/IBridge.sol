pragma solidity ^0.8.0;

interface IBridge {

    event RequestBridgingToStart(
        address indexed _tokenAtStart,
        address indexed _tokenAtEnd,
        address indexed _from,
        address _to,
        uint256 _amount
    );

    event BridgingToEndPerformed(
        address indexed _tokenAtStart,
        address indexed _tokenAtEnd,
        address indexed _to,
        uint256 _amount
    );

    function requestBridgingToStart(
        address _tokenAtStart,
        address _tokenAtEnd,
        address _to,
        uint256 _amount
    ) external;

    function performBridgingToEnd(
        address _tokenAtStart,
        address _to,
        uint256 _amount,
        string memory _name,
        string memory _symbol
    ) external;

}
