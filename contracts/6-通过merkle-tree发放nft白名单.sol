// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

//https://lab.miguelmota.com/merkletreejs/example/  Merkle Tree 生成网站


// Merkle Tree允许对大型数据结构的内容进行有效和安全的验证（Merkle Proof）
// 利用 Merkle Tree 发放 NFT 白名单是一种常见的方法，它可以有效地验证地址是否在白名单中，以控制 NFT 的访问或交易权限。

// 创建白名单：首先，你需要创建一个包含被授权地址的白名单列表。这可以是一个简单的文本文件、数据库或其他数据结构。
// 构建 Merkle Tree：使用白名单中的地址构建 Merkle Tree 数据结构。Merkle Tree 是一种哈希树结构，用于有效地验证数据的完整性和证明数据是否属于某个集合。将白名单中的地址作为叶节点，并计算每个节点的哈希值，直到得到根节点的哈希值。
// 生成 Merkle Root：从 Merkle Tree 中获取根节点的哈希值，称为 Merkle Root。Merkle Root 是整个 Merkle Tree 的唯一标识。
// 发放 NFT 白名单：将 Merkle Root 作为一个参数嵌入到 NFT 合约中。可以通过合约的构造函数或特定的函数来传递 Merkle Root。
// 验证地址：当用户希望验证其地址是否在白名单中时，他们可以提供其地址和相应的 Merkle Proof。Merkle Proof 是一组路径节点，用于验证某个叶节点在 Merkle Tree 中的位置。
// 验证过程：合约通过计算用户地址和 Merkle Proof 的哈希值，与 Merkle Root 进行比较。如果匹配成功，则表示地址在白名单中，用户可以获得相应的权限。

library MerkleProof {
    /**
     * @dev 当通过`proof`和`leaf`重建出的`root`与给定的`root`相等时，返回`true`，数据有效。
     * 在重建时，叶子节点对和元素对都是排序过的。
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) public pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns 通过Merkle树用`leaf`和`proof`计算出`root`. 当重建出的`root`和给定的`root`相同时，`proof`才是有效的。
     * 在重建时，叶子节点对和元素对都是排序过的。
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    // Sorted Pair Hash
    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
    }
}

contract MerkleTree is ERC721 {

    bytes32 immutable public root; // Merkle树的根
    mapping(address => bool) public mintedAddress;   // 记录已经mint的地址

    constructor(string memory name, string memory symbol, bytes32 merkleroot) ERC721(name, symbol){
        root = merkleroot;
    }

    // 利用Merkle树验证地址并完成mint
    function mint(address account, uint256 tokenId, bytes32[] calldata proof)
    external
    {
        require(_verify(_leaf(account), proof), "Invalid merkle proof"); // Merkle检验通过
        require(!mintedAddress[account], "Already minted!"); // 地址没有mint过
        _mint(account, tokenId); // mint
        mintedAddress[account] = true; // 记录mint过的地址
    }

    // 计算Merkle树叶子的哈希值
    function _leaf(address account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    // Merkle树验证，调用MerkleProof库的verify()函数
    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns(bool) {   
        return  MerkleProof.verify(proof, root, leaf);
    }
}