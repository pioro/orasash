-- (c) Kyle Hailey 2007

select host from sash_targets;
column f_host new_value v_host
column f_dbid new_value v_dbid;
select '&host' f_host  from dual;

select dbid f_dbid from sash_targets where host='&v_host';

delete from sash_target;
insert into sash_target values (&v_dbid);
commit;
