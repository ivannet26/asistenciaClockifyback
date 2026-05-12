package com.gmingenieros.asistenciagm.exception;

/** Se lanza cuando una regla de negocio no se cumple. */
public class NegocioException extends AsistenciaGMException {

    private static final long serialVersionUID = 1L;

    public NegocioException(String mensaje) {
        super(mensaje);
    }

    public NegocioException(String mensaje, Throwable causa) {
        super(mensaje, causa);
    }
}
