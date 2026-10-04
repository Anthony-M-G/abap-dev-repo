@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection ADF Employee'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true
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
