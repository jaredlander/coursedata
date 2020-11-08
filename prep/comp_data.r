library(dplyr)
library(recipes)

build_comps <- function(n=1000)
{
    n <- n
    regions <- c('North America', 'Europe', 'UK', 'Switzerland', 'AIPAC')
    titles <- c('Analyst', 'Associate', 'VP', 'MD')
    sectors <- c('Tech', 'Media', 'Pharma', 'Law', 'Retail', 'Real Estate')
    reviews <- c('Negative', 'Neutral', 'Positive')

    info <- tibble::tibble(
        ID=seq(n),
        Region=sample(regions, size=n, replace=TRUE, 
                      prob=c(0.30, 0.10, 0.15, 0.20, 0.25)
        ),
        Title=sample(titles, size=n, replace=TRUE,
                     prob=c(0.55, 0.2, 0.15, 0.10)
        ),
        Sector=sample(sectors, size=n, replace=TRUE,
                      prob=c(0.20, 0.15, 0.25, 0.05, 0.15, 0.20)
        ),
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
            Title == 'VP' ~ 3,
            Title == 'MD' ~ 4
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
            Title == 'MD' ~ 30
        ),
        Review=sample(reviews, size=n, replace=TRUE, 
                      prob=c(0.05, 0.55, 0.40)),
        Office=case_when(
            Title %in% c('Analyst') ~ 'Cubicle',
            Title %in% c('Associate') ~ sample(c('Cubicle', 'Shared'), size=1, prob=c(0.7, 0.3)),
            Title == 'VP' ~ sample(c('Shared', 'Office'), size=1, prob=c(0.65, 0.35)),
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
                      mean=60000 + 0*Floor + 1500*Years + 1200*Reports + 
                          -7000*Region_Europe + 6000*Region_North.America +
                          12000*Region_Switzerland + 0*Region_UK + 
                          -3000*Region_AIPAC + 
                          0*Title_Analyst + 7000*Title_Associate + 
                          17000*Title_VP + 60000*Title_MD + 
                          -6000*Review_Negative + 0*Review_Neutral + 
                          14000*Review_Positive + 
                          1800*Years + 3500*Reports,
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
    
    return(salaries)
}

set.seed(2863)
salaries <- build_comps(n=107237)

salaries %>% 
    group_split(Region) %>% 
    purrr::walk(
        ~ readr::write_csv(x=.x, 
                           path=here::here(
                               'data', 
                               stringr::str_replace_all(
                                   glue::glue('Comp_{.x$Region[1]}.csv'),
                                   pattern=' +', replacement='_'
                               )
                           )
        )
    )

# piggyback::pb_delete('data/Comp_Switzerland.csv')

dir('data', pattern='^Comp.+\\.csv') %>% 
    file.path('data', .) %>% 
    purrr::map(~piggyback::pb_upload(.x, repo='jaredlander/coursedata'))

# test data
set.seed(28631)
salaries_test <- build_comps(n=10823)
readr::write_csv(x=salaries_test, 'data/salary_test.csv')

piggyback::pb_upload(file='data/salary_test.csv', repo='jaredlander/coursedata')
