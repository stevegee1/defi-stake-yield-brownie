//SPDX-License-Identifier: MIT

//We want to be able to:
//stake tokens
//unstake tokens
//issuetokens
//add allowed tokens to be staked
//getETH value of tokens staked

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    //array of the allowed tokens
    address[] public allowedTokens;

    //address array of stakers with just added unique tokens in their wallet
    //users get rewarded with our DappToken by staking a unique token
    //this token must not be staked before by the user
    address[] public stakers;

    //mapping of token address per staker, per the amount
    mapping(address => mapping(address => uint256)) public stakingBalance;

    //this maps the user address to the number of unique token staked
    mapping(address => uint256) public uniqueTokenStaked;

    //this is the erc version of our reward token
    IERC20 public dappToken;

    //this maps each token to its chainlink priceFeed
    mapping(address => address) public tokenPriceFeedMapping;

    //We pass in our reward token address, dapp_token address
    constructor(address _dappTokenAddress) public {
        //this gives us the interface of our dapp_token erc20 standard
        dappToken = IERC20(_dappTokenAddress);
    }

    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    // this function can only be called by the owner
    function issueTokens() public onlyOwner {
        //Issue tokens to all stakers
        for (
            uint256 stakerIndex = 0;
            stakerIndex < stakers.length;
            stakerIndex++
        ) {
            address recipient = stakers[stakerIndex];
            //sending the stakers a token reward based on individual total value locked
            //dappToken.transfer(recipient, )
            uint256 usertotalValue = getUserTotalValue(recipient);
            //transfer the dappToken based on the user total value locked in each allowed token
            dappToken.transfer(recipient, usertotalValue);
        }
    }

    function unStakeTokens(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "staking balance cannot be zero");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokenStaked[msg.sender] = uniqueTokenStaked[msg.sender] - 1;
    }

    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 total_value = 0;
        require(uniqueTokenStaked[_user] > 0, "No token currently staked");
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            total_value =
                total_value +
                getEachAllowedTokenValueForEachUser(
                    _user,
                    allowedTokens[allowedTokensIndex]
                );
        }
        return total_value;
    }

    function getEachAllowedTokenValueForEachUser(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokenStaked[_user] <= 0) {
            return 0;
        }
        //get the price of the token*stakingBalance[_token][_user]
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return ((stakingBalance[_token][_user] * price) / (10**decimals));
    }

    //this function returns the value of each token according
    //AggregatorV3Interface chainlink priceFeed
    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        //priceFeed address
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimal = uint256(priceFeed.decimals());
        return (uint256(price), decimal);
    }

    //Users must stake allowed tokens
    //the function takes the amount and the token address the user want to stake
    function stakeTokens(uint256 _amount, address _token) public {
        //the amount must be greater than zero, it reverts if the user enters <=0
        require(_amount > 0, "the amount to stake must be greater than zero");

        //We have to check if the token the user wanna stake is allowed
        require(tokenIsAllowed(_token), "sorry, this token is not allowed");

        //if the token is allowed, we use IERC20 stadard of the token, method "transferFrom",
        //this method check the amount of this token and transfers it from the wallet of the
        //function caller to this contract
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        //this function check to see the number of unique tokens the function caller staked
        updateUniqueTokensStaked(msg.sender, _token);

        //this updates the amount of each token staked by each user
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;

        //this condition checks if the token has already been by the caller
        if (uniqueTokenStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    //this function updates the number of unique token staked by the user
    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_user][_token] <= 0) {
            uniqueTokenStaked[_user] = uniqueTokenStaked[_user] + 1;
        }
    }

    //this function can only be called by the owner of the contract
    //this function adds tokens that are allowed to be staked in the contract
    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    //this function handles the tokens the admin has allowed in this contract
    // it returns boolean in any case
    function tokenIsAllowed(address _token) public returns (bool) {
        for (
            uint256 tokenIndex = 0;
            tokenIndex < allowedTokens.length;
            tokenIndex++
        ) {
            if (allowedTokens[tokenIndex] == _token) {
                return true;
            }
        }
        return false;
    }
}
