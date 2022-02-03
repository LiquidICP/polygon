// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBridge {

    event RequestBridgingToStart(
        address indexed _token,
        address indexed _from,
        uint256 _amount
    );

    event BridgingToEndPerformed(
        address indexed _token,
        address indexed _to,
        uint256 _amount
    );

    function requestBridgingToStart(
        uint256 _amount
    ) external;

    function performBridgingToEnd(
        address _to,
        uint256 _amount,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external;

}
