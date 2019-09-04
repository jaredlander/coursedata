library(piggyback)
library(magrittr)
pb_track('data/*')


all_files <- fs::dir_ls('data')
all_files <- all_files[all_files != 'data/data.md']

all_files %>% 
    purrr::walk(pb_upload, tag='v0.0.1')
