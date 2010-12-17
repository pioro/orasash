---------------------------------------------------------------------------------------------------
-- File Revision $Rev$
-- Last change $Date$
-- SVN URL $HeadURL$
---------------------------------------------------------------------------------------------------

-- (c) Kyle Hailey 2007
-- (c) Marcin Przepiorowski 2010
-- v2.0 Package deployed on target database, database link pointed to repository 
-- v2.1 Changes: - Deployed on repository database not on target, 
--               - Data collection via DB link pointed to target, 
--               - Bug fixing in get_sqlids
-- v2.2 Changes: - splited between 10g and above and 9i
--               - gathered instance statistic 
--				 - sql information improved


create sequence sashseq ;

--
-- BEGIN CREATE TARGET PACKAGE SASH_PKG
--
CREATE OR REPLACE PACKAGE sash_pkg AS
--          PROCEDURE print (v_sleep number, loops number) ;
          PROCEDURE get_all  ;
		  procedure get_one(v_sql_id varchar2);
          PROCEDURE get_objs(l_dbid number)  ;
 	      PROCEDURE get_latch ; 
          PROCEDURE get_users  ;
	      PROCEDURE get_params  ;
		  PROCEDURE get_sqltxt(l_dbid number) ;
          PROCEDURE get_sqlstats(l_hist_samp_id number, l_dbid number)  ;
		  PROCEDURE get_sqlid(l_dbid number, v_sql_id varchar2) ;
		  procedure get_sqlids(l_dbid number);
          PROCEDURE get_data_files  ;
		  PROCEDURE get_sqlplans(l_hist_samp_id number, l_dbid number) ;
		  PROCEDURE get_extents;
          PROCEDURE get_event_names  ;
		  PROCEDURE collect_stats(v_sleep number, loops number, vinstance number);
          PROCEDURE collect (v_sleep number, loops number,vinstance number) ;
          FUNCTION get_dbid  return number ;
          PROCEDURE set_dbid  ;
          END sash_pkg;
/
show errors

--
-- BEGIN CREATE TARGET PACKAGE BODY SASH_PKG
--
-- ZZZZ
CREATE OR REPLACE PACKAGE BODY sash_pkg AS

       FUNCTION get_dbid return number is
          l_dbid number;
          begin
            select dbid into l_dbid from v$database@sashprod1;
            return l_dbid;
            -- return 1;
       end get_dbid;

       PROCEDURE get_users is
          l_dbid number;
          begin
            select dbid into l_dbid from v$database@sashprod1;
            insert into sash_users 
                     (dbid, username, user_id)
                     select l_dbid,username,user_id from dba_users@sashprod1; 
			exception
				when DUP_VAL_ON_INDEX then
					sash_repo.log_message('GET_USERS', 'Already configured ?','W');
       end get_users;

PROCEDURE get_latch is
 l_dbid number;
 begin
 select dbid into l_dbid from v$database@sashprod1;
 insert into sash_latch
 (dbid, latch#, name)
 select l_dbid,latch#, name from v$latch@sashprod1;
 commit;
 end get_latch; 
 
 procedure get_stats is
 l_dbid number;
 begin
  select dbid into l_dbid from v$database@sashprod1;
  insert into sash_stats select l_dbid, STATISTIC#, name, 0 from v$sysstat@sashprod1;
  commit;
 end get_stats;
 
 
       PROCEDURE get_params is
          l_dbid number;
          begin
            select dbid into l_dbid from v$database@sashprod1;
            -- using gv$ because of problem with the error
            -- ORA-02070: database SASHREPO does not 
            -- support operator USERENV in this context
            insert into sash_params 
                  ( dbid, name, value)
                  select l_dbid,name,value from gv$parameter@sashprod1;
			exception
				when DUP_VAL_ON_INDEX then
					sash_repo.log_message('GET_PARAMS', 'Already configured ?','W');				  
       end get_params;

       PROCEDURE set_dbid is
          l_dbid number;
          l_version varchar(17);
          l_oracle_home varchar2(150);
          l_instance_name varchar2(30);
          l_host varchar2(30);
          cnt number;
          begin 
            select dbid into l_dbid from v$database@sashprod1;
            select count(*) into cnt from 
                sash_target;
            if cnt = 0 then 
                insert into 
                   sash_target ( dbid )
                   values (l_dbid);
            end if;
            select 
                      version,
                      host_name,
                      instance_name 
               into 
                      l_version,
                      l_host,
                      l_instance_name 
               from v$instance@sashprod1;
            select substr(file_spec,0,instr(file_spec,'bin')-2) into l_oracle_home
            from DBA_LIBRARIES@sashprod1  where library_name = 'DBMS_SUMADV_LIB';
			begin
            insert into sash_targets 
                  (       dbid, 
                          host, 
                          home, 
                          sid, 
                          sashseq, 
                          version)
                  values (l_dbid,
                          l_host,
                          l_oracle_home,
                          l_instance_name,
                          0,
                          l_version); 
			exception
				when DUP_VAL_ON_INDEX then
					sash_repo.log_message('SET_DBID', 'Already configured ?','W');					
			end;
       end set_dbid;

       PROCEDURE get_data_files is
          l_dbid number;
          --v_file_name varchar2(513);
          --v_file_id number;
          --v_tablespace_name varchar2(30);
          cursor files_cur is
             select file_name, file_id, tablespace_name from dba_data_files@sashprod1;
       begin
          l_dbid:=get_dbid;
            -- using gv$ because of problem with the error
            -- ORA-02070: database SASHREPO does not 
            -- support operator USERENV in this context
         /*
          insert into sash_data_files@SASHREPO 
                  ( dbid, file_name, file_id, tablespace_name )
                   select l_dbid, file_name, file_id, tablespace_name 
                   from dba_data_files;
         */
         for file_rec in files_cur loop 
          insert into sash_data_files ( dbid, file_name, file_id, tablespace_name ) values
                   ( l_dbid, 
                    file_rec.file_name, 
                    file_rec.file_id, 
                    file_rec.tablespace_name );
         end loop;
		exception
				when DUP_VAL_ON_INDEX then
					sash_repo.log_message('GET_DATA_FILES', 'Already configured ?','W');		 
       end get_data_files;

       PROCEDURE get_extents is
          l_dbid number;
       begin
          l_dbid:=get_dbid;
            -- using gv$ because of problem with the error
            -- ORA-02070: database SASHREPO does not 
            -- support operator USERENV in this context
          insert into sash_extents 
                  ( dbid, segment_name, partition_name, segment_type, tablespace_name, 	extent_id, file_id, block_id, bytes, blocks, relative_fno)
                   select l_dbid, segment_name, partition_name, segment_type, tablespace_name, 	extent_id, file_id, block_id, bytes, blocks, relative_fno from dba_extents@sashprod1;
       end get_extents;
	   
	   PROCEDURE get_event_names is
          l_dbid number;
       begin
          l_dbid:=get_dbid;
            -- using gv$ because of problem with the error
            -- ORA-02070: database SASHREPO does not 
            -- support operator USERENV in this context
          insert into sash_event_names 
                  ( dbid, event#, name )
                   select distinct l_dbid, event#, name from gv$event_name@sashprod1;
 		exception
			when DUP_VAL_ON_INDEX then
					sash_repo.log_message('GET_EVENT_NAMES', 'Already configured ?','W');
end get_event_names;
	   

PROCEDURE get_objs(l_dbid number) is
type sash_objs_type is table of sash_objs%rowtype;
sash_objsrec  sash_objs_type := sash_objs_type();
cursor c_sashobjs is select /*+DRIVING_SITE(o) */ l_dbid, 
                       o.object_id,
                       o.owner,
                       o.object_name,
                       o.subobject_name,
                       o.object_type
                from dba_objects@sashprod1 o
                where object_id  in ( 
                        select current_obj# from (
                        select count(*) cnt, CURRENT_OBJ#
                        from sash 
                        where
                           current_obj# > 0
                           and sample_time > (sysdate - 1/24)
                        group by current_obj#
                        order by cnt desc )
                     where rownum < 100)
                  and object_id not in (select object_id from 
                       sash_objs where dbid = l_dbid
                       ) ;

begin
open c_sashobjs;
fetch c_sashobjs bulk collect into sash_objsrec;
forall i in 1 .. sash_objsrec.count 
         insert into sash_objs values sash_objsrec(i);          
close c_sashobjs;
end get_objs;

PROCEDURE get_sqlplans(l_hist_samp_id number, l_dbid number) is
type sash_sqlrec_type is table of sash_sqlplans%rowtype;
sash_sqlrec  sash_sqlrec_type := sash_sqlrec_type();
cursor c is
                select /*+DRIVING_SITE(sql) */
                      sql.sql_id, 
					  sql.inst_id,
					  sql.plan_hash_value,
                       'REMARKS' remarksdesc ,
                       sql.OPERATION,
                       sql.OPTIONS,
                       sql.OBJECT_NODE,
                       sql.OBJECT_OWNER,
                       sql.OBJECT_NAME,
                       0,
                       sql.OBJECT_TYPE,
                       sql.OPTIMIZER,
                       sql.SEARCH_COLUMNS,
                       sql.ID,
                       sql.PARENT_ID,
					   sql.depth,
                       sql.POSITION,
                       sql.COST,
                       sql.CARDINALITY,
                       sql.BYTES,
                       sql.OTHER_TAG,
                       sql.PARTITION_START,
                       sql.PARTITION_STOP,
                       sql.PARTITION_ID,
                       sql.OTHER,
                       sql.DISTRIBUTION,
                       sql.CPU_COST,
                       sql.IO_COST,
                       sql.TEMP_SPACE,
                       sql.ACCESS_PREDICATES,
                       sql.FILTER_PREDICATES,
					   l_dbid 
                from gv$sql_plan@sashprod1 sql, sash_hour_sqlid sqlids
                where sql.sql_id= sqlids.sql_id and sql.plan_hash_value = sqlids.sql_plan_hash_value
				and not exists (select 1 from sash_sqlplans sqlplans where sqlplans.plan_hash_value = sqlids.sql_plan_hash_value 
										 and sqlplans.sql_id = sqlids.sql_id );
begin
open c;
fetch c bulk collect into sash_sqlrec;
forall i in 1 .. sash_sqlrec.count 
         insert into sash_sqlplans values sash_sqlrec(i);          
close c;		   
--update sash_sqlplans set HIST_SAMPLE_ID = l_hist_samp_id, dbid = l_dbid where HIST_SAMPLE_ID = -1;
--commit;
end get_sqlplans;

PROCEDURE get_sqlstats(l_hist_samp_id number, l_dbid number) is
type sash_sqlstats_type is table of sash_sqlstats%rowtype;
sash_sqlstats_rec sash_sqlstats_type;
cursor c is select /*+DRIVING_SITE(sql) */  
					   l_dbid,
                       l_hist_samp_id,
                       sql.address,
                       sql.sql_id,
					   sql.inst_id,
                       sql.child_number,
                       sql.executions,
                       sql.elapsed_time,
					   sql.disk_reads,
					   sql.buffer_gets,
					   sql.cpu_time,
					   sql.fetches,
                       sql.rows_processed,
					   1,
					   1
                from gv$sql@sashprod1 sql
                where (sql.sql_id, sql.plan_hash_value) in ( select sql_id, SQL_PLAN_HASH_VALUE from sash_hour_sqlid t  );
	begin
		open c;
		fetch c bulk collect into sash_sqlstats_rec;
		forall i in 1..sash_sqlstats_rec.count 
			insert into sash_sqlstats values sash_sqlstats_rec(i);	
			
		update sash_sqlstats s set (s.ELAPSED_TIME_DELTA,s.DISK_READS_DELTA) = (select s.ELAPSED_TIME - old.ELAPSED_TIME, s.DISK_READS - old.DISK_READS from sash_sqlstats old where 
		old.HIST_SAMPLE_ID = s.HIST_SAMPLE_ID - 1 and old.sql_id = s.sql_id and old.child_number = s.child_number)
		where HIST_SAMPLE_ID = l_hist_samp_id;	
end get_sqlstats;
	   
	   
PROCEDURE get_sqlid(l_dbid number, v_sql_id varchar2) is
begin
		 insert into sash_hour_sqlid select sql_id, sql_plan_hash_value from sash where l_dbid = dbid and sql_id = v_sql_id;
end get_sqlid;	   

PROCEDURE get_sqlids(l_dbid number) is
          v_sqlid  number;
		  v_sqllimit number:=0;
		  v_lastall number;
		  
       begin
		 begin
			select to_number(value) into v_sqllimit from sash_configuration where param='SQL LIMIT';
		    dbms_output.put_line('v limit ' || v_sqllimit);
			exception when NO_DATA_FOUND then 
		      v_sqllimit:=21;
		 end;
		 -- check when was last get_all 
		 select (sysdate-max(HIST_DATE))*24 into v_lastall from sash_hist_sample;
		 -- if last get_all was more than 1 h ago - limit data to 1h
		 if (v_lastall>1) then
			v_lastall:=1;
		 end if;
		 dbms_output.put_line('start');
		 insert into sash_hour_sqlid select sql_id, sql_plan_hash_value from (
                          select count(*) cnt, sql_id, sql_plan_hash_value
                          from sash 
                          where l_dbid = dbid
                             and sql_id != '0'
							 --and sql_plan_hash_value != '0'
                             and sample_time > sysdate - v_lastall/24
                          group by sql_id, sql_plan_hash_value
                          order by cnt desc )
                        where rownum < v_sqllimit;
		dbms_output.put_line('next');
end get_sqlids;


PROCEDURE get_sqltxt(l_dbid number)  is
type sash_sqltxt_type is table of sash_sqltxt%rowtype;
sash_sqltxt_rec sash_sqltxt_type;
cursor c_sqltxt is select /*+DRIVING_SITE(sqlt) */ distinct 1,null,sqlt.sql_id,0,sqlt.piece,sqlt.sql_text 
		    from gv$sqltext@sashprod1 sqlt 
			where sqlt.sql_id in 
			(select sql_id from sash_hour_sqlid t 
			 where not exists (select 1 from sash_sqltxt psql where t.sql_id = psql.sql_id));
begin
open c_sqltxt;
fetch c_sqltxt bulk collect into sash_sqltxt_rec;
FOR i IN 1..sash_sqltxt_rec.count loop
	sash_sqltxt_rec(i).dbid := l_dbid;
end loop;
forall i in 1..sash_sqltxt_rec.count 
	insert into sash_sqltxt values sash_sqltxt_rec(i);
close c_sqltxt;
end get_sqltxt;
 
 
/*
       PROCEDURE print(v_sleep number, loops number) is
          sash_rec sash%rowtype;
          cursor sash_cur
             return sash%ROWTYPE is  
               select a.*, sashseq.nextval sample_id from sashnow a;
          begin
            for i in 1..loops loop
              open sash_cur; loop
                fetch sash_cur into sash_rec;
                exit when sash_cur%notfound;
                dbms_output.put_line(sash_rec.sample_time||' '||
                                     to_char(sash_rec.session_id)||' '||
                                     sash_rec.session_state);
              end loop;
              dbms_lock.sleep(v_sleep);
              close sash_cur;
            end loop;
       end print;
*/

PROCEDURE collect(v_sleep number, loops number, vinstance number) is
          sash_rec sash%rowtype;
		  TYPE SashcurTyp IS REF CURSOR;
		  sash_cur   SashcurTyp;		  
          l_dbid number;
          cur_sashseq   number := 0;
		  sql_stat varchar2(4000);
          
          begin
            l_dbid:=get_dbid;
			sql_stat := 'select a.*, 1 sample_id, null machine,  null terminal, null inst_id from sys.sashnow@sashprod' || vinstance || ' a';
            for i in 1..loops loop
              select  sashseq.nextval into cur_sashseq from dual;
              open sash_cur FOR sql_stat; 
			  loop
                fetch sash_cur into sash_rec;
                exit when sash_cur%notfound;
                  insert into sash
                   (  DBID,
                      SAMPLE_TIME,
                      SESSION_ID,
                      SESSION_STATE,
                      SESSION_SERIAL#,
                      USER_ID,
                      SQL_ADDRESS,
                      SQL_PLAN_HASH_VALUE,
                      SQL_CHILD_NUMBER,
                      SQL_ID,
                      SQL_OPCODE,
                      SESSION_TYPE,
                      EVENT#,
                      SEQ#,
                      P1,
                      P2,
                      P3,
                      WAIT_TIME,
                      TIME_WAITED,
                      CURRENT_OBJ#,
                      CURRENT_FILE#,
                      CURRENT_BLOCK#,
                      PROGRAM,
                      MODULE,
                      ACTION,
                      FIXED_TABLE_SEQUENCE,
                      SAMPLE_ID,
					  inst_id
					  )
                  values 
                       ( sash_rec.DBID,
                         sash_rec.SAMPLE_TIME,
                         sash_rec.SESSION_ID,
                         sash_rec.SESSION_STATE,
                         sash_rec.SESSION_SERIAL#,
                         sash_rec.USER_ID,
                         sash_rec.SQL_ADDRESS,
                         sash_rec.SQL_PLAN_HASH_VALUE,
                         sash_rec.SQL_CHILD_NUMBER,
                         sash_rec.SQL_ID,
                         sash_rec.SQL_OPCODE,
                         sash_rec.SESSION_TYPE,
                         sash_rec.EVENT#,
                         sash_rec.SEQ#,
                         sash_rec.P1,
                         sash_rec.P2,
                         sash_rec.P3,
                         sash_rec.WAIT_TIME,
                         sash_rec.TIME_WAITED,
                         sash_rec.CURRENT_OBJ#,
                         sash_rec.CURRENT_FILE#,
                         sash_rec.CURRENT_BLOCK#,
                         sash_rec.PROGRAM,
                         sash_rec.MODULE,
                         sash_rec.ACTION,
                         sash_rec.FIXED_TABLE_SEQUENCE,
                         cur_sashseq,
						 vinstance
						);
              end loop;
              close sash_cur;
              commit;
              dbms_lock.sleep(v_sleep);
            end loop;
       end collect;
	   
	   procedure collect_stats(v_sleep number, loops number, vinstance number) is
		type sash_instance_stats_type is table of sash_instance_stats%rowtype;
		session_rec sash_instance_stats_type;
		session_rec1 sash_instance_stats_type;
		session_rec_delta sash_instance_stats_type := sash_instance_stats_type();
		sql_stat varchar2(4000);
		sql_stat1 varchar2(4000);
     	TYPE SashcurTyp IS REF CURSOR;
		sash_cur   SashcurTyp;		  

		begin
		if session_rec_delta.count < 3 then 
			session_rec_delta.extend(3);
		end if;
		
		open sash_cur FOR sql_stat; 
			  
		sql_stat := 'select /*+DRIVING_SITE(ss) */ 1, sysdate, statistic#, value from v$sysstat@sashprod'|| vinstance || 'ss where statistic# in (select sash_s.statistic# from sash_stats sash_s where collect = 1)';
		for l in 1..loops loop
			fetch sash_cur bulk collect into session_rec;
			dbms_lock.sleep(v_sleep);
			fetch sash_cur bulk collect into session_rec1;
			--select /*+DRIVING_SITE(ss) */ 1, sysdate, statistic#, value bulk collect into session_rec1 from v$sysstat@sashprod1 ss where statistic# in (select sash_s.statistic# from sash_stats sash_s where collect = 1);
			for i in 1..session_rec.count loop
				session_rec_delta(i).value := session_rec1(i).value - session_rec(i).value;
				session_rec_delta(i).sample_time := session_rec1(i).sample_time;
				session_rec_delta(i).statistic# := session_rec1(i).statistic#;
				session_rec_delta(i).dbid := 1;
			end loop;
			forall i in 1..session_rec_delta.count 
				insert into sash_instance_stats values session_rec_delta(i);
			--dbms_output.put_line('Commits ' || session_rec1(2).value ||' ' || session_rec(2).value || ' rate ' || to_number((session_rec1(2).value - session_rec(2).value))/15 );
			--dbms_output.put_line('Calls ' || session_rec1(3).value ||' ' || session_rec(3).value || ' rate ' || to_number((session_rec1(3).value - session_rec(3).value))/15 );
			commit;
		end loop;   
	   end collect_stats;
	   
	   
	 PROCEDURE get_one(v_sql_id varchar2) is
		l_hist_samp_id	number;
		l_dbid number;
	   begin
		  select hist_id_seq.currval into l_hist_samp_id from dual;
		  l_dbid:=get_dbid;
          get_sqlid(l_dbid,v_sql_id);
		  get_sqltxt(l_dbid);
          get_sqlstats(l_hist_samp_id, l_dbid);
          get_objs(l_dbid);
          get_sqlplans(l_hist_samp_id, l_dbid);
		  insert into sash_hist_sample values (l_hist_samp_id, l_dbid, sysdate);
		  commit;
       end get_one;	

       PROCEDURE get_all is
		l_hist_samp_id	number;
		l_dbid number;
	   begin
		  select hist_id_seq.nextval into l_hist_samp_id from dual;
		  l_dbid:=get_dbid;
          get_sqlids(l_dbid);
		  get_sqltxt(l_dbid);
          get_sqlstats(l_hist_samp_id, l_dbid);
          get_objs(l_dbid);
          get_sqlplans(l_hist_samp_id, l_dbid);
		  insert into sash_hist_sample values (l_hist_samp_id, l_dbid, sysdate);
		  commit;
       end get_all;	   
	   
END sash_pkg;
/


show errors
