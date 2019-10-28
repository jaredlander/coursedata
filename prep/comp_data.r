library(dplyr)
library(recipes)

regions <- c('North America', 'Europe', 'UK', 'Switzerland', 'AIPAC')
titles <- c('Analyst', 'Associate', 'VP', 'MD')
sectors <- c('Tech', 'Media', 'Industrials', 'Pharma', 'Law', 'Retail', 
             'Real Estate', 'CPG', 'Automotive', 'Aerospace')
reviews <- c('Negative', 'Neutral', 'Positive')

n <- 105030
set.seed(2863)
info <- tibble::tibble(
    ID=seq(from=1, to=n, by=1),
    Region=sample(regions, size=n, replace=TRUE, 
                  prob=c(0.25, 0.1, 0.25, 0.2, 0.2)),
    Title=sample(titles, size=n, replace=TRUE,
                 prob=c(0.6, 0.2, 0.15, 0.05)),
    Sector=sample(sectors, size=n, replace=TRUE),
    Level=case_when(
        Title %in% c('Analyst', 'Associate') ~ 'Junior',
        Title == 'VP' ~ 'VP',
        Title == 'MD' ~ 'Executive'
    ),
    Career=case_when(
        Title %in% c('Analyst', 'Associate') ~ 'Junior',
        Title %in% c('VP', 'MD') ~ 'Senior'
    ),
    YearCenter=case_when(
        Title == 'Analyst' ~ 2,
        Title == 'Associate' ~ 5,
        Title == 'VP' ~ 12,
        Title == 'MD' ~ 20
    ),
    YearSD=case_when(
        Title == 'Analyst' ~ 0.5,
        Title == 'Associate' ~ 1,
        Title == 'VP' ~ 2,
        Title == 'MD' ~ 2
    ),
    ReportsCenter=case_when(
        Title == 'Analyst' ~ 0,
        Title == 'Associate' ~ 3,
        Title == 'VP' ~ 30,
        Title == 'MD' ~ 350
    ),
    ReportsSD=case_when(
        Title == 'Analyst' ~ 0,
        Title == 'Associate' ~ 1,
        Title == 'VP' ~ 3,
        Title == 'MD' ~ 20
    ),
    Review=sample(reviews, size=n, replace=TRUE, 
                  prob=c(0.05, 0.50, 0.45)),
    Office=case_when(
        Title %in% c('Analyst', 'Associate') ~ 'Cubicle',
        Title == 'VP' ~ sample(c('Office', 'Shared'), size=1),
        Title == 'MD' ~ 'Corner'
    ),
    Floor=sample(1:47, size=n, replace=TRUE),
    BonusLevel=case_when(
        Title == 'Analyst' ~ 0.3,
        Title == 'Associate' ~ 0.5,
        Title == 'VP' ~ 0.8,
        Title == 'MD' ~ 3
    ),
    RaiseLevel=case_when(
        Title == 'Analyst' ~ 0.05,
        Title == 'Associate' ~ 0.07,
        Title == 'VP' ~ 0.12,
        Title == 'MD' ~ 0.25
    )
) %>% 
    group_by(Title) %>% 
    mutate(
        Years=abs(round(rnorm(n=n(), mean=YearCenter, sd=YearSD), 0)),
        Reports=abs(round(rnorm(n=n(), mean=ReportsCenter, sd=ReportsSD), 0))
    ) %>% 
    ungroup() %>% 
    mutate(
        Retirement=if_else(Years > 20, 
                           sample(x=c('Ineligible', 'Eligible'), size=1, prob=c(0.2, 0.8)),
                           sample(x=c('Ineligible', 'Eligible'), size=1, prob=c(0.9, 0.1))
        )
    ) %>% 
    select(-YearCenter, -YearSD, -ReportsCenter, -ReportsSD)

info_math <- recipe(~ ., data=info) %>% 
    step_dummy(all_nominal(), one_hot=TRUE) %>% 
    prep() %>% 
    juice()

salaries <- info_math %>% 
    mutate(
        SalaryPY=
            rnorm(n=n(),
                  mean=60000 + 0*Floor + 2500*Years + 1500*Reports + 
                      -7000*Region_Europe + 6000*Region_North.America +
                      12000*Region_Switzerland + 2000*Region_UK + 
                      -3000*Region_AIPAC + 
                      -1000*Title_Analyst + 7000*Title_Associate + 
                      26000*Title_VP + 120000*Title_MD + 
                      -6000*Review_Negative + 0*Review_Neutral + 
                      14000*Review_Positive + 
                      4000*Years + 7000*Reports,
                  sd=4000
            ) %>% round(digits=0)
    ) %>% 
    select(ID, SalaryPY) %>% 
    right_join(info, by='ID') %>% 
    group_by(Title) %>% 
    mutate(
        BonusPY=round(SalaryPY*rnorm(n(), mean=BonusLevel, sd=0.03), digits=0),
        SalaryCY=round(SalaryPY * abs((1 + rnorm(n(), mean=RaiseLevel, sd=0.05))), 0),
        BonusCY=round(SalaryCY*rnorm(n(), mean=BonusLevel, sd=0.03), digits=0)
    ) %>% 
    select(-BonusLevel, -RaiseLevel) %>% 
    select(ID, SalaryPY, SalaryCY, BonusPY, BonusCY, Region, Title, Years,
           Reports, Review, Sector, Level, Career, Office, Floor, Retirement) %>% 
    ungroup()

salaries %>% 
    group_split(Region) %>% 
    purrr::walk(
        ~ readr::write_csv(x=.x, 
                           path=here::here(
                               'data', glue::glue('Comp_{.x$Region[1]}.csv')
                           )
        )
    )
    
