// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../admin/AdminableInit.sol";
import "../../interface/IMdexChef.sol";
import "../../interface/IMdexFactory.sol";
import "../../interface/ISwapStorage.sol";

import "../../interface/IMdexPair.sol";
import "../../libraries/TransferHelper.sol";
import "../../libraries/SwapLibrary.sol";
import "../../libraries/SwapLibraryInternal.sol";
import '../../libraries/LiquidityLibrary.sol';


contract CustomAutoInvestment is AdminableInit {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public tokenReward; // pair reward address
    IMdexChef public pool; // mdx chef
    uint256 public pid;
    address public pair; // mdex pair, Address of LP contract address.
    address public factory; // mdx factory

    ISwapStorage swapStore; // swap stroage

    address public receiver; // receiver address
    address public newInvest; // new invest
    uint256 public overlapRate; // overlap

    constructor(){}

    function initialize(
        address _adminStore,
        address _swapStore,
        address _tokenReward,
        address _mdxChef,
        uint256 _mdxChefPid,
        address _pair,
        address _factory,
        address _receiver,
        address _newInvest,
        uint256 _overlapRate
    )  public {
        AdminableInit.initializeAdmin(_adminStore);
        swapStore = ISwapStorage(_swapStore);
        tokenReward = _tokenReward;
        pool = IMdexChef(_mdxChef);
        pid = _mdxChefPid;
        pair = _pair;
        factory = _factory;
        receiver = _receiver;
        newInvest = _newInvest;
        overlapRate = _overlapRate;
    }

    function setTokenReward(address _tokenReword) external onlyAdmin  {
       tokenReward = _tokenReword;
    }

    function setNewInvest(address _newInvest) external onlyAdmin {
        newInvest = _newInvest;
    }
    function setOverlapRate(uint256 _overlapRate) external onlyAdmin {
        overlapRate = _overlapRate;
    }
    
    function pairFor(address tokenA, address tokenB) internal view returns (address pair){
        pair = IMdexFactory(factory).getPair(tokenA, tokenB);
    }
    function swapTokensForExactTokens(
        address tokenA,
        address tokenB,
        uint amountOut,
        address to
    ) public {
        ISwapStorage.PathItem memory item0 = ISwapStorage(swapStore).pathFor(tokenA, tokenB);
        uint256[] memory amounts = 
            SwapLibrary.swapTokensForExactTokens(amountOut,uint256(-1),item0,to);

    }
    function addLiquidity(
        address[] calldata tokens,
        uint256[] calldata amountsDesired
    ) public onlyAdmin returns (uint256) {
        uint256 amountADesired;
        uint256 amountBDesired;
        uint256 lpAmount;
        require(tokens.length == amountsDesired.length,"tokens and amount length not correspond");
        require(tokens.length > 0 && tokens.length <=2 ,"must be one token or two");
        if(tokens.length == 1) { // only one Token
            require(tokens[0] != address(0),"token0 address mistake");
            (,,lpAmount) =  SwapLibrary.swapToLpToken(swapStore,tokens[0],pair,amountsDesired[0],address(this));
        }else { // Token + Token
            address newPair = pairFor(tokens[0], tokens[1]);
            require(pair == newPair, "wrong pid");
            (amountADesired, amountBDesired) = 
                tokens[0] == IMdexPair(pair).token0() ? (amountsDesired[0], amountsDesired[1]) : (amountsDesired[1], amountsDesired[0]);
            (,,lpAmount) = LiquidityLibrary.addLiquidity(pair, amountADesired, amountBDesired, 0, 0, address(this));
        }        
        // uint256 lpBalance = IERC20(pair).balanceOf(address(this));
        deposite(lpAmount);
        return lpAmount;
    }

    function removeLiquity(
        address to,
        uint liquidity
    ) public onlyAdmin returns(uint256 amountA, uint256 amountB){
        // remove liquidity
        uint256 amount = withdraw(liquidity);
        if(amount > 0 ){
            IMdexPair(pair).transfer(pair, amount);
            (amountA, amountB) = IMdexPair(pair).burn(to);
        }
    }

    function deposite(
        uint256 amount
    ) internal {
        if(amount >0 ){
            IERC20(pair).approve(address(pool), amount);
            pool.deposit(pid, amount);
        }
    }

    function withdraw(
        uint256 liquidity
    ) internal returns(uint256) {
        (uint256 lpBalance,,) = pool.userInfo(pid, address(this));
        if(liquidity > lpBalance) {
            liquidity = lpBalance;
        }
        if (liquidity != 0) {
            pool.withdraw(pid, liquidity);
        }
        return liquidity;
    }
    function addNewInvest(uint256 swapAmount) internal {
        require(newInvest != address(0),"new invest mistake");
        address[] memory tokens = new address[](1);
        tokens[0] = tokenReward;
        uint[] memory amountsDesired = new uint[](1);
        amountsDesired[0] = swapAmount;
        // approve
        IERC20(tokenReward).approve(newInvest, 0);
        IERC20(tokenReward).approve(newInvest, swapAmount);
        // transfer
        CustomAutoInvestment(newInvest).addLiquidity(tokens, amountsDesired);
    }
    function OverlapInvestment(uint256 swapAmount) internal {
        SwapLibraryInternal.swapToLpToken(swapStore,tokenReward, pair, swapAmount, address(this));
        uint256 lpBalance = IERC20(pair).balanceOf(address(this));
        deposite(lpBalance);
    }

    function doHardWork() public {
        // claim inveset
        pool.withdraw(pid, 0);
        uint256 swapAmount = IERC20(tokenReward).balanceOf(address(this));
        uint256 overlapAmount = overlapRate.mul(swapAmount).div(1e18);
        if (overlapAmount > 0 ){
            OverlapInvestment(overlapAmount);
        }
        uint256 newInvestAmount = swapAmount.sub(overlapAmount);
        if (newInvestAmount > 0 ){
            addNewInvest(newInvestAmount);
        }

    }

    function claimTo() public {
        // claim inveset
        pool.withdraw(pid, 0);
        // transfer token
        uint256 claimBalance = IERC20(tokenReward).balanceOf(address(this));
        if(claimBalance >0){
            TransferHelper.safeTransfer(tokenReward, receiver, claimBalance);
        }
    }
}
