set serveroutput on
set define off

DECLARE
    l_register_schema_count PLS_INTEGER;
    l_delete_schema_count   PLS_INTEGER;
BEGIN
    --------------------------------------------------------------------
    -- Check whether the legacy XML Schema registration procedures
    -- are exposed to the current Autonomous Database user
    --------------------------------------------------------------------
    SELECT COUNT(*)
      INTO l_register_schema_count
      FROM all_procedures
     WHERE object_name = 'DBMS_XMLSCHEMA'
       AND procedure_name = 'REGISTERSCHEMA';

    SELECT COUNT(*)
      INTO l_delete_schema_count
      FROM all_procedures
     WHERE object_name = 'DBMS_XMLSCHEMA'
       AND procedure_name = 'DELETESCHEMA';

    DBMS_OUTPUT.put_line(
        'DBMS_XMLSCHEMA.REGISTERSCHEMA accessible overloads: ' ||
        l_register_schema_count
    );

    DBMS_OUTPUT.put_line(
        'DBMS_XMLSCHEMA.DELETESCHEMA accessible overloads: ' ||
        l_delete_schema_count
    );

    IF l_register_schema_count = 0 THEN
        DBMS_OUTPUT.put_line(
            'XML Schema registration is not exposed to the current ADB user.'
        );
    END IF;

    IF l_delete_schema_count = 0 THEN
        DBMS_OUTPUT.put_line(
            'XML Schema deletion is not exposed to the current ADB user.'
        );
    END IF;
END;
/