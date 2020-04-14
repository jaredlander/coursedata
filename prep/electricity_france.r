library(magrittr)

elec_raw <- readr::read_delim(
    'raw/household_power_consumption.txt',
    delim=';',
    col_types=readr::cols(Date=readr::col_date(format='%d/%m/%Y'))
)

elec <- elec_raw %>% 
    dplyr::group_by(Date) %>% 
    dplyr::summarize(
        ActivePower=sum(Global_active_power, na.rm=TRUE)
        , ReactivePower=sum(Global_reactive_power, na.rm=TRUE)
        , Voltage=mean(Voltage, na.rm=TRUE)
        , Kitchen=sum(Sub_metering_1, na.rm=TRUE)
        , Laundry=sum(Sub_metering_2, na.rm=TRUE)
        , HVAC=sum(Sub_metering_3, na.rm=TRUE)
    ) %>% 
    tsibble::as_tsibble(index=Date)

readr::write_csv(elec, here::here('data', 'electricity_france.csv'))
piggyback::pb_upload(file='data/electricity_france.csv', repo='jaredlander/coursedata')
