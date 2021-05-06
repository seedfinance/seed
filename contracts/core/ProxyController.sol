// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

import '@openzeppelin/contracts/proxy/ProxyAdmin.sol';
import './Adminable.sol';

contract ProxyController is Adminable, ProxyAdmin {
    constructor(address _store) Adminable(_store) {}

    function changeProxyAdmin(TransparentUpgradeableProxy, address) public view override onlyAdmin {
        require(false, 'proxy admin cannot change');
    }

    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public override onlyAdmin {
        proxy.upgradeTo(implementation);
    }

    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable override onlyAdmin {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}
