require('dotenv').config()
const HDWalletProvider = require('@truffle/hdwallet-provider');

const MNEMONIC = process.env.MNEMONIC;
console.log(MNEMONIC)
module.exports = {
  networks: {
    development: { //ganache
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
    },
    testnet: { 
      provider: new HDWalletProvider(MNEMONIC, "https://cronos-testnet-3.crypto.org:8545"),
      network_id: "*",
     },
     cronos: {
       provider: new HDWalletProvider(MNEMONIC, "https://evm-cronos.crypto.org"), 
       network_id: 25,
       skipDryRun: true
     },
  },
  contracts_directory: "./contracts/",
  contracts_build_directory: "./abis/",
  compilers: {
    solc: {
      version: ">0.8.0",
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};