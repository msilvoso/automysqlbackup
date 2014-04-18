#!/usr/bin/env bash
#

# return  true, if variable is set; else false
function isSet() {
  if declare -p $1 >/dev/null 2>&1; then return 0; else return 1; fi
}

function activateIO() {
  touch "$1"
  exec 6>&1
  exec > "$1"
}
function removeIO() {
  exec 1>&6 6>&-
}

function upgrade_config_file() {
  ( # execute in subshell, so that sourced variables are only available inside ()
    #create temp file
    local temp
    temp=$(mktemp /tmp/tmp.XXXXXX)
    (( $? != 0 )) && return 1
    activateIO "$temp"

    # empty path to find out if it's changed
    newPath=$(cat $1 | grep '^PATH=')
    newUmask=$(cat $1 | grep '^umask ')
    source "$1"
    if [ "$2" == "2" ]; then
      # conversion from version 2 (not tested)
      if isSet USERNAME; then
        CONFIG_mysql_dump_username=$USERNAME
      fi
      if isSet PASSWORD; then
        CONFIG_mysql_dump_password=$PASSWORD
      fi
      if isSet DBHOST; then
        CONFIG_mysql_dump_host=$DBHOST
      fi
      if isSet BACKUPDIR; then
        CONFIG_backup_dir=$BACKUPDIR
      fi
      if isSet DBNAMES; then
        if [ "x$DBNAMES" != "xall" ]; then
          CONFIG_db_names=( "${DBNAMES[@]}" )
        fi
      fi
      if isSet MDBNAMES; then
        if [ "x$MDBNAMES" != "xall" ]; then
          CONFIG_db_month_names=( "${MDBNAMES[@]}" )
        fi
      fi
      if isSet DBEXCLUDE; then
        CONFIG_db_exclude=( "${DBEXCLUDE[@]}" )
      fi
      if isSet DOWEEKLY; then
        CONFIG_do_weekly=$DOWEEKLY
      fi
      if isSet COMMCOMP; then
        CONFIG_mysql_dump_commcomp=$COMMCOMP
      fi
      if isSet SOCKET; then
        CONFIG_mysql_dump_socket=$SOCKET
      fi
      if isSet MAX_ALLOWED_PACKET; then
        CONFIG_mysql_dump_max_allowed_packet=$MAX_ALLOWED_PACKET
      fi
      if isSet CREATE_DATABASE; then
        CONFIG_mysql_dump_create_database=$CREATE_DATABASE
      fi
      if isSet SEPDIR; then
        CONFIG_mysql_dump_use_separate_dirs=$SEPDIR
      fi
      if isSet COMP; then
        CONFIG_mysql_dump_compression=$COMP
      fi
      if isSet LATEST; then
        CONFIG_mysql_dump_latest=$LATEST
      fi
      if isSet MAILCONTENT; then
        CONFIG_mailcontent=$MAILCONTENT
      fi
      if isSet MAXATTSIZE; then
        CONFIG_mail_maxattsize=$MAXATTSIZE
      fi
      if isSet MAILADDR; then
        CONFIG_mail_address=$MAILADDR
      fi
      if isSet PREBACKUP; then
        CONFIG_prebackup=$PREBACKUP
      fi
      if isSet POSTBACKUP; then
        CONFIG_postbackup=$POSTBACKUP
      fi
    fi
    echo "#version=3.1"
    echo "# DONT'T REMOVE THE PREVIOUS VERSION LINE!"
    echo "#"
    echo "# Uncomment to change the default values (shown after =)"
    echo "# WARNING:"
    echo "# This is not true for UMASK, CONFIG_prebackup and CONFIG_postbackup!!!"
    echo "#"
    echo "# Default values are stored in the script itself. Declarations in"
    echo "# /etc/automysqlbackup/automysqlbackup.conf will overwrite them. The"
    echo "# declarations in here will supersede all other."
    echo ""
    echo "# Edit \$PATH if mysql and mysqldump are not located in /usr/local/bin:/usr/bin:/bin:/usr/local/mysql/bin"
    if [ -n "$newPath" ] ; then
      echo $newPath
    else
      echo "#PATH=\${PATH}:FULL_PATH_TO_YOUR_DIR_CONTAINING_MYSQL:FULL_PATH_TO_YOUR_DIR_CONTAINING_MYSQLDUMP"
    fi
    echo ""
    echo "# Basic Settings"
    echo ""
    echo "# Username to access the MySQL server e.g. dbuser"
    if isSet CONFIG_mysql_dump_username; then
      printf "%s='%s'\n" CONFIG_mysql_dump_username "${CONFIG_mysql_dump_username-}"
    else
      echo "#CONFIG_mysql_dump_username='root'"
    fi
    echo ""
    echo "# Password to access the MySQL server e.g. password"
    if isSet CONFIG_mysql_dump_password; then
      printf "%s='%s'\n" CONFIG_mysql_dump_password "${CONFIG_mysql_dump_password-}"
    else
      echo "#CONFIG_mysql_dump_password=''"
    fi
    echo ""
    echo "# Host name (or IP address) of MySQL server e.g localhost"
    if isSet CONFIG_mysql_dump_host; then
      printf "%s='%s'\n" CONFIG_mysql_dump_host "${CONFIG_mysql_dump_host-}"
    else
      echo "#CONFIG_mysql_dump_host='localhost'"
    fi
    echo ""
    echo "# use a config file to suppress warning in mysql 5.6 about passwords in command line"
    echo "# in debian this file exists and is located in /etc/mysql/debian.cnf"
    if isSet CONFIG_mysql_configuration_file; then
      printf "%s='%s'\n" CONFIG_mysql_configuration_file "${CONFIG_mysql_configuration_file-}"
    else
      echo "#CONFIG_mysql_configuration_file=''"
    fi
    echo ""
    echo "# \"Friendly\" host name of MySQL server to be used in email log"
    echo "# if unset or empty (default) will use CONFIG_mysql_dump_host instead"
    if isSet CONFIG_mysql_dump_host_friendly; then
      printf "%s='%s'\n" CONFIG_mysql_dump_host_friendly "${CONFIG_mysql_dump_host_friendly-}"
    else
      echo "#CONFIG_mysql_dump_host_friendly=''"
    fi
    echo ""
    echo "# Backup directory location e.g /backups"
    if isSet CONFIG_backup_dir; then
      printf "%s='%s'\n" CONFIG_backup_dir "${CONFIG_backup_dir-}"
    else
      echo "#CONFIG_backup_dir='/var/backup/db'"
    fi
    echo ""
    echo "# This is practically a moot point, since there is a fallback to the compression"
    echo "# functions without multicore support in the case that the multicore versions aren't"
    echo "# present in the system. Of course, if you have the latter installed, but don't want"
    echo "# to use them, just choose no here."
    echo "# pigz -> gzip"
    echo "# pbzip2 -> bzip2"
    if isSet CONFIG_multicore; then
      printf "%s='%s'\n" CONFIG_multicore "${CONFIG_multicore-}"
    else
      echo "#CONFIG_multicore='yes'"
    fi
    echo ""
    echo "# Number of threads (= occupied cores) you want to use. You should - for the sake"
    echo "# of the stability of your system - not choose more than (#number of cores - 1)."
    echo "# Especially if the script is run in background by cron and the rest of your system"
    echo "# has already heavy load, setting this too high, might crash your system. Assuming"
    echo "# all systems have at least some sort of HyperThreading, the default is 2 threads."
    echo "# If you wish to let pigz and pbzip2 autodetect or use their standards, set it to"
    echo "# 'auto'."
    if isSet CONFIG_multicore_threads; then
      printf '%s=%q\n' CONFIG_multicore_threads "${CONFIG_multicore_threads-}"
    else
      echo "#CONFIG_multicore_threads=2"
    fi
    echo ""
    echo "# Databases to backup"
    echo ""
    echo "# List of databases for Daily/Weekly Backup e.g. ( 'DB1' 'DB2' 'DB3' ... )"
    echo "# set to (), i.e. empty, if you want to backup all databases"
    if isSet CONFIG_db_names; then
      declare -p CONFIG_db_names | perl -pe 's/\[[^]]*]=//g' | perl -pe 's/^.*?([^ ]*=).*\((.*)\).*/$1($2)/' | tr '"' "'"
    else
      echo "#CONFIG_db_names=()"
    fi
    echo "# You can use"
    echo "#declare -a MDBNAMES=( \"\${DBNAMES[@]}\" 'added entry1' 'added entry2' ... )"
    echo "# INSTEAD to copy the contents of \$DBNAMES and add further entries (optional)."
    echo ""
    echo "# List of databases for Monthly Backups."
    echo "# set to (), i.e. empty, if you want to backup all databases"
    if isSet CONFIG_db_month_names; then
      declare -p CONFIG_db_month_names | perl -pe 's/\[[^]]*]=//g' | perl -pe 's/^.*?([^ ]*=).*\((.*)\).*/$1($2)/' | tr '"' "'"
    else
      echo "#CONFIG_db_month_names=()"
    fi
    echo ""
    echo "# List of DBNAMES to EXLUCDE if DBNAMES is empty, i.e. ()."
    if isSet CONFIG_db_exclude; then
      declare -p CONFIG_db_exclude | perl -pe 's/\[[^]]*]=//g' | perl -pe 's/^.*?([^ ]*=).*\((.*)\).*/$1($2)/' | tr '"' "'"
    else
      echo "#CONFIG_db_exclude=('information_schema')"
    fi
    echo ""
    echo "# List of tables to exclude, in the form db_name.table_name"
    echo "# You may use wildcards for the table names, i.e. 'mydb.a*' selects all tables starting with an 'a'."
    echo "# However we only offer the wildcard '*', matching everything that could appear, which translates to the"
    echo "# '%' wildcard in mysql."
    if isSet CONFIG_table_exclude; then
      declare -p CONFIG_table_exclude | perl -pe 's/\[[^]]*]=//g' | perl -pe 's/^.*?([^ ]*=).*\((.*)\).*/$1($2)/' | tr '"' "'"
    else
      echo "#CONFIG_table_exclude=('mysql.event')"
    fi
    echo ""
    echo ""
    echo "# Advanced Settings"
    echo ""
    echo "# Rotation Settings"
    echo ""
    echo "# Which day do you want monthly backups? (01 to 31)"
    echo "# If the chosen day is greater than the last day of the month, it will be done"
    echo "# on the last day of the month."
    echo "# Set to 0 to disable monthly backups."
    if isSet CONFIG_do_monthly; then
      printf "%s='%s'\n" CONFIG_do_monthly "${CONFIG_do_monthly-}"
    else
      echo "#CONFIG_do_monthly='01'"
    fi
    echo ""
    echo "# Which day do you want weekly backups? (1 to 7 where 1 is Monday)"
    echo "# Set to 0 to disable weekly backups."
    if isSet CONFIG_do_weekly; then
      printf "%s='%s'\n" CONFIG_do_weekly "${CONFIG_do_weekly-}"
    else
      echo "#CONFIG_do_weekly='5'"
    fi
    echo ""
    echo "# Set rotation of daily backups. VALUE*24hours"
    echo "# If you want to keep only today's backups, you could choose 1, i.e. everything older than 24hours will be removed."
    if isSet CONFIG_rotation_daily; then
      printf '%s=%q\n' CONFIG_rotation_daily "${CONFIG_rotation_daily-}"
    else
      echo "#CONFIG_rotation_daily=6"
    fi
    echo ""
    echo "# Set rotation for weekly backups. VALUE*24hours"
    if isSet CONFIG_rotation_weekly; then
      printf '%s=%q\n' CONFIG_rotation_weekly "${CONFIG_rotation_weekly-}"
    else
      echo "#CONFIG_rotation_weekly=35"
    fi
    echo ""
    echo "# Set rotation for monthly backups. VALUE*24hours"
    if isSet CONFIG_rotation_monthly; then
      printf '%s=%q\n' CONFIG_rotation_monthly "${CONFIG_rotation_monthly-}"
    else
      echo "#CONFIG_rotation_monthly=150"
    fi
    echo ""
    echo ""
    echo "# Server Connection Settings"
    echo ""
    echo "# Set the port for the mysql connection"
    if isSet CONFIG_mysql_dump_port; then
      printf '%s=%q\n' CONFIG_mysql_dump_port "${CONFIG_mysql_dump_port-}"
    else
      echo "#CONFIG_mysql_dump_port=3306"
    fi
    echo ""
    echo "# Compress communications between backup server and MySQL server?"
    if isSet CONFIG_mysql_dump_commcomp; then
      printf "%s='%s'\n" CONFIG_mysql_dump_commcomp "${CONFIG_mysql_dump_commcomp-}"
    else
      echo "#CONFIG_mysql_dump_commcomp='no'"
    fi
    echo ""
    echo "# Use ssl encryption with mysqldump?"
    if isSet CONFIG_mysql_dump_usessl; then
      printf "%s='%s'\n" CONFIG_mysql_dump_usessl "${CONFIG_mysql_dump_usessl-}"
    else
      echo "#CONFIG_mysql_dump_usessl='yes'"
    fi
    echo ""
    echo "# For connections to localhost. Sometimes the Unix socket file must be specified."
    if isSet CONFIG_mysql_dump_socket; then
      printf "%s='%s'\n" CONFIG_mysql_dump_socket "${CONFIG_mysql_dump_socket-}"
    else
      echo "#CONFIG_mysql_dump_socket=''"
    fi
    echo ""
    echo "# The maximum size of the buffer for client/server communication. e.g. 16MB (maximum is 1GB)"
    if isSet CONFIG_mysql_dump_max_allowed_packet; then
      printf "%s='%s'\n" CONFIG_mysql_dump_max_allowed_packet "${CONFIG_mysql_dump_max_allowed_packet-}"
    else
      echo "#CONFIG_mysql_dump_max_allowed_packet=''"
    fi
    echo ""
    echo "# This option sends a START TRANSACTION SQL statement to the server before dumping data. It is useful only with"
    echo "# transactional tables such as InnoDB, because then it dumps the consistent state of the database at the time"
    echo "# when BEGIN was issued without blocking any applications."
    echo "#"
    echo "# When using this option, you should keep in mind that only InnoDB tables are dumped in a consistent state. For"
    echo "# example, any MyISAM or MEMORY tables dumped while using this option may still change state."
    echo "#"
    echo "# While a --single-transaction dump is in process, to ensure a valid dump file (correct table contents and"
    echo "# binary log coordinates), no other connection should use the following statements: ALTER TABLE, CREATE TABLE,"
    echo "# DROP TABLE, RENAME TABLE, TRUNCATE TABLE. A consistent read is not isolated from those statements, so use of"
    echo "# them on a table to be dumped can cause the SELECT that is performed by mysqldump to retrieve the table"
    echo "# contents to obtain incorrect contents or fail."
    if isSet CONFIG_mysql_dump_single_transaction; then
      printf "%s='%s'\n" CONFIG_mysql_dump_single_transaction "${CONFIG_mysql_dump_single_transaction-}"
    else
      echo "#CONFIG_mysql_dump_single_transaction='no'"
    fi
    echo ""
    echo "# http://dev.mysql.com/doc/refman/5.0/en/mysqldump.html#option_mysqldump_master-data"
    echo "# --master-data[=value]"
    echo "# Use this option to dump a master replication server to produce a dump file that can be used to set up another"
    echo "# server as a slave of the master. It causes the dump output to include a CHANGE MASTER TO statement that indicates"
    echo "# the binary log coordinates (file name and position) of the dumped server. These are the master server coordinates"
    echo "# from which the slave should start replicating after you load the dump file into the slave."
    echo "#"
    echo "# If the option value is 2, the CHANGE MASTER TO statement is written as an SQL comment, and thus is informative only;"
    echo "# it has no effect when the dump file is reloaded. If the option value is 1, the statement is not written as a comment"
    echo "# and takes effect when the dump file is reloaded. If no option value is specified, the default value is 1."
    echo "#"
    echo "# This option requires the RELOAD privilege and the binary log must be enabled."
    echo "#"
    echo "# The --master-data option automatically turns off --lock-tables. It also turns on --lock-all-tables, unless"
    echo "# --single-transaction also is specified, in which case, a global read lock is acquired only for a short time at the"
    echo "# beginning of the dump (see the description for --single-transaction). In all cases, any action on logs happens at"
    echo "# the exact moment of the dump."
    echo "# =================================================================================================================="
    echo "# possible values are 1 and 2, which correspond with the values from mysqldump"
    echo "# VARIABLE=    , i.e. no value, turns it off (default)"
    echo "#"
    if isSet CONFIG_mysql_dump_master_data; then
      printf '%s=%q\n' CONFIG_mysql_dump_master_data "${CONFIG_mysql_dump_master_data-}"
    else
      echo "#CONFIG_mysql_dump_master_data="
    fi
    echo ""
    echo "# Included stored routines (procedures and functions) for the dumped databases in the output. Use of this option"
    echo "# requires the SELECT privilege for the mysql.proc table. The output generated by using --routines contains"
    echo "# CREATE PROCEDURE and CREATE FUNCTION statements to re-create the routines. However, these statements do not"
    echo "# include attributes such as the routine creation and modification timestamps. This means that when the routines"
    echo "# are reloaded, they will be created with the timestamps equal to the reload time."
    echo "#"
    echo "# If you require routines to be re-created with their original timestamp attributes, do not use --routines. Instead,"
    echo "# dump and reload the contents of the mysql.proc table directly, using a MySQL account that has appropriate privileges"
    echo "# for the mysql database."
    echo "#"
    echo "# This option was added in MySQL 5.0.13. Before that, stored routines are not dumped. Routine DEFINER values are not"
    echo "# dumped until MySQL 5.0.20. This means that before 5.0.20, when routines are reloaded, they will be created with the"
    echo "# definer set to the reloading user. If you require routines to be re-created with their original definer, dump and"
    echo "# load the contents of the mysql.proc table directly as described earlier."
    echo "#"
    if isSet CONFIG_mysql_dump_full_schema; then
      printf "%s='%s'\n" CONFIG_mysql_dump_full_schema "${CONFIG_mysql_dump_full_schema-}"
    else
      echo "#CONFIG_mysql_dump_full_schema='yes'"
    fi
    echo ""
    echo "# Backup status of table(s) in textfile. This is very helpful when restoring backups, since it gives an idea, what changed"
    echo "# in the meantime."
    if isSet CONFIG_mysql_dump_dbstatus; then
      printf "%s='%s'\n" CONFIG_mysql_dump_dbstatus "${CONFIG_mysql_dump_dbstatus-}"
    else
      echo "#CONFIG_mysql_dump_dbstatus='yes'"
    fi
    echo ""
    echo "# Backup dump settings"
    echo ""
    echo "# Include CREATE DATABASE in backup?"
    if isSet CONFIG_mysql_dump_create_database; then
      printf "%s='%s'\n" CONFIG_mysql_dump_create_database "${CONFIG_mysql_dump_create_database-}"
    else
      echo "#CONFIG_mysql_dump_create_database='no'"
    fi
    echo ""
    echo "# Separate backup directory and file for each DB? (yes or no)"
    if isSet CONFIG_mysql_dump_use_separate_dirs; then
      printf "%s='%s'\n" CONFIG_mysql_dump_use_separate_dirs "${CONFIG_mysql_dump_use_separate_dirs-}"
    else
      echo "#CONFIG_mysql_dump_use_separate_dirs='yes'"
    fi
    echo ""
    echo "# Choose Compression type. (gzip or bzip2)"
    if isSet CONFIG_mysql_dump_compression; then
      printf "%s='%s'\n" CONFIG_mysql_dump_compression "${CONFIG_mysql_dump_compression-}"
    else
      echo "#CONFIG_mysql_dump_compression='gzip'"
    fi
    echo ""
    echo "# Store an additional copy of the latest backup to a standard"
    echo "# location so it can be downloaded by third party scripts."
    if isSet CONFIG_mysql_dump_latest; then
      printf "%s='%s'\n" CONFIG_mysql_dump_latest "${CONFIG_mysql_dump_latest-}"
    else
      echo "#CONFIG_mysql_dump_latest='no'"
    fi
    echo ""
    echo "# Remove all date and time information from the filenames in the latest folder."
    echo "# Runs, if activated, once after the backups are completed. Practically it just finds all files in the latest folder"
    echo "# and removes the date and time information from the filenames (if present)."
    if isSet CONFIG_mysql_dump_latest_clean_filenames; then
      printf "%s='%s'\n" CONFIG_mysql_dump_latest_clean_filenames "${CONFIG_mysql_dump_latest_clean_filenames-}"
    else
      echo "#CONFIG_mysql_dump_latest_clean_filenames='no'"
    fi
    echo ""
    echo '# Create differential backups. Master backups are created weekly at #$CONFIG_do_weekly weekday. Between master backups,'
    echo "# diff is used to create differential backups relative to the latest master backup. In the Manifest file, you find the"
    echo "# following structure"
    echo '# $filename   md5sum  $md5sum diff_id $diff_id    rel_id  $rel_id'
    echo "# where each field is separated by the tabular character '\t'. The entries with $ at the beginning mean the actual values,"
    echo "# while the others are just for readability. The diff_id is the id of the differential or master backup which is also in"
    echo "# the filename after the last _ and before the suffixes begin, i.e. .diff, .sql and extensions. It is used to relate"
    echo '# differential backups to master backups. The master backups have 0 as $rel_id and are thereby identifiable. Differential'
    echo '# backups have the id of the corresponding master backup as $rel_id.'
    echo "#"
    echo '# To ensure that master backups are kept long enough, the value of $CONFIG_rotation_daily is set to a minimum of 21 days.'
    echo "#"
    if isSet CONFIG_mysql_dump_differential; then
      printf "%s='%s'\n" CONFIG_mysql_dump_differential "${CONFIG_mysql_dump_differential-}"
    else
      echo "#CONFIG_mysql_dump_differential='no'"
    fi
    echo ""
    echo ""
    echo "# Notification setup"
    echo ""
    echo "# What would you like to be mailed to you?"
    echo "# - log   : send only log file"
    echo "# - files : send log file and sql files as attachments (see docs)"
    echo "# - stdout : will simply output the log to the screen if run manually."
    echo "# - quiet : Only send logs if an error occurs to the MAILADDR."
    if isSet CONFIG_mailcontent; then
      printf "%s='%s'\n" CONFIG_mailcontent "${CONFIG_mailcontent-}"
    else
      echo "#CONFIG_mailcontent='stdout'"
    fi
    echo ""
    echo "# Set the maximum allowed email size in k. (4000 = approx 5MB email [see docs])"
    if isSet CONFIG_mail_maxattsize; then
      printf '%s=%q\n' CONFIG_mail_maxattsize "${CONFIG_mail_maxattsize-}"
    else
      echo "#CONFIG_mail_maxattsize=4000"
    fi
    echo ""
    echo "# Allow packing of files with tar and splitting it in pieces of CONFIG_mail_maxattsize."
    if isSet CONFIG_mail_splitandtar; then
      printf "%s='%s'\n" CONFIG_mail_splitandtar "${CONFIG_mail_splitandtar-}"
    else
      echo "#CONFIG_mail_splitandtar='yes'"
    fi
    echo ""
    echo "# Use uuencode instead of mutt. WARNING: Not all email clients work well with uuencoded attachments."
    if isSet CONFIG_mail_use_uuencoded_attachments; then
      printf "%s='%s'\n" CONFIG_mail_use_uuencoded_attachments "${CONFIG_mail_use_uuencoded_attachments-}"
    else
      echo "#CONFIG_mail_use_uuencoded_attachments='no'"
    fi
    echo ""
    echo "# Email Address to send mail to? (user@domain.com)"
    if isSet CONFIG_mail_address; then
      printf "%s='%s'\n" CONFIG_mail_address "${CONFIG_mail_address-}"
    else
      echo "#CONFIG_mail_address='root'"
    fi
    echo ""
    echo ""
    echo "# Encryption"
    echo ""
    echo "# Do you wish to encrypt your backups using openssl?"
    if isSet CONFIG_encrypt; then
      printf "%s='%s'\n" CONFIG_encrypt "${CONFIG_encrypt-}"
    else
      echo "#CONFIG_encrypt='no'"
    fi
    echo ""
    echo "# Choose a password to encrypt the backups."
    if isSet CONFIG_encrypt_password; then
      printf "%s='%s'\n" CONFIG_encrypt_password "${CONFIG_encrypt_password-}"
    else
      echo "#CONFIG_encrypt_password='password0123'"
    fi
    echo ""
    echo "# Other"
    echo ""
    echo "# Backup local files, i.e. maybe you would like to backup your my.cnf (mysql server configuration), etc."
    echo "# These files will be tar'ed, depending on your compression option CONFIG_mysql_dump_compression compressed and"
    echo "# depending on the option CONFIG_encrypt encrypted."
    echo "#"
    echo "# Note: This could also have been accomplished with CONFIG_prebackup or CONFIG_postbackup."
    if isSet CONFIG_backup_local_files; then
      declare -p CONFIG_backup_local_files | perl -pe 's/\[[^]]*]=//g' | perl -pe 's/^.*?([^ ]*=).*\((.*)\).*/$1($2)/' | tr '"' "'"
    else
      echo "#CONFIG_backup_local_files=()"
    fi
    echo ""
    echo "# Command to run before backups (uncomment to use)"
    if isSet CONFIG_prebackup; then
      printf "%s='%s'\n" CONFIG_prebackup "${CONFIG_prebackup-}"
    else
      echo "#CONFIG_prebackup='/etc/mysql-backup-pre'"
    fi
    echo ""
    echo "# Command run after backups (uncomment to use)"
    if isSet CONFIG_postbackup; then
      printf "%s='%s'\n" CONFIG_postbackup "${CONFIG_postbackup-}"
    else
      echo "#CONFIG_postbackup='/etc/mysql-backup-post'"
    fi
    echo ""
    echo "# Uncomment to activate! This will give folders rwx------"
    echo "# and files rw------- permissions."
    if [ -n "$newUmask" ] ; then
      echo $newUmask
    else
      echo "#umask 0077"
    fi
    echo ""
    echo "# dry-run, i.e. show what you are gonna do without actually doing it"
    echo "# inactive: =0 or commented out"
    echo "# active: uncommented AND =1"
    if isSet CONFIG_dryrun; then
      printf '%s=%q\n' CONFIG_dryrun "${CONFIG_dryrun-}"
    else
      echo "#CONFIG_dryrun=1"
    fi
    echo ""
    removeIO
    mv "$temp" "${1}${3:-_converted}"
    return 0
  )
}


function parse_config_file () {
  printf 'Found config file %s. ' "$1"
  if head -n1 "$1" | egrep -o 'version=.*' >& /dev/null; then
    version=`head -n1 "$1" | egrep -o 'version=.*' | awk -F"=" '{print $2}'`
    if [[ "$version" =~ 3.* ]]; then
      printf 'Version 3.* determined. Upgrade the configuration.\n'
      while true; do
        read -p "Upgrade configuration? [Y/n] " yn
        [[ "x$yn" = "x" ]] && { upgrade_config_file "$1" "3" "_new" || echo "Failed to convert."; break; }
        case $yn in
          [Yy]* ) upgrade_config_file "$1" "3" "_new" || echo "Failed to convert."; break;;
          [Nn]* ) break;;
          * ) echo "Please answer yes or no.";;
        esac
      done
    else
      printf 'Unknown version. Can not convert it. You have to convert it manually.\n'
    fi
  else
    printf 'No version information on first line of config file. Assuming the version is <3.\n'
    while true; do
      read -p "Convert? [Y/n] " yn
      [[ "x$yn" = "x" ]] && { upgrade_config_file "$1" "2" || echo "Failed to convert."; break; }
      case $yn in
        [Yy]* ) upgrade_config_file "$1" "2" || echo "Failed to convert."; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
      esac
    done
  fi
}

function create_config_file() {
  echo "Creating configuration file"
  upgrade_config_file "$1" "1" "_new" || echo "Failed to create."
}

######################################################################################################3
#create a new conf file if a name has been given as first argument
if [ "$1" != "" ]; then
  create_config_file $1
  exit 0
fi

#configuration
echo
printf 'Select the global configuration directory [/etc/automysqlbackup]: '
read configdir
configdir="${configdir%/}" # strip trailing slash if there
[[ "x$configdir" = "x" ]] && configdir='/etc/automysqlbackup'
printf 'Select directory for the executable [/usr/local/bin]: '
read bindir
bindir="${bindir%/}" # strip trailing slash if there
[[ "x$bindir" = "x" ]] && bindir='/usr/local/bin'
# Debian configuration file
DEBIANCNF='/etc/mysql/debian.cnf'
if [ -f $DEBIANCNF ]; then
  while true; do
    read -p "Debian configuration file found. Should I prepopulate the configuration with the path ? [Y/n] " yn
    [[ "x$yn" = "x" ]] && { CONFIG_mysql_configuration_file=$DEBIANCNF; break; }
    case $yn in
      [Yy]* ) CONFIG_mysql_configuration_file=$DEBIANCNF; break;;
      [Nn]* ) break;;
      * ) echo "Please answer yes or no.";;
    esac
  done
fi

#create global config directory
echo "### Creating global configuration directory ${configdir}:"
echo
if [ -d "${configdir}" ]; then
  echo "exists already ... searching for config files:"
  for i in "${configdir}"/*.conf; do
    parse_config_file "$i"
  done
else
  if mkdir "${configdir}" >/dev/null 2>&1; then
    #testing for permissions
    if [ -r "${configdir}" -a -x "${configdir}" ]; then
      printf "success\n"
    else
      printf "directory successfully created but has wrong permissions, trying to correct ... "
      if chmod +rx "${configdir}" >/dev/null 2>&1; then
        printf "corrected\n"
      else
        printf "failed. Aborting. Make sure you run the script with appropriate permissions.\n"
      fi
    fi
  else
    printf "failed ... check permissions.\n"
  fi
fi

echo
#creating configuration file
unset CONFIG_mysql_configuration_file
touch automysqlbackup.conf
create_config_file automysqlbackup.conf
mv automysqlbackup.conf_new automysqlbackup.conf
#copying files
echo "### Copying files."
echo
cp -i automysqlbackup.conf LICENSE README "${configdir}"/
cp -i automysqlbackup "${bindir}"/
[[ -f "${bindir}"/automysqlbackup ]] && [[ -x "${bindir}"/automysqlbackup ]] || chmod +x "${bindir}"/automysqlbackup || echo " failed - make sure you make the program executable, i.e. run 'chmod +x ${bindir}/automysqlbackup'"
echo
# restrict rights because of passwords
chmod -R o-rwx ${configdir}

if echo $PATH | grep "${bindir}" >/dev/null 2>&1; then
  printf "if you are running automysqlbackup under the same user as you run this install script,\nyou should be able to access it by running 'automysqlbackup' from the command line.\n"
  printf "if not, you have to check if 'echo \$PATH' has ${bindir} in it\n"
  printf "\nSetup Complete!\n"
else
  printf "if running under the current user, you have to use the full path ${bindir}/automysqlbackup since /usr/local/bin is not in 'echo \$PATH'\n"
  printf "\nSetup Complete!\n"
fi