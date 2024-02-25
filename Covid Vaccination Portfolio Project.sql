
SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVacinations
--ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

--Looking at Total Cases and Total Deaths
--Shows the likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths as FLOAT)/CAST(total_cases as FLOAT))*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like 'vietnam'
ORDER BY 1,2


--Looking at Total Cases vs Population
--Show percentage of population got Covid
SELECT location, date, total_cases, population, (CAST(total_cases as FLOAT)/CAST(population as FLOAT))*100 as InfectedPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like 'Vietnam'
ORDER BY 1,2

--Looking at country with the highest infection rate compare to population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, (MAX(total_cases)/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

--Showing countries with highest death count per population

SELECT location, population, MAX(CAST(total_deaths as INT)) as HighestDeathCount, (MAX(CAST(total_deaths as INT))/population)*100 as PercentagePopulationDeath
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY HighestDeathCount DESC

--BREAK THINGS DOWN BY CONTINENT

SELECT continent, MAX(CAST(total_deaths as INT)) as HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY HighestDeathCount DESC

SELECT continent, MAX(CAST(total_deaths as INT)) as TotalDeathCount from PortfolioProject..CovidDeaths
Where continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC


--GLOBAL NUMNER

SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as INT)) as total_deaths, SUM(CAST(new_deaths as INT))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null and new_cases <> 0
--GROUP BY date
ORDER BY 1,2

--Looking at Total Population vs Vacination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVacinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVacinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

--Since we want to use RollingPeopleVacinated to do further calculation, but we cant do it without repeat the whole SUM, we will need to use CTE

--USE CTE

WITH PopVsVac(continent, Location, Data, Population,New_Vaccination, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVacinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)

SELECT *, (RollingPeopleVaccinated/Population)*100 as PercentageVaccinated
FROM PopVsVac


--USE TEMP TABLE
DROP TABLE IF EXISTS #PercentagePopulationVaccinated
CREATE TABLE #PercentagePopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentagePopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVacinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (RollingPeopleVaccinated/Population)*100 as PercentageVaccinated
FROM #PercentagePopulationVaccinated


--Creating view to store data for later visualization

CREATE VIEW PercentagePopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVacinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT * FROM PercentagePopulationVaccinated