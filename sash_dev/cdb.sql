
WHENEVER SQLERROR EXIT
prompt "jestem w cdb"                                                                                                                                                                                   
undef ENTER_SASH_PDB                                                                                                                                                                                    

col sash_pdb noprint new_value SASH_PDB                                                                                                                                                                 

accept ENTER_SASH_PDB prompt "Enter PDB container to connect "                                                                                                                                          

declare
 r varchar2(100);
begin
 select name into r from v$pdbs where open_mode='READ WRITE' and upper(name) = upper('&&ENTER_SASH_PDB');
end;
/

prompt Changing container to &&ENTER_SASH_PDB
alter session set container = &&ENTER_SASH_PDB;
