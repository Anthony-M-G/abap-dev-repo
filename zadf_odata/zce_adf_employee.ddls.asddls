// Custom entity cuyo contenido obtiene la clase indicada en implementedBy.
// Devuelve como máximo un documento por empleado según la consulta implementada.
@EndUserText.label: 'Custom Entity to return lob data'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_CE_ADF_EMPLOYEE'
define custom entity ZCE_ADF_EMPLOYEE
{
  key employee    : /dmo/employee_id;

      // Vincular el binario con su tipo MIME y nombre de archivo.
      // La disposición ATTACHMENT indica que el documento se ofrece como adjunto.
      @Semantics.largeObject: { mimeType: 'MimeType',
                                fileName: 'FileName',
                                contentDispositionPreference: #ATTACHMENT }
      FormContent : abap.rawstring( 0 );

      FileName    : abap.char( 255 );

      @Semantics.mimeType: true
      MimeType    : abap.char( 255 );
}
