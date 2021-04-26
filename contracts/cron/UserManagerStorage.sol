// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

import '../admin/AdminableInit.sol';

contract UserManagerStorage is AdminableInit {
    //最小的手续费
    uint256 public minFee;
    //除正常执行外,额外扣除的手续费
    uint256 public additionFee;
    address public feeReceiver;

    event NewMinFee(uint256 oldMinFee, uint256 newMinFee);

    event NewAdditionFee(uint256 oldAdditionFee, uint256 newAdditionFee);

    event NewFeeReceiver(address oldReceiver, address newFeeReceiver);

    function _setMinFee(uint256 newMinFee) private {
        uint256 oldMinFee = minFee;
        minFee = newMinFee;
        emit NewMinFee(oldMinFee, minFee);
    }

    function _setAdditionFee(uint256 newAdditionFee) private {
        uint256 oldAdditionFee = additionFee;
        additionFee = newAdditionFee;
        emit NewAdditionFee(oldAdditionFee, additionFee);
    }

    function _setFeeReceiver(address newFeeReceiver) private {
        require(newFeeReceiver != address(0), 'illegal feeReceiver');
        address oldFeeReceiver = feeReceiver;
        feeReceiver = newFeeReceiver;
        emit NewFeeReceiver(oldFeeReceiver, newFeeReceiver);
    }

    constructor() {}

    function initialize(address _store) public initializer {
        initializeAdmin(_store);
    }

    function setMinFee(uint256 newMinFee) external onlyAdmin {
        _setMinFee(newMinFee);
    }

    function setAdditionFee(uint256 newAdditionFee) external onlyAdmin {
        _setAdditionFee(newAdditionFee);
    }

    function setFeeReceiver(address newFeeReceiver) external onlyAdmin {
        _setFeeReceiver(newFeeReceiver);
    }
}
