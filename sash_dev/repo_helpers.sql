CREATE OR REPLACE procedure create_indexes (table_name varchar2, no_part number, index_name varchar2, col varchar2) as
 create_index varchar2(1000) := 'create index target on source (columns)';
 create_target varchar2(1000);
 np number;
 begin
   FOR I IN 1..NO_PART LOOP
		 create_target := replace ( create_index, 'target' , index_name || i );
		 create_target := replace ( create_target, 'source' , table_name || i );
	   CREATE_TARGET := REPLACE ( CREATE_TARGET, 'columns' , col);
		 execute immediate create_target;
    end loop;
end;
/

CREATE OR REPLACE procedure      drop_partitions (table_name varchar2, no_part number) as
 create_tab varchar2(1000) := 'drop table target_all';
 create_target varchar2(1000);
 np number;
begin
	   FOR I IN 2..NO_PART LOOP
		    create_target := replace ( create_tab, 'target' , table_name || i );
	    execute immediate create_target;
	   end loop;
	   EXECUTE IMMEDIATE 'drop view ' || TABLE_NAME ;
end;
/

create or replace PROCEDURE      CREATE_PARTITIONS (TABLE_NAME VARCHAR2, NO_PART NUMBER) AS
 create_tab varchar2(1000) := 'create table target as select * from source1 where 1=2';
 create_source varchar2(1000);
 create_target varchar2(1000);
 NP NUMBER;
 create_view varchar2(4000) := 'create view target_all as ';
BEGIN
	   create_source := replace ( create_tab, 'source' , table_name );
	   create_view := replace ( create_view, 'target' , table_name );
	   FOR I IN 2..NO_PART LOOP
      create_target := replace ( create_source, 'target' , table_name || i );
	    execute immediate create_target;
      create_view := create_view || ' select * from ' || table_name || i || ' union ' ;
	   end loop;
	   create_view := substr (create_view, 1, length(create_view) - 7);
	   execute immediate create_view;
	   dbms_output.put_line ( create_view );
end;
/
