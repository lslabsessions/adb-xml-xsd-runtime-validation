set serveroutput on
set define off

DECLARE
    c_schema_url CONSTANT VARCHAR2(700) :=
        'https://lslabsessions.com/schemas/interface.xsd';

    l_xsd VARCHAR2(32767);

    l_count PLS_INTEGER;
BEGIN
    --------------------------------------------------------------------
    -- XML Schema used by this lab.
    --
    -- The same XSD is also available as:
    --   xsd/interface.xsd
    --------------------------------------------------------------------
    l_xsd := q'~
<xs:schema
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ord="https://lslabsessions.com/xml/order/v1"
    targetNamespace="https://lslabsessions.com/xml/order/v1"
    elementFormDefault="qualified"
    attributeFormDefault="unqualified">

    <xs:simpleType name="OrderIdType">
        <xs:restriction base="xs:positiveInteger"/>
    </xs:simpleType>

    <xs:simpleType name="CustomerType">
        <xs:restriction base="xs:string">
            <xs:minLength value="1"/>
            <xs:maxLength value="100"/>
        </xs:restriction>
    </xs:simpleType>

    <xs:simpleType name="PositiveAmountType">
        <xs:restriction base="xs:decimal">
            <xs:minExclusive value="0"/>
        </xs:restriction>
    </xs:simpleType>

    <xs:simpleType name="CurrencyType">
        <xs:restriction base="xs:string">
            <xs:enumeration value="EUR"/>
            <xs:enumeration value="USD"/>
            <xs:enumeration value="GBP"/>
        </xs:restriction>
    </xs:simpleType>

    <xs:complexType name="AmountType">
        <xs:simpleContent>
            <xs:extension base="ord:PositiveAmountType">
                <xs:attribute
                    name="currency"
                    type="ord:CurrencyType"
                    use="required"/>
            </xs:extension>
        </xs:simpleContent>
    </xs:complexType>

    <xs:complexType name="OrderType">
        <xs:sequence>
            <xs:element
                name="orderId"
                type="ord:OrderIdType"/>

            <xs:element
                name="customer"
                type="ord:CustomerType"/>

            <xs:element
                name="amount"
                type="ord:AmountType"/>
        </xs:sequence>
    </xs:complexType>

    <xs:element
        name="order"
        type="ord:OrderType"/>

</xs:schema>
~';

    --------------------------------------------------------------------
    -- Prevent accidental re-registration when the lab is rerun.
    --------------------------------------------------------------------
    SELECT COUNT(*)
      INTO l_count
      FROM user_xml_schemas
     WHERE schema_url = c_schema_url;

    IF l_count > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'XML Schema is already registered: ' || c_schema_url
        );
    END IF;

    --------------------------------------------------------------------
    -- Legacy XML Schema registration.
    --------------------------------------------------------------------
    DBMS_XMLSCHEMA.registerSchema(
        schemaURL       => c_schema_url,
        schemaDoc       => l_xsd,
        local           => TRUE,
        genTypes        => TRUE,
        genTables       => FALSE,
        force           => FALSE,
        enableHierarchy => DBMS_XMLSCHEMA.ENABLE_HIERARCHY_NONE
    );

    DBMS_OUTPUT.put_line(
        'XML Schema registered successfully: ' || c_schema_url
    );
END;
/

------------------------------------------------------------------------
-- Verify registration.
------------------------------------------------------------------------

SELECT schema_url,
       local,
       hier_type,
       binary,
       hidden
FROM   user_xml_schemas
WHERE  schema_url =
       'https://lslabsessions.com/schemas/interface.xsd';
