require("hardhat-gas-reporter");
require("hardhat-spdx-license-identifier");
require('hardhat-deploy');
require("@nomiclabs/hardhat-ethers");

let accounts = [];
var fs = require("fs");
var read = require('read');
var util = require('util');
const keythereum = require("keythereum");
const prompt = require('prompt-sync')();
(async function() {
    try {
        const root = '.keystore';
        var pa = fs.readdirSync(root);
        for (let index = 0; index < pa.length; index ++) {
            let ele = pa[index];
            let fullPath = root + '/' + ele;
		    var info = fs.statSync(fullPath);
            //console.dir(ele);
		    if(!info.isDirectory() && ele.endsWith(".keystore")){
                const content = fs.readFileSync(fullPath, 'utf8');
                const json = JSON.parse(content);
                const password = prompt('Input password for 0x' + json.address + ': ', {echo: '*'});
                //console.dir(password);
                const privatekey = keythereum.recover(password, json).toString('hex');
                //console.dir(privatekey);
                accounts.push('0x' + privatekey);
                //console.dir(keystore);
		    }
	    }
    } catch (ex) {
    }
    try {
        const file = '.secret';
        var info = fs.statSync(file);
        if (!info.isDirectory()) {
            const content = fs.readFileSync(file, 'utf8');
            let lines = content.split('\n');
            for (let index = 0; index < lines.length; index ++) {
                let line = lines[index];
                if (line == undefined || line == '') {
                    continue;
                }
                if (!line.startsWith('0x') || !line.startsWith('0x')) {
                    line = '0x' + line;
                }
                accounts.push(line);
            }
        }
    } catch (ex) {
    }
})();

module.exports = {
    defaultNetwork: "hardhat",
    namedAccounts: {
        deployer: {
            default: 0,
            128: '0xA8c2f5E3427a94cd8a0BC8d42DdbA574f890E2b4',
        },
        admin: {
            default: 1,
            128: '0xA8c2f5E3427a94cd8a0BC8d42DdbA574f890E2b4',
        },
        caller: {
            default: 2,
            128: '0xA8c2f5E3427a94cd8a0BC8d42DdbA574f890E2b4',
        },
        worker: {
            default: 3,
            128: '0xA8c2f5E3427a94cd8a0BC8d42DdbA574f890E2b4',
        },
        receiver: {
            default: 4,
            128: '0xA8c2f5E3427a94cd8a0BC8d42DdbA574f890E2b4',
        }
    },
    networks: {
        mainnet: {
            url: `https://http-mainnet-node.huobichain.com`,
            accounts: accounts,
            gasPrice: 1.3 * 1000000000,
            chainId: 128,
        },
        hardhat: {
            forking: {
                enabled: process.env.FORKING === "true",
                url: `https://http-mainnet-node.huobichain.com`,
            },
            live: true,
            saveDeployments: true,
            tags: ["test", "local"],
        }
    },
    solidity: {
        compilers: [
            {
                version: "0.7.2",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        ],
    },
    spdxLicenseIdentifier: {
        overwrite: true,
        runOnCompile: true,
    },
};
