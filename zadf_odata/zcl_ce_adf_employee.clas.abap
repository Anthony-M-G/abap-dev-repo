" Proveedor de consulta de la custom entity que devuelve el PDF de un empleado.
CLASS zcl_ce_adf_employee DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_ce_adf_employee IMPLEMENTATION.


  METHOD if_rap_query_provider~select.

    CONSTANTS:
      lc_form_name     TYPE string VALUE 'ZADF_PRUEBA',   " Form Object que contiene el layout XDP
      lc_data_provider TYPE string VALUE 'ZSD_ADF_EMPLOYEE', " Service definition utilizada como FDP
      lc_key_name      TYPE string VALUE 'EMPLOYEE',             " Nombre esperado en las claves del FDP
      lc_locale        TYPE string VALUE 'en_US'.


    DATA lv_employee TYPE zr_i_adf_employee-employee.
    DATA lt_result TYPE STANDARD TABLE OF ZCE_ADF_EMPLOYEE.
    " Se consulta el tamaño de página, pero no se utiliza para limitar el resultado.
    " La implementación tampoco aplica el desplazamiento solicitado mediante $skip.
    DATA(lv_page_size) = io_request->get_paging( )->get_page_size( ).

    " 1. Obtener el empleado desde el filtro de la solicitud.
    " El acceso ADF_EMPLOYEE('X') se procesa buscando EMPLOYEE en los rangos.
    TRY.
        DATA(lt_ranges) = io_request->get_filter( )->get_as_ranges( ).
      CATCH cx_rap_query_filter_no_range INTO DATA(lx_filter).
        " Si el filtro no se puede convertir a rangos, no se informa el error.
        " Sin una clave recuperada, la respuesta queda vacía.
    ENDTRY.

    ASSIGN lt_ranges[ name = 'EMPLOYEE' ] TO FIELD-SYMBOL(<ls_filter>).
    IF sy-subrc = 0 AND <ls_filter>-range IS NOT INITIAL.
      " Se toma únicamente LOW del primer rango; no se validan SIGN ni OPTION.
      " No se implementa aquí la selección de varios empleados o intervalos.
      lv_employee = <ls_filter>-range[ 1 ]-low.
    ENDIF.

    " 2. Generar como máximo un PDF por solicitud.
    " Sin empleado, o si este no existe en la vista raíz, no se agrega un resultado.
    IF lv_employee IS NOT INITIAL.

      SELECT SINGLE @abap_true FROM zr_i_adf_employee
        WHERE Employee = @lv_employee
        INTO @DATA(lv_exists).

      " TODO: implementar la autorización de lectura antes de generar el PDF.
      " La comprobación de existencia no comprueba permisos de acceso al empleado.

      IF lv_exists = abap_true.
        TRY.
            " 3. Leer el layout XDP del Form Object configurado.
            " El layout define la presentación que ADS combinará con los datos XML.
            DATA(lo_reader) = cl_fp_form_reader=>create_form_reader( iv_formname = CONV #( lc_form_name ) ).
            DATA(lv_layout) = lo_reader->get_layout( ).

            " 4. Obtener los datos del empleado mediante el Form Data Provider (FDP).
            " Se recuperan sus claves y se asigna el empleado a la clave EMPLOYEE.
            " Si esa clave no existe, la expresión de tabla genera la excepción
            " cx_sy_itab_line_not_found capturada al final de este bloque.
            " El XML resultante debe ser compatible con el esquema usado por el XDP.
            DATA(lo_fdp) = cl_fp_fdp_services=>get_instance( iv_service_definition = CONV #( lc_data_provider ) ).
            DATA(lt_keys) = lo_fdp->get_keys( ).
            lt_keys[ name = lc_key_name ]-value = lv_employee.
            DATA(lv_xml_data) = lo_fdp->read_to_xml_v2( it_select = lt_keys ).

            " 5. Enviar el XML y el layout a Adobe Document Services (ADS).
            " El PDF se recibe como contenido binario; el locale configurado es en_US.
            cl_fp_ads_util=>render_pdf(
              EXPORTING iv_xml_data   = lv_xml_data
                        iv_xdp_layout = lv_layout
                        iv_locale     = lc_locale
              IMPORTING ev_pdf        = DATA(lv_pdf) ).

            " 6. Construir el resultado con la clave, el nombre y el contenido del PDF.
            " La custom entity relaciona FormContent con FileName y MimeType mediante
            " @Semantics.largeObject para permitir la descarga del documento.
            append  VALUE #( employee = lv_employee
                            filename = |Employee_{ lv_employee }.pdf|
                            mimetype = 'application/pdf'
                            FormContent     = lv_pdf ) to lt_result .

          CATCH cx_fp_form_reader cx_fp_fdp_error cx_fp_ads_util
                cx_sy_itab_line_not_found INTO DATA(lx_render).
            " Actualmente estos errores no se registran ni se devuelven al consumidor.
            " Como no se agrega una fila, el resultado permanece vacío.
        ENDTRY.
      ENDIF.

    ENDIF.

    " 7. Entregar los datos y el conteo solo cuando la solicitud los requiera.
    " El conteo corresponde a los PDF generados (cero o uno), no al total de empleados.
    " La generación anterior también se ejecuta en solicitudes que solo piden conteo.
    IF io_request->is_data_requested( ).
      io_response->set_data( lt_result ).
    ENDIF.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( lt_result ) ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
