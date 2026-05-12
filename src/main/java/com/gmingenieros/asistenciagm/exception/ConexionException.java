package com.gmingenieros.asistenciagm.exception;

/** Se lanza cuando falla la conexión o el pool de conexiones. */
public class ConexionException extends AsistenciaGMException {

    private static final long serialVersionUID = 1L;

    public ConexionException(String mensaje) {
        super(mensaje);
    }

    public ConexionException(String mensaje, Throwable causa) {
        super(mensaje, causa);
    }
}
