// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import "../admin/AdminableInit.sol";

contract UserManagerStorage is AdminableInit {
    //最小的手续费
    uint public minFee;
    //除正常执行外,额外扣除的手续费
    uint public additionFee;
    address public feeReceiver;

    event NewMinFee(uint oldMinFee, uint newMinFee);

    event NewAdditionFee(uint oldAdditionFee, uint newAdditionFee);

    event NewFeeReceiver(address oldReceiver, address newFeeReceiver);

    function _setMinFee(uint newMinFee) private {
        uint oldMinFee = minFee;
        minFee = newMinFee;
        emit NewMinFee(oldMinFee, minFee);
    }

    function _setAdditionFee(uint newAdditionFee) private {
        uint oldAdditionFee = additionFee;
        additionFee = newAdditionFee;
        emit NewAdditionFee(oldAdditionFee, additionFee);
    }

    function _setFeeReceiver(address newFeeReceiver) private {
        require(newFeeReceiver != address(0), "illegal feeReceiver");
        address oldFeeReceiver = feeReceiver;
        feeReceiver = newFeeReceiver;
        emit NewFeeReceiver(oldFeeReceiver, newFeeReceiver);
    }

    constructor() {}

    function initialize(address _store) public initializer {
        AdminableInit.initializeAdmin(_store);
    }

    function setMinFee(uint newMinFee) external onlyAdmin {
        _setMinFee(newMinFee);
    }

    function setAdditionFee(uint newAdditionFee) external onlyAdmin {
        _setAdditionFee(newAdditionFee);
    }

    function setFeeReceiver(address newFeeReceiver) external onlyAdmin {
        _setFeeReceiver(newFeeReceiver);
    }

}
