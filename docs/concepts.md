# Concepts

This document explains the concepts behind the lab without repeating the step-by-step execution in the main README.

## 1. XML namespace vs registered schema URL

The lab uses two URI-shaped identifiers:

```text
XML namespace
https://lslabsessions.com/xml/order/v1
```

```text
Legacy registered schema URL
https://lslabsessions.com/schemas/interface.xsd
```

They are not interchangeable.

### XML namespace

The namespace identifies the XML vocabulary. In the XSD it appears as both the target namespace and the namespace bound to the `ord` prefix:

```xml
<xs:schema
    xmlns:ord="https://lslabsessions.com/xml/order/v1"
    targetNamespace="https://lslabsessions.com/xml/order/v1"
    ...>
```

The XML instance uses the same namespace:

```xml
<ord:order xmlns:ord="https://lslabsessions.com/xml/order/v1">
```

The prefix itself (`ord`) is only a local alias. Another prefix could refer to the same namespace URI without changing the semantic identity of the elements.

### Registered schema URL

In the legacy portion of the lab:

```text
https://lslabsessions.com/schemas/interface.xsd
```

is supplied as `schemaURL` to `DBMS_XMLSCHEMA.registerSchema` and later passed to `createSchemaBasedXML()`.

It identifies the registered Oracle XML DB schema. It does not have to be the same URI as the XML namespace.

## 2. Schema-based is not the same as schema-validated

The legacy valid-document test deliberately exposes three states.

### Initial `XMLType`

```text
isSchemaBased() = 0
```

The document contains the correct XML namespace but is not yet associated with the registered XML Schema.

### After `createSchemaBasedXML()`

```text
isSchemaBased() = 1
isSchemaValidated() = 0
```

The instance is schema-based, but full validation has not yet completed.

### After `schemaValidate()`

```text
isSchemaValidated() = 1
```

`schemaValidate()` performs full schema validation. If validation fails, Oracle raises an error and the document does not become validated.

This distinction is central to understanding the legacy design:

```text
schema association != successful full validation
```

## 3. Invalid datatype vs invalid facet

The lab intentionally uses two negative XML documents because they fail for different reasons.

### Invalid datatype

XML:

```xml
<ord:orderId>ABC</ord:orderId>
```

XSD:

```xml
<xs:restriction base="xs:positiveInteger"/>
```

`ABC` cannot represent the datatype required by the schema. In the tested Oracle Database 19c environment, evaluating the schema-based `XMLType` raised:

```text
ORA-31038: Invalid number value: "ABC"
```

This can surface before the explicit `schemaValidate()` call.

### Valid datatype, invalid facet

XML:

```xml
<ord:amount currency="EUR">0</ord:amount>
```

XSD:

```xml
<xs:restriction base="xs:decimal">
    <xs:minExclusive value="0"/>
</xs:restriction>
```

`0` is syntactically and lexically a valid decimal. The datatype can therefore be represented. However, it violates a restriction layered on top of that datatype: the value must be greater than zero.

In the legacy test:

```text
createSchemaBasedXML() -> succeeds
schemaValidate()       -> ORA-31154
```

This makes the distinction useful when diagnosing XML validation problems:

```text
Can the value be represented as the required datatype?
                    vs
Does the represented value satisfy all XSD constraints?
```

## 4. Runtime validation in Autonomous AI Database

Autonomous AI Database does not use the registered-schema flow demonstrated in the legacy portion of the lab.

Instead, the XSD is supplied directly as an `XMLType`:

```sql
l_xmlschema := XMLTYPE(l_xsd);
```

and passed with the document to either:

```sql
DBMS_XMLSCHEMA_UTIL.VALIDATE(...)
```

or:

```sql
DBMS_XMLSCHEMA_UTIL.CONFORMING(...)
```

The tested XML remained non-schema-based before and after runtime validation:

```text
isSchemaBased() = 0
```

Runtime validation answers the question "does this XML conform to this XSD?" without converting the XML into the legacy schema-based storage model.

## 5. `VALIDATE` vs `CONFORMING`

Both subprograms validate an XML instance against an XSD supplied at runtime.

### `VALIDATE`

`VALIDATE` is a procedure:

```sql
DBMS_XMLSCHEMA_UTIL.VALIDATE(
    doc => l_xml,
    sch => l_xmlschema
);
```

In the lab:

- valid XML completed normally;
- invalid XML raised `ORA-31154`;
- the error stack exposed detailed LSX diagnostics.

This style fits code where validation failure is naturally treated as an exception and the detailed Oracle error stack is useful.

### `CONFORMING`

`CONFORMING` is a function:

```sql
l_result := DBMS_XMLSCHEMA_UTIL.CONFORMING(
    doc => l_xml,
    sch => l_xmlschema
);
```

Its API uses a return value:

```text
0       -> conforms
nonzero -> LSX validation code
```

For the invalid `amount = 0` document, the tested environment returned:

```text
213
```

which the script displays as:

```text
LSX-00213
```

This is recorded as an observed lab result. The script does not hard-code `213` as the only acceptable failure code; the semantic assertion is that the invalid document must return a non-zero result.

## 6. Why `VALIDATE` can be better for diagnostics

For the same invalid facet test, the `VALIDATE` error stack contained more diagnostic information than the single numeric result returned by `CONFORMING`.

That does not make one API universally better than the other. It gives them different practical ergonomics:

- choose `VALIDATE` when exception-based control flow and a fuller error stack are useful;
- choose `CONFORMING` when a numeric pass/fail result is easier to integrate into ordinary application logic.

## 7. Runtime validation does not imply registration

The XSD passed to `DBMS_XMLSCHEMA_UTIL` is validation input. The lab does not call `DBMS_XMLSCHEMA.registerSchema` in the Autonomous AI Database scripts.

Oracle's Autonomous AI Database documentation separately states that XML Schema Registration is not supported and identifies runtime validation through `DBMS_XMLSCHEMA_UTIL` as the supported alternative.

The final ADB script also checks API visibility through `ALL_PROCEDURES`. In the tested environment, the current user exposed zero `REGISTERSCHEMA` and `DELETESCHEMA` overloads. That result is environment evidence, not a replacement for the documented product limitation.

## 8. Why the embedded XSD has no XML declaration

The standalone `xsd/interface.xsd` begins normally with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
```

The PL/SQL literals omit that declaration.

During development, placing a newline before the XML declaration inside a quoted PL/SQL literal caused Oracle's XML parser to treat the `xml` text as a processing instruction and reject it. Omitting the declaration in the embedded version avoids that whitespace-sensitive issue while keeping the schema document valid.

The standalone file remains the human-readable source copy of the XSD contract.
