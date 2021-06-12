# MIMIC4-Win

This is a repository to install MIMIC 4 in PostgreSQL a Windows environment, and then add materialised views of common SQL searches.
The first part is reasonably straight forward, and is covered in various detail on other pages, which will be linked. 
The second part, using supplied SQL code to perform common searches, is more challenging, particularly as a number of SQL dialects have been used, along with a Cloud based mimic_derived database.
To simplify this for Windows users, this links to a straight forward Windows installation of Postgres and PGadmin on a local machine, and building the dataset from the SQL command line.
I have then altered the SQL code to work natively within PGAdmin, to completely build the dataset and materialised views on the local machine (or a stand alone local/Cloud VM).

## VM considerations
If you are creating a VM to specifically host this, a few considerations. 
1. If you place the full database is on the primary disk, you will need more than the usual 128gb of storage. You can do this initially when creating the drive, or add additional space (which in some VMs needs to be manually connected to the primary partition - go in to disk management and click on primary partition and select 'expand'). 
2. Separating data and processing drives is often considered good practice, however for this may only provide a small advantage, with a concommitant increase in complexity. It works fine all hosted on a single disk.
3. You will note when creating both the database and the materialized views there is often 100% disk utilisation - so ensure you have good qualilty SSDs.
4. Temporary separate storage for the source files is useful when building the datasets. 
5. Postgres processing is predominantly a few threads only, so a smaller number of CPU cores will work fine.

## Install Postgres
And standard installation is all you need, and thus the inital instructions from here work fine (https://www.programmersought.com/article/21858700192/ ). Version 13 works with MIMIC IV, and the included version of PGAdmin also. 

## Install 7-Zip
next install 7-zip (https://www.7-zip.org/) (this works fine with the supplied compressed MIMIC files). As per the link above, make sure you keep a note of the installation directory, and then add the path to you environment variables (in the Windows search box type 'environment', 'edit system variables', click on 'environment variables', clikc on 'path', click on 'edit' and add the pathe for 7-zip.

## Download the MIMIC files.
Note that these are fairly large files (around 7Gb total), so you will need both space to store them, and bandwidth. Even with good Cloud connections the download speeds are not high.
IF you go to the MIMIC IV paper on physionet (https://physionet.org/content/mimiciv/1.0/) and log in to your account, you will find a link at the bottom to download the ZIP file (https://physionet.org/content/mimiciv/get-zip/1.0/). When finished downloading, unzip it in a directory that is easy to find, and with a short file path (to decrease typing and chance of errors!). Placing it on a separate drive to Postgres will help database load times. 
