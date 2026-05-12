-- ============================================================
-- AsistenciaGM – Esquema de base de datos
-- Motor: MySQL 8.0  |  BD: asistenciaGM
-- ============================================================
-- INSTRUCCIÓN: ejecutar este script completo en Workbench
--              conectado a Aiven (bd: asistenciaGM).
-- ============================================================

USE asistenciaGM;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS registro_etiquetas;
DROP TABLE IF EXISTS registros_tiempo;
DROP TABLE IF EXISTS tareas;
DROP TABLE IF EXISTS etiquetas;
DROP TABLE IF EXISTS proyectos;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS workspace_usuarios;
DROP TABLE IF EXISTS workspace;
DROP TABLE IF EXISTS usuarios;
SET FOREIGN_KEY_CHECKS = 1;

-- ────────────────────────────────────────
-- 1. USUARIOS
-- ────────────────────────────────────────
CREATE TABLE usuarios (
    id            INT          NOT NULL AUTO_INCREMENT,
    nombre        VARCHAR(100) NOT NULL,
    email         VARCHAR(150) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,           -- BCrypt hash
    rol           ENUM('ADMIN','MANAGER','EMPLEADO') NOT NULL DEFAULT 'EMPLEADO',
    activo        TINYINT(1)   NOT NULL DEFAULT 1,
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_usuarios PRIMARY KEY (id),
    CONSTRAINT uq_usuarios_email UNIQUE (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ────────────────────────────────────────
-- 2. WORKSPACE
-- ────────────────────────────────────────
CREATE TABLE workspace (
    id          INT          NOT NULL AUTO_INCREMENT,
    nombre      VARCHAR(100) NOT NULL,
    descripcion VARCHAR(255),
    owner_id    INT          NOT NULL,
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_workspace PRIMARY KEY (id),
    CONSTRAINT fk_ws_owner FOREIGN KEY (owner_id) REFERENCES usuarios(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ────────────────────────────────────────
-- 3. WORKSPACE_USUARIOS  (N:M con rol)
-- ────────────────────────────────────────
CREATE TABLE workspace_usuarios (
    workspace_id     INT NOT NULL,
    usuario_id       INT NOT NULL,
    rol_en_workspace ENUM('ADMIN','MANAGER','EMPLEADO') NOT NULL DEFAULT 'EMPLEADO',
    joined_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_wu PRIMARY KEY (workspace_id, usuario_id),
    CONSTRAINT fk_wu_workspace FOREIGN KEY (workspace_id) REFERENCES workspace(id) ON DELETE CASCADE,
    CONSTRAINT fk_wu_usuario   FOREIGN KEY (usuario_id)   REFERENCES usuarios(id)  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ────────────────────────────────────────
-- 4. CLIENTES
-- ────────────────────────────────────────
CREATE TABLE clientes (
    id           INT          NOT NULL AUTO_INCREMENT,
    workspace_id INT          NOT NULL,
    nombre       VARCHAR(100) NOT NULL,
    email        VARCHAR(150),
    direccion    VARCHAR(255),
    archivado    TINYINT(1)   NOT NULL DEFAULT 0,
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_clientes   PRIMARY KEY (id),
    CONSTRAINT fk_cl_ws      FOREIGN KEY (workspace_id) REFERENCES workspace(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ────────────────────────────────────────
-- 5. PROYECTOS
-- ────────────────────────────────────────
CREATE TABLE proyectos (
    id           INT          NOT NULL AUTO_INCREMENT,
    workspace_id INT          NOT NULL,
    cliente_id   INT,
    nombre       VARCHAR(100) NOT NULL,
    color        CHAR(7)      NOT NULL DEFAULT '#3B8BD4',  -- hex color
    billable     TINYINT(1)   NOT NULL DEFAULT 0,
    archivado    TINYINT(1)   NOT NULL DEFAULT 0,
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_proyectos  PRIMARY KEY (id),
    CONSTRAINT fk_pr_ws      FOREIGN KEY (workspace_id) REFERENCES workspace(id)  ON DELETE CASCADE,
    CONSTRAINT fk_pr_cliente FOREIGN KEY (cliente_id)   REFERENCES clientes(id)   ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ────────────────────────────────────────
-- 6. TAREAS
-- ────────────────────────────────────────
CREATE TABLE tareas (
    id          INT          NOT NULL AUTO_INCREMENT,
    proyecto_id INT          NOT NULL,
    nombre      VARCHAR(150) NOT NULL,
    archivado   TINYINT(1)   NOT NULL DEFAULT 0,
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tareas    PRIMARY KEY (id),
    CONSTRAINT fk_ta_pr     FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ────────────────────────────────────────
-- 7. ETIQUETAS
-- ────────────────────────────────────────
CREATE TABLE etiquetas (
    id           INT         NOT NULL AUTO_INCREMENT,
    workspace_id INT         NOT NULL,
    nombre       VARCHAR(80) NOT NULL,
    color        CHAR(7)     NOT NULL DEFAULT '#1D9E75',
    CONSTRAINT pk_etiquetas PRIMARY KEY (id),
    CONSTRAINT fk_et_ws     FOREIGN KEY (workspace_id) REFERENCES workspace(id) ON DELETE CASCADE,
    CONSTRAINT uq_et_nombre UNIQUE (workspace_id, nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ────────────────────────────────────────
-- 8. REGISTROS_TIEMPO
-- ────────────────────────────────────────
CREATE TABLE registros_tiempo (
    id           INT          NOT NULL AUTO_INCREMENT,
    usuario_id   INT          NOT NULL,
    workspace_id INT          NOT NULL,
    proyecto_id  INT,
    tarea_id     INT,
    descripcion  VARCHAR(255),
    inicio       DATETIME     NOT NULL,
    fin          DATETIME,                        -- NULL = timer en curso
    duracion_seg INT GENERATED ALWAYS AS (
        CASE WHEN fin IS NOT NULL
             THEN TIMESTAMPDIFF(SECOND, inicio, fin)
             ELSE NULL
        END
    ) STORED,
    billable     TINYINT(1)   NOT NULL DEFAULT 0,
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_registros  PRIMARY KEY (id),
    CONSTRAINT fk_rt_usuario FOREIGN KEY (usuario_id)   REFERENCES usuarios(id)   ON DELETE RESTRICT,
    CONSTRAINT fk_rt_ws      FOREIGN KEY (workspace_id) REFERENCES workspace(id)   ON DELETE CASCADE,
    CONSTRAINT fk_rt_pr      FOREIGN KEY (proyecto_id)  REFERENCES proyectos(id)   ON DELETE SET NULL,
    CONSTRAINT fk_rt_ta      FOREIGN KEY (tarea_id)     REFERENCES tareas(id)      ON DELETE SET NULL,
    CONSTRAINT chk_fechas    CHECK (fin IS NULL OR fin >= inicio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ────────────────────────────────────────
-- 9. REGISTRO_ETIQUETAS  (N:M)
-- ────────────────────────────────────────
CREATE TABLE registro_etiquetas (
    registro_id INT NOT NULL,
    etiqueta_id INT NOT NULL,
    CONSTRAINT pk_re        PRIMARY KEY (registro_id, etiqueta_id),
    CONSTRAINT fk_re_reg    FOREIGN KEY (registro_id) REFERENCES registros_tiempo(id) ON DELETE CASCADE,
    CONSTRAINT fk_re_etq    FOREIGN KEY (etiqueta_id) REFERENCES etiquetas(id)        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ────────────────────────────────────────
-- ÍNDICES adicionales para rendimiento
-- ────────────────────────────────────────
CREATE INDEX idx_rt_usuario_ws   ON registros_tiempo (usuario_id, workspace_id);
CREATE INDEX idx_rt_inicio       ON registros_tiempo (inicio);
CREATE INDEX idx_rt_fin          ON registros_tiempo (fin);
CREATE INDEX idx_pr_ws           ON proyectos (workspace_id);
CREATE INDEX idx_wu_usuario      ON workspace_usuarios (usuario_id);