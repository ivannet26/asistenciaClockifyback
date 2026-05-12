-- ============================================================
-- AsistenciaGM – Stored Procedures
-- Ejecutar DESPUÉS de schema.sql
-- ============================================================

USE asistenciaGM;

DELIMITER $$

-- ══════════════════════════════════════════════════════════════
-- MÓDULO: USUARIOS
-- ══════════════════════════════════════════════════════════════

-- Obtener usuario por email (login)
DROP PROCEDURE IF EXISTS sp_usuario_por_email $$
CREATE PROCEDURE sp_usuario_por_email(IN p_email VARCHAR(150))
BEGIN
    SELECT id, nombre, email, password_hash, rol, activo, created_at
    FROM usuarios
    WHERE email = p_email AND activo = 1;
END $$

-- Crear usuario
DROP PROCEDURE IF EXISTS sp_crear_usuario $$
CREATE PROCEDURE sp_crear_usuario(
    IN  p_nombre        VARCHAR(100),
    IN  p_email         VARCHAR(150),
    IN  p_password_hash VARCHAR(255),
    IN  p_rol           ENUM('ADMIN','MANAGER','EMPLEADO'),
    OUT p_id            INT
)
BEGIN
    INSERT INTO usuarios (nombre, email, password_hash, rol)
    VALUES (p_nombre, p_email, p_password_hash, p_rol);
    SET p_id = LAST_INSERT_ID();
END $$

-- Listar usuarios de un workspace
DROP PROCEDURE IF EXISTS sp_usuarios_por_workspace $$
CREATE PROCEDURE sp_usuarios_por_workspace(IN p_workspace_id INT)
BEGIN
    SELECT u.id, u.nombre, u.email, u.rol, wu.rol_en_workspace, wu.joined_at
    FROM usuarios u
    INNER JOIN workspace_usuarios wu ON u.id = wu.usuario_id
    WHERE wu.workspace_id = p_workspace_id AND u.activo = 1
    ORDER BY u.nombre;
END $$

-- Desactivar usuario (baja lógica)
DROP PROCEDURE IF EXISTS sp_desactivar_usuario $$
CREATE PROCEDURE sp_desactivar_usuario(IN p_id INT)
BEGIN
    UPDATE usuarios SET activo = 0 WHERE id = p_id;
END $$

-- ══════════════════════════════════════════════════════════════
-- MÓDULO: WORKSPACE
-- ══════════════════════════════════════════════════════════════

-- Crear workspace y agregar al owner como ADMIN
DROP PROCEDURE IF EXISTS sp_crear_workspace $$
CREATE PROCEDURE sp_crear_workspace(
    IN  p_nombre      VARCHAR(100),
    IN  p_descripcion VARCHAR(255),
    IN  p_owner_id    INT,
    OUT p_id          INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
        INSERT INTO workspace (nombre, descripcion, owner_id)
        VALUES (p_nombre, p_descripcion, p_owner_id);
        SET p_id = LAST_INSERT_ID();
        INSERT INTO workspace_usuarios (workspace_id, usuario_id, rol_en_workspace)
        VALUES (p_id, p_owner_id, 'ADMIN');
    COMMIT;
END $$

-- Workspaces de un usuario
DROP PROCEDURE IF EXISTS sp_workspaces_de_usuario $$
CREATE PROCEDURE sp_workspaces_de_usuario(IN p_usuario_id INT)
BEGIN
    SELECT w.id, w.nombre, w.descripcion, w.owner_id, wu.rol_en_workspace
    FROM workspace w
    INNER JOIN workspace_usuarios wu ON w.id = wu.workspace_id
    WHERE wu.usuario_id = p_usuario_id
    ORDER BY w.nombre;
END $$

-- Agregar miembro a workspace
DROP PROCEDURE IF EXISTS sp_agregar_miembro_workspace $$
CREATE PROCEDURE sp_agregar_miembro_workspace(
    IN p_workspace_id     INT,
    IN p_usuario_id       INT,
    IN p_rol_en_workspace ENUM('ADMIN','MANAGER','EMPLEADO')
)
BEGIN
    INSERT INTO workspace_usuarios (workspace_id, usuario_id, rol_en_workspace)
    VALUES (p_workspace_id, p_usuario_id, p_rol_en_workspace)
    ON DUPLICATE KEY UPDATE rol_en_workspace = p_rol_en_workspace;
END $$

-- Eliminar miembro de workspace
DROP PROCEDURE IF EXISTS sp_remover_miembro_workspace $$
CREATE PROCEDURE sp_remover_miembro_workspace(
    IN p_workspace_id INT,
    IN p_usuario_id   INT
)
BEGIN
    DELETE FROM workspace_usuarios
    WHERE workspace_id = p_workspace_id AND usuario_id = p_usuario_id;
END $$

-- ══════════════════════════════════════════════════════════════
-- MÓDULO: CLIENTES
-- ══════════════════════════════════════════════════════════════

DROP PROCEDURE IF EXISTS sp_crear_cliente $$
CREATE PROCEDURE sp_crear_cliente(
    IN  p_workspace_id INT,
    IN  p_nombre       VARCHAR(100),
    IN  p_email        VARCHAR(150),
    IN  p_direccion    VARCHAR(255),
    OUT p_id           INT
)
BEGIN
    INSERT INTO clientes (workspace_id, nombre, email, direccion)
    VALUES (p_workspace_id, p_nombre, p_email, p_direccion);
    SET p_id = LAST_INSERT_ID();
END $$

DROP PROCEDURE IF EXISTS sp_listar_clientes $$
CREATE PROCEDURE sp_listar_clientes(
    IN p_workspace_id INT,
    IN p_incluir_archivados TINYINT(1)
)
BEGIN
    SELECT id, nombre, email, direccion, archivado, created_at
    FROM clientes
    WHERE workspace_id = p_workspace_id
      AND (p_incluir_archivados = 1 OR archivado = 0)
    ORDER BY nombre;
END $$

DROP PROCEDURE IF EXISTS sp_archivar_cliente $$
CREATE PROCEDURE sp_archivar_cliente(IN p_id INT, IN p_archivar TINYINT(1))
BEGIN
    UPDATE clientes SET archivado = p_archivar WHERE id = p_id;
END $$

-- ══════════════════════════════════════════════════════════════
-- MÓDULO: PROYECTOS
-- ══════════════════════════════════════════════════════════════

DROP PROCEDURE IF EXISTS sp_crear_proyecto $$
CREATE PROCEDURE sp_crear_proyecto(
    IN  p_workspace_id INT,
    IN  p_cliente_id   INT,
    IN  p_nombre       VARCHAR(100),
    IN  p_color        CHAR(7),
    IN  p_billable     TINYINT(1),
    OUT p_id           INT
)
BEGIN
    INSERT INTO proyectos (workspace_id, cliente_id, nombre, color, billable)
    VALUES (p_workspace_id, p_cliente_id, p_nombre, p_color, p_billable);
    SET p_id = LAST_INSERT_ID();
END $$

DROP PROCEDURE IF EXISTS sp_listar_proyectos $$
CREATE PROCEDURE sp_listar_proyectos(
    IN p_workspace_id INT,
    IN p_incluir_archivados TINYINT(1)
)
BEGIN
    SELECT p.id, p.nombre, p.color, p.billable, p.archivado,
           c.id AS cliente_id, c.nombre AS cliente_nombre
    FROM proyectos p
    LEFT JOIN clientes c ON p.cliente_id = c.id
    WHERE p.workspace_id = p_workspace_id
      AND (p_incluir_archivados = 1 OR p.archivado = 0)
    ORDER BY p.nombre;
END $$

DROP PROCEDURE IF EXISTS sp_archivar_proyecto $$
CREATE PROCEDURE sp_archivar_proyecto(IN p_id INT, IN p_archivar TINYINT(1))
BEGIN
    UPDATE proyectos SET archivado = p_archivar WHERE id = p_id;
END $$

-- ══════════════════════════════════════════════════════════════
-- MÓDULO: TAREAS
-- ══════════════════════════════════════════════════════════════

DROP PROCEDURE IF EXISTS sp_crear_tarea $$
CREATE PROCEDURE sp_crear_tarea(
    IN  p_proyecto_id INT,
    IN  p_nombre      VARCHAR(150),
    OUT p_id          INT
)
BEGIN
    INSERT INTO tareas (proyecto_id, nombre) VALUES (p_proyecto_id, p_nombre);
    SET p_id = LAST_INSERT_ID();
END $$

DROP PROCEDURE IF EXISTS sp_tareas_por_proyecto $$
CREATE PROCEDURE sp_tareas_por_proyecto(
    IN p_proyecto_id INT,
    IN p_incluir_archivadas TINYINT(1)
)
BEGIN
    SELECT id, nombre, archivado
    FROM tareas
    WHERE proyecto_id = p_proyecto_id
      AND (p_incluir_archivadas = 1 OR archivado = 0)
    ORDER BY nombre;
END $$

-- ══════════════════════════════════════════════════════════════
-- MÓDULO: ETIQUETAS
-- ══════════════════════════════════════════════════════════════

DROP PROCEDURE IF EXISTS sp_crear_etiqueta $$
CREATE PROCEDURE sp_crear_etiqueta(
    IN  p_workspace_id INT,
    IN  p_nombre       VARCHAR(80),
    IN  p_color        CHAR(7),
    OUT p_id           INT
)
BEGIN
    INSERT INTO etiquetas (workspace_id, nombre, color)
    VALUES (p_workspace_id, p_nombre, p_color);
    SET p_id = LAST_INSERT_ID();
END $$

DROP PROCEDURE IF EXISTS sp_listar_etiquetas $$
CREATE PROCEDURE sp_listar_etiquetas(IN p_workspace_id INT)
BEGIN
    SELECT id, nombre, color FROM etiquetas
    WHERE workspace_id = p_workspace_id ORDER BY nombre;
END $$

-- ══════════════════════════════════════════════════════════════
-- MÓDULO: RASTREADOR (registros_tiempo)
-- ══════════════════════════════════════════════════════════════

-- Iniciar un timer (fin = NULL)
DROP PROCEDURE IF EXISTS sp_iniciar_timer $$
CREATE PROCEDURE sp_iniciar_timer(
    IN  p_usuario_id   INT,
    IN  p_workspace_id INT,
    IN  p_proyecto_id  INT,
    IN  p_tarea_id     INT,
    IN  p_descripcion  VARCHAR(255),
    IN  p_billable     TINYINT(1),
    OUT p_id           INT
)
BEGIN
    -- Detener cualquier timer activo del usuario en este workspace
    UPDATE registros_tiempo
    SET fin = NOW()
    WHERE usuario_id = p_usuario_id
      AND workspace_id = p_workspace_id
      AND fin IS NULL;

    INSERT INTO registros_tiempo (usuario_id, workspace_id, proyecto_id, tarea_id, descripcion, inicio, billable)
    VALUES (p_usuario_id, p_workspace_id, p_proyecto_id, p_tarea_id, p_descripcion, NOW(), p_billable);
    SET p_id = LAST_INSERT_ID();
END $$

-- Detener timer activo
DROP PROCEDURE IF EXISTS sp_detener_timer $$
CREATE PROCEDURE sp_detener_timer(
    IN p_registro_id INT,
    IN p_usuario_id  INT
)
BEGIN
    UPDATE registros_tiempo
    SET fin = NOW()
    WHERE id = p_registro_id AND usuario_id = p_usuario_id AND fin IS NULL;
END $$

-- Obtener timer activo de un usuario
DROP PROCEDURE IF EXISTS sp_timer_activo $$
CREATE PROCEDURE sp_timer_activo(
    IN p_usuario_id   INT,
    IN p_workspace_id INT
)
BEGIN
    SELECT rt.id, rt.descripcion, rt.inicio, rt.billable,
           p.id AS proyecto_id, p.nombre AS proyecto_nombre, p.color AS proyecto_color,
           t.id AS tarea_id, t.nombre AS tarea_nombre
    FROM registros_tiempo rt
    LEFT JOIN proyectos p ON rt.proyecto_id = p.id
    LEFT JOIN tareas    t ON rt.tarea_id    = t.id
    WHERE rt.usuario_id   = p_usuario_id
      AND rt.workspace_id = p_workspace_id
      AND rt.fin IS NULL
    LIMIT 1;
END $$

-- Agregar/quitar etiqueta a un registro
DROP PROCEDURE IF EXISTS sp_toggle_etiqueta_registro $$
CREATE PROCEDURE sp_toggle_etiqueta_registro(
    IN p_registro_id INT,
    IN p_etiqueta_id INT
)
BEGIN
    IF EXISTS (SELECT 1 FROM registro_etiquetas
               WHERE registro_id = p_registro_id AND etiqueta_id = p_etiqueta_id) THEN
        DELETE FROM registro_etiquetas
        WHERE registro_id = p_registro_id AND etiqueta_id = p_etiqueta_id;
    ELSE
        INSERT INTO registro_etiquetas (registro_id, etiqueta_id)
        VALUES (p_registro_id, p_etiqueta_id);
    END IF;
END $$

-- ══════════════════════════════════════════════════════════════
-- MÓDULO: PANEL (dashboard) – totales por usuario/periodo
-- ══════════════════════════════════════════════════════════════

DROP PROCEDURE IF EXISTS sp_panel_resumen $$
CREATE PROCEDURE sp_panel_resumen(
    IN p_workspace_id INT,
    IN p_usuario_id   INT,       -- NULL = todos los usuarios
    IN p_desde        DATE,
    IN p_hasta        DATE
)
BEGIN
    SELECT
        u.id   AS usuario_id,
        u.nombre AS usuario_nombre,
        COUNT(rt.id)              AS total_registros,
        COALESCE(SUM(rt.duracion_seg), 0) AS total_segundos,
        COALESCE(SUM(CASE WHEN rt.billable = 1 THEN rt.duracion_seg ELSE 0 END), 0) AS segundos_billable
    FROM registros_tiempo rt
    INNER JOIN usuarios u ON rt.usuario_id = u.id
    WHERE rt.workspace_id = p_workspace_id
      AND DATE(rt.inicio)  >= p_desde
      AND DATE(rt.inicio)  <= p_hasta
      AND rt.fin IS NOT NULL
      AND (p_usuario_id IS NULL OR rt.usuario_id = p_usuario_id)
    GROUP BY u.id, u.nombre
    ORDER BY total_segundos DESC;
END $$

-- ══════════════════════════════════════════════════════════════
-- MÓDULO: INFORMES – desglose por proyecto y fecha
-- ══════════════════════════════════════════════════════════════

DROP PROCEDURE IF EXISTS sp_informe_detallado $$
CREATE PROCEDURE sp_informe_detallado(
    IN p_workspace_id INT,
    IN p_usuario_id   INT,
    IN p_proyecto_id  INT,
    IN p_desde        DATE,
    IN p_hasta        DATE
)
BEGIN
    SELECT
        rt.id,
        rt.descripcion,
        rt.inicio,
        rt.fin,
        rt.duracion_seg,
        rt.billable,
        u.nombre  AS usuario_nombre,
        p.nombre  AS proyecto_nombre,
        p.color   AS proyecto_color,
        t.nombre  AS tarea_nombre,
        GROUP_CONCAT(e.nombre ORDER BY e.nombre SEPARATOR ', ') AS etiquetas
    FROM registros_tiempo rt
    INNER JOIN usuarios  u  ON rt.usuario_id  = u.id
    LEFT JOIN  proyectos p  ON rt.proyecto_id = p.id
    LEFT JOIN  tareas    t  ON rt.tarea_id    = t.id
    LEFT JOIN  registro_etiquetas re ON rt.id = re.registro_id
    LEFT JOIN  etiquetas e  ON re.etiqueta_id = e.id
    WHERE rt.workspace_id = p_workspace_id
      AND rt.fin IS NOT NULL
      AND DATE(rt.inicio) >= p_desde
      AND DATE(rt.inicio) <= p_hasta
      AND (p_usuario_id  IS NULL OR rt.usuario_id  = p_usuario_id)
      AND (p_proyecto_id IS NULL OR rt.proyecto_id = p_proyecto_id)
    GROUP BY rt.id
    ORDER BY rt.inicio DESC;
END $$

DROP PROCEDURE IF EXISTS sp_informe_por_proyecto $$
CREATE PROCEDURE sp_informe_por_proyecto(
    IN p_workspace_id INT,
    IN p_desde        DATE,
    IN p_hasta        DATE
)
BEGIN
    SELECT
        COALESCE(p.id, 0)      AS proyecto_id,
        COALESCE(p.nombre, 'Sin proyecto') AS proyecto_nombre,
        p.color                AS proyecto_color,
        SUM(rt.duracion_seg)   AS total_segundos,
        COUNT(rt.id)           AS total_registros
    FROM registros_tiempo rt
    LEFT JOIN proyectos p ON rt.proyecto_id = p.id
    WHERE rt.workspace_id = p_workspace_id
      AND rt.fin IS NOT NULL
      AND DATE(rt.inicio) >= p_desde
      AND DATE(rt.inicio) <= p_hasta
    GROUP BY p.id, p.nombre, p.color
    ORDER BY total_segundos DESC;
END $$

DELIMITER ;