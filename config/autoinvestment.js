const {TOKEN, MDX} = require('./address.js');

module.exports.AUTOINVESTMENT = [
    {
        masterChef: MDX.MasterChef,
        rewardToken: TOKEN.MDX,
        pair: MDX.Pair.MDX_USDT,
        pid: MDX.Pid.MDX_USDT,
        name: "MDX_USDT",
    },
]
