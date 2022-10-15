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
