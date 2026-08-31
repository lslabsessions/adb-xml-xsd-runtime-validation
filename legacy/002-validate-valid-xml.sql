set serveroutput on
set define off

DECLARE
    c_schema_url CONSTANT VARCHAR2(700) :=
        'https://lslabsessions.com/schemas/interface.xsd';

    l_xml              XMLTYPE;
    l_schema_based_xml XMLTYPE;
BEGIN
    --------------------------------------------------------------------
    -- Valid, non-schema-based XML document.
    --
    -- The document uses the target namespace, but deliberately does
    -- not contain xsi:schemaLocation. This allows the lab to explicitly
    -- demonstrate the conversion to schema-based XML.
    --------------------------------------------------------------------
    l_xml := XMLTYPE(q'~
<ord:order
    xmlns:ord="https://lslabsessions.com/xml/order/v1">

    <ord:orderId>1001</ord:orderId>
    <ord:customer>LS Lab Sessions</ord:customer>
    <ord:amount currency="EUR">125.50</ord:amount>

</ord:order>
~');

    DBMS_OUTPUT.put_line(
        'Original XML is schema-based: ' ||
        l_xml.isSchemaBased()
    );

    --------------------------------------------------------------------
    -- Associate the document with the registered XML Schema.
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
    -- Validate the document against the registered XML Schema.
    --------------------------------------------------------------------
    l_schema_based_xml.schemaValidate();

    DBMS_OUTPUT.put_line(
        'XML Schema validation completed successfully.'
    );

    DBMS_OUTPUT.put_line(
        'Schema validated after schemaValidate(): ' ||
        l_schema_based_xml.isSchemaValidated()
    );
END;
/