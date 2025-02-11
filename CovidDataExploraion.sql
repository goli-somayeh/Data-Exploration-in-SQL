SELECT * FROM CovidDeaths LIMIT 10;
SELECT * FROM CovidVaccinations LIMIT 10;


SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2;


-- Likelihood of dying from Covid in each country

SELECT Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2;


-- percentage of population infected with Covid

SELECT Location, date, Population, total_cases,  (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
ORDER BY 1,2;


-- Countries with Highest Infection Rate compared to Population

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount,  MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;


-- Countries with Highest Death Count per Population

SELECT Location, MAX(CAST(Total_deaths AS SIGNED)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeathCount DESC;


-- Contintents with the highest death count per population

SELECT continent, MAX(CAST(Total_deaths AS SIGNED)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS SIGNED)) AS total_deaths, SUM(CAST(new_deaths AS SIGNED))/SUM(New_Cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL 
-- Group By date
ORDER BY 1,2;


-- Total Population vs Vaccinations
-- Percentage of Population that has recieved at least one Covid Vaccine

Select CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations
, SUM(CAST(CovidVaccinations.new_vaccinations AS SIGNED)) OVER (Partition by CovidDeaths.Location Order by CovidDeaths.location, CovidDeaths.Date) as RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
From CovidDeaths 
Join CovidVaccinations 
	On CovidDeaths.location = CovidVaccinations.location
	and CovidDeaths.date = CovidVaccinations.date
where CovidDeaths.continent is not null 
order by 2,3;



-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
-- order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac;



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS PercentPopulationVaccinated;

CREATE TABLE PercentPopulationVaccinated (
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATETIME,
    Population DECIMAL(18,2),
    New_vaccinations DECIMAL(18,2),
    RollingPeopleVaccinated DECIMAL(18,2)
);

-- Insert data into the table
INSERT INTO PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) 
        OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date;

-- Retrieve data from the table
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS VaccinationPercentage
FROM PercentPopulationVaccinated;


-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated_View AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) 
        OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;





