-- Exploratory data analysis 

SELECT * 
FROM layoffs_staging3 ls 

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging3 ls

-- look at companies with 100% laid off 
SELECT * 
FROM layoffs_staging3 ls
WHERE ls.percentage_laid_off = 1
ORDER BY total_laid_off DESC

-- calculate total laid off per company 
SELECT company, SUM(total_laid_off)
FROM layoffs_staging3 ls
GROUP BY company
ORDER BY 2 DESC; -- column 2 total laid off

-- review date range 
SELECT MIN(`date`), MAX(`date`) 
FROM layoffs_staging3 ls

-- calculate total laid off per industry, country 
SELECT ls.industry , SUM(total_laid_off)
FROM layoffs_staging3 ls
GROUP BY industry 
ORDER BY 2 DESC; -- column 2 total laid off

SELECT ls.country , SUM(total_laid_off)
FROM layoffs_staging3 ls
GROUP BY country  
ORDER BY 2 DESC; -- column 2 total laid off

-- compare by total laid off by year 
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging3 ls
GROUP BY YEAR(`date`) 
ORDER BY 1 DESC; -- column 2 total laid off

-- extract month, total laid off per month  
SELECT SUBSTRING(`date`, 1, 7) AS MONTH, SUM(ls.total_laid_off )
FROM layoffs_staging3 ls 
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY `MONTH` ASC

-- create rolling sum based on month
WITH rolling_total AS 
(
SELECT SUBSTRING(`date`, 1, 7) AS MONTH, SUM(ls.total_laid_off) AS total_off
FROM layoffs_staging3 ls 
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY `MONTH` ASC
)
SELECT `MONTH`, total_off, 
SUM(total_off) OVER(ORDER BY `MONTH`) AS rolling_total
FROM rolling_total;

-- total per company, per year 
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging3 ls 
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

WITH company_year (company, years, total_laid_off) AS 
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging3 ls 
GROUP BY company, YEAR(`date`)
), company_year_rank AS
(
SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
FROM company_year
WHERE years IS NOT NULL
)
SELECT * 
FROM company_year_rank
WHERE ranking <= 5;