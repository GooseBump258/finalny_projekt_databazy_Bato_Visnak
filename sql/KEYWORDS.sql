Goosebump
goosebump69
In voice

Goosebump — 1/4/2026 3:08 PM
okej
Goosebump — Yesterday at 12:35 PM
uz som tak ze budem potrebovat kod
tak ked prides daj vediet
Matúš — Yesterday at 12:37 PM
Za 25 min so mna pc
Goosebump — Yesterday at 12:37 PM
oki idem zachod zatial
Matúš — Yesterday at 1:04 PM
NIGHA
Matúš — Yesterday at 1:22 PM
CREATE OR REPLACE VIEW test AS
SELECT *
FROM GOOGLE_KEYWORDS_SEARCH_DATASET__DISCOVER_ALL_SEARCHES_ON_GOOGLE.DATAFEEDS.GOOGLE_KEYWORDS;
SELECT * FROM test LIMIT 10;
Image
// VYHLADANIE VSETKYCH KODOV KRAJIN V TABULKE
SELECT DISTINCT country FROM test ORDER BY country DESC;
Image
Matúš — Yesterday at 1:47 PM
CREATE OR REPLACE TABLE dim_country AS
SELECT DISTINCT
    c.country        AS country_id,
    c.countryname    AS country
FROM countries c;
CREATE OR REPLACE TABLE dim_date AS
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY TO_DATE(date)) AS date_id,
    TO_DATE(date) AS date,
    day,
    month,
    year
FROM test;
CREATE OR REPLACE TABLE dim_keyword AS
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY keyword) AS keyword_id,
    keyword,
    clean_landingpage AS clean_landing_page
FROM test
WHERE keyword IS NOT NULL;
Matúš — Yesterday at 5:37 PM
neviem co s tym, nejde mi vytvorit ta faktova tabulka
vytvara mi to 2.3 biliona riadkov
Goosebump — Yesterday at 6:09 PM
Hm
Matúš — Yesterday at 6:09 PM
uz fixed
Goosebump — Yesterday at 6:09 PM
Aha okej
Ahahahahahah
Matúš — Yesterday at 6:09 PM
uz idem robit tie grafy pomaly xD ale mozno budes musiet upravit tie tvoje dim tabulky lebo tam mi nieco chat zmenil
uvidime, pozrieme sa na to neskor alebo zajtra este
Goosebump — Yesterday at 6:10 PM
Okej
Zajtra
Dokoncime
Matúš — Yesterday at 6:11 PM
jj
Matúš — Yesterday at 7:19 PM
Image
mame aj grafy už
Goosebump — Yesterday at 7:22 PM
Ppci
Uz to len najebat hentam zajtra
A posielame to obaja
Ja to nebudem davat na svoj snowflake
Jbmnt
Netreba realne
Staci ked obaja dame github link
A aj keby sa pyta tak povieme jeden robil to a to a druhy to a to a stale sme spolu volali
Matúš — Yesterday at 7:23 PM
jj ved realne
proste mu tam odovzdam ten github link co robis ty a hotovo
Goosebump — Yesterday at 7:23 PM
Jj
Matúš — Yesterday at 7:23 PM
zbytocne to robit na dvakrat
Goosebump — Yesterday at 7:23 PM
Ja si snowflake ani neotvorim
A ptm by sme mohli dat spolu recap na stredu
Ngl
Matúš — Yesterday at 7:30 PM
akoze urcite hej
zajtra ked dokoncime databazy tak tomanova
lebo nevidel som to od posledneho zapoctu xD
Goosebump — 11:41 AM
13/14 sadnem na pc a ideme na to
Do 15 to mame odovzdane a ptm studium
Matúš — 11:43 AM
Suhlasim
Matúš — 12:43 PM
Za 10 min som doma cca
Goosebump — 1:04 PM
som vc
Matúš — 1:06 PM
jj idem
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
    t.calibrated_clicks
FROM test t
LEFT JOIN dim_date dd 
    ON t.date = dd.date
LEFT JOIN dim_country dc 
    ON t.country = dc.country_id
LEFT JOIN dim_keyword dk 
    ON t.keyword = dk.keyword 
    AND t.clean_landingpage = dk.clean_landingpage;
Image
Matúš — 1:15 PM
//1. POCET VYHLADAVANI SLOVA YOUTUBE NA SVETE ZA KAZDY DEN V MESIACI JUN ROKU 2022
SELECT
    dd.date AS DEN,
    SUM(f.calibrated_users) AS POCET_VYHLADAVANI,
    SUM(f.calibrated_clicks) AS POCET_KLIKNUTI
FROM fact_keywords f
JOIN dim_date dd 
    ON f.date_id = dd.date_id
JOIN dim_keyword dk 
    ON f.keyword_id = dk.keyword_id
WHERE dd.year = 2022
  AND dd.month = 6
  AND LOWER(dk.keyword) LIKE '%youtube%'
GROUP BY
    dd.date
ORDER BY
    dd.date;

//2. 10 NAJVYHLADAVANEJSICH OTAZOK V SPOJENYCH STATOCH AMERICKYCH PODLA POCTU UZIVATELOV
SELECT 
    dk.keyword AS VYHLADAVANY_VYRAZ,
    SUM(f.calibrated_users) AS SPOLU_UZIVATELOV,
    SUM(f.calibrated_clicks) AS SPOLU_KLIKNUTI
FROM fact_keywords f
JOIN dim_keyword dk ON f.keyword_id = dk.keyword_id
JOIN dim_country dc ON f.country_id = dc.country_id
WHERE dc.country_name = 'United States of America'
  AND f.is_question = '1'
GROUP BY VYHLADAVANY_VYRAZ
ORDER BY SPOLU_UZIVATELOV DESC
LIMIT 10;


//3. 25 NAJVYHLADAVANEJSICH VYRAZOV NA SLOVENSKU ZA MESIAC JUN ROKU 2022 PODLA POCTU UZIVATELOV
SELECT 
    dk.keyword AS VYHLADAVANY_VYRAZ,
    SUM(f.calibrated_users) AS SPOLU_UZIVATELOV,
    SUM(f.calibrated_clicks) AS SPOLU_KLIKNUTI
FROM fact_keywords f
JOIN dim_keyword dk ON f.keyword_id = dk.keyword_id
JOIN dim_country dc ON f.country_id = dc.country_id
JOIN dim_date dd ON f.date_id = dd.date_id
WHERE dc.country_name = 'Slovakia'
  AND dd.month = '06'
  AND dd.year = '22'
GROUP BY VYHLADAVANY_VYRAZ
ORDER BY SPOLU_UZIVATELOV DESC
LIMIT 25;
//4. NAJVYHLADAVANEJSI VYRAZ NA SLOVENSKU ZA KAZDY DEN V MESIACI JUN ROKU 2022
WITH ranked AS (
    SELECT
        dd.date AS den,
        dk.keyword AS najvyhladavanejsi_vyraz,
        SUM(f.calibrated_clicks) AS pocet_kliknuti,
        ROW_NUMBER() OVER (
            PARTITION BY dd.date
            ORDER BY SUM(f.calibrated_clicks) DESC
        ) AS rn
    FROM fact_keywords f
    JOIN dim_keyword dk ON f.keyword_id = dk.keyword_id
    JOIN dim_country dc ON f.country_id = dc.country_id
    JOIN dim_date dd ON f.date_id = dd.date_id
    WHERE dc.country_name = 'Slovakia'
      AND dd.month = '06'
      AND dd.year = '22'
    GROUP BY dd.date, dk.keyword
)
SELECT 
    den,
    najvyhladavanejsi_vyraz,
    pocet_kliknuti
FROM ranked
WHERE rn = 1
ORDER BY den;

//5. POCET UZIVATELOV PRE OKOLNE STATY V MESIACI JUN ROKU 2022
SELECT 
    dc.country_name AS krajina,
    SUM(f.calibrated_users) AS pocet_uzivatelov,
    SUM(f.calibrated_clicks) AS pocet_kliknuti
FROM fact_keywords f
JOIN dim_country dc ON f.country_id = dc.country_id
JOIN dim_date dd ON f.date_id = dd.date_id
WHERE dc.country_name IN ('Slovakia', 'Czechia','Poland','Hungary','Ukraine')
  AND dd.month = 06
  AND dd.year = 22
GROUP BY dc.country_name
ORDER BY pocet_uzivatelov DESC;

//6. 10 KRAJIN S NAJVACSIM POCTOM VYHLADAVANI PODLA POCTU UZIVATELOV
SELECT 
    dc.country_name AS NAZOV_KRAJINY,
    SUM(f.calibrated_users) AS SPOLU_UZIVATELOV,
    SUM(f.calibrated_clicks) AS SPOLU_KLIKNUTI,
FROM fact_keywords f
JOIN dim_country dc ON f.country_id = dc.country_id
GROUP BY NAZOV_KRAJINY
ORDER BY SPOLU_UZIVATELOV DESC
LIMIT 10;
//
// VYTVARANIE QUERIES PRE TVORBU GRAFOV
//

//1. POCET VYHLADAVANI SLOVA YOUTUBE NA SVETE ZA KAZDY DEN V MESIACI JUN ROKU 2022
SELECT
Expand
grafy.txt
4 KB
//
// VYTVORENIE SCHEMY A VIEW NAD ZVOLENYM DATASETOM
//
CREATE SCHEMA finalnyprojekt;

Expand
tvorbadimatd.txt
3 KB
﻿
//
// VYTVARANIE QUERIES PRE TVORBU GRAFOV
//

//1. POCET VYHLADAVANI SLOVA YOUTUBE NA SVETE ZA KAZDY DEN V MESIACI JUN ROKU 2022
SELECT
    dd.date AS DEN,
    SUM(f.calibrated_users) AS POCET_VYHLADAVANI,
    SUM(f.calibrated_clicks) AS POCET_KLIKNUTI
FROM fact_keywords f
JOIN dim_date dd 
    ON f.date_id = dd.date_id
JOIN dim_keyword dk 
    ON f.keyword_id = dk.keyword_id
WHERE dd.year = 2022
  AND dd.month = 6
  AND LOWER(dk.keyword) LIKE '%youtube%'
GROUP BY
    dd.date
ORDER BY
    dd.date;

//2. 10 NAJVYHLADAVANEJSICH OTAZOK V SPOJENYCH STATOCH AMERICKYCH PODLA POCTU UZIVATELOV
SELECT 
    dk.keyword AS VYHLADAVANY_VYRAZ,
    SUM(f.calibrated_users) AS SPOLU_UZIVATELOV,
    SUM(f.calibrated_clicks) AS SPOLU_KLIKNUTI
FROM fact_keywords f
JOIN dim_keyword dk ON f.keyword_id = dk.keyword_id
JOIN dim_country dc ON f.country_id = dc.country_id
WHERE dc.country_name = 'United States of America'  
  AND f.is_question = '1'  
GROUP BY VYHLADAVANY_VYRAZ
ORDER BY SPOLU_UZIVATELOV DESC
LIMIT 10;


//3. 25 NAJVYHLADAVANEJSICH VYRAZOV NA SLOVENSKU ZA MESIAC JUN ROKU 2022 PODLA POCTU UZIVATELOV
SELECT 
    dk.keyword AS VYHLADAVANY_VYRAZ,
    SUM(f.calibrated_users) AS SPOLU_UZIVATELOV,
    SUM(f.calibrated_clicks) AS SPOLU_KLIKNUTI
FROM fact_keywords f
JOIN dim_keyword dk ON f.keyword_id = dk.keyword_id
JOIN dim_country dc ON f.country_id = dc.country_id
JOIN dim_date dd ON f.date_id = dd.date_id
WHERE dc.country_name = 'Slovakia'
  AND dd.month = '06'
  AND dd.year = '22'
GROUP BY VYHLADAVANY_VYRAZ
ORDER BY SPOLU_UZIVATELOV DESC
LIMIT 25;

//4. NAJVYHLADAVANEJSI VYRAZ NA SLOVENSKU ZA KAZDY DEN V MESIACI JUN ROKU 2022
WITH ranked AS (
    SELECT
        dd.date AS den,
        dk.keyword AS najvyhladavanejsi_vyraz,
        SUM(f.calibrated_clicks) AS pocet_kliknuti,
        ROW_NUMBER() OVER (
            PARTITION BY dd.date
            ORDER BY SUM(f.calibrated_clicks) DESC
        ) AS rn
    FROM fact_keywords f
    JOIN dim_keyword dk ON f.keyword_id = dk.keyword_id
    JOIN dim_country dc ON f.country_id = dc.country_id
    JOIN dim_date dd ON f.date_id = dd.date_id
    WHERE dc.country_name = 'Slovakia'
      AND dd.month = '06'
      AND dd.year = '22'
    GROUP BY dd.date, dk.keyword
)
SELECT 
    den,
    najvyhladavanejsi_vyraz,
    pocet_kliknuti
FROM ranked
WHERE rn = 1
ORDER BY den;

//5. POCET UZIVATELOV PRE OKOLNE STATY V MESIACI JUN ROKU 2022
SELECT 
    dc.country_name AS krajina,
    SUM(f.calibrated_users) AS pocet_uzivatelov,
    SUM(f.calibrated_clicks) AS pocet_kliknuti
FROM fact_keywords f
JOIN dim_country dc ON f.country_id = dc.country_id
JOIN dim_date dd ON f.date_id = dd.date_id
WHERE dc.country_name IN ('Slovakia', 'Czechia','Poland','Hungary','Ukraine')
  AND dd.month = 06
  AND dd.year = 22
GROUP BY dc.country_name
ORDER BY pocet_uzivatelov DESC;

//6. 10 KRAJIN S NAJVACSIM POCTOM VYHLADAVANI PODLA POCTU UZIVATELOV
SELECT 
    dc.country_name AS NAZOV_KRAJINY,
    SUM(f.calibrated_users) AS SPOLU_UZIVATELOV,
    SUM(f.calibrated_clicks) AS SPOLU_KLIKNUTI,
FROM fact_keywords f
JOIN dim_country dc ON f.country_id = dc.country_id
GROUP BY NAZOV_KRAJINY
ORDER BY SPOLU_UZIVATELOV DESC
LIMIT 10;
