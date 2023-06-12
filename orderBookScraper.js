require('dotenv').config();
const {WebsocketClient, DefaultLogger } = require('binance');
const { getAllActiveTrackersWithOrderbook, saveOrderBook } = require('./database');

// optionally override the logger
const logger = {
    ...DefaultLogger,
    silly: (...params) => { },
};
const wsClient = new WebsocketClient({
        // Disable ping/pong ws heartbeat mechanism (not recommended)
        // disableHeartbeat: true
    },
    logger
);

// receive raw events
wsClient.on('message', (data) => {
    const tracker_id = tracker_ids[data.wsKey];
    if(tracker_id === undefined){
        console.warn("Received orderbook data for unknown tracker", data.wsKey)
        return;
    }
    saveOrderBook(new Date(), tracker_id, data.asks, data.bids);
});

// notification when a connection is opened
wsClient.on('open', (data) => {
    console.log('connection opened open:', data.wsKey, data.ws.target.url);
});

// read response to command sent via WS stream (e.g LIST_SUBSCRIPTIONS)
wsClient.on('reply', (data) => {
    console.log('log reply: ', JSON.stringify(data, null, 2));
});

// receive notification when a ws connection is reconnecting automatically
wsClient.on('reconnecting', (data) => {
    console.log('ws automatically reconnecting.... ', data?.wsKey);
});

// receive notification that a reconnection completed successfully (e.g use REST to check for missing data)
wsClient.on('reconnected', (data) => {
    console.log('ws has reconnected ', data?.wsKey);
});

// Recommended: receive error events (e.g. first reconnection failed)
wsClient.on('error', (data) => {
    console.log('ws saw error ', data?.wsKey);
});

const tracker_ids = [];

async function startOrderBookScraper(){
    const trackers = await getAllActiveTrackersWithOrderbook();
    for(const {id, ccxt_identifier, symbol} of trackers){
        if(ccxt_identifier !== 'binance'){
            console.warn("Tried to track the orderbook of a non ccxt exchange. Skipping", ccxt_identifier, symbol)
            continue;
        }

        const key = symbol.replace(/\//g, '').toLowerCase();
        const wsKey = 'spot_depth_' + key + '_';
        tracker_ids[wsKey] = id;
        console.log(wsKey, id)

        wsClient.subscribeSpotPartialBookDepth(key, 20, 100);
    }
}

module.exports = {
    startOrderBookScraper
}