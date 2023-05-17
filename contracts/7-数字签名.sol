// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

// 以太坊中的数字签名ECDSA，以及如何利用它发放NFT白名单。

// 由于签名是链下的，不需要gas，因此这种白名单发放模式比Merkle Tree模式还要经济；
// 但由于用户要请求中心化接口去获取签名，不可避免的牺牲了一部分去中心化；
// 额外还有一个好处是白名单可以动态变化，而不是提前写死在合约里面了，因为项目方的中心化后端接口可以接受任何新地址的请求并给予白名单签名。

// 测试
// _account: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// _tokenId: 0
// _signature: 0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SignatureNFT is ERC721 {
    address immutable public signer; // 签名地址
    mapping (address => bool) public mintedAddress;  // 记录已经mint的地址

    constructor (string memory name, string memory symbol, address _signer) ERC721(name, symbol){
        signer = _signer;
    }

    // 利用ECDSA验证签名并mint
    function mint(address _account, uint _tokenId, bytes memory _signature) external {
        bytes32 _msgHash = getMessageHash(_account, _tokenId);
        bytes32 _ethSignedMessageHash = ECDSA.toEthSignedMessageHash(_msgHash);
        require(verify(_ethSignedMessageHash, _signature), "Invalid signature");
        require(!mintedAddress[_account], "Already minted!"); // 地址没有mint过
        _mint(_account, _tokenId);
        mintedAddress[_account] = true;
    }

    /*
     * 将mint地址（address类型）和tokenId（uint256类型）拼成消息msgHash
     * _account: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * _tokenId: 0
     * 对应的消息: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
     */
    function getMessageHash(address _account, uint256 _tokenId) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_account, _tokenId));
    }

    // ECDSA验证，调用ECDSA库的verify()函数
    function verify(bytes32 _msgHash, bytes memory _signature)
    public view returns (bool)
    {
        return ECDSA.recover(_msgHash, _signature) == signer;
    }
}