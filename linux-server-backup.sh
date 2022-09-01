#!/bin/bash
## daily backup script

##########################
####  Rsync Options  #####
##########################
#Path where Rsync'd files are stored locally
FILEPATH="/home/backup/server1"
#FILEPATH=""
#
#Proper Rsync options to use
#Dry Run & Verbose will give the output of what would be copied (a test)
#OPTS=" --dry-run --verbose "
#
#BWlimit allows the I/O bandwidth to be limited KBytes per second 
#OPTS=" --bwlimit=20 "
#
#OPTS=""
##########################


#############################
###  Incremental backups!  ##
#############################
#if it hasn't already rotated do so...
THISDIR="/home/scripts/"
WEEKLYLOCK="$THISDIR/.server1weeklybackup.lock"
DAILYLOCK="$THISDIR/.server1dailybackup.lock"

function weeklycopy {
 	rm -rf $FILEPATH/weekly-6
        mv $FILEPATH/weekly-5/ $FILEPATH/weekly-6
        mv $FILEPATH/weekly-4/ $FILEPATH/weekly-5
        mv $FILEPATH/weekly-3/ $FILEPATH/weekly-4
        mv $FILEPATH/weekly-2/ $FILEPATH/weekly-3
        mv $FILEPATH/weekly-1/ $FILEPATH/weekly-2
	    mv $FILEPATH/daily-8/ $FILEPATH/weekly-1
touch $WEEKLYLOCK
echo "Weekly Lock File Updated & Files Moved " 
}

function dailycopy {
rm -rf $FILEPATH/daily-8
mv $FILEPATH/daily-7 $FILEPATH/daily-8
mv $FILEPATH/daily-6 $FILEPATH/daily-7
mv $FILEPATH/daily-5 $FILEPATH/daily-6
mv $FILEPATH/daily-4 $FILEPATH/daily-5
mv $FILEPATH/daily-3 $FILEPATH/daily-4
mv $FILEPATH/daily-2 $FILEPATH/daily-3
mv $FILEPATH/daily-1 $FILEPATH/daily-2
cp -al $FILEPATH/daily-0 $FILEPATH/daily-1
touch $DAILYLOCK
echo "Daily Lock File Updated & Files Moved "
}

TODAYNUM=$(date +%u)
#Day 1 is Monday, so we'll do the weekly backups
if [ $TODAYNUM = 1 ]; then
    #check to see when the last backup was run
    #Today is Monday!
	if [ -e $WEEKLYLOCK ]; then
	#There is a lock file - better check it! 
	  LOCKTIME=$(date -r $WEEKLYLOCK +%s)
	  NOW=$(date +%s)
  	  LASTWEEKLYBACKUP=$(expr $NOW - $LOCKTIME) 
	#%s is the number of seconds since time began, useful for comparisons
	#3600 is an hour, 86400 is a day, 518400 is 6 days,
		WEEKLYDAYS=$(expr $LASTWEEKLYBACKUP / 86400)
	   echo "Last weekly backup was $WEEKLYDAYS Days Ago" 
		 if [ $WEEKLYDAYS -gt "5" ]; then 
			#lock file was changed more than 5 days ago
			#remember this only runs on a monday anyway
			echo "Moving Weekly Files" 
			weeklycopy
		 fi	  
	else 
	 #no lock file found, so we'll move the weekly files
	 echo "No Lock File in Place - moving weekly files" 
	 weeklycopy
	fi
fi 

#check to see if daily backup has been run today
if [ -e $DAILYLOCK ]; then
   #There is a daily lock file - better check it!
      DLOCKTIME=$(date -r $DAILYLOCK +%s)
      DNOW=$(date +%s)
      LASTDAILYBACKUP=$(expr $DNOW - $DLOCKTIME)
    #%s is the number of seconds since time began, useful for comparisons
    #3600 is an hour, 79200 is 22 hours,
	DAILYHOURS=$(expr $LASTDAILYBACKUP / 3600) 
    echo "Last daily backup was $DAILYHOURS Hours Ago"
             if [ $DAILYHOURS -gt "22" ]; then
                        #lock file was changed more than 23 hours ago
                        #remember this only does the moving locally - so it shouldn't take long.
                        echo "Moving Daily Files"
                        dailycopy
             fi
  else
  #no lock file found, so we'll move the weekly files
  echo "No Lock File in Place - moving daily files"
  dailycopy
fi
#
##############################

##########################
###   Copy The Data.   ###
##########################

#The exlude _order_ is VERY important!
#Do not change this order!!
rsync -a --delete $OPTS  			\
		--exclude 'log/' 		\
		--exclude 'logs/' 		\
		--exclude '.imap/' 		\
		--exclude 'nobackup/'		\
		--include '/etc'		\
	        --include '/home'               \
		--include '/home/scripts'	\
		--include '/home/nick'          \
		--include '/home/server1'	\
	        --exclude '/home/*'                	\
                --include '/usr'                        \
                --include '/usr/src'                    \
                --include '/usr/src/redhat'            	\
                --include '/usr/src/redhat/SRPMS'   	\
                --include '/usr/src/redhat/SPECS'      	\
                --exclude '/usr/src/redhat/*'          	\
                --exclude '/usr/src/*'                  \
                --exclude '/usr/*'              	\
		--include '/var'		\
		--include '/var/lib'		\
		--include '/var/lib/mysql'	\
		--exclude '/var/lib/mysql/mysql.sock' \
		--include '/var/lib/mysql/*'    \
		--include '/var/lib/asterisk' \
		--include '/var/lib/asterisk/*' \
		--exclude '/var/lib/*'		\
		--include '/var/named'		\
		--include '/var/named/chroot' \
		--exclude '/var/named/chroot/proc' \
		--include '/var/spool'		\
		--include '/var/spool/cron' \
		--exclude '/var/spool/*' \
		--exclude '/var/*'		\
		--exclude '/*'			\
		root@server1.dnsname.co.uk:/      $FILEPATH/daily-0/
#
############################
