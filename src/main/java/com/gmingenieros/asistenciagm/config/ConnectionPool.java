package com.gmingenieros.asistenciagm.config;

import com.gmingenieros.asistenciagm.constant.Constantes;
import com.gmingenieros.asistenciagm.exception.ConexionException;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Pool de conexiones JDBC minimalista para MySQL/Aiven.
 * Implementa el patrón Singleton y maneja un pool de conexiones
 * reutilizables para evitar la sobrecarga de crear/cerrar conexiones
 * en cada operación.
 *
 * <p>Uso:</p>
 * <pre>
 *   Connection conn = ConnectionPool.getInstance().obtener();
 *   try {
 *       // operaciones DB
 *   } finally {
 *       ConnectionPool.getInstance().liberar(conn);
 *   }
 * </pre>
 */
public final class ConnectionPool {

    private static final Logger LOG = Logger.getLogger(ConnectionPool.class.getName());

    private static volatile ConnectionPool instancia;

    private final Deque<Connection> disponibles = new ArrayDeque<>();
    private int totalCreadas = 0;

    // ── Constructor privado: crea las conexiones mínimas ───────────────
    private ConnectionPool() {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            for (int i = 0; i < Constantes.POOL_SIZE_MIN; i++) {
                disponibles.push(crearConexion());
            }
            LOG.info("Pool inicializado con " + Constantes.POOL_SIZE_MIN + " conexiones.");
        } catch (ClassNotFoundException e) {
            throw new ConexionException("Driver MySQL no encontrado en el classpath.", e);
        }
    }

    // ── Singleton thread-safe (double-checked locking) ─────────────────
    public static ConnectionPool getInstance() {
        if (instancia == null) {
            synchronized (ConnectionPool.class) {
                if (instancia == null) {
                    instancia = new ConnectionPool();
                }
            }
        }
        return instancia;
    }

    /**
     * Obtiene una conexión del pool. Si no hay disponibles y no se ha
     * alcanzado el máximo, crea una nueva. Si se alcanzó el máximo,
     * espera hasta {@code POOL_TIMEOUT} ms.
     *
     * @return conexión lista para usar
     * @throws ConexionException si no se puede obtener una conexión
     */
    public synchronized Connection obtener() {
        long inicio = System.currentTimeMillis();

        while (true) {
            // Intentar reutilizar una conexión válida del pool
            while (!disponibles.isEmpty()) {
                Connection conn = disponibles.pop();
                try {
                    if (conn.isValid(2)) {
                        return conn;
                    }
                    totalCreadas--;
                } catch (SQLException ex) {
                    totalCreadas--;
                    LOG.log(Level.WARNING, "Conexión inválida descartada.", ex);
                }
            }

            // Si hay margen, crear una nueva
            if (totalCreadas < Constantes.POOL_SIZE_MAX) {
                return crearConexion();
            }

            // Esperar a que se libere una
            long transcurrido = System.currentTimeMillis() - inicio;
            long restante = Constantes.POOL_TIMEOUT - transcurrido;
            if (restante <= 0) {
                throw new ConexionException(
                    "Tiempo de espera agotado: no hay conexiones disponibles en el pool.");
            }
            try {
                wait(restante);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new ConexionException("Hilo interrumpido esperando conexión.", e);
            }
        }
    }

    /**
     * Devuelve una conexión al pool para ser reutilizada.
     * Nunca llames a {@code connection.close()} directamente; usa este método.
     *
     * @param conn conexión a devolver
     */
    public synchronized void liberar(Connection conn) {
        if (conn != null) {
            disponibles.push(conn);
            notifyAll();
        }
    }

    /**
     * Cierra todas las conexiones del pool. Llamar al cerrar la aplicación.
     */
    public synchronized void cerrarTodo() {
        for (Connection conn : disponibles) {
            try {
                conn.close();
            } catch (SQLException e) {
                LOG.log(Level.WARNING, "Error al cerrar conexión.", e);
            }
        }
        disponibles.clear();
        totalCreadas = 0;
        LOG.info("Pool cerrado correctamente.");
    }

    // ── Utilidad interna ───────────────────────────────────────────────
    private Connection crearConexion() {
        try {
            Connection conn = DriverManager.getConnection(
                Constantes.DB_URL,
                Constantes.DB_USER,
                Constantes.DB_PASSWORD
            );
            totalCreadas++;
            LOG.fine("Nueva conexión creada. Total: " + totalCreadas);
            return conn;
        } catch (SQLException e) {
            throw new ConexionException("No se pudo conectar a la base de datos Aiven.", e);
        }
    }
}
