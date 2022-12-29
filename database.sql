-- Adminer 4.8.1 PostgreSQL 14.5 dump

DROP TABLE IF EXISTS "exchanges";
DROP SEQUENCE IF EXISTS exchanges_id_seq;
CREATE SEQUENCE exchanges_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1;

CREATE TABLE "public"."exchanges" (
    "id" integer DEFAULT nextval('exchanges_id_seq') NOT NULL,
    "name" text NOT NULL,
    "ccxt_identifier" text NOT NULL,
    CONSTRAINT "exchanges_pkey" PRIMARY KEY ("id")
) WITH (oids = false);


DROP TABLE IF EXISTS "trackers";
DROP SEQUENCE IF EXISTS trackers_id_seq;
CREATE SEQUENCE trackers_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1;

CREATE TABLE "public"."trackers" (
    "id" integer DEFAULT nextval('trackers_id_seq') NOT NULL,
    "trading_pair_id" integer NOT NULL,
    "exchange_id" integer NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    CONSTRAINT "trackers_pkey" PRIMARY KEY ("id")
) WITH (oids = false);


DROP TABLE IF EXISTS "trades";

CREATE TABLE "public"."trades" (
    "timestamp" timestamptz NOT NULL,
    "tracker_id" integer NOT NULL,
    "price" numeric(16,8) NOT NULL,
    "amount" numeric(16,8) NOT NULL,
    "cost" numeric(16,8) NOT NULL,
    "identification" text NOT NULL
) WITH (oids = false);


DROP TABLE IF EXISTS "trading_pairs";
DROP SEQUENCE IF EXISTS trading_pairs_id_seq;
CREATE SEQUENCE trading_pairs_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1;

CREATE TABLE "public"."trading_pairs" (
    "id" integer DEFAULT nextval('trading_pairs_id_seq') NOT NULL,
    "symbol" text NOT NULL,
    CONSTRAINT "trading_pairs_pkey" PRIMARY KEY ("id")
) WITH (oids = false);


ALTER TABLE ONLY "public"."trackers" ADD CONSTRAINT "trackers_exchange_id_fkey" FOREIGN KEY (exchange_id) REFERENCES exchanges(id) NOT DEFERRABLE;
ALTER TABLE ONLY "public"."trackers" ADD CONSTRAINT "trackers_trading_pair_id_fkey" FOREIGN KEY (trading_pair_id) REFERENCES trading_pairs(id) NOT DEFERRABLE;

ALTER TABLE ONLY "public"."trades" ADD CONSTRAINT "trades_tracker_id_fkey" FOREIGN KEY (tracker_id) REFERENCES trackers(id) NOT DEFERRABLE;

-- 2022-10-15 15:27:19.09495+00

SELECT create_hypertable('trades','timestamp');
CREATE INDEX ix_tracking_id_timestamp ON trades(tracker_id, timestamp DESC);

-- 2022-11-24 14:12:12.09495+00

CREATE TABLE "public"."trades_grouped_by_second" (
    "timestamp" timestamptz NOT NULL,
    "tracker_id" integer NOT NULL,
    "num_trades" integer NOT NULL,
    "min_price" numeric(16, 8) NOT NULL,
    "max_price" numeric(16, 8) NOT NULL,
    "weighted_avg_price" numeric(16, 8) NOT NULL,
    "volume" numeric(16, 8) NOT NULL,
    "cost" numeric(16,8) NOT NULL
) WITH (oids = false);

SELECT create_hypertable('trades_grouped_by_second','timestamp');
CREATE INDEX ix_tracking_id_timestamp_grouped_by_second ON trades_grouped_by_second(tracker_id, timestamp DESC);

INSERT INTO trades_grouped_by_second
SELECT time_bucket('1 second', timestamp) AS one_sec,
       tracker_id,
       count(*) AS num_trades,
       min(price) AS min_price,
       max(price) AS max_price,
       sum(price * amount) / sum(amount) AS weighted_avg_price,
       sum(amount) AS volume,
       sum(cost) as cost
FROM trades
GROUP BY tracker_id, one_sec
ORDER BY one_sec
