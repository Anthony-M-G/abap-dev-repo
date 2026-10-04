" Handler local de las autorizaciones declaradas en el behavior de empleados.
CLASS lhc_ADF_EMPLOYEE DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations FOR adf_employee RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR adf_employee RESULT result.

ENDCLASS.

CLASS lhc_ADF_EMPLOYEE IMPLEMENTATION.

  METHOD get_instance_authorizations.
    " Pendiente: evaluar las autorizaciones solicitadas para las claves recibidas.
    " El método está vacío y no asigna decisiones de autorización a result.
  ENDMETHOD.

  METHOD get_global_authorizations.
    " Pendiente: evaluar la autorización global de creación declarada en el behavior.
    " El método está vacío y no asigna decisiones de autorización a result.
  ENDMETHOD.

ENDCLASS.
