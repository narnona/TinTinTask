// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AMMPool {
    IERC20 public token;
    IERC20 public weth;
    
    uint256 public reserveToken;
    uint256 public reserveWETH;

    // 初始化ERC20代币和wETH
    constructor(IERC20 _token, IERC20 _weth) {
        token = _token;
        weth = _weth;
    }

    // 添加流动性
    function addLiquidity(uint256 tokenAmount, uint256 wethAmount) public {
        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");
        require(weth.transferFrom(msg.sender, address(this), wethAmount), "WETH transfer failed");
        
        reserveToken += tokenAmount;
        reserveWETH += wethAmount;
    }

    // 根据常数乘积公式计算换出的数量
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256) {
        require(amountIn > 0, "Amount in must be greater than zero");
        uint256 amountInWithFee = amountIn * 997;  // 0.3% fee
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        return numerator / denominator;
    }

    // wETH -> Token
    function swapWETHForToken(uint256 wethAmount) public {
        uint256 tokenOut = getAmountOut(wethAmount, reserveWETH, reserveToken);

        require(weth.transferFrom(msg.sender, address(this), wethAmount), "WETH transfer failed");
        require(token.transfer(msg.sender, tokenOut), "Token transfer failed");

        reserveWETH += wethAmount;
        reserveToken -= tokenOut;
    }

    // Token -> wETH
    function swapTokenForWETH(uint256 tokenAmount) public {
        uint256 wethOut = getAmountOut(tokenAmount, reserveToken, reserveWETH);

        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");
        require(weth.transfer(msg.sender, wethOut), "WETH transfer failed");

        reserveToken += tokenAmount;
        reserveWETH -= wethOut;
    }

    // 移除流动性
    function removeLiquidity(uint256 tokenAmount, uint256 wethAmount) public {
        require(tokenAmount <= reserveToken, "Not enough token reserve");
        require(wethAmount <= reserveWETH, "Not enough WETH reserve");

        require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");
        require(weth.transfer(msg.sender, wethAmount), "WETH transfer failed");

        reserveToken -= tokenAmount;
        reserveWETH -= wethAmount;
    }
}
