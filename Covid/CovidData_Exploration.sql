/* 
Covid-19 Data Exploration 
Skills used - Joins,CTE's, Temp Tables,Windows function, Aggregate function, Creating views, Converting Data Types, Subquery*/


-- Select data that we are going to be starting with

Select continent,location,date,population,total_cases, new_cases, total_deaths
FROM
Covid_PortfolioProj..CovidDeaths
order by location,date;



-- Total Cases VS Total Deaths
-- Shows likelihood of dying in India if you contract Covid

Select continent,location,date,population,total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM
Covid_PortfolioProj..CovidDeaths
where location = 'India'
order by location,date;



-- Total Cases VS Total Population
-- Chances to get Covid in India

Select continent,location,date,population,total_cases, total_deaths, (total_cases/population)*100 as PercentagePopulationInfected
FROM
Covid_PortfolioProj..CovidDeaths
where location = 'India'
order by location,date;



-- Countries with highest Covid infected percentage and DeathPercentage by covid

Select location,population,Max(total_cases) as TotalCases, Max(Cast(total_deaths as int)) as TotalDeaths, (Max(Cast (total_cases as INT))/population)*100 as InfectedPercentage
, (Max(Cast (total_deaths as INT))/Max(total_cases))*100 as DeathPercentage
FROM
Covid_PortfolioProj..CovidDeaths
where continent is not null 
group by location,population
order by InfectedPercentage desc;



-- Global Statistics

select 
Format(Max(population),'#,#') as TotalPopulation,Format(MAx(total_cases),'#,#') as TotalCovidCases, Format(MAX(Cast(total_deaths as int)),'#,#') as TotalDeaths
from 
Covid_PortfolioProj..CovidDeaths
where location='World';



-- Breakdown by continents
select 
 location,Format(Max(population),'#,#') as totalPopulation,Format(Max(total_cases),'#,#') as totalCovidCases, Format(Max(CAST(total_deaths as bigint)),'#,#') as totaldeaths
from 
Covid_PortfolioProj..CovidDeaths
where continent is null and location in ('Asia','Africa','North America','South America','Europe','Antartica','Oceania')
group by location
order by totaldeaths desc;



-- Data along with vaccination (Population Vs Vaccination)

Select
dea.continent, dea.location, dea.date,dea.population, dea.total_cases, vac.new_vaccinations,
SUM(Cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
from Covid_PortfolioProj..CovidDeaths dea
JOIN Covid_PortfolioProj..CovidVaccinations vac
ON dea.location= vac.location and dea.date=vac.date
where dea.continent is not null
order by dea.location, dea.date;



-- Shows percentage of people that has received atleast one vaccination 
-- Using CTE to perform calculation on Partition by  in previous query

With PopVsVac(continent, location, date, population, total_cases, new_vaccinations, rollingPeopleVaccinated)
AS
(
Select
dea.continent, dea.location, dea.date,dea.population, dea.total_cases, vac.new_vaccinations,
SUM(Cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
from Covid_PortfolioProj..CovidDeaths dea
JOIN Covid_PortfolioProj..CovidVaccinations vac
ON dea.location= vac.location and dea.date=vac.date
where dea.continent is not null
)

Select 
* , (rollingPeopleVaccinated/population)*100 as percentagePeoplevaccinated
from 
PopVsVac 
order by location,date;



-- using Temp table to perform calculation on Partition by in previous query

Drop Table if exists #PercentpopulationVaccinated
Create table #PercentpopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	Total_Cases numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric
)

Insert into #PercentpopulationVaccinated
Select
dea.continent, dea.location, dea.date,dea.population, dea.total_cases, vac.new_vaccinations,
SUM(Cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
from Covid_PortfolioProj..CovidDeaths dea
JOIN Covid_PortfolioProj..CovidVaccinations vac
ON dea.location= vac.location and dea.date=vac.date
where dea.continent is not null;

Select 
*, (rollingPeopleVaccinated/population)*100 as percentagePeoplevaccinated
from #PercentpopulationVaccinated
order by location,date;



--Creating view to store the data for later Visualization

Drop view if exists PercentpopulationVaccinated
GO
Create View PercentpopulationVaccinated 
as
Select
dea.continent, dea.location, dea.date,dea.population, dea.total_cases, vac.new_vaccinations,
SUM(Cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
from Covid_PortfolioProj..CovidDeaths dea
JOIN Covid_PortfolioProj..CovidVaccinations vac
ON dea.location= vac.location and dea.date=vac.date
where dea.continent is not null;

GO

Select *from PercentpopulationVaccinated;



--  Stats of India

Select 
Format(dea.population,'#,#') as Population, 
Format(Max(dea.total_cases),'#,#') as TotalCovidCases, 
Format(Max(CAST(dea.total_deaths as bigint)),'#,#') as Totaldeaths,
Format(Max(Cast(vac.people_vaccinated as bigint)),'#,#') as PeopleVaccinated, 
Format(Max(Cast(vac.people_fully_vaccinated as bigint)),'#,#') as PeopleFullyVaccinated,
(Max(Cast(vac.people_fully_vaccinated as bigint))/dea.population)*100 as PercentageOfPeopleFullyVaccinated
from 
Covid_PortfolioProj..CovidDeaths dea 
JOIN Covid_PortfolioProj..CovidVaccinations vac
On dea.location = vac.location AND dea.date= vac.date
where dea.location = 'India'
group by dea.population;



-- Month Wise Covid Cases Breakdown for India
Select 
ywb.EffectiveYear,ywb.MonthName,ywb.Total_Cases,ywb.Deaths,ywb.MonthlyDeathPercentage,PeopleVaccinated
FROM
(
Select 
Year(dea.date) as EffectiveYear,
MONTH(dea.date) as MonthNumber, DATENAME(month,dea.date) as MonthName,
Format(SUM(dea.new_cases),'#,#') as Total_Cases, ISNULL(Format(SUM(Convert(int,new_deaths)),'#,#'),0) as Deaths,
ISNULL((SUM(Convert(int,new_deaths))/SUM(dea.new_cases))*100,0) as MonthlyDeathPercentage,
ISNULL(Format((MAX(Convert(bigint,vac.people_vaccinated)) - ISNull(Lag(MAX(Convert(bigint,vac.people_vaccinated))) Over (order by Year(dea.date),Month(dea.date)),0)),'#,#'),0)  As PeopleVaccinated
from 
Covid_PortfolioProj..CovidDeaths dea 
JOIN Covid_PortfolioProj..CovidVaccinations vac
On dea.location = vac.location AND dea.date= vac.date
where dea.location = 'India' 
group by Year(dea.date), MONTH(dea.date),DATENAME(month,dea.date)
) ywb
order by ywb.EffectiveYear,ywb.MonthNumber;






