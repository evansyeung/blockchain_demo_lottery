// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract Lottery {
  address payable[] public players;
  uint256 usdEntryFee;
  AggregatorV3Interface internal ethUsdPriceFeed;

  constructor(address _priceFeedAddress) public {
    usdEntryFee = 50 * (10**18);  // fee in wei
    ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
  }

  function enter() public {
    // $50 minimum
    // require();

    players.push(msg.sender);
  }

  function getEntranceFee() public view  returns (uint256) {
    // NOTE: Since we're doing math, its recommended to use SafeMath functions
    (,int256 price,,,) = ethUsdPriceFeed.latestRoundData();
    uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
    // $50, $2,000 / ETH
    // 50/2,000
    // 50 * 100000 / 2000
    uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
    return costToEnter;
  }

  function startLottery() public {

  }

  function endLottery() public {

  }
}
