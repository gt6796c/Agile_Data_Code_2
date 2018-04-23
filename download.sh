#!/usr/bin/env bash
#
# Script to download data for book
#
mkdir data
pushd data

#
# Get airplane data
#

# Get on-time records for all flights in 2015 - 273MB
if [ ! -f On_Time_On_Time_Performance_2015.csv ]; then
		curl -sL http://s3.amazonaws.com/agile_data_science/On_Time_On_Time_Performance_2015.csv.gz -O && \
			gzip -d ./On_Time_On_Time_Performance_2015.csv.gz 
fi

# Get openflights data
if [ ! -f airports.csv ]; then
	curl -Lk https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat -O
fi

if [ ! -f airlines.csv ]; then
	curl -Lk https://raw.githubusercontent.com/jpatokal/openflights/master/data/airlines.dat -O
fi

if [ ! -f routes.csv ]; then
	curl -Lk https://raw.githubusercontent.com/jpatokal/openflights/master/data/routes.dat -O
fi

if [ ! -f countries.csv ]; then
	curl -Lk https://raw.githubusercontent.com/jpatokal/openflights/master/data/countries.dat -O
fi

# Get FAA data
if [ ! -f aircraft.txt ]; then
	curl -Lko http://av-info.faa.gov/data/ACRef/tab/aircraft.txt -O
fi
if [ ! -f ata.txt ]; then
	curl -Lko http://av-info.faa.gov/data/ACRef/tab/ata.txt -O
fi
if [ ! -f compt.txt ]; then
	curl -Lko http://av-info.faa.gov/data/ACRef/tab/compt.txt -O
fi
if [ ! -f engine.txt ]; then
	curl -Lko http://av-info.faa.gov/data/ACRef/tab/engine.txt -O
fi
if [ ! -f prop.txt ]; then
	curl -Lko http://av-info.faa.gov/data/ACRef/tab/prop.txt -O
fi


if [ ! -f wbanmasterlist.psv ]; then 
		curl -sL http://www.ncdc.noaa.gov/homr/file/wbanmasterlist.psv.zip -O && \
		  unzip -o ./wbanmasterlist.psv.zip
fi

for i in $(seq -w 1 12); do 
  curl -Lk http://www.ncdc.noaa.gov/orders/qclcd/QCLCD2015${i}.zip -O && \
    unzip -o ./QCLCD2015${i}.zip && \
    gzip 2015${i}*.txt && \
    rm -f ./QCLCD2015${i}.zip
done
