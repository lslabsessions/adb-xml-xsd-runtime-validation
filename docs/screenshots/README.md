# Screenshots

These screenshots show the observed results from the lab executions.

| Screenshot | Environment | Related script | What it demonstrates |
|---|---|---|---|
| `001-register-schema-success.jpg` | Oracle Database 19c (non-ADB) | `legacy/001-register-schema.sql` | `DBMS_XMLSCHEMA.registerSchema` succeeds and the schema appears in `USER_XML_SCHEMAS`. |
| `002-schema-based-valid-xml.jpg` | Oracle Database 19c (non-ADB) | `legacy/002-validate-valid-xml.sql` | `isSchemaBased()` changes from `0` to `1`; `isSchemaValidated()` changes from `0` to `1` only after `schemaValidate()`. |
| `003-invalid-datatype-conversion.jpg` | Oracle Database 19c (non-ADB) | `legacy/003-invalid-datatype-conversion.sql` | `orderId = ABC` conflicts with `xs:positiveInteger`; the tested environment raises `ORA-31038`. |
| `004-schema-validate-invalid-amount-zero.jpg` | Oracle Database 19c (non-ADB) | `legacy/004-schema-validate-invalid-facet.sql` | `amount = 0` is a valid decimal but violates `minExclusive=0`; schema-based conversion succeeds and full validation raises `ORA-31154` with LSX details. |
| `005-delete-schema-success.jpg` | Oracle Database 19c (non-ADB) | `legacy/005-delete-schema.sql` | The registered schema count goes from `1` to `0` after `DBMS_XMLSCHEMA.deleteSchema`. |
| `006-runtime-validate-valid.jpg` | Autonomous AI Database | `adb/001-runtime-validate-valid.sql` | `DBMS_XMLSCHEMA_UTIL.VALIDATE` accepts the valid XML and the XML remains non-schema-based. |
| `007-runtime-validate-invalid.jpg` | Autonomous AI Database | `adb/002-runtime-validate-invalid.sql` | `VALIDATE` rejects the invalid facet case with `ORA-31154` and detailed LSX diagnostics. |
| `008-conforming-valid.jpg` | Autonomous AI Database | `adb/003-conforming-valid.sql` | `CONFORMING` returns `0` for the valid XML. |
| `009-conforming-invalid.jpg` | Autonomous AI Database | `adb/004-conforming-invalid.sql` | `CONFORMING` returns a non-zero LSX code; the tested result is `213`, displayed as `LSX-00213`. |
| `010-no-schema-registration.jpg` | Autonomous AI Database | `adb/005-no-schema-registration.sql` | `REGISTERSCHEMA` and `DELETESCHEMA` expose zero accessible overloads to the current ADB user in the tested environment. |

The screenshots document observed results from the tested environments. Results may vary across database versions or patch levels.
