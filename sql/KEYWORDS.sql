//
// VYTVORENIE SCHEMY A VIEW NAD ZVOLENYM DATASETOM
//
CREATE SCHEMA finalnyprojekt;


SHOW TABLES IN DATABASE GOOGLE_KEYWORDS_SEARCH_DATASET__DISCOVER_ALL_SEARCHES_ON_GOOGLE;

DESCRIBE TABLE GOOGLE_KEYWORDS_SEARCH_DATASET__DISCOVER_ALL_SEARCHES_ON_GOOGLE.DATAFEEDS.GOOGLE_KEYWORDS;

CREATE OR REPLACE VIEW test AS
SELECT *
FROM GOOGLE_KEYWORDS_SEARCH_DATASET__DISCOVER_ALL_SEARCHES_ON_GOOGLE.DATAFEEDS.GOOGLE_KEYWORDS;

SELECT * FROM test LIMIT;

//
// VYTVORENIE VLASTNEJ TABULKY PRE SPOJENIE KODOV KRAJIN S ICH NAZVOM
//

// VYHLADANIE VSETKYCH KODOV KRAJIN V TABULKE
SELECT DISTINCT country FROM test ORDER BY country DESC;

CREATE OR REPLACE FILE FORMAT finalnyprojekt_format
  TYPE = 'CSV'
  FIELD_DELIMITER = ';'
  SKIP_HEADER = 1
  ;
  
  CREATE OR REPLACE STAGE finalnyprojekt_stage
  FILE_FORMAT = finalnyprojekt_format;

 
  
  CREATE OR REPLACE TABLE countries (
    COUNTRY INT,
    COUNTRYNAME STRING 
);

// NAHRANIE EXCEL SUBORU DO VYTVORENEHO STAGE A NASLEDNE DO TABULKY COUNTRIES
COPY INTO countries
FROM @finalnyprojekt_stage/nazvykrajin.csv
FILE_FORMAT = finalnyprojekt_format
ON_ERROR = 'CONTINUE'
;

SELECT * FROM countries;

//
// VYTVARANIE DIMENZII A FAKTOVEJ TABULKY
//

// VYTVORENIE DIMENZIE COUNTRY
CREATE OR REPLACE TABLE dim_country AS
SELECT DISTINCT
    country AS country_id,
    countryname AS country_name
FROM countries;

// VYTVORENIE DIMENZIE DATE
CREATE OR REPLACE TABLE dim_date AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY year, month, day) AS date_id,
    date,
    day,
    month,
    year
FROM (
    SELECT DISTINCT
        date,
        day,
        month,
        year
    FROM test
);

// VYTVORENIE DIMENZIE KEYWORD
CREATE OR REPLACE TABLE dim_keyword AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY keyword, clean_landingpage) AS keyword_id,
    keyword,
    clean_landingpage
FROM (
    SELECT DISTINCT
        keyword,
        clean_landingpage
    FROM test
    WHERE keyword IS NOT NULL
);


// VYTVORENIE FAKTOVEJ TABULKY FACT_KEYWORDS
CREATE OR REPLACE TABLE fact_keywords AS
SELECT 
    dd.date_id,
    dc.country_id,
    dk.keyword_id,
    t.platform,
    t.referral_type,
    t.site,
    t.is_branded_keyword,
    t.is_question,
    t.calibrated_users,
    t.calibrated_clicks,

    -- KUMULATÍVNY POČET KLIKNUTÍ PRE KEYWORD A KRAJINU V ČASE
    SUM(t.calibrated_clicks) OVER (
        PARTITION BY dc.country_id, dk.keyword_id
        ORDER BY dd.date_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_clicks

FROM test t
LEFT JOIN dim_date dd 
    ON t.date = dd.date
LEFT JOIN dim_country dc 
    ON t.country = dc.country_id
LEFT JOIN dim_keyword dk 
    ON t.keyword = dk.keyword 
    AND t.clean_landingpage = dk.clean_landingpage;
