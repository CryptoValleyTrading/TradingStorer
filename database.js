const { DB_HOST, DB_USER, DB_PASSWORD, DB_DATABASE } = process.env;

const knex = require("knex")({
  client: "pg",
  connection: {
    host: DB_HOST,
    user: DB_USER,
    password: DB_PASSWORD,
    database: DB_DATABASE,
  },
});

async function getLatestTradeTimestamp(tracker_id) {
  const result = await knex("trades")
    .where({ tracker_id })
    .orderBy("timestamp", "desc")
    .first();

  return result ? result.timestamp : undefined;
}

async function getAllActiveTrackers() {
  const result = await knex
    .select("trackers.id", "exchanges.ccxt_identifier", "trading_pairs.symbol")
    .from("trackers")
    .where("trackers.is_active", true)
    .join("exchanges", function () {
      this.on("exchanges.id", "=", "trackers.exchange_id");
    })
    .join("trading_pairs", function () {
      this.on("trackers.trading_pair_id", "=", "trading_pairs.id");
    });

  return result;
}

async function saveTrades(trades) {
  if (!trades.length) {
    return;
  }
  await knex("trades").insert(trades);
}

module.exports = {
  getLatestTradeTimestamp,
  getAllActiveTrackers,
  saveTrades,
};
