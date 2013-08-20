-- (c) Marcin Przepiorowski 2010
-- v2.3 Initial version
-- v2.4 Changes: fix for RAC duplicated plan

CREATE OR REPLACE FORCE VIEW SASH_PLAN_TABLE (STATEMENT_ID, PLAN_ID, TIMESTAMP, REMARKS, OPERATION, OPTIONS, OBJECT_NODE,
OBJECT_OWNER, OBJECT_NAME, OBJECT_ALIAS, OBJECT_INSTANCE, OBJECT_TYPE, OPTIMIZER,
 SEARCH_COLUMNS, ID, PARENT_ID, DEPTH, POSITION, COST, CARDINALITY, BYTES, OTHER_TAG, PARTITION_START, PARTITION_STOP,
 PARTITION_ID, OTHER, OTHER_XML, DISTRIBUTION, CPU_COST, IO_COST, TEMP_SPACE,
 ACCESS_PREDICATES, FILTER_PREDICATES, PROJECTION, TIME, QBLOCK_NAME) AS
  select distinct
 SQL_ID             ,
 PLAN_HASH_VALUE    ,
 sysdate,
 null ,
 OPERATION,
 OPTIONS   ,
 OBJECT_NODE,
 OBJECT_OWNER,
 OBJECT_NAME  ,
 'ALIAS',
 OBJECT_INSTANCE    ,
 OBJECT_TYPE        ,
 OPTIMIZER          ,
 SEARCH_COLUMNS     ,
 ID                 ,
 PARENT_ID          ,
 depth,
 POSITION           ,
 COST               ,
 CARDINALITY        ,
 BYTES              ,
 OTHER_TAG          ,
 PARTITION_START    ,
 PARTITION_STOP     ,
 PARTITION_ID       ,
 OTHER              ,
 null           ,
 DISTRIBUTION       ,
 CPU_COST           ,
 IO_COST            ,
 TEMP_SPACE         ,
 ACCESS_PREDICATES  ,
 FILTER_PREDICATES  ,
 null,
1,
 null
 from sash_sqlplans where inst_id = (select inst_num from sash_target);

CREATE OR REPLACE PACKAGE sash_xplan AS		  
		  function display(v_sql_id varchar2, v_plan_hash varchar2, v_format in varchar2 default 'TYPICAL') return sys.DBMS_XPLAN_TYPE_TABLE pipelined;
		  function display(v_sql_id varchar2) return sys.DBMS_XPLAN_TYPE_TABLE pipelined;
		  function display_plan(v_sql_id varchar2) return sys.DBMS_XPLAN_TYPE_TABLE pipelined;
end sash_xplan;
/

		  
CREATE OR REPLACE PACKAGE BODY sash_xplan AS	

	  
		  
function display(v_sql_id varchar2, v_plan_hash varchar2, v_format in varchar2 default 'TYPICAL') return sys.DBMS_XPLAN_TYPE_TABLE pipelined is
v_returnline sys.dbms_xplan_type := sys.dbms_xplan_type(null);
v_filter varchar2(4000);
begin
  
    v_returnline.plan_table_output := 'SQL ID ' || v_sql_id;
    pipe row(v_returnline);
    v_returnline.plan_table_output := lpad('-',40,'-');
    pipe row(v_returnline);

    for cur in (select SQL_TEXT from sash_sqltxt where SQL_ID=v_sql_id) 
	loop
      v_returnline.plan_table_output := substr(cur.sql_text,1,300);
      pipe row(v_returnline);	
	end loop;
	
	v_returnline.plan_table_output := lpad(' ',40,' ');
    pipe row(v_returnline);


    v_filter:='plan_id=' || v_plan_hash;
    v_returnline.plan_table_output := 'Plan hash value is :' || v_plan_hash;
    pipe row(v_returnline);

  FOR cur IN (SELECT * from table(dbms_xplan.display('sash_plan_table',v_sql_id,format=>v_format,filter_preds=>v_filter)))
  LOOP
      v_returnline.plan_table_output := cur.plan_table_output;
      pipe row(v_returnline);
  end loop;
	return ;
end;

function display(v_sql_id varchar2) return sys.DBMS_XPLAN_TYPE_TABLE pipelined is
v_returnline sys.dbms_xplan_type := sys.dbms_xplan_type(null);
v_filter varchar2(4000);
v_plan_hash number;
begin
    v_returnline.plan_table_output := 'SQL ID ' || v_sql_id;
    pipe row(v_returnline);
    v_returnline.plan_table_output := lpad('-',40,'-');
    pipe row(v_returnline);

    for cur in (select SQL_TEXT from sash_sqltxt where SQL_ID=v_sql_id and rownum < 2) 
	loop
      v_returnline.plan_table_output := substr(cur.sql_text,1,300);
      pipe row(v_returnline);	
	end loop;

	
    for plan_cur in (select distinct plan_id from sash_plan_table where statement_id = v_sql_id) loop
	v_returnline.plan_table_output := lpad(' ',40,' ');
    pipe row(v_returnline);
	v_plan_hash := plan_cur.plan_id;
    v_filter:='plan_id=' || v_plan_hash;

    v_returnline.plan_table_output := 'Plan hash value is :' || v_plan_hash;
    pipe row(v_returnline);

    FOR cur IN (SELECT * from table(dbms_xplan.display('sash_plan_table',v_sql_id,filter_preds=>v_filter)))
    LOOP
      v_returnline.plan_table_output := cur.plan_table_output;
      pipe row(v_returnline);
    end loop;
    end loop;
    return ;
end;

function display_plan(v_sql_id varchar2) return sys.DBMS_XPLAN_TYPE_TABLE pipelined is
v_returnline sys.dbms_xplan_type := sys.dbms_xplan_type(null);
v_filter varchar2(4000);
v_plan_hash number;
begin	
    select min(plan_id) into v_plan_hash from sash_plan_table where statement_id = v_sql_id;
    v_filter:='plan_id=' || v_plan_hash;

    v_returnline.plan_table_output := 'Plan hash value is :' || v_plan_hash;
    pipe row(v_returnline);

    FOR cur IN (SELECT * from table(dbms_xplan.display('sash_plan_table',v_sql_id,filter_preds=>v_filter)))
    LOOP
      v_returnline.plan_table_output := cur.plan_table_output;
      pipe row(v_returnline);
    end loop;
	return ;
end;


end sash_xplan;
/
