package com.gmingenieros.asistenciagm.exception;

/** Se lanza cuando se busca una entidad que no existe en la base de datos. */
public class EntidadNoEncontradaException extends AsistenciaGMException {

    private static final long serialVersionUID = 1L;

    public EntidadNoEncontradaException(String entidad, Object id) {
        super(entidad + " con id=" + id + " no encontrada.");
    }

    public EntidadNoEncontradaException(String mensaje) {
        super(mensaje);
    }
}
