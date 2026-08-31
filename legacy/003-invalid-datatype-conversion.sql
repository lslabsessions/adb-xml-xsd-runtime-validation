set serveroutput on
set define off

DECLARE
    c_schema_url CONSTANT VARCHAR2(700) :=
        'https://lslabsessions.com/schemas/interface.xsd';

    l_xml              XMLTYPE;
    l_schema_based_xml XMLTYPE;
BEGIN
    l_xml := XMLTYPE(q'~
<ord:order
    xmlns:ord="https://lslabsessions.com/xml/order/v1">

    <ord:orderId>ABC</ord:orderId>
    <ord:customer>LS Lab Sessions</ord:customer>
    <ord:amount currency="EUR">125.50</ord:amount>

</ord:order>
~');

    DBMS_OUTPUT.put_line(
        'Original XML is schema-based: ' ||
        l_xml.isSchemaBased()
    );

    BEGIN
        l_schema_based_xml :=
            l_xml.createSchemaBasedXML(c_schema_url);

        ----------------------------------------------------------------
        -- Force evaluation of the schema-based XMLTYPE
        ----------------------------------------------------------------
        DBMS_OUTPUT.put_line(
            'After createSchemaBasedXML: ' ||
            l_schema_based_xml.isSchemaBased()
        );

        DBMS_OUTPUT.put_line(
            'Associated schema URL: ' ||
            l_schema_based_xml.getSchemaURL()
        );

        DBMS_OUTPUT.put_line(
            'UNEXPECTED: schema-based XML was created successfully.'
        );

    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -31038 THEN
                DBMS_OUTPUT.put_line(
                    'Expected schema-based conversion failure.'
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
END;
/