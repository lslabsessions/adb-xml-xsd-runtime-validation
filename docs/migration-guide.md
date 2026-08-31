# Migration Guide: Registered XSD Validation to Runtime Validation

This guide maps the legacy Oracle XML DB pattern used in the lab to the runtime-validation pattern used in Oracle Autonomous AI Database.

## Migration objective

The legacy application pattern assumes that the XSD is registered and that XML can be associated with that registered schema:

```text
register XSD
   -> create schema-based XMLType
      -> validate schema-based instance
```

The Autonomous AI Database pattern instead treats the XSD as runtime input:

```text
XML document + XSD
   -> validate directly
```

The XML contract itself can remain unchanged.

## 1. Identify legacy registration code

Look for code such as:

```sql
DBMS_XMLSCHEMA.registerSchema(
    schemaURL => ...,
    schemaDoc => ...
);
```

Also look for dependencies on:

```sql
USER_XML_SCHEMAS
DBMS_XMLSCHEMA.deleteSchema
XMLTYPE.createSchemaBasedXML
XMLTYPE.schemaValidate
XMLTYPE.isSchemaBased
XMLTYPE.isSchemaValidated
```

These calls indicate that the application is using Oracle XML DB's registered-schema model rather than only performing standalone XML parsing.

## 2. Separate the XML contract from its registration lifecycle

In the legacy design, a schema URL is used to identify a registered XSD:

```sql
c_schema_url :=
    'https://lslabsessions.com/schemas/interface.xsd';
```

The XML vocabulary itself is identified by its namespace:

```text
https://lslabsessions.com/xml/order/v1
```

When migrating, preserve the XML namespace and XSD rules unless the business contract itself needs to change. Remove only the dependency on the registration lifecycle.

## 3. Replace registration with XSD retrieval

Legacy:

```sql
DBMS_XMLSCHEMA.registerSchema(...);
```

Runtime pattern:

```sql
l_xsd       CLOB;
l_xmlschema XMLTYPE;

-- Load l_xsd from the application's chosen source.
l_xmlschema := XMLTYPE(l_xsd);
```

The lab embeds the XSD in the SQL script so that the example is self-contained. In an application, the CLOB could come from an application-controlled source appropriate to the integration design.

The migration requirement is simply that the XSD is available as an `XMLType` when validation is performed.

## 4. Remove `createSchemaBasedXML()` from the validation path

Legacy:

```sql
l_schema_based_xml :=
    l_xml.createSchemaBasedXML(c_schema_url);
```

Runtime validation does not require that conversion.

Use the ordinary XML instance directly:

```sql
l_xml := XMLTYPE(...);
```

and pass it together with the XSD to `DBMS_XMLSCHEMA_UTIL`.

## 5. Replace `schemaValidate()` with `VALIDATE` or `CONFORMING`

### Option A — `VALIDATE`

Legacy:

```sql
l_schema_based_xml.schemaValidate();
```

Autonomous runtime pattern:

```sql
DBMS_XMLSCHEMA_UTIL.VALIDATE(
    doc => l_xml,
    sch => l_xmlschema
);
```

Choose this when the existing application already treats invalid XML as an exception or when detailed Oracle/LSX diagnostics are valuable.

In this lab, the invalid `amount = 0` case raised:

```text
ORA-31154
```

and exposed a detailed LSX stack.

### Option B — `CONFORMING`

```sql
l_result := DBMS_XMLSCHEMA_UTIL.CONFORMING(
    doc => l_xml,
    sch => l_xmlschema
);

IF l_result <> 0 THEN
    -- Handle non-conformance.
END IF;
```

Choose this when the application prefers ordinary return-code logic for expected validation failures.

In the tested environment:

```text
valid XML   -> 0
invalid XML -> 213 (displayed as LSX-00213)
```

Do not hard-code `213` as the general definition of an invalid document. The general condition is `result <> 0`.

## 6. Rework exception handling deliberately

A migration should not replace every legacy exception handler with `WHEN OTHERS` and assume any exception means "invalid XML".

The lab's negative tests distinguish expected validation errors from unrelated failures:

```sql
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -31154 THEN
            -- Expected validation failure.
            ...
        ELSE
            RAISE;
        END IF;
```

The legacy datatype test similarly expects `ORA-31038` for the deliberately invalid `orderId = ABC` input.

This makes the scripts useful as reproducible assertions rather than demonstrations that silently accept unrelated failures.

## 7. Remove registered-schema cleanup

Legacy lifecycle:

```sql
DBMS_XMLSCHEMA.deleteSchema(...);
```

Runtime validation has no equivalent cleanup step because the XSD supplied to `DBMS_XMLSCHEMA_UTIL` is not being registered by the validation call.

This also means application code should no longer depend on the registered-schema lifecycle as part of validation initialization or shutdown.

## 8. Reconsider metadata checks

Legacy code may inspect:

```sql
USER_XML_SCHEMAS
```

That metadata check makes sense only in a registered-schema design.

In the Autonomous AI Database portion of this lab, the final script instead checks whether the legacy `DBMS_XMLSCHEMA.REGISTERSCHEMA` and `DELETESCHEMA` procedures are exposed to the current user through `ALL_PROCEDURES`.

The tested result was zero for both. Treat that as environment evidence. The general migration decision should rely on Oracle's documented support matrix, which states that XML Schema Registration is not supported in Autonomous AI Database.

## 9. Preserve negative tests during migration

A migration is stronger when it proves that invalid XML continues to be rejected for the intended reasons.

This lab preserves two different negative cases:

| Negative test | Purpose |
|---|---|
| `order-invalid-order-id.xml` | Proves rejection of a value that cannot represent the required XSD datatype |
| `order-invalid-amount-zero.xml` | Proves rejection of a value with a valid datatype that violates an XSD facet |

The second case is used on both sides of the migration so that legacy `schemaValidate()` can be compared directly with ADB `VALIDATE` and `CONFORMING`.

## 10. Before/after code pattern

### Before: registered schema

```sql
DECLARE
    c_schema_url CONSTANT VARCHAR2(700) :=
        'https://lslabsessions.com/schemas/interface.xsd';

    l_xml              XMLTYPE;
    l_schema_based_xml XMLTYPE;
BEGIN
    ...

    l_schema_based_xml :=
        l_xml.createSchemaBasedXML(c_schema_url);

    l_schema_based_xml.schemaValidate();
END;
/
```

This assumes that `c_schema_url` has previously been registered through `DBMS_XMLSCHEMA.registerSchema`.

### After: runtime validation with exception semantics

```sql
DECLARE
    l_xml       XMLTYPE;
    l_xsd       CLOB;
    l_xmlschema XMLTYPE;
BEGIN
    ...

    l_xmlschema := XMLTYPE(l_xsd);

    DBMS_XMLSCHEMA_UTIL.VALIDATE(
        doc => l_xml,
        sch => l_xmlschema
    );
END;
/
```

### After: runtime validation with return-code semantics

```sql
DECLARE
    l_xml       XMLTYPE;
    l_xsd       CLOB;
    l_xmlschema XMLTYPE;
    l_result    NUMBER;
BEGIN
    ...

    l_xmlschema := XMLTYPE(l_xsd);

    l_result := DBMS_XMLSCHEMA_UTIL.CONFORMING(
        doc => l_xml,
        sch => l_xmlschema
    );

    IF l_result <> 0 THEN
        RAISE_APPLICATION_ERROR(
            -20020,
            'XML does not conform to the XSD. LSX-' ||
            LPAD(TO_CHAR(l_result), 5, '0')
        );
    END IF;
END;
/
```

## Migration checklist

- [ ] Identify all `DBMS_XMLSCHEMA.registerSchema` calls.
- [ ] Identify all `createSchemaBasedXML()` and `schemaValidate()` calls.
- [ ] Identify metadata or cleanup logic tied to registered schemas.
- [ ] Preserve the XML namespace and XSD contract unless the interface itself changes.
- [ ] Make the XSD available to the application as `XMLType` at validation time.
- [ ] Choose `VALIDATE` or `CONFORMING` based on the desired error-handling model.
- [ ] Preserve negative tests for datatype and XSD constraint failures.
- [ ] Re-raise unexpected Oracle errors instead of treating every exception as invalid XML.
- [ ] Remove registration and deletion lifecycle code from the ADB path.
- [ ] Verify behavior in the target ADB environment with representative production XSDs and XML documents.
