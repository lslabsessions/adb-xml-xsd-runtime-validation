set serveroutput on
set define off

DECLARE
    l_xml       XMLTYPE;
    l_xsd       CLOB;
    l_xmlschema XMLTYPE;
    l_result    NUMBER;
BEGIN
    --------------------------------------------------------------------
    -- Same valid XML document used in the previous tests
    --------------------------------------------------------------------
    l_xml := XMLTYPE(q'~
<ord:order
    xmlns:ord="https://lslabsessions.com/xml/order/v1">

    <ord:orderId>1001</ord:orderId>
    <ord:customer>LS Lab Sessions</ord:customer>
    <ord:amount currency="EUR">125.50</ord:amount>

</ord:order>
~');

    --------------------------------------------------------------------
    -- Same XSD used throughout the lab
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
            <xs:element name="orderId" type="ord:OrderIdType"/>
            <xs:element name="customer" type="ord:CustomerType"/>
            <xs:element name="amount" type="ord:AmountType"/>
        </xs:sequence>
    </xs:complexType>

    <xs:element name="order" type="ord:OrderType"/>

</xs:schema>
~';

    l_xmlschema := XMLTYPE(l_xsd);

    DBMS_OUTPUT.put_line(
        'XML is schema-based before validation: ' ||
        l_xml.isSchemaBased()
    );

    --------------------------------------------------------------------
    -- Runtime validation using CONFORMING
    --------------------------------------------------------------------
    l_result := DBMS_XMLSCHEMA_UTIL.CONFORMING(
        doc => l_xml,
        sch => l_xmlschema
    );

    DBMS_OUTPUT.put_line(
        'CONFORMING result: ' || l_result
    );

    IF l_result = 0 THEN
        DBMS_OUTPUT.put_line(
            'XML conforms to the XSD.'
        );
    ELSE
        RAISE_APPLICATION_ERROR(
            -20001,
            'Unexpected CONFORMING result. LSX-' ||
            LPAD(TO_CHAR(l_result), 5, '0')
        );
    END IF;

    DBMS_OUTPUT.put_line(
        'XML is schema-based after validation: ' ||
        l_xml.isSchemaBased()
    );
END;
/