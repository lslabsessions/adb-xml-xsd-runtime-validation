set serveroutput on
set define off

DECLARE
    c_schema_url CONSTANT VARCHAR2(700) :=
        'https://lslabsessions.com/schemas/interface.xsd';

    l_xml              XMLTYPE;
    l_schema_based_xml XMLTYPE;
BEGIN
    --------------------------------------------------------------------
    -- Invalid XML document for full schema validation.
    --
    -- amount = 0 is a valid decimal, so schema-based conversion should
    -- succeed, but the XSD requires amount > 0 (minExclusive = 0).
    --------------------------------------------------------------------
    l_xml := XMLTYPE(q'~
<ord:order
    xmlns:ord="https://lslabsessions.com/xml/order/v1">

    <ord:orderId>1001</ord:orderId>
    <ord:customer>LS Lab Sessions</ord:customer>
    <ord:amount currency="EUR">0</ord:amount>

</ord:order>
~');

    DBMS_OUTPUT.put_line(
        'Original XML is schema-based: ' ||
        l_xml.isSchemaBased()
    );

    --------------------------------------------------------------------
    -- Associate the document with the registered XML Schema
    --------------------------------------------------------------------
    l_schema_based_xml :=
        l_xml.createSchemaBasedXML(c_schema_url);

    DBMS_OUTPUT.put_line(
        'After createSchemaBasedXML: ' ||
        l_schema_based_xml.isSchemaBased()
    );

    DBMS_OUTPUT.put_line(
        'Associated schema URL: ' ||
        l_schema_based_xml.getSchemaURL()
    );

    DBMS_OUTPUT.put_line(
        'Schema validated before schemaValidate(): ' ||
        l_schema_based_xml.isSchemaValidated()
    );

    --------------------------------------------------------------------
    -- Full XML Schema validation is expected to fail because amount = 0
    -- violates minExclusive = 0
    --------------------------------------------------------------------
    BEGIN
        l_schema_based_xml.schemaValidate();

        DBMS_OUTPUT.put_line(
            'UNEXPECTED: XML Schema validation succeeded.'
        );

    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -31154 THEN
                DBMS_OUTPUT.put_line(
                    'Expected XML Schema validation failure.'
                );

                DBMS_OUTPUT.put_line(
                    'SQLCODE: ' || SQLCODE
                );

                DBMS_OUTPUT.put_line(
                    'Error stack:'
                );

                DBMS_OUTPUT.put_line(
                    DBMS_UTILITY.format_error_stack
                );
            ELSE
                RAISE;
            END IF;
    END;

    DBMS_OUTPUT.put_line(
        'Schema validated after schemaValidate(): ' ||
        l_schema_based_xml.isSchemaValidated()
    );
END;
/