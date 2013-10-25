create or replace TRIGGER INS_DYNAMIC
AFTER INSERT ON SASH_TARGET_DYNAMIC
declare
tabrows number;
BEGIN
  select count(*) into tabrows from SASH_TARGET_DYNAMIC;
  if (tabrows > 1) then
     raise_application_error('-20500','you can''t put two rows into sash_target_dynamic table');
  end if;
END;
/

create or replace TRIGGER INS_DYNAMIC_ROWS
BEFORE INSERT OR UPDATE ON SASH_TARGET_DYNAMIC
REFERENCING NEW AS NEW
FOR EACH ROW
BEGIN
  :NEW.TABLE_ORDER := 1;
END;
/

create or replace TRIGGER INS_STATIC
AFTER INSERT ON SASH_TARGET_STATIC
declare
tabrows number;
BEGIN
  select count(*) into tabrows from SASH_TARGET_STATIC;
  if (tabrows > 1) then
     raise_application_error('-20500','you can''t put two rows into sash_target_static table');
  end if;
END;
/

create or replace TRIGGER INS_STATIC_ROWS
BEFORE INSERT OR UPDATE ON SASH_TARGET_STATIC
REFERENCING NEW AS NEW
FOR EACH ROW
BEGIN
  :NEW.TABLE_ORDER := 2;
END;
/
