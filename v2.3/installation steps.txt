-- Revision number $Rev$
-- Modification date $Date$

-------------------------------------------------------------------------------------------------------------
Installation steps
-------------------------------------------------------------------------------------------------------------

1. Uncompress sash.tar.gz (or sash.7z) package into your working directory.

2. Connect to target database as user SYS and execute the following script. 

targ_userview_<db_version>.sql 

3. Run the following script as user SYS on repository database 

sqlplus / as sysdba @config.sql

and answer all questions. 
In first part script will create repository owner and
whole repository schema. The following questions have to be answered:
- repository schema name - default is sash
- schema name password
- schema name tablespace

Warining:
If specified username and schema already exist it will be dropped and recreated with new empty repository.

Press Control-C if you don't want to configure target database at that time.
Next part is a target (monitored) database configuration and the following questions have to be answered:
- database name, 
- number of instances (1 for single instance database or more than one for RAC database),
- target database host name
- instance(s) name
- listener port
- password for sash user on target database.

Configuration script will create a database links from repository database to every instance of target database
and will setup a collection jobs for active sessions (SASH_PKG_COLLECT_%) and jobs for SQL/metrics collection (SASH_PKG_GET_ALL%).
Beside of that repository clean up job and watch dog job will be setup as well.

See example below

"------------------------------------------------------------------------------------"
Creating repository owner and job kill function using SYS user
"------------------------------------------------------------------------------------"
Enter user name (schema owner) [or enter to accept username sash] ?
Enter user password ? sash
Enter SASH user default tablespace [or enter to accept USERS tablespace] ?
SASH default tablespace is: users
"------------------------------------------------------------------------------------"
Existing sash user will be deleted.
If you are not sure hit Control-C , else Return :
"------------------------------------------------------------------------------------"
New sash user will be created.

Warning: Procedure created with compilation errors.

Connected.
"------------------------------------------------------------------------------------"
Installing SASH objects into sash schema
"------------------------------------------------------------------------------------"
Create sequence
Create tables
Crating SASH_REPO package
No errors.
No errors.
Crating SASH_PKG package
No errors.
No errors.
"------------------------------------------------------------------------------------"
Instalation completed. Starting SASH configuration process
"------------------------------------------------------------------------------------"
Enter target database name POLTP
Enter number of instances [default 1]
Enter host name for instance number 1 oracle-server.mydomain
Enter instance name for instance number 1 [ default POLTP ]
Enter listener port number [default 1521]
Enter SASH password on target database sash
"------------------------------------------------------------------------------------"
Configuration completed. Exiting.
You can now connect using user name and password specified above
"------------------------------------------------------------------------------------"
Disconnected from Oracle Database 11g Enterprise Edition Release 11.2.0.1.0 - 64bit Production
With the Partitioning, OLAP, Data Mining and Real Application Testing options

4. check repository jobs and log table

Login as user sash to repository database and run following script - job_stat.sql
Outout should be similar to this

SQL> @job_stat.sql

JOB_NAME                       LAST_START_DATE                     NEXT_RUN_DATE                       STATE           FAILURE_COUNT
------------------------------ ----------------------------------- ----------------------------------- --------------- -------------
SASH_PKG_GET_ALL_POLTP1        24-NOV-11 03.00.30.431000 +00:00    24-NOV-11 03.15.30.300000 +00:00    SCHEDULED                   0
SASH_REPO_PURGE                                                    25-NOV-11 00.00.00.000000 +00:00    SCHEDULED                   0
SASH_REPO_WATCHDOG             24-NOV-11 11.00.30.408000 +00:00    24-NOV-11 11.05.30.000000 +00:00    SCHEDULED                   0
SASH_PKG_COLLECT_POLTP1        24-NOV-11 11.00.30.295000 +00:00    24-NOV-11 11.00.30.000000 +00:00    RUNNING                     0

Check repository error log using the following script - checklog.sql

SQL> @checklog.sql

R START_TIME                ACTION                                           MESSAGE
- ------------------------- ------------------------------------------------ ------------------------------------------------------------------------
W 2011-11-24 11:07:20       add_db                                           no db link - moving forward POLTP1
I 2011-11-24 11:07:20       configure_db                                     get_event_names
I 2011-11-24 11:07:20       configure_db                                     get_users
I 2011-11-24 11:07:20       configure_db                                     get_params
I 2011-11-24 11:07:20       configure_db                                     get_data_files
I 2011-11-24 11:07:20       configure_db                                     get_metrics
I 2011-11-24 11:07:20       add_instance_job                                 adding scheduler job sash_pkg_collect_POLTP1
I 2011-11-24 11:07:20       add_instance_job                                 adding scheduler job sash_pkg_get_all_POLTP1
I 2011-11-24 11:07:21       create_repository_jobs                           adding new repository job

9 rows selected.

-------------------------------------------------------------------------------------------------------------
Adding new database
-------------------------------------------------------------------------------------------------------------

New databases can be added by using adddb.sql script when connected to repository using respository owner.
The following questions have to be answered:
- database name, 
- number of instances (1 for single instance database or more than one for RAC database),
- target database host name
- instance(s) name
- listener port
- password for sash user on target database.

SQL> @adddb
Enter database name newdb
Enter number of instances [default 1]
Enter host name for instance number 1 newdb.localdomain
Enter instance name for instance number 1 [ default newdb ]
Enter listener port number [default 1521]
Enter SASH password on target database sash
"------------------------------------------------------------------------------------"
Database added.
"------------------------------------------------------------------------------------"


-------------------------------------------------------------------------------------------------------------
Daily operations
-------------------------------------------------------------------------------------------------------------

Job maintenace:

To start job connect as repository owner and run script @start.sql or pl/sql function exec sash_repo.start_collecting_jobs; 
To stop run script @stop or pl/sql funcktion exec sash_repo.stop_collecting_jobs;  

To change default month retention you can use following pl/sql function 

exec sash_repo.set_retention('<retention>');

where <retention> is one of:
- d - last week
- w - last month
- h - last 24 h
- m - last 30 minutes



-------------------------------------------------------------------------------------------------------------
Manuall configuration
-------------------------------------------------------------------------------------------------------------
If for any reason adddb.sql can't be used steps specified below allow expirienced user to manually configure new database

To add database(s) instance(s) to repository using following package can be used:

exec sash_repo.add_db('svr1-vip', <listener_port>, <target password for sash user>, '<dbname>', '<instance_name>', <instance_number>, '<db_version>', <number of cores>);
select db_link from sash.sash_targets;
exec sash_pkg.configure_db('<db_link>');
exec sash_pkg.set_dbid('<db_link>');

ex. one instance
exec sash_repo.add_db('svr1', 1521, 'sash', 'test', 'test1', 1, '11.2.0.2', 8);
exec sash_pkg.configure_db('test1');
exec sash_pkg.set_dbid('test1');

ex. RAC
exec sash_repo.add_db('svr1-vip', 1521, 'sash', 'test', 'test1', 1, '11.2.0.2', 8);
exec sash_repo.add_db('svr2-vip', 1521, 'sash', 'test', 'test2', 2, '11.2.0.2', 8);
exec sash_pkg.configure_db('test1');
exec sash_pkg.set_dbid('test1');

To setup a new jobs following package can be used:

exec sash_repo.setup_jobs



