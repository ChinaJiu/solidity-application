// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenContract {
    uint256 public amountAllowed = 100; // 单位 wei
    address public tokenContract; // 合约地址
    mapping (address => bool) public requestedAddress; // 集合

    event SendToken(address indexed Receiver, uint256 indexed Amount); 

    constructor(address _tokenContract) {
        tokenContract = _tokenContract;
    }

    function requestTokens() external {
        // 每个账户只能领取一次
        require(requestedAddress[msg.sender] == false, "Can't Request Multiple Times!");
        IERC20 token = IERC20(tokenContract); // 创建IERC20合约对象
        require(token.balanceOf(address(this)) >= amountAllowed, "Faucet Empty!");
        token.transfer(msg.sender, amountAllowed);
        requestedAddress[msg.sender] = true;
        emit SendToken(msg.sender, amountAllowed);
    }
}

