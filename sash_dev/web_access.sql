BEGIN
  DBMS_EPG.create_dad (
    dad_name => 'sash',
    path     => '/sash/*');
END;
/


SET SERVEROUTPUT ON SIZE UNLIMITED
DECLARE
  l_paths  DBMS_EPG.varchar2_table;
BEGIN
  DBMS_EPG.get_all_dad_mappings (
    dad_name => 'sash',
    paths    => l_paths);

  DBMS_OUTPUT.put_line('Mappings');
  DBMS_OUTPUT.put_line('========');
  FOR i IN 1 .. l_paths.count LOOP
    DBMS_OUTPUT.put_line(l_paths(i));
  END LOOP;
END;
/


BEGIN
  DBMS_EPG.set_dad_attribute (
    dad_name   => 'sash',
    attr_name  => 'default-page',
    attr_value => 'home');

  DBMS_EPG.set_dad_attribute (
    dad_name   => 'sash',
    attr_name  => 'database-username',
    attr_value => 'SASH24RC2');
END;
/


SET SERVEROUTPUT ON SIZE UNLIMITED
DECLARE
  l_attr_names   DBMS_EPG.varchar2_table;
  l_attr_values  DBMS_EPG.varchar2_table;
BEGIN
  DBMS_OUTPUT.put_line('Attributes');
  DBMS_OUTPUT.put_line('==========');

  DBMS_EPG.get_all_dad_attributes (
    dad_name    => 'sash',
    attr_names  => l_attr_names,                       
    attr_values => l_attr_values);

  FOR i IN 1 .. l_attr_names.count LOOP
    DBMS_OUTPUT.put_line(l_attr_names(i) || '=' || l_attr_values(i));
  END LOOP;
END;
/


BEGIN
  DBMS_EPG.authorize_dad (
    dad_name => 'sash',
    user     => 'SASH24RC2');
END;
/


SET SERVEROUTPUT ON
DECLARE
  l_configxml XMLTYPE;
  l_value     VARCHAR2(5) := 'true'; -- (true/false)
BEGIN
  l_configxml := DBMS_XDB.cfg_get();

  IF l_configxml.existsNode('/xdbconfig/sysconfig/protocolconfig/httpconfig/allow-repository-anonymous-access') = 0 THEN
    -- Add missing element.
    SELECT insertChildXML
           (
             l_configxml,
       	     '/xdbconfig/sysconfig/protocolconfig/httpconfig',
       	     'allow-repository-anonymous-access',
       	     XMLType('<allow-repository-anonymous-access xmlns="http://xmlns.oracle.com/xdb/xdbconfig.xsd">' ||
       	              l_value ||
       	             '</allow-repository-anonymous-access>'),
       	     'xmlns="http://xmlns.oracle.com/xdb/xdbconfig.xsd"'
       	   )
    INTO   l_configxml
    FROM   dual;

    DBMS_OUTPUT.put_line('Element inserted.');
  ELSE
    -- Update existing element.
    SELECT updateXML
           (
             DBMS_XDB.cfg_get(),
             '/xdbconfig/sysconfig/protocolconfig/httpconfig/allow-repository-anonymous-access/text()',
             l_value,
             'xmlns="http://xmlns.oracle.com/xdb/xdbconfig.xsd"'
           )
    INTO   l_configxml
    FROM   dual;

    DBMS_OUTPUT.put_line('Element updated.');
  END IF;

  DBMS_XDB.cfg_update(l_configxml);
  DBMS_XDB.cfg_refresh;
END;
/


ALTER USER anonymous ACCOUNT UNLOCK;
