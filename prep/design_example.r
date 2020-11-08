design_example <- tibble::tribble(
    ~ID, ~Weight, ~Age, ~Height, ~Eyes, ~Hair,
    1, 125, 14, 65, 'Green', 'Light',
    2, 107, 12, 62, 'Brown', 'Dark',
    3, 143, 16, 69, 'Green', 'Dark',
    4, 126, 14, 68, 'Blue', 'Light',
    5, 155, 18, 68, 'Brown', 'Dark',
    6, 153, 17, 67, 'Blue', 'Dark',
    7, 146, 17, 64, 'Green', 'Light'
)

readr::write_csv(design_example, 'data/design_example.csv')
piggyback::pb_upload('data/design_example.csv', repo='jaredlander/coursedata')
