package com.gmingenieros.asistenciagm.exception;

/**
 * Excepción base del sistema AsistenciaGM.
 * Todas las excepciones de negocio heredan de esta clase.
 */
public class AsistenciaGMException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    public AsistenciaGMException(String mensaje) {
        super(mensaje);
    }

    public AsistenciaGMException(String mensaje, Throwable causa) {
        super(mensaje, causa);
    }
}
