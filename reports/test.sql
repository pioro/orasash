create or replace PROCEDURE collect1(v_sleep number, loops number, vinstance number) is
          --sash_rec sash@SASHREPO%rowtype;
          sash_rec sash%rowtype;
		  TYPE SashcurTyp IS REF CURSOR;
		  sash_cur   SashcurTyp;

          l_dbid number;
          cpart    number := -1;      /* current partition number */
          part     number := 1;       /* new partition number */
		  g number;
          cur_sashseq   number := 0;
          -- return sash@SASHREPO%rowtype is
          sql_stat varchar2(4000);
          begin
            --l_dbid:=get_dbid;

			sql_stat := 'select a.*, 1 session_id, null machine,  null terminal from sys.sashnow@sashprod' || vinstance || ' a';
            for i in 1..loops loop
              --this looks questionable -looks expensive 
              select  sashseq.nextval into cur_sashseq from dual;
              -- update  sash_targets@SASHREPO set sashseq = cur_ashseq
              -- where dbid = l_dbid;
              dbms_output.put_line('loop # '||to_char(i));
              --change partitions every day of the week  1-7 , SUN = 1
              select to_number(to_char(sysdate,'D')) into part from dual;
              --if part != cpart then
              --   -- don't purge the first time around incase data exists from previous run
              --   if cpart != -1 then
              --      purge(part);
              --   end if;
              --   cpart:=part;
              --end if; 
			  dbms_output.put_line(sql_stat);
              open sash_cur FOR sql_stat; 
			  loop
                fetch sash_cur into sash_rec;
                exit when sash_cur%notfound;
                -- ie if sample_id not great than 1 then its not real data, don't insert
                if sash_rec.sample_id > 1 then
                  --dbms_output.put_line('insert into part '||to_char(part));
                  -- dbms_output.put_line('insert '||
                  --      to_char(sash_rec.DBID)||','||
                  --      to_char( sash_rec.SESSION_ID)||','||
                  --      to_char(sash_rec.SQL_ID)||','||
                  --      to_char(sash_rec.EVENT#) );
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
                      SAMPLE_ID )
                  values 
                       ( sash_rec.DBID,
                         sash_rec.SAMPLE_TIME,
                         cur_sashseq,
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
                         sash_rec.SAMPLE_ID );
                end if;
              end loop;
              close sash_cur;
              commit;
              dbms_lock.sleep(v_sleep);
            end loop;
       end collect1;
/