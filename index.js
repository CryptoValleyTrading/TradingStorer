require("dotenv").config();
const ccxt = require("ccxt");
const {
  getLatestTradeTimestamp,
  getAllActiveTrackers,
  saveTrades,
} = require("./database");
const binance = new ccxt.bittrex({ enableRateLimit: true });

const exchanges = {};

async function start() {
  const trackers = await getAllActiveTrackers();
  trackers.forEach(startTracker);
}

async function startTracker({ ccxt_identifier, symbol, id }) {
  if (!exchanges[ccxt_identifier]) {
    exchanges[ccxt_identifier] = new ccxt[ccxt_identifier]({
      enableRateLimit: true,
    });
  }
  console.log(ccxt_identifier);
  let exchange = exchanges[ccxt_identifier];

  setInterval(async () => {
    let twenty_seconds_ago = exchange.milliseconds() - 6 * 1000;
    let last_trade_timestamp = await getLatestTradeTimestamp(id);

    const trades = await exchange.fetchTrades(symbol, twenty_seconds_ago);

    while (
      last_trade_timestamp &&
      trades.length &&
      trades[0].timestamp <= last_trade_timestamp
    ) {
      trades.shift();
    }

    const mapped_trades = trades.map((e) => {
      return {
        timestamp: e.datetime,
        tracker_id: id,
        price: e.price,
        amount: e.amount,
        cost: e.cost,
        identification: e.id,
      };
    });

    saveTrades(mapped_trades);
  }, 5 * 1000);
}

start();
