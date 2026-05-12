package com.gmingenieros.asistenciagm.exception;

/** Se lanza cuando una operación DAO falla a nivel de SQL. */
public class DAOException extends AsistenciaGMException {

    private static final long serialVersionUID = 1L;

    public DAOException(String mensaje) {
        super(mensaje);
    }

    public DAOException(String mensaje, Throwable causa) {
        super(mensaje, causa);
    }
}
