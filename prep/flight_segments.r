library(dplyr)
library(tidyr)

flights <- readr::read_csv(here::here('data', 'flightPaths.csv'))

flightSegments <- flights %>% 
    rename_with(.cols=starts_with('o', ignore.case=FALSE), .fn=~stringr::str_replace(.x, '^o', 'Origin_')) %>%
    rename_with(.cols=starts_with('d', ignore.case=FALSE), .fn=~stringr::str_replace(.x, '^d', 'Destination_')) %>%
    rename(Origin_Airport=Origin, Destination_Airport=Destination) %>% 
    tibble::rowid_to_column(var='Segment') %>% 
    pivot_longer(
        starts_with(c('Origin', 'Destination')), 
        names_to=c("Place", ".value"),
        names_sep="_"
    )

readr::write_csv(flightSegments, here::here('data', 'flightSegments.csv'))
piggyback::pb_upload(file='data/flightSegments.csv', repo='jaredlander/coursedata')

download.file('http://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73909/world.topo.bathy.200412.3x5400x2700.jpg',
              here::here('data', 'nasa_globe.jpg'), mode='wb')
piggyback::pb_upload(file='data/nasa_globe.jpg', repo='jaredlander/coursedata')
