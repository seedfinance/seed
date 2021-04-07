// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "../libraries/UniswapV2Library.sol";
import "../interfaces/IMasterChef.sol";

contract AutoInvestment is Ownable {
    using SafeMath for uint256;

    event AddLiquidity(address indexed forAddr, uint256 share);
    event RemoveLiquidity(
        address indexed from,
        address indexed to,
        uint256 amount0,
        uint256 amount1
    );

    bool public pause;
    uint256 public totalShares;

    address public router;
    address public factory;

    IMasterChef public chef;
    address public chefToken;

    uint256 public pairId;

    address public lpToken;
    address public token0;
    address public token1;

    mapping(address => mapping(address => address[])) swapPaths;
    mapping(address => uint256) public shares;

    constructor(
        address router_,
        address chef_,
        uint256 _pid
    ) {
        router = router_;
        factory = IUniswapV2Router02(router_).factory();
        require(factory != address(0), "factory address mistake");
        chef = IMasterChef(chef_);
        (lpToken, , , ) = chef.poolInfo(_pid);
        require(lpToken != address(0), "lp token address mistake");
        pairId = _pid;

        token0 = IUniswapV2Pair(lpToken).token0();
        token1 = IUniswapV2Pair(lpToken).token1();
    }

    function setSwapPath(address[] memory path) external onlyOwner {
        require(
            path[0] == chefToken &&
                (path[path.length - 1] == token0 ||
                    path[path.length - 1] == token1),
            "path not allowed"
        );
        swapPaths[path[0]][path[path.length - 1]] = path;
    }

    function paused() external onlyOwner {
        pause = true;
    }

    function unPaused() external onlyOwner {
        pause = false;
    }

    function addLiquidity(
        address[] calldata tokens,
        uint256[] calldata amountsDesired,
        address forAddr
    ) external payable returns (uint256 share) {
        require(pause, "addLiquidity has been paused");
        address pair = UniswapV2Library.pairFor(factory, tokens[0], tokens[1]);
        require(lpToken == pair, "pair address mismatch");

        doHardWork();

        uint256 totalAmounts = getTotalAmount();

        (, , uint256 liquidity) =
            _addLiquidity(
                tokens[0],
                tokens[1],
                amountsDesired[0],
                amountsDesired[1]
            );

        if (totalShares == 0 || totalAmounts == 0) {
            share = liquidity;
        } else {
            share = liquidity.mul(totalShares).div(totalAmounts);
        }
        addShare(forAddr, share);
        IERC20(lpToken).approve(address(chef), 0);
        IERC20(lpToken).approve(address(chef), liquidity);
        chef.deposit(pairId, liquidity);

        emit AddLiquidity(forAddr, share);
    }

    function emergencyWithdraw() external onlyOwner {
        chef.emergencyWithdraw(pairId);
        pause = true;
    }

    function doHardWork() public {
        if (pause) {
            return;
        }
        chef.withdraw(pairId, 0);

        uint256 swapAmount = IERC20(chefToken).balanceOf(address(this)).div(2);

        if (token0 != chefToken) {
            IUniswapV2Router02(router).swapExactTokensForTokens(
                swapAmount,
                0,
                swapPaths[chefToken][token0],
                address(this),
                block.timestamp
            );
        }
        if (token1 != chefToken) {
            IUniswapV2Router02(router).swapExactTokensForTokens(
                swapAmount,
                0,
                swapPaths[chefToken][token1],
                address(this),
                block.timestamp
            );
        }
        uint256 token0Amount = IERC20(token0).balanceOf(address(this));
        uint256 token1Amount = IERC20(token1).balanceOf(address(this));

        (, , uint256 liquidity) =
            _addLiquidity(token0, token1, token0Amount, token1Amount);

        IERC20(lpToken).approve(address(chef), 0);
        IERC20(lpToken).approve(address(chef), liquidity);
        chef.deposit(pairId, liquidity);
    }

    function removeLiquidity(address to, uint256 share) external {
        require(shares[msg.sender] >= share, "share not enough");

        doHardWork();
        uint256 what = share.mul(getTotalAmount()).div(totalShares);
        uint256 withdrawAmount = what.sub(getLocalAmount());

        if (withdrawAmount > 0) {
            chef.withdraw(pairId, withdrawAmount);
        }

        _removeLiquidity(lpToken, what, to);
        removeShare(msg.sender, share);
    }

    function addShare(address to, uint256 amount) internal {
        totalShares = totalShares.add(amount);
        shares[to] = shares[to].add(amount);
    }

    function removeShare(address to, uint256 amount) internal {
        shares[to] = shares[to].sub(amount);
        totalShares = totalShares.sub(amount);
    }

    function getTotalAmount() internal view returns (uint256 amount) {
        (amount, ) = IMasterChef(chef).userInfo(pairId, address(this));
        amount = amount.add(IERC20(lpToken).balanceOf(address(this)));
    }

    function getLocalAmount() internal view returns (uint256 amount) {
        amount = amount.add(IERC20(lpToken).balanceOf(address(this)));
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
    )
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (uint256 reserveA, uint256 reserveB) =
            UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal =
                UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal =
                    UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
        TransferHelper.safeTransferFrom(tokenA, msg.sender, lpToken, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, lpToken, amountB);
        liquidity = IUniswapV2Pair(lpToken).mint(address(this));
    }

    function _removeLiquidity(
        address pair,
        uint256 liquidity,
        address to
    ) internal returns (uint256 amount0, uint256 amount1) {
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (amount0, amount1) = IUniswapV2Pair(pair).burn(to);

        emit RemoveLiquidity(msg.sender, to, amount0, amount1);
    }
}
