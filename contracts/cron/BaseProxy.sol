// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
import "./User.sol";
import "../interface/IERC2612.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/UpgradeableProxy.sol";

contract BaseProxy is UpgradeableProxy {

    bytes32 private constant _CANUPDATE_SLOT = 0x3c02e515b32f677002b87e0aba495d5507b9fd353e0278e1e6e5c69d60538042;

    constructor(address _imp, bool _canUpdate) 
        UpgradeableProxy(_imp, new bytes(0))
    {
        require(_CANUPDATE_SLOT == bytes32(uint256(keccak256("eip1967.baseproxy.canupdate")) - 1));
        bytes32 slot = _CANUPDATE_SLOT;
        uint _val = _canUpdate ? 1 : 0;
        assembly {
            sstore(slot, _val)
        }
    }

    function upgradeTo(address _imp) external {
        bytes32 slot = _CANUPDATE_SLOT;
        uint256 canUpdate = 0;
        assembly {
            canUpdate := sload(slot)
        }
        require(canUpdate == 1, "contract cannot update");
        _upgradeTo(_imp);
    }
}
