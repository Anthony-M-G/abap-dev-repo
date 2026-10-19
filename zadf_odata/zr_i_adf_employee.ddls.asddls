// Entidad raíz que obtiene los datos de empleados y construye el enlace al formulario.
// NOT_REQUIRED no exige un DCL; no equivale a implementar una autorización.
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface for adobe form'
@Metadata.ignorePropagatedAnnotations: false
define root view entity ZR_I_ADF_EMPLOYEE as select from /dmo/employee_hr
{
    key employee as Employee,
    first_name as FirstName,
    last_name as LastName,
    // Asociar el importe del salario con el campo que contiene su moneda.
    @Semantics.amount.currencyCode: 'SalaryCurrency'
    salary as Salary,
    salary_currency as SalaryCurrency,
    manager as Manager,
    // Construir la ruta relativa al contenido binario de la custom entity.
    // Las comillas escapadas rodean la clave: ADF_EMPLOYEE('<empleado>')/FormContent.
    // La ruta fija depende del binding, la versión y el alias publicados en el sistema.
    concat(
      '/sap/opu/odata4/sap/zsb_adf_employee_form_v4/srvd_a2x/sap/zsd_adf_employee_form/0001/ADF_EMPLOYEE(''', concat( employee, ''')/FormContent' )) as FormURL,
      'Print PDF' as Form
    
    
}
