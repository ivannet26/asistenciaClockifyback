package com.gmingenieros.asistenciagm.util;

import java.sql.Connection; 
import java.sql.DriverManager;
import java.sql.SQLException;
import io.github.cdimascio.dotenv.Dotenv;

public class ConnectionDB {
    private static final Dotenv dotenv = Dotenv.load();

    private static final String HOST = dotenv.get("DB_HOST"); 
    private static final String PORT = dotenv.get("DB_PORT");
    private static final String DATABASE = dotenv.get("DB_NAME");
    private static final String USER = dotenv.get("DB_USER");
    private static final String PASSWORD = dotenv.get("DB_PASSWORD");
    private static final String URL = "jdbc:mysql://" + HOST + ":" + PORT + "/" + DATABASE + "?useSSL=true&sslMode=REQUIRED&serverTimezone=UTC";
    
    private static Connection conexion = null;

    private ConnectionDB() {
        // Constructor privado para evitar instanciación (Singleton)
    }

    public static Connection getConexion() throws SQLException {
        if (conexion == null || conexion.isClosed()) {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                conexion = DriverManager.getConnection(URL, USER, PASSWORD);
                System.out.println("Conexión exitosa a Aiven - AsistenciaGM");
            } catch (ClassNotFoundException e) {
                throw new SQLException("Driver MySQL no encontrado.", e);
            }
        }
        return conexion;
    }
    
    public static void cerrarConexion() {
        try {
            if (conexion != null && !conexion.isClosed()) {
                conexion.close();
                System.out.println("Conexión cerrada correctamente.");
            }
        } catch (SQLException e) {
            System.err.println("Error al cerrar la conexión: " + e.getMessage());
        }
    }
    
    // Método principal para probar la conexión
    public static void main(String[] args) {
        System.out.println("⏳ Iniciando prueba de conexión...");
        try {
            Connection conn = getConexion();
            if (conn != null && !conn.isClosed()) {
                System.out.println("🎉 ¡Éxito! La aplicación se ha conectado a Aiven correctamente.");
            }
        } catch (SQLException e) {
            System.err.println("❌ Error crítico de conexión:");
            e.printStackTrace();
        } finally {
            cerrarConexion();
        }
    }
}