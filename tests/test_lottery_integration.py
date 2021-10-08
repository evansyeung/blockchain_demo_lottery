from brownie import network
from scripts.deploy_lottery import deploy_lottery
from scripts.helpful_scripts import LOCAL_BLOCKCHAIN_ENVIRONMENTS, fund_with_link, get_account
from scripts.deploy_lottery import deploy_lottery
import pytest
import time


def test_can_pick_winner():
  # Integration test on a real testnet not local chains
  if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
    pytest.skip()

  lottery = deploy_lottery()
  account = get_account()
  lottery.startLottery({"from": account})
  lottery.enter({"from": account, "value": lottery.getEntranceFee()})
  lottery.enter({"from": account, "value": lottery.getEntranceFee()})
  fund_with_link(lottery)
  lottery.endLottery({"from": account})
  # Different from unit tests, we do not need to pretend to be the VRFCoordinator
  time.sleep(60)  # wait for VRFCoordinator
  assert lottery.recentWinner() == account
  assert lottery.balance() == 0
