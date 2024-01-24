SELECT *
FROM Portfolio_Project..CovidDeaths
Where continent is not null
ORDER BY 3,4 


--SELECT *
--FROM Portfolio_Project..CovidVaccinations
--ORDER BY 3,4 


-- Select Data that we are going to using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio_Project..CovidDeaths
Where continent is not null
ORDER BY 1,2 


-- Looking at Total Cases vs Total Deaths
-- Shows likelyhood of dying if we contract covid in country
SELECT location, date, total_cases, total_deaths, (cast(total_deaths as float)/cast(total_cases as float))*100 as DeathPercentage
FROM Portfolio_Project..CovidDeaths
Where location = 'Russia' and total_cases is not null
ORDER BY 1,2 


-- Looking a Total Cases VS Population
-- Shows what percentage of population got Covid
SELECT location, date, Population, total_cases, (cast(total_cases as float)/population)*100 as PercentageOfPopInfected
FROM Portfolio_Project..CovidDeaths
Where continent is not null
ORDER BY 1,2


-- Looking at Countries with Highest Infection Rate compared to population

SELECT location, Population, max(cast(total_cases as float)) as HighestInfCount, Max((cast(total_cases as float)/population))*100 
as PercentageOfPopInfected
FROM Portfolio_Project..CovidDeaths
Where continent is not null
Group by location, Population
ORDER BY 4 desc


-- Showing Countries with Highest Death Count per Population


SELECT location, max(cast(total_deaths as int)) as HighestDeathCount
FROM Portfolio_Project..CovidDeaths
Where continent is not null
Group by location
ORDER BY HighestDeathCount desc


-- Let's things break down by Continent

-- Showing continents with the highest death count per population

SELECT continent, max(cast(total_deaths as int)) as HighestDeathCount
FROM Portfolio_Project..CovidDeaths
Where continent is not null
Group by continent
ORDER BY HighestDeathCount desc


-- GLOBAL NUMBERS
SELECT SUM(new_cases) as total_cases, Sum(new_deaths) as total_deaths, sum(new_deaths)/sum(new_cases)*100 as DeathPercentage
FROM Portfolio_Project..CovidDeaths
-- Where location = 'Russia' and total_cases is not null
Where continent is not null and new_cases is not null
-- GROUP BY date
ORDER BY 1,2 


-- Looking at Total Population vs Vaccinations
-- vac.new_vaccinations as bigint (The bigint data type is used to store values outside the range supported by the int data type)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as bigint)) over 
	(Partition By dea.location order by dea.location, dea.date ROWS UNBOUNDED PRECEDING) 
-- When you write ROWS UNBOUNDED PRECEDING, then the frame's lower bound is simply infinite. This is useful when calculating sums (i.e. "running totals")
as Rolling_People_Vac
FROM Portfolio_Project..CovidDeaths dea
join Portfolio_Project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- we can't use a column that's just created, so we use Common Table Expression (CTE)
-- or temp table.
--Use CTE
-- check,  the number of columns in the cte must be equal the number of columns in head query

WITH PopvsVac (continent, location, date, population, new_vaccinations, Rolling_People_Vac)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as bigint)) over 
	(Partition By dea.location order by dea.location, dea.date ROWS UNBOUNDED PRECEDING)
as Rolling_People_Vac
FROM Portfolio_Project..CovidDeaths dea
join Portfolio_Project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
SELECT *, (Rolling_People_Vac/population)*100 AS PercentageOfVaccinatedPeople
FROM PopvsVac




-- TEMP TABLE
DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric, 
New_vaccinations numeric,
Rolling_People_Vac numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as bigint)) over 
	(Partition By dea.location order by dea.location, dea.date ROWS UNBOUNDED PRECEDING)
as Rolling_People_Vac
FROM Portfolio_Project..CovidDeaths dea
join Portfolio_Project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null

SELECT *, (Rolling_People_Vac/population)*100 AS PercentageOfVaccinatedPeople
FROM #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as bigint)) over 
	(Partition By dea.location order by dea.location, dea.date ROWS UNBOUNDED PRECEDING)
as Rolling_People_Vac
FROM Portfolio_Project..CovidDeaths dea
join Portfolio_Project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3


Select *
From PercentPopulationVaccinated