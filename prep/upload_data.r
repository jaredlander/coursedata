library(piggyback)
library(magrittr)
library(ssh)
pb_track('data/*')

session <- ssh_connect('jaredlander@jaredlander.com', '~/../.ssh/id_rsa')
session


all_files <- fs::dir_ls('data')
all_files <- all_files[all_files != 'data/data.md']

all_files %>% 
    purrr::walk(pb_upload, tag='v0.0.1')

# individual files
pb_upload('data/TomatoTypes.csv')
scp_upload(session=session, files='data/TomatoTypes.csv', to='www/www/data/TomatoTypes.csv')

pb_upload('data/TomatoPizzerias.csv')
scp_upload(session=session, files='data/TomatoPizzerias.csv', to='www/www/data/TomatoPizzerias.csv')

pb_upload('data/gdp_us.csv')
scp_upload(session=session, files='data/gdp_us.csv', to='www/www/data/gdp_us.csv')
