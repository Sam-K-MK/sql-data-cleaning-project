-- Data Cleaning 

-- create a staging table to keep the raw data separate 
CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging

-- insert all of the data into the staging table 
INSERT layoffs_staging 
SELECT *
FROM layoffs;

-- 1. Remove duplicates 

-- there is no unique identifying column, create a row number where all of the columns are identical
-- where row is > 1 this will show duplicates  
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- create a cte to identify the duplicate rows 
WITH duplicate_cte AS 
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT * 
FROM duplicate_cte
WHERE row_num > 1;

-- check it has worked correctly 
SELECT *
FROM layoffs_staging
WHERE company = 'Casper'

-- create new table to delete the duplicate rows
-- right click on the table and select generate SQL and then DDL 
-- add a column for row_num 

CREATE TABLE `layoffs_staging3` (
  `company` varchar(50) DEFAULT NULL,
  `location` varchar(50) DEFAULT NULL,
  `industry` varchar(50) DEFAULT NULL,
  `total_laid_off` varchar(50) DEFAULT NULL,
  `percentage_laid_off` varchar(50) DEFAULT NULL,
  `date` varchar(50) DEFAULT NULL,
  `stage` varchar(50) DEFAULT NULL,
  `country` varchar(50) DEFAULT NULL,
  `funds_raised_millions` varchar(50) DEFAULT NULL,
  `row_num` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- insert the data from the staging table including the row_num
INSERT INTO layoffs_staging3
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

SELECT *
FROM layoffs_staging3
WHERE row_num > 1;

-- delete the rows 
DELETE
FROM layoffs_staging3
WHERE row_num > 1;

SELECT *
FROM layoffs_staging3;

-- 2. Standardise Data (finding issues and fixing)

SELECT company, TRIM(company)
FROM layoffs_staging3;

-- remove whitespaces from column
UPDATE layoffs_staging3
SET company = TRIM(company);

-- check inconsistent names for the same data
SELECT DISTINCT(industry)
FROM layoffs_staging3
WHERE industry LIKE 'Crypto%';

-- update incorrect data  
UPDATE layoffs_staging3
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'

-- check all columns individually for errors
SELECT DISTINCT(country)
FROM layoffs_staging3
ORDER BY 1;

-- country has two entries for United States one with . one without. update 
SELECT country, TRIM(TRAILING '.' FROM country) 
FROM layoffs_staging3; 

UPDATE layoffs_staging3 
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

SELECT *
FROM layoffs_staging3;

-- change format of date column (first need to sort 'NULL' string values)
UPDATE layoffs_staging3
SET `date` = NULL 
WHERE `date` = '' OR `date` = 'NULL';


SELECT `date`, 
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging3;

UPDATE layoffs_staging3 
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging3 
MODIFY COLUMN `date` DATE;

UPDATE layoffs_staging3
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y')
WHERE `date` IS NOT NULL AND `date` != '';

-- 3. Look at null or blank values

-- using join to populate industry values where two companies are the same
SELECT t1.industry, t2.industry
FROM layoffs_staging3 t1
JOIN layoffs_staging3 t2
	ON t1.company = t2.company	
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- change all blanks or NULL string cells to NULL values 
UPDATE layoffs_staging3
SET funds_raised_millions = NULL 
WHERE funds_raised_millions = '' OR funds_raised_millions = 'NULL';


-- updating blank or NULL values with correct industry 
UPDATE layoffs_staging3 t1
JOIN layoffs_staging3 t2
	ON t1.company = t2.company	
SET t1.industry = t2.industry 
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- check final NULL value, indicates only 1 entry from country so unable to populate it 
SELECT * 
FROM layoffs_staging3
WHERE company LIKE 'Bally%'

-- find rows where there is no data in the total laid off and percentage laid off rows were NULL
SELECT * 
FROM layoffs_staging3 
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL; 

-- delete these rows (be cautious when deleting)
DELETE 
FROM layoffs_staging3 
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL; 


-- 4. Remove any columns

SELECT * 
FROM layoffs_staging3 ls 

-- drop row_num column 

ALTER TABLE layoffs_staging3 
DROP COLUMN row_num;

-- 5. update data type 

ALTER TABLE layoffs_staging3
MODIFY COLUMN total_laid_off INT;

