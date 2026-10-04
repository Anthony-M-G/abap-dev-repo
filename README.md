# abap-dev-repo

Repositorio de aprendizaje y práctica de ABAP cloud y on-premise. El paquete `zadf_odata` contiene un ejemplo RAP de empleados con generación de formularios PDF mediante Adobe Document Services (ADS).

## Objetos del paquete

| Objeto | Función |
| --- | --- |
| `ZR_I_ADF_EMPLOYEE` | Entidad raíz sobre `/dmo/employee_hr`. Expone los datos del empleado y construye `FormURL`. Su behavior managed declara creación, modificación y eliminación. |
| `ZC_I_ADF_EMPLOYEE` | Proyección de consumo con contrato `transactional_query` y capacidad `OUTPUT_FORM_DATA_PROVIDER`. Su behavior expone las operaciones de la raíz. |
| `ZBP_R_I_ADF_EMPLOYEE` | Behavior pool. El archivo `clas.locals_imp.abap` contiene los handlers de autorización, actualmente vacíos. |
| `ZME_I_ADF_EMPLOYEE` | Metadata extension con columnas, filtros, campos de la Object Page y enlace al PDF. |
| `ZSD_ADF_EMPLOYEE` | Service definition que expone la proyección con el alias `EMPLOYEES`. Se utiliza como proveedor de datos del formulario. |
| `ZSB_ADF_EMPLOYEE` | Service binding OData V4 de `ZSD_ADF_EMPLOYEE`, versión `0001` según el XML exportado. |
| `ZCE_ADF_EMPLOYEE` | Custom entity con la clave del empleado, el contenido binario, el nombre del archivo y el tipo MIME. |
| `ZCL_CE_ADF_EMPLOYEE` | Implementación de `IF_RAP_QUERY_PROVIDER`. Obtiene el layout y los datos XML, solicita el PDF a ADS y devuelve el resultado. |
| `ZSD_ADF_EMPLOYEE_FORM` | Service definition que expone la custom entity con el alias `ADF_EMPLOYEE`. |
| `ZSB_ADF_EMPLOYEE_FORM_V4` | Service binding OData V4 del servicio de formularios, versión `0001` según el XML exportado. |

Los archivos `.xml` contienen la serialización de objetos y configuración exportada. Los `.baseinfo` acompañan a las definiciones CDS; los `.sco2.xml` y `.sush.xml` contienen objetos técnicos exportados asociados a los servicios. Estos archivos no sustituyen una comprobación de la configuración en el sistema SAP destino.

## Flujo de generación del PDF

1. La vista raíz obtiene los empleados de `/dmo/employee_hr` y construye `FormURL` con la clave de cada registro. La metadata extension utiliza `Form` como texto del enlace.
2. El enlace apunta a `ADF_EMPLOYEE('<empleado>')/FormContent` en el servicio de formularios. La custom entity delega la consulta en `ZCL_CE_ADF_EMPLOYEE` mediante `@ObjectModel.query.implementedBy`.
3. El método `if_rap_query_provider~select` convierte el filtro a rangos y toma `LOW` del primer rango de `EMPLOYEE`. Si no obtiene una clave, devuelve un resultado vacío.
4. Un `SELECT SINGLE` comprueba que el empleado exista en `ZR_I_ADF_EMPLOYEE`. Esta consulta no implementa una comprobación explícita de permisos.
5. `cl_fp_form_reader` lee el layout XDP del Form Object `ZADF_PRUEBA`.
6. `cl_fp_fdp_services` obtiene las claves del proveedor `ZSD_ADF_EMPLOYEE`, asigna el empleado a `EMPLOYEE` y obtiene los datos XML con `read_to_xml_v2`. El layout debe ser compatible con la estructura de esos datos.
7. `cl_fp_ads_util=>render_pdf` combina el XML y el XDP mediante ADS con el locale `en_US`.
8. Se agrega una fila con el PDF, el tipo MIME `application/pdf` y el nombre `Employee_<empleado>.pdf`. `@Semantics.largeObject` relaciona el contenido con su nombre y tipo MIME, con disposición `ATTACHMENT`.
9. La respuesta entrega los datos y el conteo cuando se solicitan. El conteo es el número de documentos generados: cero o uno.

## Configuración utilizada

| Elemento | Valor en el código | Consideración |
| --- | --- | --- |
| Tabla persistente | `/dmo/employee_hr` | Debe existir y contener el empleado solicitado. |
| Form Object | `ZADF_PRUEBA` | Se referencia en el código, pero no se incluye en este repositorio. |
| Proveedor de datos | `ZSD_ADF_EMPLOYEE` | Su estructura debe corresponder al esquema utilizado por el layout. |
| Clave del FDP | `EMPLOYEE` | Debe estar presente en el resultado de `get_keys( )`. |
| Locale de renderizado | `en_US` | Se conserva el valor existente. |
| Ruta de descarga | `/sap/opu/odata4/sap/zsb_adf_employee_form_v4/srvd_a2x/sap/zsd_adf_employee_form/0001/ADF_EMPLOYEE('<empleado>')/FormContent` | Está escrita directamente en la vista raíz y depende del servicio publicado en destino. |

La disponibilidad de las clases referenciadas, la configuración de ADS y la activación de los objetos deben comprobarse en el entorno SAP utilizado. Los XML de ambos bindings contienen `PUBLISHED=true`; este dato describe la exportación y no confirma que el servicio esté disponible en otro sistema.

## Limitaciones actuales

- Los handlers de autorización por instancia y global están vacíos. El proveedor de PDF también tiene pendiente una comprobación explícita de autorización.
- Las vistas declaran `@AccessControl.authorizationCheck: #NOT_REQUIRED`. No se incluyen archivos DCL en este repositorio.
- El filtro solo utiliza `LOW` del primer rango de `EMPLOYEE`; no valida `SIGN` ni `OPTION`, ni procesa varios empleados o intervalos.
- Se consulta el tamaño de página, pero no se aplica al resultado. Tampoco se implementa el desplazamiento `$skip`.
- La generación del PDF se ejecuta antes de comprobar si se solicitaron datos o solo el conteo.
- Las excepciones capturadas de conversión del filtro, lectura del formulario, FDP, ADS o clave ausente no se registran ni se devuelven al consumidor. Esos casos pueden producir una respuesta vacía, igual que un empleado inexistente.
- `Employee` está declarado como `readonly`; no se declara una estrategia de numeración en el behavior. La creación necesita validación en SAP antes de considerarse operativa.
- No hay un campo ETag configurado en el behavior raíz.

## Verificación en SAP

Esta documentación describe el código del repositorio; no acredita su activación ni su ejecución en SAP. Para comprobar el flujo en el sistema destino:

1. Revisar en ADT la disponibilidad de la tabla, las clases utilizadas, el Form Object y la configuración de ADS.
2. Comprobar la activación de las entidades, behaviors, clases, metadata extension y servicios, y revisar la URL efectiva del binding de formularios.
3. Solicitar el formulario de un empleado existente y comprobar el contenido PDF, el nombre del archivo y el tipo MIME.
4. Revisar los resultados sin clave, con empleado inexistente, con filtros distintos de igualdad y con solicitudes de paginación o conteo.
5. Validar por separado las autorizaciones y las operaciones de creación, modificación y eliminación; su declaración en el behavior no demuestra que el flujo completo funcione.

## Criterio de comentarios

Los comentarios están escritos en español y conservan los términos técnicos y nombres de objetos. En los bloques complejos se explica el propósito, la relación entre los datos y las limitaciones del comportamiento actual. Los pasos del proveedor de PDF mantienen la numeración existente. Los textos de interfaz, los identificadores y la configuración conservan sus valores originales.
