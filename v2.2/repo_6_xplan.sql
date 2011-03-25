CREATE OR REPLACE PACKAGE sash_xplan AS		  
		  function display(v_sql_id varchar2, v_plan_hash varchar2) return sys.DBMS_XPLAN_TYPE_TABLE pipelined;
		  function display(v_sql_id varchar2) return sys.DBMS_XPLAN_TYPE_TABLE pipelined;
		  function display_plan(v_sql_id varchar2) return sys.DBMS_XPLAN_TYPE_TABLE pipelined;
end sash_xplan;
/

		  
CREATE OR REPLACE PACKAGE BODY sash_xplan AS	

	  
		  
function display(v_sql_id varchar2, v_plan_hash varchar2) return sys.DBMS_XPLAN_TYPE_TABLE pipelined is
v_returnline sys.dbms_xplan_type := sys.dbms_xplan_type(null);
v_filter varchar2(4000);
begin
  
    v_returnline.plan_table_output := 'SQL ID ' || v_sql_id;
    pipe row(v_returnline);
    v_returnline.plan_table_output := lpad('-',40,'-');
    pipe row(v_returnline);

    for cur in (select SQL_TEXT from sash_sqltxt where SQL_ID=v_sql_id order by piece) 
	loop
      v_returnline.plan_table_output := cur.sql_text;
      pipe row(v_returnline);	
	end loop;
	
	v_returnline.plan_table_output := lpad(' ',40,' ');
    pipe row(v_returnline);


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

function display(v_sql_id varchar2) return sys.DBMS_XPLAN_TYPE_TABLE pipelined is
v_returnline sys.dbms_xplan_type := sys.dbms_xplan_type(null);
v_filter varchar2(4000);
v_plan_hash number;
begin
    v_returnline.plan_table_output := 'SQL ID ' || v_sql_id;
    pipe row(v_returnline);
    v_returnline.plan_table_output := lpad('-',40,'-');
    pipe row(v_returnline);

    for cur in (select SQL_TEXT from sash_sqltxt where SQL_ID=v_sql_id order by piece) 
	loop
      v_returnline.plan_table_output := cur.sql_text;
      pipe row(v_returnline);	
	end loop;

	v_returnline.plan_table_output := lpad(' ',40,' ');
    pipe row(v_returnline);
	
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
