// Proyección de consumo de empleados utilizada por el servicio y sus anotaciones UI.
// NOT_REQUIRED no exige un DCL; no equivale a implementar una autorización.
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection ADF Employee'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true
// Declarar la capacidad de suministrar datos para formularios mediante el FDP.
@ObjectModel.supportedCapabilities: [ #OUTPUT_FORM_DATA_PROVIDER ]

define root view entity ZC_I_ADF_EMPLOYEE 
provider contract transactional_query
as projection on ZR_I_ADF_EMPLOYEE
{
    key Employee,
    FirstName,
    LastName,
    Salary,
    SalaryCurrency,
    Manager,
    FormURL,
    Form
}
