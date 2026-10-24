# LAB-01 — Protección y Privacidad de Datos

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
**Unidad:** II — Seguridad, privacidad y control de acceso  
**Tema:** 2.3 — Datos sensibles, privacidad y protección de la información  
**Motor:** PostgreSQL 16 (Podman)  
**Estudiante:** darksitoV  
**Organización Evaluada:** Comercializadora Norte S.A. de C.V.  

---

## 🎯 Objetivo del Laboratorio

Aplicar mecanismos avanzados de protección de datos en PostgreSQL 16 de acuerdo con el propósito y nivel de acceso requerido por diferentes áreas de una organización (Soporte, Analítica, Dirección y DBA), implementando:

1. **Clasificación de datos** (identificadores directos vs cuasi-identificadores).
2. **Enmascaramiento dinámico (Data Masking)** mediante vistas seguras.
3. **Control de acceso basado en roles (RBAC)** aplicando el principio de mínimo privilegio.
4. **Seudonimización (Pseudonymization)** con tokens criptográficos UUID v4 y aislamiento de esquemas (`pii` y `analitica`).
5. **Separación de funciones (Separation of Duties)** entre analistas y custodios de identidad.
6. **Anonimización estadística** (generalización de atributos, agregación y supresión de microgrupos $k \ge 5$).
7. **Retención de datos y ciclo de vida** con identificación de expiración y auditoría previa a purga.

---

## 📂 Estructura del Repositorio

El repositorio mantiene la estructura reglamentaria y limpia de la práctica (Sección 16 del documento del laboratorio):

```text
laboratorio-1-dba/
├── .gitignore                          # Configuración de archivos excluidos de Git
├── README.md                           # Documentación general e instrucciones de despliegue
├── informe.md                          # Informe técnico completo con respuestas a todas las preguntas
├── sql/                                # Scripts SQL modulares y documentados
│   ├── 01-clasificacion.sql            # Preparación de tabla clientes + metadatos y clasificación
│   ├── 02-enmascaramiento.sql          # Rol soporte, vista v_clientes_soporte y validación de seguridad
│   ├── 03-seudonimizacion.sql          # Esquemas pii/analitica, pgcrypto, tokens UUID y mapa_cliente
│   ├── 04-anonimizacion.sql            # Rol analista, SoD, generalización, supresión y reto de privacidad
│   └── 05-retencion.sql                # Regla de retención (> 5 años), registros históricos y bitácora
└── evidencias/                         # Guía y plantillas para generación de PDFs
    ├── GUIA_EVIDENCIAS.md              # Instrucciones paso a paso para capturar evidencias
    ├── 01-clasificacion.md             # Plantilla de evidencia 01 (exportable a PDF)
    ├── 02-enmascaramiento.md           # Plantilla de evidencia 02 (exportable a PDF)
    ├── 03-seudonimizacion.md           # Plantilla de evidencia 03 (exportable a PDF)
    ├── 04-anonimizacion.md             # Plantilla de evidencia 04 (exportable a PDF)
    └── 05-retencion.md                 # Plantilla de evidencia 05 (exportable a PDF)
```

---

## ⚙️ Requisitos y Despliegue con Podman

### Prerrequisitos
* **Podman** instalado en Windows.
* **Git** instalado.

### 1. Iniciar el motor PostgreSQL 16
Abre tu terminal (PowerShell o CMD) en la carpeta raíz del proyecto y ejecuta:

```powershell
# Iniciar la máquina virtual de Podman (si está detenida)
podman machine start

# Iniciar el contenedor oficial de PostgreSQL 16
podman run -d --name postgres_lab01 -p 5432:5432 -e POSTGRES_DB=lab01_db -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgrespassword -v "c:\Users\darks\OneDrive\Escritorio\dba\laboratorio-1-dba\sql:/sql:ro" docker.io/library/postgres:16-alpine
```

### 2. Verificar el contenedor
```powershell
podman ps
```
Deberás ver `postgres_lab01` activo escuchando en el puerto estándar `5432`.

---

## 💻 Ejecución de Scripts y Pruebas en PSQL

Para conectarte a la consola interactiva `psql` dentro del contenedor:

```powershell
podman exec -it postgres_lab01 psql -U postgres -d lab01_db
```

Dentro de `psql`, puedes ejecutar cada actividad en orden:

```sql
\i /sql/01-clasificacion.sql
\i /sql/02-enmascaramiento.sql
\i /sql/03-seudonimizacion.sql
\i /sql/04-anonimizacion.sql
\i /sql/05-retencion.sql
```

---

## 📸 Guía para Captura y Entrega de Evidencias

La rúbrica exige la entrega de 5 archivos en formato PDF dentro de la carpeta `evidencias/`:
1. `01-clasificacion.pdf`: Evidencia de estructura de `clientes`, inserción y diccionario de datos clasificados.
2. `02-enmascaramiento.pdf`: Evidencia de consulta permitida a `v_clientes_soporte` y el **mensaje de error de permisos** al intentar consultar `clientes` como rol `soporte`.
3. `03-seudonimizacion.pdf`: Evidencia de la tabla `pii.mapa_cliente` con tokens UUID y la tabla `analitica.clientes`.
4. `04-anonimizacion.pdf`: Evidencia de permisos de `analista` (permitido en analítica, denegado en pii/public), consultas de generalización, supresión con `HAVING COUNT(*) >= 5` y el reto de mitigación de reidentificación.
5. `05-retencion.pdf`: Evidencia de la consulta identificando clientes de más de 5 años y el registro en la bitácora de auditoría.

> Consulta la guía paso a paso en [evidencias/GUIA_EVIDENCIAS.md](file:///c:/Users/darks/OneDrive/Escritorio/dba/laboratorio-1-dba/evidencias/GUIA_EVIDENCIAS.md) para ver las instrucciones detalladas de comandos y capturas.

---

## 📊 Matriz de Evaluación

| Criterio | Porcentaje | Cumplimiento en este Repo |
| :--- | :---: | :--- |
| Clasificación y análisis de datos | 15 % | ✅ Completo en `sql/01-clasificacion.sql` e `informe.md` |
| Enmascaramiento y control de acceso | 20 % | ✅ Completo en `sql/02-enmascaramiento.sql` e `informe.md` |
| Seudonimización y separación de funciones | 20 % | ✅ Completo en `sql/03-seudonimizacion.sql` y `04-anonimizacion.sql` |
| Anonimización y análisis de reidentificación | 25 % | ✅ Completo en `sql/04-anonimizacion.sql` (incluye Reto) |
| Retención de datos | 10 % | ✅ Completo en `sql/05-retencion.sql` e `informe.md` |
| Evidencias y documentación | 10 % | ✅ Plantillas, scripts y guía detallada en `evidencias/` |
| **Total** | **100 %** |  |
