
-- (c) Kyle Hailey 2007

   
CREATE OR REPLACE PACKAGE sash_repo AS
          PROCEDURE purge(type varchar2)  ;
          END sash_repo;
/
show errors


CREATE OR REPLACE PACKAGE BODY sash_repo AS
  procedure purge(type varchar2) is
          l_text        varchar2(4000);
          l_day         number;
       begin
        --change partitions every day of the week  1-7 , SUN = 1
        if type = 'd' then 
          select to_number(to_char(sysdate,'D')) into l_day from dual;
        elsif type = 'h' then
          select mod(to_number(to_char(sysdate,'HH')),7)+1 into l_day from dual;
        else 
          -- 'm' then
          select mod(to_number(to_char(sysdate,'MI')),7)+1 into l_day from dual;
        end if;
        --l_day:=partn;
        l_text:='truncate table sash'||to_char(l_day);
        execute immediate l_text;
        l_text:='create or replace view sash as select * from sash'||to_char(l_day);
        execute immediate l_text;
       exception
          when others then
             insert into sash_log (action, message,result) values 
                  ('PURGE PARTITION', l_text,'E');
             commit;
             RAISE_APPLICATION_ERROR(-20010,'SASH purge errored ');
  end purge;
end sash_repo;

/
show err 

