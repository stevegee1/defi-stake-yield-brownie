from web3 import Web3
import pytest


@pytest.fixture
def amount_staked():
    return Web3.toWei(2, "ether")
