// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

// 荷兰拍卖（Dutch auction）是一种落槌价从高往低递减的拍卖方式。
// 在荷兰拍卖中，卖家会先宣布拍卖品的最高价，然后从该价开始递减，一直到有买家接受了该价为止，成交价即为此时的价位。
// 荷兰拍卖常用于卖方数量超过买方数量的情况，也可以用于对品质相同但价格不同的商品进行定价。
// 近年来，荷兰拍卖在电子商务领域得到广泛应用，例如在一些电商平台上以荷兰拍卖的方式销售商品。

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract DutchAuction is Ownable, ERC721 {

    uint256 public constant COLLECTOIN_SIZE = 10000; // NFT总数
    uint256 public constant AUCTION_START_PRICE = 1 ether; // 起拍价(最高价)
    uint256 public constant AUCTION_END_PRICE = 0.1 ether; // 结束价(最低价/地板价)
    uint256 public constant AUCTION_TIME = 10 minutes; // 拍卖时间，为了测试方便设为10分钟
    uint256 public constant AUCTION_DROP_INTERVAL = 1 minutes; // 每过多久时间，价格衰减一次
    uint256 public constant AUCTION_DROP_PER_STEP =
        (AUCTION_START_PRICE - AUCTION_END_PRICE) /
        (AUCTION_TIME / AUCTION_DROP_INTERVAL); // 每次价格衰减步长
    
    uint256 public auctionStartTime; // 拍卖开始时间戳
    string private _baseTokenURI;   // metadata URI
    uint256[] private _allTokens; // 记录所有存在的tokenId 

    constructor() ERC721("WTF Dutch Auctoin", "WTF Dutch Auctoin") {
        auctionStartTime = block.timestamp;
    }

    // auctionStartTime setter函数，onlyOwner
    function setAuctionStartTime(uint32 timestamp) external onlyOwner {
        auctionStartTime = timestamp;
    }

    // 获取拍卖实时价格
    // 当block.timestamp小于起始时间，价格为最高价AUCTION_START_PRICE；
    // 当block.timestamp大于结束时间，价格为最低价AUCTION_END_PRICE；
    // 当block.timestamp处于两者之间时，则计算出当前的衰减价格。
    function getAuctionPrice()
        public
        view
        returns (uint256)
    {
        if (block.timestamp < auctionStartTime) {
        return AUCTION_START_PRICE;
        }else if (block.timestamp - auctionStartTime >= AUCTION_TIME) {
        return AUCTION_END_PRICE;
        } else {
        uint256 steps = (block.timestamp - auctionStartTime) /
            AUCTION_DROP_INTERVAL;
        return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
        }
    }

    // 拍卖mint函数
    // 该函数首先检查拍卖是否开始/铸造是否超出NFT总量。
    // 接着，合约通过getAuctionPrice()和铸造数量计算拍卖成本，并检查用户支付的ETH是否足够：
    // 如果足够，则将NFT铸造给用户，并退回超额的ETH；反之，则回退交易。
    function auctionMint(uint256 quantity) external payable{
        uint256 _saleStartTime = uint256(auctionStartTime); // 建立local变量，减少gas花费
        require(
        _saleStartTime != 0 && block.timestamp >= _saleStartTime,
        "sale has not started yet"
        ); // 检查是否设置起拍时间，拍卖是否开始
        require(
        totalSupply() + quantity <= COLLECTOIN_SIZE,
        "not enough remaining reserved for auction to support desired mint amount"
        ); // 检查是否超过NFT上限

        uint256 totalCost = getAuctionPrice() * quantity; // 计算mint成本
        require(msg.value >= totalCost, "Need to send more ETH."); // 检查用户是否支付足够ETH
        
        // Mint NFT
        for(uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            _mint(msg.sender, mintIndex);
            _addTokenToAllTokensEnumeration(mintIndex);
        }
        // 多余ETH退款
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost); //注意一下这里是否有重入的风险
        }
    }
}