// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTSwap {
    
    struct Order {
        uint256 price;
        address owner;
    }
    
    mapping(address => mapping(uint256 => Order)) public orders;

    event List(address indexed nftContract, uint256 indexed tokenId, uint256 price, address indexed owner);
    event Revoke(address indexed nftContract, uint256 indexed tokenId, address indexed owner);
    event Update(address indexed nftContract, uint256 indexed tokenId, uint256 price, address indexed owner);
    event Purchase(address indexed nftContract, uint256 indexed tokenId, address indexed buyer, uint256 price);

    function list(address nftContract, uint256 tokenId, uint256 price) external {
        IERC721 nft = IERC721(nftContract);
        
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner of the NFT");
        require(nft.getApproved(tokenId) == address(this), "Contract not approved to transfer this NFT");
        require(orders[nftContract][tokenId].owner == address(0), "Existing order for this NFT");

        orders[nftContract][tokenId] = Order({
            price: price,
            owner: msg.sender
        });

        emit List(nftContract, tokenId, price, msg.sender);
    }

    function revoke(address nftContract, uint256 tokenId) external {
        Order memory order = orders[nftContract][tokenId];
        
        require(order.owner == msg.sender, "You are not the owner of this order");

        delete orders[nftContract][tokenId];

        emit Revoke(nftContract, tokenId, msg.sender);
    }

    function update(address nftContract, uint256 tokenId, uint256 newPrice) external {
        Order storage order = orders[nftContract][tokenId];
        
        require(order.owner == msg.sender, "You are not the owner of this order");

        order.price = newPrice;

        emit Update(nftContract, tokenId, newPrice, msg.sender);
    }

    function purchase(address nftContract, uint256 tokenId) external payable {
        Order memory order = orders[nftContract][tokenId];
        
        require(order.owner != address(0), "No order exists for this NFT");
        require(msg.value >= order.price, "Insufficient payment");

        IERC721 nft = IERC721(nftContract);
        
        nft.safeTransferFrom(order.owner, msg.sender, tokenId);
        
        payable(order.owner).transfer(order.price);
        
        delete orders[nftContract][tokenId];

        emit Purchase(nftContract, tokenId, msg.sender, order.price);
    }
}
