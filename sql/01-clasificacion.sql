-- =============================================================================
-- LAB-01: Protección y Privacidad de Datos
-- Actividad 1: Preparación de la Base de Datos y Clasificación de los Datos
-- Materia: Gestión de Seguridad y Desempeño de Bases de Datos
-- Motor: PostgreSQL 16
-- =============================================================================

\connect lab01_db;

-- -----------------------------------------------------------------------------
-- 6.1 Crear la tabla clientes (Preparación de la Base de Datos)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS public.clientes CASCADE;

CREATE TABLE public.clientes (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    correo VARCHAR(150) NOT NULL,
    telefono VARCHAR(20),
    rfc VARCHAR(13),
    edad INTEGER,
    ciudad VARCHAR(80),
    codigo_postal VARCHAR(10),
    fecha_alta DATE DEFAULT CURRENT_DATE
);

-- -----------------------------------------------------------------------------
-- 6.2 Insertar datos de prueba institucionales
-- -----------------------------------------------------------------------------
INSERT INTO public.clientes 
(nombre, correo, telefono, rfc, edad, ciudad, codigo_postal)
VALUES
('Ana López',     'ana.lopez@example.test',     '6671234567', 'LOAA850315ABC', 41, 'Culiacán',   '80000'),
('Carlos Pérez',  'carlos.perez@example.test',  '6672345678', 'PECA900720DEF', 35, 'Culiacán',   '80100'),
('María García',  'maria.garcia@example.test',  '6673456789', 'GAMA780912GHI', 47, 'Mazatlán',   '82000'),
('Luis Torres',   'luis.torres@example.test',   '6674567890', 'TOLU920201JKL', 34, 'Los Mochis', '81200'),
('Laura Sánchez', 'laura.sanchez@example.test', '6675678901', 'SALA880525MNO', 38, 'Culiacán',   '80200');

-- Verificar estructura y registros
\d public.clientes;

SELECT * FROM public.clientes;

-- -----------------------------------------------------------------------------
-- 7. Documentación de la clasificación formal mediante metadatos (COMMENT ON COLUMN)
-- -----------------------------------------------------------------------------
COMMENT ON COLUMN public.clientes.id IS 
'Identificador interno técnico. Directo en el contexto de la base de datos. Requiere control de acceso e integridad.';

COMMENT ON COLUMN public.clientes.nombre IS 
'Dato Personal - Identificador Directo. Permite asociar la identidad legal de la persona física. Nivel de Protección: ALTO.';

COMMENT ON COLUMN public.clientes.correo IS 
'Dato Personal de Contacto - Identificador Directo. Permite identificación y contacto individual. Nivel de Protección: ALTO.';

COMMENT ON COLUMN public.clientes.telefono IS 
'Dato Personal de Contacto - Identificador Directo. Línea unívoca de comunicación directa. Nivel de Protección: ALTO.';

COMMENT ON COLUMN public.clientes.rfc IS 
'Identificador Oficial Fiscal - Identificador Directo y Unívoco Nacional (México). Nivel de Protección: CRÍTICO.';

COMMENT ON COLUMN public.clientes.edad IS 
'Dato Demográfico - Cuasi-identificador. No identifica solo, pero reduce drásticamente el espacio de búsqueda. Nivel de Protección: MEDIO (Generalización).';

COMMENT ON COLUMN public.clientes.ciudad IS 
'Dato Geográfico - Cuasi-identificador. Delimita residencia o ubicación de operación. Nivel de Protección: MEDIO (Generalización).';

COMMENT ON COLUMN public.clientes.codigo_postal IS 
'Dato Geográfico de Alta Precisión - Cuasi-identificador de alto riesgo. Aisla áreas reducidas. Nivel de Protección: ALTO (Generalización / Supresión).';

COMMENT ON COLUMN public.clientes.fecha_alta IS 
'Metadato Operativo / Temporal - Cuasi-identificador temporal y criterio de la política de ciclo de vida / retención.';

-- -----------------------------------------------------------------------------
-- Consulta del Diccionario de Datos con las Clasificaciones Registradas
-- -----------------------------------------------------------------------------
SELECT 
    cols.column_name AS campo,
    cols.data_type AS tipo_dato,
    cols.is_nullable AS nulo,
    pg_catalog.col_description(c.oid, cols.ordinal_position::int) AS clasificacion_y_politica
FROM information_schema.columns cols
JOIN pg_catalog.pg_class c ON c.relname = cols.table_name
JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE cols.table_name = 'clientes' 
  AND n.nspname = 'public'
ORDER BY cols.ordinal_position;

-- -----------------------------------------------------------------------------
-- Análisis exploratorio de singularidad de atributos (Cuasi-identificadores)
-- -----------------------------------------------------------------------------
SELECT 
    ciudad, 
    codigo_postal, 
    edad, 
    COUNT(*) AS cantidad_individuos
FROM public.clientes
GROUP BY ciudad, codigo_postal, edad
ORDER BY cantidad_individuos ASC;
