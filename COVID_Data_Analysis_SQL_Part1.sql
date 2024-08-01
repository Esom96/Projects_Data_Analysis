SELECT *
FROM "owid-covid-data.csv"
WHERE continent IS NOT NULL;


SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM "owid-covid-data.csv"
order by 1,2;

-- TOTAL CASES VS TOTAL DEATHS
SELECT location, date, total_cases, total_deaths, ((total_deaths/total_cases)*100) AS death_ratio
FROM "owid-covid-data.csv"
WHERE location = 'Poland'
	AND continent IS NOT NULL
ORDER BY 1,2;

-- TOTAL CASES VS POPULATION
SELECT location, date, total_cases, population, ((total_cases/population)*100) AS sick_ratio
FROM "owid-covid-data.csv"
WHERE location = 'Poland'
	AND continent IS NOT NULL
ORDER BY 1,2;

-- HIGHEST INFECTION RATE VS POPULATION
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population)*100) AS max_sick_ratio
FROM "owid-covid-data.csv"
WHERE continent IS NOT NULL
GROUP BY population, location
ORDER BY max_sick_ratio DESC;

-- COUNTRIES WITH HIGHEST DEATH COUNT VS POPULATION
SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM "owid-covid-data.csv"
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;

-- FOUND OUT THAT QUERYING SHOWS ALSO AGGREGATED CONTINENT VALUES, WE CAN AVOID THAT BY SIMPLY USING
-- "WHERE continent IS NOT NULL"
-- ADDED THE MENTIONED CODE TO ALL QUERIES PREVIOUSLY EXECUTED

-- COUNTRIES WITH HIGHEST DEATH COUNT VS POPULATION
SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM "owid-covid-data.csv"
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC;

--- GLOBAL DATA
--GLOBAL DEATH RATE IN TIME
SELECT date, SUM(new_cases) AS total_cases_global, SUM(new_deaths) AS total_deaths_global, (SUM(new_deaths)/SUM(new_cases)*100) AS global_death_rate
FROM "owid-covid-data.csv"
GROUP BY date;

-- GLOBAL DATA WITH CASES, DEATHS, DEATH RATIO
SELECT SUM(new_cases) AS total_cases_global, SUM(new_deaths) AS total_deaths_global, (SUM(new_deaths)/SUM(new_cases)*100) AS global_death_rate
FROM "owid-covid-data.csv"
WHERE continent IS NOT NULL;

-- TOTAL POPULATION VS VACCINATIONS - THE DATA HAS BEEN MERGED FROM TWO SEPERATE FILES AT THE BEGINNING OF ANALYSIS SO THERES NO NEED TO USE JOINS HERE
-- BELOW EXAMPLE WITH THE CODE IF THE DATA WAS NOT MERGED (JOINS) - PLEASE BE AWARE THIS CODE WILL NOT WORK HERE AS I'M USING ONLY ONE TABLE
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations
FROM "owid-covid-data.csv".CovidDeaths AS deaths
JOIN "owid-covid-data.csv".CovidVaccinations as vaccinations
	ON deaths.location = vaccinations.location
	AND deaths.date = vaccinations.date
WHERE deaths.continent is NOT NULL
ORDER BY 2,3;

-- TOTAL POPULATION VS ROLLING VACCINATIONS
SELECT continent, location, date, population, new_vaccinations, (SUM(CAST(new_vaccinations AS int)) OVER (PARTITION BY location ORDER BY location, date)) AS rolling_vaccination
FROM "owid-covid-data.csv"
WHERE continent IS NOT NULL
ORDER BY 2,3;

-- COMPARING TOTAL POPULATION WITH THE ROLLING VACCINATIONS USING CTE
WITH population_vs_rolling_vaccination (continent, location, date, population, new_vaccinations, rolling_vaccination)
	AS
(
	SELECT continent, location, date, population, new_vaccinations, (SUM(CAST(new_vaccinations AS int)) OVER (PARTITION BY location ORDER BY location, date)) AS 		rolling_vaccination
	FROM "owid-covid-data.csv"
	WHERE continent IS NOT NULL
)
SELECT *, ((rolling_vaccination/population)*100) AS people_vaccinated
FROM population_vs_rolling_vaccination;

-- COMPARING TOTAL POPULATION WITH THE ROLLING VACCINATIONS USING TEMP TABLE
DROP TABLE IF EXISTS RollingVaccinationsCovid;
CREATE TABLE RollingVaccinationsCovid
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	rolling_vaccination numeric
);

INSERT INTO RollingVaccinationsCovid
	SELECT continent, location, date, population, new_vaccinations, (SUM(CAST(new_vaccinations AS int)) OVER (PARTITION BY location ORDER BY location, date)) AS 		rolling_vaccination
	FROM "owid-covid-data.csv"
	WHERE continent IS NOT NULL;

SELECT *, ((rolling_vaccination/population)*100) AS people_vaccinated
FROM RollingVaccinationsCovid;


-- CREATING AND USING VIEWS
CREATE VIEW VaccinatedPopulationPercentage_worktable AS
SELECT continent, location, date, population, new_vaccinations, (SUM(CAST(new_vaccinations AS int)) OVER (PARTITION BY location ORDER BY location, date)) AS rolling_vaccination
FROM "owid-covid-data.csv"
WHERE continent IS NOT NULL
ORDER BY 2,3;

SELECT *
FROM VaccinatedPopulationPercentage_worktable
