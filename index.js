require("dotenv").config();
const { startTrackers } = require("./trackerScraper");
const { startOrderBookScraper } = require("./orderBookScraper");

startTrackers();
startOrderBookScraper();