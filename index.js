const { Token, Fetcher, WETH, Trade, Route, TokenAmount, TradeType } = require('@pancakeswap-libs/sdk')
const { JsonRpcProvider } = require("@ethersproject/providers");
const { ethers, EventFilter } = require("ethers")
const { privateKey, userAddress, targetTokenAddress, wbnbAddress, factoryAddress, routerAddress, rpcProvider, chainId} = require('./config')
const factory = require('./factory.json')
const router = require('./router.json')
const wbnb = WETH[chainId]
const provider = new ethers.providers.JsonRpcProvider(rpcProvider, {
  name: 'Binance Smart Chain',
  chainId
});
const targetToken = new Token(chainId, targetTokenAddress, 18)


const main = async () => {
  // todo: fix pancake sdk bug
  wbnb.address = wbnbAddress //wrong address testnet
  // sdk.cjs.development.js => set address line 1554

  // get trade info
  // const pair = await Fetcher.fetchPairData(targetToken,wbnb,provider)
  // const route = new Route([pair], wbnb)
  // const trade = new Trade(route, new TokenAmount(wbnb, '1000000000000000000'), TradeType.EXACT_INPUT)

  // todo: fix pancake sdk bug remove on prod

  const acc = new ethers.Wallet(privateKey, provider)
  const fact = new ethers.Contract(factoryAddress, factory, provider);
  const rout = new ethers.Contract(routerAddress, router, acc);
  const amountInEth = { value: ethers.utils.parseEther("0.1") }

  // Auto purchase target tokens with amountInEth on PairCreated event
  fact.on("PairCreated", async (token0, token1, pair, amount) => {
    if (token0 == targetTokenAddress || token1 == targetTokenAddress) {
      rout.estimateGas.swapExactETHForTokens(0, [wbnbAddress, targetTokenAddress], userAddress, Math.floor(Date.now() / 1000) + 60 * 20, amountInEth)
        .then(async gas => {
          console.log(gas)
          console.log(await rout.swapExactETHForTokens(0, [wbnbAddress, targetTokenAddress], userAddress, Math.floor(Date.now() / 1000) + 60 * 20, amountInEth))
        }).catch(err => {
          console.log(err)
        })
    }
  });
}

main()