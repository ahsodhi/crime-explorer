# Crime Explorer

Crime Explorer is a flexible, adaptive program used to navigate and generate visual data from Statistics Canada’s downloadable CSV file.  
  
You can search for all statistics regarding a particualar crime in one or more locations, and you can also track a particular statistic of a crime over multiple years.  
  
The program allows you to generate an appropriate visual representation (bar graph or line plot) each time you execute a new query.  
  
**Contrubutors:** *Mark Waters* and *Alexander Thiele*

## Requirements

|Software|Hardware|
|--------|--------|
|1. Perl interpreter|2GB+ of RAM
|2. R
|3. PDF Reader

## Instructions

1. Clone this repo

2. Download the crime data csv file and place it in the same directory as the repo  
https://drive.google.com/open?id=0B1uhOkyVD6tAY0RWdUZhX1NVejg

3. From a terminal window, navigate to the repo directory and execute `perl crimeExplorer.pl crimedata.csv`

Read _**UserManual.pdf**_ (included in repo) for full instructions covering each functionality.
