set serveroutput on
set define off

DECLARE
    c_schema_url CONSTANT VARCHAR2(700) :=
        'https://lslabsessions.com/schemas/interface.xsd';

    l_count PLS_INTEGER;
BEGIN
    --------------------------------------------------------------------
    -- Confirm that the XML Schema is currently registered
    --------------------------------------------------------------------
    SELECT COUNT(*)
      INTO l_count
      FROM user_xml_schemas
     WHERE schema_url = c_schema_url;

    DBMS_OUTPUT.put_line(
        'Registered schemas before deleteSchema(): ' || l_count
    );

    --------------------------------------------------------------------
    -- Remove the registered XML Schema and the SQL types generated
    -- during registration
    --------------------------------------------------------------------
    DBMS_XMLSCHEMA.deleteSchema(
        schemaURL     => c_schema_url,
        delete_option => DBMS_XMLSCHEMA.DELETE_CASCADE
    );

    DBMS_OUTPUT.put_line(
        'XML Schema deleted successfully.'
    );

    --------------------------------------------------------------------
    -- Confirm that the XML Schema is no longer registered
    --------------------------------------------------------------------
    SELECT COUNT(*)
      INTO l_count
      FROM user_xml_schemas
     WHERE schema_url = c_schema_url;

    DBMS_OUTPUT.put_line(
        'Registered schemas after deleteSchema(): ' || l_count
    );
END;
/