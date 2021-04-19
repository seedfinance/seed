// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

interface IMasterChef {
    function poolInfo(uint256 pid)
        external
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accSushiPerShare
        );

    function userInfo(uint256 pid, address from) external view returns (uint256 amount, uint256 rewardDebt);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external view;

    function emergencyWithdraw(uint256 _pid) external;
}
