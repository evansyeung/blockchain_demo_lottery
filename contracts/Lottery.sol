// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

// is Ownable means inheriting this class from OpenZeppelin
// Also inherits VRFConsumerBase
contract Lottery is VRFConsumerBase, Ownable {
  address payable[] public players;
  address payable recentWinner;
  uint256 public randomness;
  uint256 public usdEntryFee;
  AggregatorV3Interface internal ethUsdPriceFeed;

  // Values are represented by OPEN=0, CLOSED=1, CALCULATING_WINNER=2
  enum LOTTERY_STATE {
    OPEN,
    CLOSED,
    CALCULATING_WINNER
  }

  LOTTERY_STATE public lottery_state;
  uint256 public fee;
  bytes32 public keyHash;
  event RequestedRandomness(bytes32 requestId);

  // After public, we can add any additional contrustors from inherited contracts
  constructor(address _priceFeedAddress, address _vrfCoordinator, address _link, uint256 _fee, bytes32 _keyHash) public VRFConsumerBase(_vrfCoordinator, _link) {
    usdEntryFee = 50 * (10**18);  // fee in wei
    ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
    lottery_state = LOTTERY_STATE.CLOSED;
    fee = _fee;
    keyHash = _keyHash;
  }

  function enter() public payable{
    // Lottery has to be open to enter
    require(lottery_state == LOTTERY_STATE.OPEN, "Lottery is not open!");
    // $50 minimum
    require(msg.value >= getEntranceFee(), "Not enough ETH!");
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

  function startLottery() public onlyOwner {
    require(lottery_state == LOTTERY_STATE.CLOSED, "Can't start a new lottery yet!");
    lottery_state = LOTTERY_STATE.OPEN;
  }

  function endLottery() public onlyOwner {
    lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
    bytes32 requestId = requestRandomness(keyHash, fee);
    emit RequestedRandomness(requestId);
  }

  // Internal -> only allow our VRFCoordinator to call this function
  // override -> Override VRFConsumerBase's fulfillRandomness function (which is meant to be overritten by us)
  function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
    require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You aren't there yet!");
    require(_randomness > 0, "random-not-found");
    uint256 indexOfWinner = _randomness % players.length;
    recentWinner = players[indexOfWinner];
    recentWinner.transfer(address(this).balance);
    // Reset lottery
    players = new address payable[](0);
    lottery_state = LOTTERY_STATE.CLOSED;
    randomness = _randomness;
  }
}
