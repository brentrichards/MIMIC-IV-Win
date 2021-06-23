# MIMIC IV-Windows - installations

This is a repository to install MIMIC 4 in PostgreSQL a Windows environment, and then add materialised views of common SQL searches.
The first part is reasonably straight forward, and is covered in various detail on other pages, which will be linked. 
The second part, using supplied SQL code to perform common searches, is more challenging, particularly as a number of SQL dialects have been used, along with a Cloud based mimic_derived database.
To simplify this for Windows users, this links to a straight forward Windows installation of Postgres and PGadmin on a local machine, and building the dataset from the SQL command line.
I have then altered the SQL code to work natively within PGAdmin, to completely build the dataset and materialised views on the local machine (or a stand alone local/Cloud VM).

## VM considerations
If you are creating a VM to specifically host this, a few considerations. 
1. If you place the full database is on the primary disk, you will need more than the usual 128gb of storage. You can do this initially when creating the drive, or add additional space (which in some VMs needs to be manually connected to the primary partition - go in to disk management and click on primary partition and select 'expand'). 
2. Separating data and processing drives is often considered good practice, however for this may only provide a small advantage, with a concomitant increase in complexity. It works fine all hosted on a single disk.
3. You will note when creating both the database and the materialized views there is often 100% disk utilisation - so ensure you have good quality SSDs.
4. Temporary separate storage for the source files is useful when building the datasets. 
5. Postgres processing is predominantly a few threads only, so a smaller number of CPU cores will work fine.

## Install Postgres
And standard installation is all you need, and thus the initial instructions from here work fine (https://www.programmersought.com/article/21858700192/ ). Version 13 works with MIMIC IV, and the included version of PGAdmin also. 
Make sure you remember the Postgres username and password. Sticking with the usual defaults ('postgres' as user, 'postgres' as password) is OK in the Windows environment (and less likely to be forgotten). When you first open PGAdmin you will be asked for this master password.  

## Install 7-Zip
next install 7-zip (https://www.7-zip.org/) (this works fine with the supplied compressed MIMIC files). As per the link above, make sure you keep a note of the installation directory, and then add the path to you environment variables (in the Windows search box type 'environment', 'edit system variables', click on 'environment variables', click on 'path', click on 'edit' and add the path for 7-zip.
It is worth checking the path has been registered before you start installing the database. Simply open a command window (Cmd) and type 7z - you should get a series of instructions about 7-zip.

## Download the MIMIC files.
Note that these are fairly large files (around 7Gb total), so you will need both space to store them, and bandwidth. Even with good Cloud connections the download speeds are not high.
IF you go to the MIMIC IV paper on physionet (https://physionet.org/content/mimiciv/1.0/) and log in to your account, you will find a link at the bottom to download the ZIP file (https://physionet.org/content/mimiciv/get-zip/1.0/). When finished downloading, unzip it in a directory that is easy to find, and with a short file path (to decrease typing and chance of errors!). Placing it on a separate drive to Postgres will help database load times. 
You will also need the MIMIC IV files from Github, linked here https://github.com/MIT-LCP/mimic-iv. Download these as a zip file (or clone using Git/Github desktop)  and place where you can find them easily - usally on the same drive as the compressed csv files. You will initially need the files to build postgres (https://github.com/MIT-LCP/mimic-iv/tree/master/buildmimic/postgres). The 'concepts' are there also, noting that not all work with Postgres on Windows (and therefore I've re-written them and included them in this repository). 

## Build the database
This is often seen as the confusing part, as it needs some command line work. However if you use the SQL shell/command box, it becomes somewhat more straight forward. 
Then follwo the instructions here https://www.programmersought.com/article/97578529676/ - copy and paste in to the SQL shell, careful to follow the sequence. 
The basic sequence is:
1. log in to the server (accept the default by simply pressing 'enter' until asked for the password, then 'postgres' as above if you have kept this
2. create the database, and switch to it (CREATE DATABASE mimic OWNER postgres;) (\c mimic;)
3. create a schema to get started (CREATE SCHEMA mimiciv;) - you will use this later when building the materialised views
4. set a search path (set search_path to mimiciv;)  - note you will need to repeat this if you get stuck and log out.
5. create the tables and schema (\i E:/postgres/create.sql) - make sure this is the correct directory for you
6. set to stop on error (\set ON_ERROR_STOP 1) 
7. set the direcotry where your compressed mimic files are stored (\set mimic_data_dir 'E:/postgres/MIMICIV') - this directory is referenced in the build sql files. Make sure that you change this to where your files are stored. Note that it is also important that you keep the original sub-directory structure of the downloaded zip file containing the MIMIC data files.
8. now build the database (\i E:/postgres/load_7z.sql) - again make sure you have the right directory for your files here. 
9. Wait...... It takes 1.5-2 hours, depending on your computer and drive speed. Some tables take >20min to build  - chartevents has over 300 million rows, so understandable. There are 27 tables to build. You will be returned to the command line when build is complete.
10. Now build the indexes (\i E:/postgres/index.sql). Again this will take considerable time - 20-30 min.
11. Once completed, close the SQL window, open PGAdmin, log in to the database, and check everything is there. To check it is working, simply right-click on any of the tables, and look at the top 100 rows (it will create a simple SELECT statement). 
12. Well done!

# Using the Concepts
The concepts included in the normal downloads (https://github.com/MIT-LCP/mimic-iv) are a series of SQL files that have been written to help with some of the more standard questions - e.g. use of vasopressors or antibiotics. These have been brought together from a number of sources, so not all the SQL code works within Postgres (yes, there are different 'dialects' of SQL). 
Also, a number of these files reference 'mimic_derived' - a database written from the original MIMIC that included many of the queries, to allow secondary and tertiary queries to occur of the dataset. The MIMIC-derived dataset is not available for MIMIC-IV. However, the functionality can be reproduced by using materialised views within MIMIC IV, and I have included the code in this repo (in fact the main reason for this repo). 
Note that given that some of the views build on other views, it is important to run these initially in order. Once these views are created, you can then go back to the primary SQL queries and run these, along with modifications as you wish.
I have chosen to use materialised views as some of the base queries take 10-20 min to run - so better in a view. Given that MIMIC is often accessed in a time-limited environment (datathon), the time saving can be significant.

The order for the materialized views is:
- first group:Age_mv, antibiotics_mv, bg_mv, bg_pg_mv, blood_differential_mv, chemistry_mv, Coagulation_mv, complete_blood_count_mv, dobutamine_mv, dopamine_mv, enzyme_mv,Epinephrine_mv, gcs_mv, height_mv, icu_times_mv, kdigo_creatinine_mv, norepinephrine_mv, Oxygen_delivery_mv, rrt_mv, urine_output_mv, ventilator_setting_mv, vital_sign_mv, weight_durations_mv
- second group:First_day_bg_art_mv, First_day_gcs_mv, first-day_lab_mv, first_day_rrt_mv, first_day_urine_output_mv, first_day_vitalsign_mv, kdigo_uo_mv, urine_output_rate_mv, ventilation_mv 

All of these queries have been tested and run within a local instance of Postgres 13, using PGAdmin, on a Windows machine, so hopefully these all work for you also.

Note that there are still a few queries that I have not managed to translate across, namely icu_stay_hourly, sofa (that relies on it), and sepsis3 (that relies on sofa). 

