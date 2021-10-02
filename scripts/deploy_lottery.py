from helpful_scripts import get_account, get_contract
from brownie import Lottery


def deploy_lottery():
  account = get_account()
  lottery = Lottery.deploy(
    get_contract("eth_usd_price_feed").address
  )

def main():
  deploy_lottery()
