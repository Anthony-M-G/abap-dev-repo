@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface for adobe form'
@Metadata.ignorePropagatedAnnotations: false
define root view entity ZR_I_ADF_EMPLOYEE as select from /dmo/employee_hr
{
    key employee as Employee,
    first_name as FirstName,
    last_name as LastName,
    @Semantics.amount.currencyCode: 'SalaryCurrency'
    salary as Salary,
    salary_currency as SalaryCurrency,
    manager as Manager,
    concat(
      '/sap/opu/odata4/sap/ZSB_ADF_EMPLOYEE_FORM_V4/srvd_a2x/sap/ZSD_ADF_EMPLOYEE_FORM/0001/ADF_EMPLOYEE(''', concat( employee, ''')/Form' )) as FormURL,
      'Print PDF' as Form
    
    
}
