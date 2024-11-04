// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/PublicAuction.sol";

contract PublicAuctionTest is Test {
    PublicAuction public auction;
    address seller = address(1);
    address bidder1 = address(2);
    address bidder2 = address(3);
    uint biddingTime = 1 hours;

    function setUp() public {
        vm.prank(seller);
        auction = new PublicAuction(biddingTime);
    }
	
	// 测试合约初始变量是否设置正确
    function testInitialState() public {
        assertEq(auction.seller(), seller);
        assertEq(auction.auctionEndTime(), block.timestamp + biddingTime);
        assertEq(auction.ended(), false);
    }
    
	// 测试竞拍逻辑
    function testBid() public {
        vm.prank(bidder1);
        vm.deal(bidder1, 1 ether);
        auction.bid{value: 1 ether}();

        assertEq(auction.highestBidder(), bidder1);
        assertEq(auction.highestBid(), 1 ether);
    }
    
    // 测试竞拍金额低于当前价格的情况
    function testBidFailsWhenLower() public {
        vm.prank(bidder1);
        vm.deal(bidder1, 2 ether);
        auction.bid{value: 2 ether}();

        vm.prank(bidder2);
        vm.deal(bidder2, 1 ether);
        // 预期合约回滚并返回特定的错误消息
        vm.expectRevert("There already is a higher bid");
        auction.bid{value: 1 ether}();
    }
	
	// 测试竞拍结束后竞拍的行为
    function testBidFailsWhenAuctionEnded() public {
        vm.warp(block.timestamp + biddingTime + 1);
        vm.prank(bidder1);
        vm.deal(bidder1, 1 ether);
        vm.expectRevert("Auction has ended");
        auction.bid{value: 1 ether}();
    }
    
    // 测试提款逻辑
    function testWithdraw() public {
        vm.prank(bidder1);
        vm.deal(bidder1, 2 ether);
        auction.bid{value: 1 ether}();

        vm.prank(bidder2);
        vm.deal(bidder2, 2 ether);
        auction.bid{value: 2 ether}();

        uint initialBalance = bidder1.balance;
        vm.prank(bidder1);
        auction.withdraw();
        assertEq(bidder1.balance, initialBalance + 1 ether);
    }
	
	// 测试拍卖结算逻辑
    function testEndAuction() public {
        vm.prank(bidder1);
        vm.deal(bidder1, 1 ether);
        auction.bid{value: 1 ether}();

        vm.warp(block.timestamp + biddingTime + 1);
        
        uint initialSellerBalance = seller.balance;
        vm.prank(seller);
        auction.endAuction();

        assertEq(auction.ended(), true);
        assertEq(seller.balance, initialSellerBalance + 1 ether);
    }
    
    // 测试非拍卖方调用endAuction()的行为
    function testEndAuctionFailsWhenNotSeller() public {
        vm.warp(block.timestamp + biddingTime + 1);
        vm.prank(bidder1);
        vm.expectRevert("Only seller can end auction");
        auction.endAuction();
    }
	
	// 测试未结束时调用endAuction()的行为
    function testEndAuctionFailsWhenStillOngoing() public {
        vm.prank(seller);
        vm.expectRevert("Auction is still ongoing");
        auction.endAuction();
    }
    
    // 测试: 冷却时间机制
    function testCooldownPeriod() public {
        vm.startPrank(bidder1);
        vm.deal(bidder1, 3 ether);
        auction.bid{value: 1 ether}();

        vm.expectRevert("Cooldown period not passed");
        auction.bid{value: 2 ether}();

        vm.warp(block.timestamp + 1 minutes + 1);
        auction.bid{value: 2 ether}();
        vm.stopPrank();
    }
    
    // 测试: 最后5分钟投票，时间延长5分钟的机制
    function testExtensionTime() public {
        vm.warp(block.timestamp + biddingTime - 4 minutes);
        
        vm.prank(bidder1);
        vm.deal(bidder1, 1 ether);
        auction.bid{value: 1 ether}();
        assertEq(auction.auctionEndTime(), block.timestamp + 9 minutes);
    }
    
    // 测试: 最后5分钟的投票，竞标金额不小于当前价格的110%
    function testWeightedBid() public {
    	vm.startPrank(bidder1);
    	vm.deal(bidder1, 5 ether);
    	auction.bid{value: 0.99 ether}();
	vm.warp(block.timestamp + 1 minutes);
    	auction.bid{value: 1 ether}();
    	assertEq(auction.highestBid(), 1 ether);
    	
    	vm.warp(block.timestamp + biddingTime - 3 minutes);
    	vm.expectRevert("Weighted bid not high enough");
    	auction.bid{value: 1.05 ether}();
    	
    	auction.bid{value: 1.1 ether}();
    	assertEq(auction.highestBid(), 1.1 ether);
	vm.stopPrank();
    }
}
