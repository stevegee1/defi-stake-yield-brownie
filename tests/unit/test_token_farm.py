from brownie import accounts, network, exceptions
import pytest
from web3 import Web3
from scripts.deploy import deploy_token_farm_and_dapp_token


from scripts.helpful_scripts import (
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
    get_account,
    get_contract,
)

# this function test priceFeedContract in tokenFarm contract
def test_set_priceFeedContract():
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("only for local testing")
    account = get_account()
    non_owner = get_account(index=1)
    token_farm, dapp_token = deploy_token_farm_and_dapp_token()

    # Arrange
    token_farm.setPriceFeedContract(
        dapp_token.address, get_contract("eth_usd_price_feed"), {"from": account}
    )
    # Assert
    assert token_farm.tokenPriceFeedMapping(dapp_token.address) == get_contract(
        "eth_usd_price_feed"
    )
    # this raises an exception if this method is called by the non-owner
    with pytest.raises(exceptions.VirtualMachineError):
        token_farm.setPriceFeedContract(
            dapp_token.address, get_contract("eth_usd_price_feed"), {"from": non_owner}
        )


def test_stake_token(amount_staked):
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("only for local testing")
    account = get_account()
    token_farm, dapp_token = deploy_token_farm_and_dapp_token()
    # Act
    dapp_token.approve(token_farm.address, amount_staked, {"from": account})
    token_farm.stakeTokens(amount_staked, dapp_token.address, {"from": account})
    # Assert
    assert (
        token_farm.stakingBalance(dapp_token.address, account.address) == amount_staked
    )

    assert token_farm.uniqueTokenStaked(account.address) == 1
    assert token_farm.stakers(0) == account.address
    return token_farm, dapp_token


def test_issue_tokens(amount_staked):

    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("only for local testing")
    account = get_account()
    token_farm, dapp_token = test_stake_token(amount_staked)
    starting_balance = dapp_token.balanceOf(account.address)
    token_farm.issueTokens({"from": account})


def test_tokenIsAllowed(amount_staked):

    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("only for local testing")
    account = get_account()
    token_farm, dapp_token = test_stake_token(amount_staked)
    token_farm.tokenIsAllowed(dapp_token.address, {"from": account})
    assert token_farm.allowedTokens(0) == dapp_token.address


def test_addAllowedTokens(amount_staked):
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("only for local testing")
    account = get_account()
    non_owner = get_account(1)
    token_farm, dapp_token = test_stake_token(amount_staked)
    token_farm.addAllowedTokens(dapp_token.address, {"from": account})
    assert token_farm.allowedTokens(0) == dapp_token.address
    with pytest.raises(exceptions.VirtualMachineError):
        token_farm.addAllowedTokens(dapp_token.address, {"from": non_owner})


def test_getTokenVAlue():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("only for local testing")
    account = get_account()
    token_farm, dapp_token = deploy_token_farm_and_dapp_token()
    assert token_farm.getTokenValue(dapp_token.address) == (
        Web3.toWei(2, "ether"),
        18,
    )


# def test_getUserTotalValue():

#     if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
#         pytest.skip("only for local testing")
#     account = get_account()
#     token_farm, dapp_token = deploy_token_farm_and_dapp_token()
