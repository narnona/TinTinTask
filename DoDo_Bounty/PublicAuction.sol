// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract PublicAuction {
    address payable public seller;   // 卖家
    uint public auctionEndTime;      // 拍卖结束时间
    uint public cooldownPeriod = 1 minutes;  // 冷却期
    uint public extensionTime = 5 minutes;   // 延长时间

    address public highestBidder;    // 最高价竞拍者
    uint public highestBid;          // 当前最高价格
    
    mapping(address => uint) public pendingReturns;   // 待退还金额
    mapping(address => uint) public lastBidTime;      // 竞拍者最新竞拍时间

    bool public ended;   // 拍卖是否结束

    // 竞拍事件
    event HighestBidIncreased(address bidder, uint amount);
    // 拍卖结束事件
    event AuctionEnded(address winner, uint amount);

    // 合约初始化: 设置卖家地址、拍卖结束时间
    constructor(uint _biddingTime) {
        seller = payable(msg.sender);
        auctionEndTime = block.timestamp + _biddingTime;
    }

    // 竞拍逻辑
    function bid() external payable {
        require(block.timestamp <= auctionEndTime, "Auction has ended");
        require(msg.value > highestBid, "There already is a higher bid");
        require(
            block.timestamp >= lastBidTime[msg.sender] + cooldownPeriod,
            "Cooldown period not passed"
        );

        // 当在拍卖最后5分钟内有人竞拍，则需要加权出价并延长拍卖时间
        if (auctionEndTime - block.timestamp <= 5 minutes) {
            uint weightedBid = msg.value * 110 / 100; // 加权出价（按1.1倍计算）
            require(weightedBid > highestBid, "Weighted bid not high enough");
            auctionEndTime += extensionTime;  // 延长拍卖时间
        }

        // 退还之前的最高出价者
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        lastBidTime[msg.sender] = block.timestamp;

        emit HighestBidIncreased(msg.sender, msg.value);
    }

    // 退还竞拍金额逻辑
    function withdraw() external {
        uint amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds to withdraw");

        pendingReturns[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    // 结束拍卖
    function endAuction() external {
        require(msg.sender == seller, "Only seller can end auction");
        require(block.timestamp >= auctionEndTime, "Auction is still ongoing");
        require(!ended, "Auction already ended");

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        // 将最终收益发送给卖家
        (bool success, ) = seller.call{value: highestBid}("");
        require(success, "Transfer to seller failed");
    }
}
