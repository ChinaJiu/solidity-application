// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

// 当人渴的时候，就要去水龙头接水；当人想要免费代币的时候，就要去代币水龙头领。代币水龙头就是让用户免费领代币的网站/应用。
// 这里，我们实现一个简版的ERC20水龙头，逻辑非常简单：我们将一些ERC20代币转到水龙头合约里，用户可以通过合约的requestToken()函数来领取100单位的代币，每个地址只能领一次。

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

