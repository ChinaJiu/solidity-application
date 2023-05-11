// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

// 空投是币圈中一种营销策略，项目方将代币免费发放给特定用户群体。为了拿到空投资格，用户通常需要完成一些简单的任务，如测试产品、分享新闻、介绍朋友等。
// 项目方通过空投可以获得种子用户，而用户可以获得一笔财富，两全其美。
// 因为每次接收空投的用户很多，项目方不可能一笔一笔的转账。利用智能合约批量发放ERC20代币，可以显著提高空投效率。

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Airdrop {
  
    function getSum(uint256[] calldata _arr) private pure returns(uint num)  {
        for (uint i = 0; i < _arr.length; i++){
            num += _arr[i];
        }
    }

    // 授权后才能转账eth
    // 转账前需要approve()
    function multiTransferToken(address _token, address[] calldata _addresses, uint256[] calldata _amounts) external {
        // 检查：_addresses和_amounts数组的长度相等
        require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");

        IERC20 token = IERC20(_token);
    
        // 检查：授权代币数量 >= 空投代币总量
        require(token.allowance(msg.sender, address(this)) >= getSum(_amounts), "Need Approve ERC20 token");

        // for循环，利用transferFrom函数发送空投
        for (uint8 i = 0; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], _amounts[i]);
        }
     }
}