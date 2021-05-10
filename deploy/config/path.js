const {TOKEN, MDX} = require('./address.js');
module.exports.PATH = [
    {
        from : TOKEN.MDX,
        to   : TOKEN.USDT,
        path : [TOKEN.MDX, TOKEN.USDT],
        pair : [MDX.Pair.MDX_USDT],
    },
    {
        from : TOKEN.USDT,
        to   : TOKEN.MDX,
        path : [TOKEN.USDT, TOKEN.MDX],
        pair : [MDX.Pair.MDX_USDT],
    },
    {
        from : TOKEN.HBTC,
        to   : TOKEN.USDT,
        path : [TOKEN.HBTC, TOKEN.USDT],
        pair : [MDX.Pair.HBTC_USDT],
    },
    {
        from : TOKEN.USDT,
        to   : TOKEN.HBTC,
        path : [TOKEN.USDT, TOKEN.HBTC],
        pair : [MDX.Pair.HBTC_USDT],
    },
    {
        from : TOKEN.HBTC,
        to   : TOKEN.MDX,
        path : [TOKEN.HBTC, TOKEN.MDX],
        pair : [MDX.Pair.HBTC_MDX],
    },
]
