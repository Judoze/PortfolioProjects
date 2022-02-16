/*
DATA CLEANING PROCESS FOR ANALYSIS AND VISUALIZATION
*/

--Step 1 Query all data in both datasets imported to confirm we are working with accurate data:

SELECT *
FROM PortfolioProject..CovidDeaths$
ORDER BY location

SELECT *
FROM PortfolioProject..CovidVaccinations$
ORDER BY location

--Step 2 Streamline the data by selecting only columns relevant to the analysis to be done:

SELECT location, date, total_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths$
ORDER BY location, date

-- 1: Show Total Cases vs Total Deaths and Death percentage for each country by date.

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL 
ORDER BY location, date

-- 2: Show and compare Total cases with the Population of each country by date.

SELECT location, date, population, total_cases,  (total_cases/population)*100 as "population_infected(%)"
FROM PortfolioProject..CovidDeaths$
ORDER by location, date


-- 3: Show in descending order, current total infection rate by country.

SELECT location, population, 
MAX(total_cases) as current_infection_count,  
Max((total_cases/population))*100 as "population_infected(%)"
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL 
GROUP BY location, population
ORDER BY "population_infected(%)" DESC


-- 4: Show in descending order, current total death count by country.

SELECT continent, 
MAX(cast(total_deaths as int)) as total_death_count
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY total_death_count DESC


-- 5: Show in descending order, current total death count by continent.

SELECT continent, 
MAX(cast(total_deaths as int)) as total_death_count
FROM PortfolioProject..CovidDeaths$
WHERE location IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC


--6: Show Total Cases and Total Deaths across the world

SELECT SUM(new_cases) AS total_cases, 
SUM(CAST(new_deaths AS INT)) AS total_deaths, 
SUM(CAST(new_deaths AS INT))/SUM(New_Cases)*100 AS death_percentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL


--7: Compare total populations to total number of vaccinations showing percentage of the population that has received at least one vaccine.

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CAST(v.new_vaccinations AS numeric)) OVER (PARTITION BY d.location ORDER BY d.location, d.Date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ d
JOIN PortfolioProject..CovidVaccinations$ v
	On d.location = v.location
	and d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY location, date


-- Adding a CTE (WITH Clause to get the percentage of people vaccinated by dates)

WITH PopvsVac (continent, location, Date, Population, New_Vaccinations, rolling_people_vaccinated)
AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CAST(v.new_vaccinations AS numeric)) OVER (PARTITION BY d.location ORDER BY d.location, d.Date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths$ d
JOIN PortfolioProject..CovidVaccinations$ v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL )
SELECT *, (rolling_people_vaccinated/Population)*100 AS population_percentage_vaccinated
FROM PopvsVac


--Alternatively a temp table can be created to achieve same results with query above^

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated 
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CAST(v.new_vaccinations AS NUMERIC)) OVER (PARTITION BY d.location ORDER BY d.location, d.Date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths$ d
JOIN PortfolioProject..CovidVaccinations$ v
	ON d.location = v.location
	and d.date = v.date
WHERE d.continent IS NOT NULL

SELECT location, population, MAX((rolling_people_vaccinated/Population)*100) AS population_percentage_vaccinated
FROM #PercentPopulationVaccinated
GROUP BY location, population
ORDER BY location

-- 8: Create views for visualization

--Show Global Numbers 
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, SUM(cast(new_deaths AS int))/SUM(New_Cases)*100 AS death_percentage
FROM PortfolioProject..CovidDeaths$
WHERE continent is not null 


--Show Death count by continent
SELECT location, SUM(cast(new_deaths AS int)) AS total_death_count
FROM PortfolioProject..CovidDeaths$
WHERE continent is null 
AND location NOT IN ('World', 'European Union', 'International', 'Upper middle income', 'High income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY total_death_count DESC

--Show Percentage of population infected by country
SELECT Location, population, MAX(total_cases) AS highest_infection_count,  Max((total_cases/population))*100 AS percent_population_infected
FROM PortfolioProject..CovidDeaths$
GROUP BY Location, population
ORDER BY percent_population_infected DESC


--Show Percentage of population infected by country over time
SELECT location, population, date, MAX(total_cases) AS highest_infection_count,  Max((total_cases/population))*100 AS percent_population_infected
FROM PortfolioProject..CovidDeaths$
WHERE continent is NOT null 
GROUP BY location, population, date













