CLASS zcl_data_generator_rap DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_data_generator_rap IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    DELETE FROM zttravel_lgl.
    DELETE FROM zttravel_lgl_d.

    INSERT zttravel_lgl FROM (
        SELECT FROM /dmo/travel
        FIELDS uuid(  ) AS travel_uuid,
                        travel_id,
                        agency_id,
                        customer_id,
                        begin_date,
                        end_date,

                        booking_fee,

                        total_price,
                        currency_code,
                        description,

                        CASE status WHEN 'B' THEN 'A'
                        WHEN 'P' THEN 'O'
                        WHEN 'N' THEN 'O'
                        ELSE 'X' END AS
                        overall_status,

          createdby   AS  local_created_by,
          createdat   AS  local_created_at,
          lastchangedby AS local_last_changed_by,
          lastchangedat AS local_last_changed_at
          WHERE travel_id BETWEEN 1 AND 3000 ).

    IF sy-subrc = 0.
      out->write( |{ sy-dbcnt } records inserted into zttravel_lgl| ).
    	ELSE.
      	
    ENDIF.



  ENDMETHOD.
ENDCLASS.
