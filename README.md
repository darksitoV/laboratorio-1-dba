# LAB-01 — Protección y Privacidad de Datos

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
**Unidad:** II — Seguridad, privacidad y control de acceso  
**Tema:** 2.3 — Datos sensibles, privacidad y protección de la información  
**Motor:** PostgreSQL 16  
**Estudiante:** darksitoV  
**Organización Evaluada:** Comercializadora Norte S.A. de C.V.  

---

## 1. Descripción de la Práctica
Este repositorio contiene la implementación técnica del **Laboratorio 01: Protección y Privacidad de Datos** en PostgreSQL 16 para la empresa ficticia *Comercializadora Norte S.A. de C.V.*. 

El objetivo es aplicar mecanismos de protección adecuados para distintos roles organizacionales (Soporte, Analítica, Dirección y DBA), garantizando el principio de mínimo privilegio y minimización de datos:
* **Clasificación de datos:** Identificación de identificadores directos y cuasi-identificadores.
* **Enmascaramiento dinámico:** Vistas con ofuscación parcial para soporte técnico y restricción sobre tablas base.
* **Seudonimización:** Generación de identificadores sustitutos (tokens UUID v4 con `pgcrypto`) y aislamiento de esquemas (`pii` y `analitica`).
* **Separación de funciones (SoD):** Aislamiento de permisos para analítica, impidiendo el acceso a la tabla de correspondencia.
* **Anonimización estadística:** Generalización etaria/geográfica y supresión de microgrupos ($k \ge 5$) para dirección.
* **Retención de datos:** Identificación de registros que exceden el ciclo de conservación (5 años) y registro en bitácora de auditoría.

---

## 2. Estructura del Repositorio

Conforme a lo especificado en la Sección 16 del documento del laboratorio:

```text
laboratorio-1-dba/
├── README.md                           # Presentación del proyecto y contexto
├── informe.md                          # Informe técnico con matrices, justificaciones y preguntas de reflexión
├── sql/                                # Scripts SQL por actividad
│   ├── 01-clasificacion.sql            # Preparación de tabla clientes + metadatos y clasificación
│   ├── 02-enmascaramiento.sql          # Rol soporte, vista v_clientes_soporte y validación de permisos
│   ├── 03-seudonimizacion.sql          # Esquemas pii/analitica, tokens UUID y mapa_cliente
│   ├── 04-anonimizacion.sql            # Rol analista, SoD, generalización, supresión y reto
│   └── 05-retencion.sql                # Consulta de retención (> 5 años) y bitácora de auditoría
└── evidencias/                         # Documentos PDF con las capturas de ejecución
    ├── 01-clasificacion.pdf            # Evidencia de preparación y clasificación
    ├── 02-enmascaramiento.pdf          # Evidencia de vista enmascarada y acceso denegado
    ├── 03-seudonimizacion.pdf          # Evidencia de tabla puente y dataset analítico
    ├── 04-anonimizacion.pdf            # Evidencia de separación de funciones y anonimización
    └── 05-retencion.pdf                # Evidencia de retención y bitácora
```
