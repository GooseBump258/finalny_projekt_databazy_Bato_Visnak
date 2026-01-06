# ELT proces datasetu Google keywords search
Tento repozitár slúži na zaznamenanie procesu spracovania a analýzy datasetu s názvom Google keywords search dataset, obsahuje obrázkovú textovú a kódovú dokumentáciu celého ELT procesu spracovania a implementácie a vytvorenia dátového skladu STAR schémy. **Dataset a ELT spracovanie sa zameriava na prácu s vyhľadávaním používateľov z krajín celého sveta, dané dáta sa dajú použiť na následnú predikciu vyhľadávaní a prispôsobenia náľho biznis modelu, taktiež za účeľmi výskumu.** 

Výsledný dátový model umožňuje multidimenzionálnu analýzu a vizualizáciu kľúčových metrik.

---

## 1.  Úvod a popis zdrojových dát/odôvodnenie výberu

### 1.1 Charakteristika datasetu
Táto práca sa zameriava na analýzu datasetu Google Keywords Search, ktorý obsahuje údaje o vyhľadávaní kľúčových slov vo vyhľadávači Google, obsahuje taktiež krajinu vyhľadávača. Dataset poskytuje prehľad o správaní používateľov na internete a umožňuje analyzovať dopyt po konkrétnych témach, produktoch alebo službách na základe reálnych vyhľadávacích dotazov.

### 1.2 Voľba datasetu
- použitie v oblasti marketingu a predaja
- vysoká praktickosť
- údaje pochádzajú priamu z Google(najpoužívanejší search engine na svete)
- identifikácia trendov

### 1.3 Podporovaný biznis proces
- analyzované dáta podporujú najmä biznis procesy súvisiace s online marketingom
- je možné efektívne plánovať reklamné kampane
- optimalizovať obsah webových stránok
- rozhodovať o výbere najvhodnejších kľúčových slov

#### Zdrojové dáta pochádzajú z snowflake marketplace datasetu dostupného [tu](https://app.snowflake.com/marketplace/listing/GZT1ZA3NJP/similarweb-ltd-google-keywords-search-dataset-discover-all-searches-on-google?search=GOOGLE%20KEYWO)
#### Dataset obsahuje jednu hlavnú tabuľku GOOGLE KEYWORDS:
- CALIBRATED_CLICKS
- CALIBRATED_USERS
- CLEAN_LANDINGPAGE
- COUNTRY
- DATE
- DAY
- IS_BRANDED_KEYWORD
- IS_QUESTION
- KEYWORD
- MONTH

### 1.4 Dátová architektúra
#### ERD diagram
Surové dáta sú usporiadané v relačnom modeli, ktorý je znázornený na entitno-relačnom diagrame:

<p align="center">
  <img src="images/googlekeywordstabulka.png" alt="ERD diagram" width="250">
</p>

<p align="center"><em>Obrázok 1 Entitno-relačná schéma Google Keywords</em></p>

#### Očíslovanie krajín
Z dôvodu číselných označení krajín vo vybranej databáze sme vytvorili csv súbor obsahujúci číselný kód každej krajiny, je potrebné ho nahrať pre plnú funkčnosť 
[Stiahni súbor tu](csv/nazvykrajin.csv)

---
# 2. Dimenzionálny model
V ukážke máme navrhnutú schému hviezdy podľa Kimballovej metodológie.Obsahuje 1 tabuľku faktov fact_keywords, ktorá je prepojená s nasledujúcimi 3 dimenziami:
- dim_date: obsahuje date,day a month. Ide o časové údaje o vyhľadávaní
- dim_country: obsahuje id a krajinu
- dim_keyword: obsahuje kľúčové slovo vyhľadania a landing page vyhľadávania

Štruktúra hviezdicového modelu je znázornená na diagrame nižšie.

<p align="center">
  <img src="images/hviezda_schema_google_keywords.png" alt="ERD diagram" width="780">
</p>

<p align="center"><em>Obrázok 2 Schéma hviezdy pre Google keywords</em></p>

---

# 3. ELT proces v Snowflake
## ELT proces pozostáva z troch hlavných krokov:
### ELT = Extract – Load – Transform
Extract (Extrahovanie)
Získavanie dát zo zdrojov:
- databázy
- API
- CSV / Excel súbory
- logy, webové dáta

Dáta sa nečistia ani neupravujú
Cieľ: dostať dáta von zo zdroja

### Load (Načítanie)
Dáta sa v surovom stave ukladajú do:
- Data Warehouse
- Data Lake
- Bez transformácií
- Rýchle nahratie veľkých objemov dát

### Transform (Transformácia)
Prebieha už v cieľovom systéme
Úpravy dát:
- čistenie (NULL hodnoty, duplicity)
- typy dát
- agregácie
- tvorba fact a dimension tabuliek (star schema)
- Typicky pomocou SQL

## 3.1 Extrakcia dát a zdroj
Naše dáta sme čerpali s verejne dostupných databáz (Snowflake marketplace), marketplace slúži na zverejňovanie datasetov ktoré sú zväčša read-only a prístup si ku ním ako užívateľ musíme žiadať. Extrakcia je tým pádom jednoduchá a ide iba o požiadanie ku čítaniu tohto datasetu.

## 3.2 Load dát 
Keďže je dataset Google Keywords read-only s datasetom ako takým pracovať nevieme. Musíme si vytvoriť views - VIEW je kópia dát s ktorou mi ako neoprávnený užívatelia môžme pracovať pretože nezasahuje do už vytvoreného datasetu.

Príklad kódu:

```SQL
CREATE OR REPLACE VIEW test AS
SELECT *
FROM GOOGLE_KEYWORDS_SEARCH_DATASET__DISCOVER_ALL_SEARCHES_ON_GOOGLE.DATAFEEDS.GOOGLE_KEYWORDS;
SELECT * FROM test LIMIT 10;

```
Daný kód nám vytvorí view s názvom test a selectne všetky údaje z GOOGLE KEYWORDS datasetu, následne vďaka funkcii select ukáže prvých 10 riadkov(vid. nižšie).
<p align="center">
  <img src="images/10_riadkov_GOOGLE.png" alt="ERD diagram" width="780">
</p>

<p align="center"><em>Obrázok 3 Prvých 10 riadkov raw view datasetu</em></p>

# 3.3 Transformácia dát
V tejto časti sme raw tabuľku upravili a vylepšili o naše pridania, tieto vylepšenia zaručili jednoduchšiu prácu s dátami a následne prehľadnejšie vizualizovanie datasetu.
Následné tabuľky sa robili podľa 7 existujúcich SCD typov:

0 – bez zmien, 1 – prepísanie bez histórie, 2 – nový riadok s históriou, 3 – uložená len predošlá hodnota.
4 – história v samostatnej tabuľke, 5 – kombinácia 1+4, 6 – kombinácia 1+2+3, 7 – dualný pohľad (aktuálny + historický). 



## 3.4 DIM date
Časová dimenzia umožňujúca analýzu dát podľa dňa, mesiaca a roka.
Každý dátum je unikátny a nemenný.

SCD: Type 0 – dátumy sa nikdy nemenia.
```SQL
CREATE OR REPLACE TABLE dim_date AS
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY TO_DATE(date)) AS date_id,
    TO_DATE(date) AS date,
    day,
    month,
    year
FROM test;



```

## 3.5 DIM country
Obsahuje zoznam krajín a ich názvy, slúži ako geografická dimenzia pre fakty.
Dáta sú stabilné a nemenia sa často.

SCD: Type 0 – krajiny sa nemenia, história nie je potrebná.
```SQL
CREATE OR REPLACE TABLE dim_country AS
SELECT DISTINCT
    c.country        AS country_id,
    c.countryname    AS country
FROM countries c;

```

## 3.6 DIM keyword
Ukladá kľúčové slová a prislúchajúce landing pages pre analytické účely.
Zmeny sa prepíšu bez zachovania histórie.

SCD: Type 1 – aktualizácia hodnoty bez histórie.
```SQL
CREATE OR REPLACE TABLE dim_keyword AS
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY keyword) AS keyword_id,
    keyword,
    clean_landingpage AS clean_landing_page
FROM test
WHERE keyword IS NOT NULL;


```

## 3.7 Faktová tabuľka
Táto fact tabuľka spája dátové dimenzie (date, country, keyword) s merateľnými hodnotami o výkone kľúčových slov.
Obsahuje fakty ako počet používateľov a klikov spolu s kontextom platformy, webu a typu návštevy.
Slúži na analytické dotazy v star schéme, napríklad sledovanie výkonu keywordov v čase a podľa krajiny

```SQL
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

```

---
# 4. Vizualizácia dát 
Na vizualizáciu dát použijeme sekciu Dashboard v snowflake, vytvorili sme základné vizualizačné prvky slúžiace na rýchle pochopenie a využívanie dát z nášho vybranáho datasetu.
<p align="center">
  <img src="images/grafy.png" alt="ERD diagram" width="780">
</p>

<p align="center"><em>Obrázok 4 Dashboard datasetu Google keywords</em></p>


---
## Graf 1: Počet vyhľadávaní slova youtube na svete za každý deň v mesiaci jún v roku 2022


```SQL
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
```
Kód slúži na vytvorenie grafu ktorý vizualizuje počet vyhľadávaní slova youtube a vyhľadávania obsahujúce "youtube" (pre príklad youtube.com) za každý jeden deň v mesiaci jún v roku 2022
---


## Graf 2: 10 Najvyhľadávanejších otázok v spojených štátoch Amerických podľa počtu užívateľov

```SQL
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

```
Kód slúži na vytvorenie grafu ktorý vizualizuje top 10 najvyhľadávanejších otázok v USA, slúži pre príklad na politické predikcie v období volieb alebo marketingové účely

---

## Graf 3: 25 Najvyhľadávanejších výrazov na Slovensku za mesiac jún v roku 2022 podľa počtu užívateľov

```SQL
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

```
Kód slúži na vytvorenie grafu ktorý vizualizuje 25 najvyhľadávanejších výrazov na Slovensku za mesiac jún 2022 a slúži taktiež na marketingové účely a analýzu internetového správania slovákov

---

## Graf 4: Najvyhľadávanejší výraz na Slovensku za každý deň v mesiaci jún v roku 2022

```SQL
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

```
Kód slúži na vytvorenie grafu ktorý vizualizuje najvyhľadávanejší výraz za každý jeden deň separátne
---

## Graf 5: Počet užívateľov pre okolité štáty v mesiaci jún v roku 2022
```SQL
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

```
Kód slúži na vytvorenie grafu ktorý vizualizuje počet užívateľov tým pádom analýzu užívania internetu a search enginov na počet obyvateľov v iných geopolitických miestach

---
## Graf 6: 10 krajín s najväčším počtom vyhľadávaní podľa počtu užívateľov
```SQL
SELECT 
    dc.country_name AS NAZOV_KRAJINY,
    SUM(f.calibrated_users) AS SPOLU_UZIVATELOV,
    SUM(f.calibrated_clicks) AS SPOLU_KLIKNUTI,
FROM fact_keywords f
JOIN dim_country dc ON f.country_id = dc.country_id
GROUP BY NAZOV_KRAJINY
ORDER BY SPOLU_UZIVATELOV DESC
LIMIT 10;

```
Kód slúži na vytvorenie grafu ktorý vizualizuje 10 krajín na svete kde ľudia najviac vyhľadávajú skrz google search engine





---
AUTORI: Samuel Baťo, Matúš Višňák










