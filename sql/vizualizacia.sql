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
