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
          PROCEDURE get_all(v_dblink varchar2, v_inst_num number)  ;
		  procedure get_stats(v_dblink varchar2) ;
		  procedure get_one(v_sql_id varchar2,v_dblink varchar2, v_inst_num number);
          PROCEDURE get_objs(l_dbid number, v_dblink varchar2)  ;
 	      PROCEDURE get_latch(v_dblink varchar2) ; 
          PROCEDURE get_users(v_dblink varchar2)  ;
	      PROCEDURE get_params(v_dblink varchar2)  ;
		  PROCEDURE get_sqltxt(l_dbid number, v_dblink varchar2) ;
          PROCEDURE get_sqlstats(l_hist_samp_id number, l_dbid number, v_dblink varchar2, v_inst_num number)  ;
		  PROCEDURE get_sqlid(l_dbid number, v_sql_id varchar2, v_dblink varchar2) ;
		  procedure get_sqlids(l_dbid number, v_dblink varchar2);
          PROCEDURE get_data_files(v_dblink varchar2)  ;
		  PROCEDURE get_sqlplans(l_hist_samp_id number, l_dbid number,v_dblink varchar2) ;
		  PROCEDURE get_extents(v_dblink varchar2);
          PROCEDURE get_event_names(v_dblink varchar2)  ;
		  PROCEDURE collect_stats(v_sleep number, loops number, v_dblink varchar2, vinstance number);
          PROCEDURE collect (v_sleep number, loops number,v_dblink varchar2, vinstance number) ;
          FUNCTION get_dbid (v_dblink varchar2) return number ;
          PROCEDURE set_dbid ( v_dblink varchar2)  ;
          END sash_pkg;
/
show errors

--
-- BEGIN CREATE TARGET PACKAGE BODY SASH_PKG
--
-- ZZZZ
CREATE OR REPLACE PACKAGE BODY sash_pkg AS

       FUNCTION get_dbid(v_dblink varchar2) return number is
          l_dbid number;
          begin
            execute immediate 'select dbid  from v$database@'||v_dblink into l_dbid;
            return l_dbid;
       end get_dbid;

       PROCEDURE get_users(v_dblink varchar2) is
          l_dbid number;
          begin
            execute immediate 'select dbid  from v$database@'||v_dblink into l_dbid;
            execute immediate 'insert into sash_users 
                     (dbid, username, user_id)
                     select ' || l_dbid || ',username,user_id from dba_users@'||v_dblink;
			exception
				when DUP_VAL_ON_INDEX then
					sash_repo.log_message('GET_USERS', 'Already configured ?','W');
       end get_users;

PROCEDURE get_latch(v_dblink varchar2) is
 l_dbid number;
 begin
 execute immediate 'select dbid  from v$database@'||v_dblink into l_dbid;
 execute immediate 'insert into sash_latch (dbid, latch#, name) select ' || l_dbid || ',latch#, name from v$latch@'||v_dblink;
 commit;
 end get_latch; 
 
 procedure get_stats(v_dblink varchar2) is
 l_dbid number;
 begin
 execute immediate 'select dbid  from v$database@'||v_dblink into l_dbid;
 execute immediate 'insert into sash_stats select ' || l_dbid || ', STATISTIC#, name, 0 from v$sysstat@'||v_dblink;
  commit;
 end get_stats;
 
 
       PROCEDURE get_params(v_dblink varchar2) is
          l_dbid number;
          begin
            execute immediate 'select dbid  from v$database@'||v_dblink into l_dbid;
            execute immediate 'insert into sash_params ( dbid, name, value) select ' || l_dbid || ',name,value from v$parameter@'||v_dblink;
			exception
				when DUP_VAL_ON_INDEX then
					sash_repo.log_message('GET_PARAMS', 'Already configured ?','W');				  
       end get_params;

       PROCEDURE set_dbid(v_dblink varchar2) is
          l_dbid number;
          l_version varchar(17);
          l_oracle_home varchar2(150);
          l_instance_name varchar2(30);
          l_host varchar2(30);
          cnt number;
          begin 
            execute immediate 'select dbid  from v$database@'||v_dblink into l_dbid;
            select count(*) into cnt from 
                sash_target;
            if cnt = 0 then 
                insert into 
                   sash_target ( dbid )
                   values (l_dbid);
            end if;
			/*
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
			*/
       end set_dbid;

       PROCEDURE get_data_files(v_dblink varchar2) is
          l_dbid number;
          sql_stat varchar2(4000);
		  TYPE SashcurTyp IS REF CURSOR;
		  sash_cur   SashcurTyp;	
          sash_rec sash_data_files%rowtype;		  
		  
		 begin
         l_dbid:=get_dbid(v_dblink);
		 sql_stat:= 'select '|| l_dbid ||', file_name, file_id, tablespace_name from dba_data_files@'||v_dblink;
		 open sash_cur FOR sql_stat; 
		 loop
           fetch sash_cur into sash_rec;
           exit when sash_cur%notfound;	 
           insert into sash_data_files ( dbid, file_name, file_id, tablespace_name ) values
                   ( l_dbid, 
                    sash_rec.file_name, 
                    sash_rec.file_id, 
                    sash_rec.tablespace_name );
         end loop;
		exception
				when DUP_VAL_ON_INDEX then
					sash_repo.log_message('GET_DATA_FILES', 'Already configured ?','W');		 
       end get_data_files;

       PROCEDURE get_extents(v_dblink varchar2) is
          l_dbid number;
       begin
          l_dbid:=get_dbid(v_dblink);
            -- using gv$ because of problem with the error
            -- ORA-02070: database SASHREPO does not 
            -- support operator USERENV in this context
			/*
          insert into sash_extents 
                  ( dbid, segment_name, partition_name, segment_type, tablespace_name, 	extent_id, file_id, block_id, bytes, blocks, relative_fno)
                   select l_dbid, segment_name, partition_name, segment_type, tablespace_name, 	extent_id, file_id, block_id, bytes, blocks, relative_fno from dba_extents@sashprod1;
			*/
       end get_extents;

PROCEDURE get_event_names(v_dblink varchar2) is
          l_dbid number;
		  
       begin
          l_dbid:=get_dbid(v_dblink);
          execute immediate 'insert into sash_event_names ( dbid, event#, name ) select distinct '|| l_dbid ||', event#, name from v$event_name@' || v_dblink;
 		exception
			when DUP_VAL_ON_INDEX then
					sash_repo.log_message('GET_EVENT_NAMES', 'Already configured ?','W');
end get_event_names;
	   

PROCEDURE get_objs(l_dbid number, v_dblink varchar2) is
type sash_objs_type is table of sash_objs%rowtype;
sash_objsrec  sash_objs_type := sash_objs_type();
type ctype is ref cursor;
C_SASHOBJS ctype;
sql_stat varchar2(4000);


begin
sql_stat:='select /*+DRIVING_SITE(o) */ :1, 
                       o.object_id,
                       o.owner,
                       o.object_name,
                       o.subobject_name,
                       o.object_type
                from dba_objects@' || v_dblink || ' o
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
                       sash_objs where dbid = :2
                       )';
open c_sashobjs for sql_stat using l_dbid, l_dbid;
fetch c_sashobjs bulk collect into sash_objsrec;
forall i in 1 .. sash_objsrec.count 
         insert into sash_objs values sash_objsrec(i);          
close c_sashobjs;
end get_objs;

PROCEDURE get_sqlplans(l_hist_samp_id number, l_dbid number,  v_dblink varchar2) is
type sash_sqlrec_type is table of sash_sqlplans%rowtype;
sash_sqlrec  sash_sqlrec_type := sash_sqlrec_type(); 
type ctype is ref cursor;
c ctype;
sql_stat varchar2(4000);

begin
sql_stat:='select /*+DRIVING_SITE(sql) */
                      sql.sql_id, 
					  sql.inst_id,
					  sql.plan_hash_value,
                       ''REMARKS'' remarksdesc ,
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
					   :1
                from v$sql_plan@' || v_dblink || ' sql, sash_hour_sqlid sqlids
                where sql.sql_id= sqlids.sql_id and sql.plan_hash_value = sqlids.sql_plan_hash_value
				and not exists (select 1 from sash_sqlplans sqlplans where sqlplans.plan_hash_value = sqlids.sql_plan_hash_value 
										 and sqlplans.sql_id = sqlids.sql_id )';
open c for sql_stat using l_dbid;
fetch c bulk collect into sash_sqlrec;
forall i in 1 .. sash_sqlrec.count 
         insert into sash_sqlplans values sash_sqlrec(i);          
close c;		   
end get_sqlplans;

PROCEDURE get_sqlstats(l_hist_samp_id number, l_dbid number, v_dblink varchar2, v_inst_num number) is
type sash_sqlstats_type is table of sash_sqlstats%rowtype;
sash_sqlstats_rec sash_sqlstats_type;
type ctype is ref cursor;
c ctype;
sql_stat varchar2(4000);

begin
	sql_stat:='select /*+DRIVING_SITE(sql) */  
					   :1,
                       :2,
					   :3,
                       sql.address,
                       sql.sql_id,
					   sql.plan_hash_value,
                       sql.child_number,
                       sql.executions,
                       sql.elapsed_time,
					   sql.disk_reads,
					   sql.buffer_gets,
					   sql.cpu_time,
					   sql.fetches,
                       sql.rows_processed,
					   1,1,1,1,1,1,1
                from v$sql@' || v_dblink || ' sql
                where (sql.sql_id, sql.plan_hash_value) in ( select sql_id, SQL_PLAN_HASH_VALUE from sash_hour_sqlid t  )';
		open c for sql_stat using l_dbid, l_hist_samp_id, v_inst_num;
		fetch c bulk collect into sash_sqlstats_rec;
		forall i in 1..sash_sqlstats_rec.count 
			insert into sash_sqlstats values sash_sqlstats_rec(i);	
			
		update sash_sqlstats s set (s.executions_delta, s.ELAPSED_TIME_DELTA,s.DISK_READS_DELTA,s.buffer_gets_delta,s.cpu_time_delta,s.fetches_delta,s.rows_processed_delta) = 
		(select s.executions - old.executions, s.ELAPSED_TIME - old.ELAPSED_TIME, s.DISK_READS - old.DISK_READS, s.buffer_gets - old.buffer_gets, s.cpu_time - old.cpu_time,
		 s.fetches - old.fetches, s.rows_processed - old.rows_processed
		from sash_sqlstats old where 
		old.HIST_SAMPLE_ID = s.HIST_SAMPLE_ID - 1 and old.sql_id = s.sql_id and old.child_number = s.child_number)
		where HIST_SAMPLE_ID = l_hist_samp_id;	
end get_sqlstats;


PROCEDURE get_sqlid(l_dbid number, v_sql_id varchar2,  v_dblink varchar2 ) is
begin
		 insert into sash_hour_sqlid select sql_id, sql_plan_hash_value from sash where l_dbid = dbid and sql_id = v_sql_id;
end get_sqlid;	   

PROCEDURE get_sqlids(l_dbid number, v_dblink varchar2) is
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
		 -- added distinct as there can be more than one child
		 insert into sash_hour_sqlid select distinct sql_id, sql_plan_hash_value from (
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


PROCEDURE get_sqltxt(l_dbid number, v_dblink varchar2)  is
type sash_sqltxt_type is table of sash_sqltxt%rowtype;
sash_sqltxt_rec sash_sqltxt_type;
type ctype is ref cursor;
c_sqltxt ctype;
sql_stat varchar2(4000);

begin
sql_stat:='select /*+DRIVING_SITE(sqlt) */ distinct 1,null,sqlt.sql_id,0,sqlt.piece,sqlt.sql_text 
		    from v$sqltext@'|| v_dblink || ' sqlt 
			where sqlt.sql_id in 
			(select sql_id from sash_hour_sqlid t 
			 where not exists (select 1 from sash_sqltxt psql where t.sql_id = psql.sql_id))';
open c_sqltxt for sql_stat;
fetch c_sqltxt bulk collect into sash_sqltxt_rec;
FOR i IN 1..sash_sqltxt_rec.count loop
	sash_sqltxt_rec(i).dbid := l_dbid;
end loop;
forall i in 1..sash_sqltxt_rec.count 
	insert into sash_sqltxt values sash_sqltxt_rec(i);
close c_sqltxt;
end get_sqltxt;
 
 
PROCEDURE collect(v_sleep number, loops number, v_dblink varchar2, vinstance number) is
          sash_rec sash%rowtype;
		  TYPE SashcurTyp IS REF CURSOR;
		  sash_cur   SashcurTyp;		  
          l_dbid number;
          cur_sashseq   number := 0;
		  sql_stat varchar2(4000);
          
          begin
            l_dbid:=get_dbid(v_dblink);
			sql_stat := 'select a.*, 1 sample_id, null machine,  null terminal, null inst_id from sys.sashnow@' || v_dblink || ' a';
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
	   
	   procedure collect_stats(v_sleep number, loops number, v_dblink varchar2, vinstance number) is
		type sash_instance_stats_type is table of sash_instance_stats%rowtype;
		session_rec sash_instance_stats_type;
		--session_rec1 sash_instance_stats_type;
		--session_rec_delta sash_instance_stats_type := sash_instance_stats_type();
		sql_stat varchar2(4000);
		--sql_stat1 varchar2(4000);
     	TYPE SashcurTyp IS REF CURSOR;
		sash_cur   SashcurTyp;		
	    l_dbid number;		
		--sash_cur1   SashcurTyp;

		begin
		/*
		if session_rec_delta.count < 3 then 
			session_rec_delta.extend(3);
		end if;
		*/	  
		
		l_dbid:=get_dbid(v_dblink);
		sql_stat := 'select /*+DRIVING_SITE(ss) */ ' || l_dbid || ' , ' || vinstance || ' ,sysdate, statistic#, value from v$sysstat@'|| v_dblink || ' ss where statistic# in (select sash_s.statistic# from sash_stats sash_s where collect = 1)';	
		--open sash_cur FOR sql_stat; 
		
		for l in 1..loops loop
			open sash_cur FOR sql_stat; 
			fetch sash_cur bulk collect into session_rec;

			forall i in 1..session_rec.count 
				insert into sash_instance_stats values session_rec(i);
			--dbms_output.put_line('Commits ' || session_rec(2).value ||' ' || session_rec(2).value || ' rate ' || to_number((session_rec(2).value - session_rec(2).value))/15 );
			--dbms_output.put_line('Calls ' || session_rec1(3).value ||' ' || session_rec(3).value || ' rate ' || to_number((session_rec1(3).value - session_rec(3).value))/15 );
			
			commit;
			close sash_cur;
			dbms_lock.sleep(v_sleep);
		end loop;   
	   end collect_stats;
	   
	   
	 PROCEDURE get_one(v_sql_id varchar2, v_dblink varchar2, v_inst_num number) is
		l_hist_samp_id	number;
		l_dbid number;
	   begin
		  select hist_id_seq.currval into l_hist_samp_id from dual;
		  l_dbid:=get_dbid(v_dblink);
          get_sqlid(l_dbid,v_sql_id, v_dblink);
		  get_sqltxt(l_dbid,v_dblink);
          get_sqlstats(l_hist_samp_id, l_dbid,v_dblink, v_inst_num);
          get_sqlplans(l_hist_samp_id, l_dbid,v_dblink);
		  insert into sash_hist_sample values (l_hist_samp_id, l_dbid, sysdate);
		  commit;
       end get_one;	

       PROCEDURE get_all(v_dblink varchar2, v_inst_num number) is
		l_hist_samp_id	number;
		l_dbid number;
	   begin
		  select hist_id_seq.nextval into l_hist_samp_id from dual;
		  l_dbid:=get_dbid(v_dblink);
          get_sqlids(l_dbid,v_dblink);
		  get_sqltxt(l_dbid,v_dblink);
          get_sqlstats(l_hist_samp_id, l_dbid,v_dblink, v_inst_num);
          get_sqlplans(l_hist_samp_id, l_dbid,v_dblink);
          get_objs(l_dbid, v_dblink);
		  insert into sash_hist_sample values (l_hist_samp_id, l_dbid, sysdate);
		  commit;
       end get_all;	   
	   
END sash_pkg;
/


show errors
