# AsistenciaGM – Backend

Sistema de registro de asistencia/tiempo inspirado en Clockify.
Stack: Java 11 · MySQL 8.0 (Aiven) · NetBeans 14.

---

## Estructura del proyecto

```
AsistenciaGM/
├── sql/
│   ├── 01_schema.sql              ← Tablas (ejecutar primero)
│   └── 02_stored_procedures.sql   ← Stored procedures
│
└── src/asistenciagm/
    ├── config/
    │   └── ConnectionPool.java    ← Pool de conexiones JDBC
    ├── constant/
    │   └── Constantes.java        ← URLs, nombres de SP, roles
    ├── exception/
    │   ├── AsistenciaGMException.java
    │   ├── ConexionException.java
    │   ├── DAOException.java
    │   ├── EntidadNoEncontradaException.java
    │   └── NegocioException.java
    ├── model/
    │   ├── Usuario.java
    │   ├── Workspace.java
    │   ├── Cliente.java
    │   ├── Proyecto.java
    │   ├── Tarea.java
    │   ├── Etiqueta.java
    │   ├── RegistroTiempo.java
    │   ├── ResumenPanel.java      ← DTO panel
    │   └── InformeProyecto.java   ← DTO informe
    ├── dao/
    │   ├── UsuarioDAO.java
    │   ├── WorkspaceDAO.java
    │   ├── ClienteDAO.java
    │   ├── ProyectoDAO.java
    │   ├── TareaDAO.java
    │   ├── EtiquetaDAO.java
    │   ├── RegistroTiempoDAO.java
    │   └── impl/
    │       ├── UsuarioDAOImpl.java
    │       ├── WorkspaceDAOImpl.java
    │       ├── ClienteDAOImpl.java
    │       ├── ProyectoDAOImpl.java
    │       ├── TareaDAOImpl.java
    │       ├── EtiquetaDAOImpl.java
    │       └── RegistroTiempoDAOImpl.java
    ├── service/
    │   ├── AuthService.java
    │   ├── WorkspaceService.java
    │   ├── ProyectoService.java
    │   ├── ClienteService.java
    │   ├── EtiquetaService.java
    │   ├── TimerService.java
    │   ├── ServiceFactory.java    ← Punto de entrada para el frontend
    │   └── impl/
    │       ├── AuthServiceImpl.java
    │       ├── WorkspaceServiceImpl.java
    │       ├── ProyectoServiceImpl.java
    │       ├── ClienteServiceImpl.java
    │       ├── EtiquetaServiceImpl.java
    │       └── TimerServiceImpl.java
    └── util/
        ├── SeguridadUtil.java     ← Hash PBKDF2 de contraseñas
        ├── ValidacionUtil.java    ← Validaciones reutilizables
        └── DuracionUtil.java      ← Formato HH:mm:ss, texto legible
```

---

## Configuración inicial

### 1. Base de datos (Workbench + Aiven)

1. Abre MySQL Workbench conectado a tu instancia Aiven.
2. Selecciona la BD `asistenciaGM`.
3. Ejecuta `sql/01_schema.sql` completo (borra y recrea todas las tablas).
4. Ejecuta `sql/02_stored_procedures.sql` completo.

### 2. Credenciales

Edita `src/asistenciagm/constant/Constantes.java`:

```java
public static final String DB_HOST     = "tu-host.aivencloud.com";
public static final int    DB_PORT     = 3306;
public static final String DB_USER     = "tu_usuario";
public static final String DB_PASSWORD = "tu_password";
```

### 3. Driver MySQL en NetBeans

1. Click derecho en el proyecto → Properties → Libraries.
2. Add JAR/Folder → selecciona `mysql-connector-j-8.x.x.jar`.
   Descarga desde: https://dev.mysql.com/downloads/connector/j/

---

## Uso desde el frontend

El equipo de frontend solo necesita importar `ServiceFactory`:

```java
import asistenciagm.service.ServiceFactory;
import asistenciagm.model.*;

// ── Autenticación ────────────────────────────────────────────
Usuario usuario = ServiceFactory.auth().login("email@ejemplo.com", "password");

// ── Workspace ────────────────────────────────────────────────
Workspace ws = ServiceFactory.workspace().crear("Mi Empresa", "Descripción", usuario.getId());
List<Workspace> misWs = ServiceFactory.workspace().listarPorUsuario(usuario.getId());

// ── Proyectos ────────────────────────────────────────────────
Proyecto p = ServiceFactory.proyecto().crear(ws.getId(), null, "App Mobile", "#3B8BD4", true);
List<Proyecto> proyectos = ServiceFactory.proyecto().listar(ws.getId(), false);

// ── Rastreador ───────────────────────────────────────────────
RegistroTiempo timer = ServiceFactory.timer()
    .iniciarTimer(usuario.getId(), ws.getId(), p.getId(), null, "Desarrollo login", true);

// ... el usuario trabaja ...

ServiceFactory.timer().detenerTimer(timer.getId(), usuario.getId());

// ── Panel ────────────────────────────────────────────────────
List<ResumenPanel> panel = ServiceFactory.timer()
    .resumenPanel(ws.getId(), null, LocalDate.now().withDayOfMonth(1), LocalDate.now());

// ── Informes ─────────────────────────────────────────────────
List<RegistroTiempo> detalle = ServiceFactory.timer()
    .informeDetallado(ws.getId(), null, null,
        LocalDate.now().minusDays(7), LocalDate.now());

List<InformeProyecto> porProyecto = ServiceFactory.timer()
    .informePorProyecto(ws.getId(), LocalDate.now().minusDays(30), LocalDate.now());
```

---

## Módulos y sus servicios

| Módulo      | Servicio           | Funciones principales                            |
|-------------|--------------------|-------------------------------------------------|
| Rastreador  | `TimerService`     | iniciarTimer, detenerTimer, timerActivo          |
| Panel       | `TimerService`     | resumenPanel (totales por usuario y periodo)     |
| Informe     | `TimerService`     | informeDetallado, informePorProyecto             |
| Proyectos   | `ProyectoService`  | crear, listar, archivar, tareas                  |
| Equipo      | `WorkspaceService` | listarEquipo, agregarMiembro, removerMiembro     |
| Clientes    | `ClienteService`   | crear, listar, actualizar, archivar              |
| Etiquetas   | `EtiquetaService`  | crear, listar, eliminar, toggleEnRegistro        |
| Auth        | `AuthService`      | login, registrar, cambiarPassword                |

---

## Manejo de excepciones

Todas las excepciones heredan de `AsistenciaGMException` (RuntimeException):

| Excepción                       | Cuándo se lanza                                  |
|---------------------------------|--------------------------------------------------|
| `NegocioException`              | Regla de negocio violada (validaciones, lógica)  |
| `EntidadNoEncontradaException`  | Búsqueda por id sin resultados                   |
| `DAOException`                  | Error SQL en la capa DAO                         |
| `ConexionException`             | Fallo en el pool de conexiones                   |

En el frontend, captura la excepción base para manejar cualquier error:

```java
try {
    ServiceFactory.timer().iniciarTimer(...);
} catch (NegocioException e) {
    // Mostrar mensaje al usuario
    JOptionPane.showMessageDialog(null, e.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
} catch (AsistenciaGMException e) {
    // Error técnico
    JOptionPane.showMessageDialog(null, "Error interno: " + e.getMessage());
}
```

---

## Notas de seguridad

- Las contraseñas se almacenan con **PBKDF2-HMAC-SHA256** (310,000 iteraciones).
- La conexión a Aiven usa **SSL/TLS** (`useSSL=true` en la URL JDBC).
- El hash de la contraseña se limpia del objeto `Usuario` después del login.
