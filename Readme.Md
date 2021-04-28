adminStore 管理员合约

swapStore 控制 swap path 和 pair的 路由合约

autoInvestment 自动复投模块合约
    存入lp token 得到xtoken

autoInvestmentRouter 自动复投合约的router（用户交互的合约）
    automoulde 自动复投模块合约地址
    amount lp 数量
    to 权益转移至to
    function deposit(address automoulde, uint256 amount, address to)

    liquidity xtoken数量
    function withdraw(address automoulde, uint256 liquidity, address to)


新增 自动复投交易对：
    部署新的autoInvestment 合约，并设置对应的 pair
    swapStore 对对应的pair换币路由
