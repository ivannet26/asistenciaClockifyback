package com.gmingenieros.asistenciagm.constant;

/**
 * Constantes globales del sistema AsistenciaGM.
 * Centraliza valores fijos para evitar cadenas mágicas en el código.
 */
public final class Constantes {

    private Constantes() { }

    // ── Base de datos ───────────────────────────────────────────────────
    public static final String DB_HOST     = "tu-host.aivencloud.com";
    public static final int    DB_PORT     = 3306;
    public static final String DB_NAME     = "asistenciaGM";
    public static final String DB_USER     = "tu_usuario";
    public static final String DB_PASSWORD = "tu_password";
    public static final String DB_URL      = String.format(
        "jdbc:mysql://%s:%d/%s?useSSL=true&requireSSL=true"
        + "&serverTimezone=America/Lima&characterEncoding=UTF-8",
        DB_HOST, DB_PORT, DB_NAME
    );

    // Pool de conexiones
    public static final int POOL_SIZE_MIN  = 2;
    public static final int POOL_SIZE_MAX  = 10;
    public static final int POOL_TIMEOUT   = 30_000; // ms

    // ── Roles ───────────────────────────────────────────────────────────
    public static final String ROL_ADMIN    = "ADMIN";
    public static final String ROL_MANAGER  = "MANAGER";
    public static final String ROL_EMPLEADO = "EMPLEADO";

    // ── Seguridad ───────────────────────────────────────────────────────
    public static final int BCRYPT_STRENGTH = 12;

    // ── Paginación ──────────────────────────────────────────────────────
    public static final int PAGINA_DEFAULT  = 0;
    public static final int TAMANO_DEFAULT  = 50;

    // ── Nombres de stored procedures ────────────────────────────────────
    public static final class SP {

        private SP() { }

        // Usuarios
        public static final String USUARIO_POR_EMAIL        = "CALL sp_usuario_por_email(?)";
        public static final String CREAR_USUARIO            = "CALL sp_crear_usuario(?,?,?,?,?)";
        public static final String USUARIOS_POR_WORKSPACE   = "CALL sp_usuarios_por_workspace(?)";
        public static final String DESACTIVAR_USUARIO       = "CALL sp_desactivar_usuario(?)";

        // Workspace
        public static final String CREAR_WORKSPACE          = "CALL sp_crear_workspace(?,?,?,?)";
        public static final String WORKSPACES_DE_USUARIO    = "CALL sp_workspaces_de_usuario(?)";
        public static final String AGREGAR_MIEMBRO          = "CALL sp_agregar_miembro_workspace(?,?,?)";
        public static final String REMOVER_MIEMBRO          = "CALL sp_remover_miembro_workspace(?,?)";

        // Clientes
        public static final String CREAR_CLIENTE            = "CALL sp_crear_cliente(?,?,?,?,?)";
        public static final String LISTAR_CLIENTES          = "CALL sp_listar_clientes(?,?)";
        public static final String ARCHIVAR_CLIENTE         = "CALL sp_archivar_cliente(?,?)";

        // Proyectos
        public static final String CREAR_PROYECTO           = "CALL sp_crear_proyecto(?,?,?,?,?,?)";
        public static final String LISTAR_PROYECTOS         = "CALL sp_listar_proyectos(?,?)";
        public static final String ARCHIVAR_PROYECTO        = "CALL sp_archivar_proyecto(?,?)";

        // Tareas
        public static final String CREAR_TAREA              = "CALL sp_crear_tarea(?,?,?)";
        public static final String TAREAS_POR_PROYECTO      = "CALL sp_tareas_por_proyecto(?,?)";

        // Etiquetas
        public static final String CREAR_ETIQUETA           = "CALL sp_crear_etiqueta(?,?,?,?)";
        public static final String LISTAR_ETIQUETAS         = "CALL sp_listar_etiquetas(?)";

        // Rastreador
        public static final String INICIAR_TIMER            = "CALL sp_iniciar_timer(?,?,?,?,?,?,?)";
        public static final String DETENER_TIMER            = "CALL sp_detener_timer(?,?)";
        public static final String TIMER_ACTIVO             = "CALL sp_timer_activo(?,?)";
        public static final String TOGGLE_ETIQUETA_REGISTRO = "CALL sp_toggle_etiqueta_registro(?,?)";

        // Panel
        public static final String PANEL_RESUMEN            = "CALL sp_panel_resumen(?,?,?,?)";

        // Informes
        public static final String INFORME_DETALLADO        = "CALL sp_informe_detallado(?,?,?,?,?)";
        public static final String INFORME_POR_PROYECTO     = "CALL sp_informe_por_proyecto(?,?,?)";
    }
}
