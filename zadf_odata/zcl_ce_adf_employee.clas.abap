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
      lc_form_name     TYPE string VALUE 'ZADF_PRUEBA',   " your Form Object
      lc_data_provider TYPE string VALUE 'ZSD_ADF_EMPLOYEE', " your data provider service definition
      lc_key_name      TYPE string VALUE 'EMPLOYEE',             " verify with get_keys( ) in debugger
      lc_locale        TYPE string VALUE 'en_US'.


    DATA lv_employee TYPE zr_i_adf_employee-employee.
    DATA lt_result TYPE STANDARD TABLE OF ZCE_ADF_EMPLOYEE.
    " Consume paging info so requests with $top/$skip are accepted
    DATA(lv_page_size) = io_request->get_paging( )->get_page_size( ).

    " 1. Key from the request: ADF_EMPLOYEE('X') arrives as filter Employee = 'X'
    TRY.
        DATA(lt_ranges) = io_request->get_filter( )->get_as_ranges( ).
      CATCH cx_rap_query_filter_no_range INTO DATA(lx_filter).

    ENDTRY.

    ASSIGN lt_ranges[ name = 'EMPLOYEE' ] TO FIELD-SYMBOL(<ls_filter>).
    IF sy-subrc = 0 AND <ls_filter>-range IS NOT INITIAL.
      lv_employee = <ls_filter>-range[ 1 ]-low.
    ENDIF.

    " 2. One request = one PDF: reads without key return nothing
    IF lv_employee IS NOT INITIAL.

      SELECT SINGLE @abap_true FROM zr_i_adf_employee
        WHERE Employee = @lv_employee
        INTO @DATA(lv_exists).

      " TODO: AUTHORITY-CHECK here (DCL does not apply to custom entities)

      IF lv_exists = abap_true.
        TRY.
            " 3. Layout (XDP) stored in the Form Object
            DATA(lo_reader) = cl_fp_form_reader=>create_form_reader( iv_formname = CONV #( lc_form_name ) ).
            DATA(lv_layout) = lo_reader->get_layout( ).

            " 4. Business data as XML, same shape as the XSD used in LiveCycle
            DATA(lo_fdp) = cl_fp_fdp_services=>get_instance( iv_service_definition = CONV #( lc_data_provider ) ).
            DATA(lt_keys) = lo_fdp->get_keys( ).
            lt_keys[ name = lc_key_name ]-value = lv_employee.
            DATA(lv_xml_data) = lo_fdp->read_to_xml_v2( it_select = lt_keys ).

            " 5. ADS merges layout + data into the PDF
            cl_fp_ads_util=>render_pdf(
              EXPORTING iv_xml_data   = lv_xml_data
                        iv_xdp_layout = lv_layout
                        iv_locale     = lc_locale
              IMPORTING ev_pdf        = DATA(lv_pdf) ).

            " 6. Result row: Form is served as Edm.Stream via @Semantics.largeObject
            append  VALUE #( employee = lv_employee
                            filename = |Employee_{ lv_employee }.pdf|
                            mimetype = 'application/pdf'
                            FormContent     = lv_pdf ) to lt_result .

          CATCH cx_fp_form_reader cx_fp_fdp_error cx_fp_ads_util
                cx_sy_itab_line_not_found INTO DATA(lx_render).

        ENDTRY.
      ENDIF.

    ENDIF.

    " 7. Response
    IF io_request->is_data_requested( ).
      io_response->set_data( lt_result ).
    ENDIF.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( lt_result ) ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
