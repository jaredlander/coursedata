library(dplyr)
library(piggyback)
library(ssh)

# more information at https://www.bls.gov/tus/atusintcodebk20.pdf

# all the columns that start with a t are explained at 
# https://www.bls.gov/tus/lexiconwex2020.pdf

# this is summary information about the respondent
atus <- readr::read_csv(here::here('raw', 'atussum_2020.dat'))
# this has information on the household (not activities)
roster <- readr::read_csv(here::here('raw', 'atusrost_2020.dat'))

# Data Manip ####
# TEIO1ICD = industry code for respondent's main job
# -1: blank
# -2: don't know
# -3: refused
time_use <- atus |> 
    select(
        ID=TUCASEID, Age=TEAGE, Sex=TESEX,
        FinalWeight=TU20FWGT, AgeOfYoungestChild=TRYHHCHILD,
        WorkHoursPerWeek=TEHRUSLT, 
        LaborForceStatus=TELFS,
        EmploymentType=TRDPFTPT,
        CurrentPostSecondaryStudent=TESCHENR, # only asked of people aged 15-49
        HighSchoolOrCollege=TESCHLVL,
        PartnerEmployment=TESPEMPNOT,
        PartnerEmploymentType=TRSPFTPT,
        NumberOfHouseholdChildren=TRCHILDNUM, 
        WeeklyEarnings=TRERNWA,
        Holiday=TRHOLIDAY,
        # For TUECYTD=1
        # sum of TRTEC_LN
        # Excludes time spent in activities with codes = 01xxxx or 0805xx.
        ElderCareTime=TRTEC,
        # Total time spent during diary day providing secondary childcare for
        # household children < 13 (in minutes)
        # TRTHH is the sum of all values of TRTHH_LN for each TUCASEID
        SecondaryChildCare=TRTHH,
        DiaryDayOfWeek=TUDIARYDAY,
        Sleeping=t010101, Sleeplessness=t010102,
        # these are added to make up personal care
        washing=t010201, grooming=t010299, health_self=t010301,
        PersonalActivities=t010401,
        Housecleaning=t020101, Laundry=t020102,
        # combined into cooking
        FoodPrep=t020201, FoodPresentation=t020202, FoodClean=t020203, FoodMisc=t020299,
        # home maintenance
        decoration=t020301, repair=t020302, hvac_repair=t020303, repair_misc=t020399,
        exterior_cleaning=t020401, exterior_repair=t020402, exterior_misc=t020499,
        # Lawn
        lawn_care=t020501, pool_care=t020502, lawn_misc=t020599,
        # AnimalCare
        animal_care=t020601, animal_activity=t020602, animal_misc=t020699,
        # VehicleCare
        vehicle_repair=t020701, vehicle_misc=t020799,
        FinancialManagement=t020901, HousePlanning=t020902,
        ## children stuff
        # ChildCare
        child_care=t030101, child_talk=t030106, child_planning=t030108,
        child_looking=t030109, child_waiting=t030111, child_drive=t030112,
        child_events=t030110,
        # ChildPlay
        child_play=t030103, child_sports=t030105, child_crafts=t030104, 
        child_reading=t030102,
        # ChildEducation - activies for children's education
        child_homework=t030201, child_school_meetings=t030202,
        # ChildHealth
        child_medical=t030301, child_doctor=t030302, child_doctor_wait=t030303,
        # AdultCare
        adult_care=t030401, adult_looking=t030402, adult_medical=t030403, 
        adult_doctor=t030404, adult_doctor_wait=t030405,
        # Work
        work_main=t050101, work_other=t050102, work_security=t050103, 
        work_waiting=t050104, work_social=t050201, 
        # work_eating=t050202,  # not in data for some reason
        work_sports=t050203, 
        # work_security_job=t050204,   # not in data for some reason
        # work_waiting_job=t050205,  # not in data for some reason
        # TakingClass
        class_for_degree=t060101, class_for_personal=t060102, 
        class_waiting=t060103, class_misc=t060199,
        # Homework
        homework_degree=t060201, homework_personal=t060202, homework_misc=t060299,
        # Shopping
        shop_grocery=t070101, shop_gas=t070102, shop_food=t070103, shop_etc=t070104,
        shop_research=t070201,
        # Socializing
        social_social=t120101, social_events_1=t120201, social_events_2=t120202,
        # TVAndMovie
        TvAndMovies=t120303,
        Radio=t120305,
        Music=t120306,
        Games=t120307,
        Computer=t120308,
        ArtsAndCrafts=t120309,
        Reading=t120312,
        Writing=t120313,
        Museums=t120402,
        Movies=t120403,
        Casinos=t120404,
        Relaxing=t120301,
        # Playing Sports
        Aerobics=t130101, Baseball=t130102, Basketball=t130103, 
        Biking=t130104, Billiards=t130105, Boating=t130106, 
        Bowling=t130107, Climbing=t130108, Dancing=t130109, 
        Equestrian=t130110, 
        # Fencing=t130111, # not in data
        Fishing=t130112, 
        Football=t130113, Golf=t130114, 
        # Gymnastics=t130115, # not in data
        Hiking=t130116, Hockey=t130117, Hunting=t130118, 
        MartialArts=t130119, RaquetSports=t130120, 
        # Rodeo=t1301121, # not in data
        Rollerblading=t130122, 
        # Rugby=t130123, # not in data
        Running=t130124,
        SnowSports=t130125, Soccer=t130126, Softball=t130127, 
        Cardio=t130128, CarRacing=t130129, Volleyball=t130130, 
        Walking=t130131, WaterSports=t130132, Weightlifting=t130133, 
        WorkingOut=t130134, 
        # Wrestling=t130135, # not in data
        Yoga=t130136,
        # Watching Sports
        # WatchingAerobics=t130201, 
        WatchingBaseball=t130202, WatchingBasketball=t130203, 
        # WatchingBiking=t130204, WatchingBilliards=t130205, WatchingBoating=t130206, 
        # WatchingBowling=t130207, WatchingClimbing=t130208, WatchingDancing=t130209, 
        WatchingEquestrian=t130210, 
        # Fencing=t130211, # not in data
        WatchingFishing=t130212, 
        WatchingFootball=t130213, 
        # Golf=t130214, 
        # Gymnastics=t130215, # not in data
        WatchingHiking=t130216, 
        # WatchingHockey=t130217, WatchingHunting=t130218, 
        # WatchingMartialArts=t130219, 
        WatchingRaquetSports=t130220, 
        # Rodeo=t1302121, # not in data
        # WatchingRollerblading=t130222, 
        # Rugby=t130223, # not in data
        WatchingRunning=t130224,
        # WatchingSnowSports=t130225, WatchingSoccer=t130226, 
        WatchingSoftball=t130227, 
        # WatchingCardio=t130228, 
        # WatchingCarRacing=t130229, 
        # WatchingVolleyball=t130230, 
        # WatchingWalking=t130231, WatchingWaterSports=t130232, WatchingWeightlifting=t130233, 
        # WatchingWorkingOut=t130234, 
        # Wrestling=t130235, # not in data
        # WatchingYoga=t130236
        # RelgiousActivities
        religious_attend=t140101, religious_participate=t140102, 
        religious_waiting=t140103, 
        # religious_security=t140104,
        religious_education=t140105,
        # Volunteering
        starts_with('t15'),
        # Telephone
        starts_with('t16'),
        # Traveling
        starts_with('t18')
    ) |> 
    mutate(
        Age=if_else(Age < 0, NA_real_, Age)
        , AgeOfYoungestChild=if_else(
            AgeOfYoungestChild < 0, NA_real_, AgeOfYoungestChild
        )
        , WorkHoursPerWeek=if_else(
            as.numeric(WorkHoursPerWeek) < 0, NA_real_, as.numeric(WorkHoursPerWeek)
        )
        , WorkHoursPerWeek=if_else(
            LaborForceStatus == 'Employed', WorkHoursPerWeek, 0
        )
        , Sex=if_else(Sex == 1, 'Male', 'Female')
        , LaborForceStatus = case_when(
            LaborForceStatus == 1 ~ 'Employed', # at work
            LaborForceStatus == 2 ~ 'Employed', # absent
            LaborForceStatus == 3 ~ 'Unemployed', # on layoff
            LaborForceStatus == 4 ~ 'Unemployed', # looking
            LaborForceStatus == 5 ~ 'Not In Labor Force'
        )
        , CurrentPostSecondaryStudent=case_when(
            CurrentPostSecondaryStudent == 1 ~ TRUE,
            CurrentPostSecondaryStudent == 2 ~ FALSE,
            CurrentPostSecondaryStudent < 0 ~ NA
        )
        , HighSchoolOrCollege=case_when(
            HighSchoolOrCollege == 1 ~ 'High School',
            HighSchoolOrCollege == 2 ~ 'College', # or university
            HighSchoolOrCollege < 0 ~ NA_character_
        )
        , PartnerEmployment=case_when(
            PartnerEmployment == 1 ~ 'Employed',
            PartnerEmployment == 2 ~ 'Not Employed',
            PartnerEmployment < 0 ~ NA_character_
        )
        , PartnerEmploymentType=case_when(
            PartnerEmploymentType == 1 ~ 'Full Time',
            PartnerEmploymentType == 2 ~ 'Part Time',
            PartnerEmploymentType == 3 ~ 'Hours Vary',
        )
        , EmploymentType=case_when(
            EmploymentType == 1 ~ 'Full Time',
            EmploymentType == 2 ~ 'Part Time',
            EmploymentType < 0 ~ NA_character_
        )
        # valid between 0 and 288461
        # only filled in if the respondent is 
        # employed (LaborForceStatus/TELFS %in% c(1, 2)) and are not
        # self employed and not working without pay (TEIO1COW %in% 1:5)
        # The allocation flag for this variable is TRWERNAL (0 if not populated
        # and 1 if populated)
        # Subject to topcoding (the maximum value cannot be greater 
        # than 2884.61);
        # topcoding is indicated in TTOT (in respondent file), 
        # TTWK (in respondent file), and TTHR (in respondent file).
        , WeeklyEarnings=case_when(
            WeeklyEarnings < 0 ~ NA_real_,
            TRUE ~ WeeklyEarnings
        )
        , WeeklyEarnings=if_else(
            LaborForceStatus == 'Employed',
            WeeklyEarnings,
            0
        )
        # the last two digits are decimals
        , WeeklyEarnings=WeeklyEarnings/100
        # whether survey was conducted on a holiday
        , Holiday=if_else(Holiday == 0, FALSE, TRUE)
        , DiaryDayOfWeek=case_when(
            DiaryDayOfWeek == 1 ~ 'Sunday',
            DiaryDayOfWeek == 2 ~ 'Monday',
            DiaryDayOfWeek == 3 ~ 'Tuesday',
            DiaryDayOfWeek == 4 ~ 'Wednesday',
            DiaryDayOfWeek == 5 ~ 'Thursday',
            DiaryDayOfWeek == 6 ~ 'Friday',
            DiaryDayOfWeek == 7 ~ 'Saturday',
        )
        , SelfCare=washing + grooming + health_self
        , Cooking=FoodPrep + FoodPresentation + FoodClean + FoodMisc,
        # home maintenance
        , HomeMaintenance=decoration + repair + hvac_repair + repair_misc + 
            exterior_cleaning + exterior_repair + exterior_misc
        # Lawn
        , Lawn=lawn_care + pool_care + lawn_misc
        # AnimalCare
        , AnimalCare=animal_care + animal_activity + animal_misc
        # VehicleCare
        , VehicleCare=vehicle_repair + vehicle_misc
        # ChildCare
        , ChildCare=child_care + child_talk + child_planning + 
            child_looking + child_waiting + child_drive + child_events
        # ChildPlay
        , ChildPlay=child_play + child_sports + child_crafts + child_reading
        # ChildEducation - activies for children's education
        , ChildEducation=child_homework + child_school_meetings
        # ChildHealth
        , ChildHealth=child_medical + child_doctor + child_doctor_wait
        # AdultCare
        , AdultCare=adult_care + adult_looking + adult_medical + 
            adult_doctor + adult_doctor_wait
        # Work
        , Work=work_main + work_other + work_security + work_waiting + work_social +  
        # work_eating +   # not in data for some reason
        work_sports
        # work_security_job +    # not in data for some reason
        # work_waiting_job  # not in data for some reason
        # TakingClass
        , TakingClass=class_for_degree + class_for_personal + class_waiting + class_misc
        # Homework
        , Homework=homework_degree + homework_personal + homework_misc
        # Shopping
        , Shopping=shop_grocery + shop_gas + shop_food + shop_etc + shop_research
        # RelgiousActivities
        , RelgiousActivities=religious_attend + religious_participate + 
            religious_waiting + religious_education
        , Social=social_social + social_events_1 + social_events_2
        # Volunteering
        , Volunteering=t150101 + t150102 + t150103 + t150104 + t150105 + 
            t150106 + t150199 + t150201 + t150202 + t150203 + t150204 + 
            t150299 + t150302 + t150399 + t150401 + t150402 + t150499 + 
            t150501 + t150599 + t150601 + t150602 + t150701 + t159999
        # Telephone
        , Telephone=t160101 + t160102 + t160103 + t160104 + t160105 + 
            t160106 + t160107 + t160108 + t160199 + t160201 + t169999
        # Traveling
        , Traveling=t180101 + t180201 + t180202 + t180203 + t180204 + 
            t180205 + t180206 + t180207 + t180208 + t180209 + t180301 + 
            t180302 + t180303 + t180304 + t180305 + t180399 + t180401 + 
            t180402 + t180403 + t180404 + t180405 + t180499 + t180501 + 
            t180502 + t180503 + t180504 + t180601 + t180602 + t180603 + 
            t180604 + t180699 + t180701 + t180702 + t180703 + t180704 + 
            t180801 + t180802 + t180803 + t180804 + t180805 + t180806 + 
            t180807 + t180899 + t180901 + t180902 + t180903 + t180905 + 
            t181001 + t181002 + t181101 + t181201 + t181202 + t181203 + 
            t181204 + t181205 + t181299 + t181301 + t181302 + t181399 + 
            t181401 + t181499 + t181501 + t181599 + t181601 + t181801 + t189999
    ) |> 
    select(
        # SelfCare
        -washing, -grooming, -health_self,
        # Cooking
        -FoodPrep, -FoodPresentation, -FoodClean, -FoodMisc,
        # HomeMaintenance
        -decoration, -repair, hvac_repair, -repair_misc, -exterior_cleaning, 
        -exterior_repair, -exterior_misc,
        # Lawn
        -lawn_care, -pool_care, -lawn_misc,
        # AnimalCare
        -animal_care, -animal_activity, -animal_misc,
        # VehicleCare
        -vehicle_repair, -vehicle_misc,
        # ChildCare
        -child_care, -child_talk, -child_planning, -child_looking, -child_waiting, 
        -child_drive, -child_events,
        # ChildPlay
        -child_play, -child_sports, -child_crafts, -child_reading,
        # ChildEducation - activies for children's education
        -child_homework, -child_school_meetings,
        # ChildHealth
        -child_medical, -child_doctor, -child_doctor_wait,
        # AdultCare
        -adult_care, -adult_looking, -adult_medical, -adult_doctor, -adult_doctor_wait,
        # Work
        -work_main, -work_other, -work_security, -work_waiting, -work_social, 
        # -work_eating,  # not in data for some reason
        - work_sports, 
        # -work_security_job,   # not in data for some reason
        # - work_waiting_job,  # not in data for some reason
        # TakingClass
        -class_for_degree, -class_for_personal, -class_waiting, -class_misc,
        # Homework
        -homework_degree, -homework_personal, -homework_misc,
        # Social
        -social_social, -social_events_1, -social_events_2,
        # Shopping
        -shop_grocery, -shop_gas, -shop_food, -shop_etc, -shop_research,
        # RelgiousActivities
        -religious_attend, -religious_participate, -religious_waiting, 
        # -religious_security,
        -religious_education,
        -starts_with('t15'),
        -starts_with('t16'),
        -starts_with('t18')
    )

# Validate ####
# see if all the time columns are free of NAs
time_use |> 
    summarize(across(everything(), ~mean(is.na(.x)))) |> 
    tidyr::pivot_longer(cols=everything()) |> 
    print(n=Inf)

# Two files ####
# break off a little data to act as new rows
time_split <- rsample::initial_split(
    time_use, prop=0.99, strata='Sex'
)

time_use_main <- rsample::training(time_split)
time_use_new <- rsample::testing(time_split)

readr::write_csv(
    time_use_main, 
    here::here('data', 'time_use_survey_2020.csv')
)
readr::write_csv(
    time_use_new, 
    here::here('data', 'time_use_survey_2020_new.csv')
)

# Put on GitHub ####
pb_upload(
    file='data/time_use_survey_2020.csv', 
    repo='jaredlander/coursedata',
    name='data/time_use_survey_2020.csv',
    overwrite=TRUE
)
pb_upload(
    file='data/time_use_survey_2020_new.csv', 
    repo='jaredlander/coursedata',
    name='data/time_use_survey_2020_new.csv',
    overwrite=TRUE
)

# Upload to jaredlander.com ####
session <- ssh_connect(
    'jaredlander@jaredlander.com'
)
files <- sprintf(
    'data/%s', 
    c('time_use_survey_2020.csv', 'time_use_survey_2020_new.csv')
)
scp_upload(session, files=files, to='www/www/data', verbose=TRUE)
