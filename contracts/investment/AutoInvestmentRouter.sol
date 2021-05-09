// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './AutoInvestment.sol';
import '../libraries/TransferHelper.sol';
import '../core/Adminable.sol';
import '../core/Swapable.sol';
import '../core/SwapStorage.sol';
import 'hardhat/console.sol';

contract AutoInvestmentRouter is Adminable, Swapable {
    using SafeMath for uint256;

    constructor(address _adminStorage, address _swapStorage) 
        Adminable(_adminStorage)
        Swapable(_swapStorage)
    {
    }

    function getPrice(address _token, address _base) public view returns (uint256) {
        if (_token == _base) {
            return 10 ** 18;
        }
        SwapStorage.PathItem memory item = pathFor(_token, _base);
        require(item.path.length > 0 && item.pair.length > 0 && item.path.length == item.pair.length + 1, "path not exist");
        uint price = 10 ** 18;
        for (uint index = item.pair.length - 1; index + 1 > 0; index --) {
            uint amount0 = IERC20(item.path[index + 1]).balanceOf(item.pair[index]);
            uint amount1 = IERC20(item.path[index]).balanceOf(item.pair[index]);
            price = price.mul(amount0).div(amount1);
        }
        return price;
    }

    function getPrices(address[] memory _token, address _base) external view returns (uint256[] memory prices) {
        prices = new uint256[](_token.length); 
        for (uint i = 0; i < _token.length; i ++) {
            prices[i] = getPrice(_token[i], _base);
        }
    }

    struct PoolInfo {
        address pool;
        address masterChef;
        address rewardToken;
        address lpToken;
        uint256 pid;
    }

    PoolInfo[] public poolInfoList;
    mapping(address => uint256) public poolInfoMap;

    function addPool(address _pool, address _masterChef, address _rewardToken, address _lpToken, uint _pid) external {
        PoolInfo memory poolInfo;
        poolInfo.pool = _pool;
        poolInfo.masterChef = _masterChef;
        poolInfo.rewardToken = _rewardToken;
        poolInfo.lpToken = _lpToken;
        poolInfo.pid = _pid;
        poolInfoList.push(poolInfo);
        poolInfoMap[_pool] = poolInfoList.length;
    }

    function setPool(uint256 _index, address _pool, address _masterChef, address _rewardToken, address _lpToken, uint _pid) external {
        require(_index < poolInfoList.length, "illegal pool index");
        poolInfoList[_index].pool = _pool;
        poolInfoList[_index].masterChef = _masterChef;
        poolInfoList[_index].rewardToken = _rewardToken;
        poolInfoList[_index].lpToken = _lpToken;
        poolInfoList[_index].pid = _pid;
    }

    function delPool(uint256 _index) external {
        require(_index < poolInfoList.length, "illegal pool index");
        uint lastIndex = poolInfoList.length - 1;
        poolInfoMap[poolInfoList[_index].pool] = 0;
        poolInfoList[_index].pool = poolInfoList[lastIndex].pool;
        poolInfoList[_index].masterChef = poolInfoList[lastIndex].masterChef;
        poolInfoList[_index].rewardToken = poolInfoList[lastIndex].rewardToken;
        poolInfoList[_index].lpToken = poolInfoList[lastIndex].lpToken;
        poolInfoList[_index].pid = poolInfoList[lastIndex].pid;
        poolInfoMap[poolInfoList[_index].pool] = _index + 1;
        poolInfoList.pop();
    }

    function getPoolInfoNum() external view returns (uint256) {
        return poolInfoList.length;
    }

    function getPoolInfoByPool(address pool) external view returns(PoolInfo memory poolInfo) {
        require(poolInfoMap[pool] > 0, "pool not exists");
        poolInfo = poolInfoList[poolInfoMap[pool] - 1];
    }

    function getAllPoolInfo() external view returns (PoolInfo[] memory list) {
        list = poolInfoList;
    }

    function deposit(
        address automoulde,
        uint256 amount,
        address to
    ) external {
        address pair = AutoInvestment(automoulde).lpToken();
        TransferHelper.safeTransferFrom(pair, msg.sender, automoulde, amount);
        AutoInvestment(automoulde).deposit(to);
    }

    function withdraw(
        address automoulde,
        uint256 liquidity,
        address to
    ) external {
        TransferHelper.safeTransferFrom(automoulde, msg.sender, automoulde, liquidity);
        AutoInvestment(automoulde).withdraw(to);
    }

    function doHardWork() external {
        for (uint i = 0; i < poolInfoList.length; i ++) {
            AutoInvestment(poolInfoList[i].pool).doHardWork();
        }
    }

    function getExchangeRate(address pool) public view returns (uint256) {
        return AutoInvestment(pool).getExchangeRate();
    }

    function accountSnapshot(address pool, address account) external view returns (uint256 deposited, uint256 balance, uint256 exchangeRate, uint256 timestamp) {
        return AutoInvestment(pool).accountSnapshot(account);
    }

}
