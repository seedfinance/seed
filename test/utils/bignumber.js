const { BigNumber } = require('ethers');

exports.expandTo18Decimals = function(n) {
    return BigNumber.from(n).mul(BigNumber.from(10).pow(18))
}
exports.expandToNormal = function(bn) {
    return BigNumber.from(bn).div(BigNumber.from(10).pow(18)).toBigInt()
}