-- =============================================================================
-- LAB-01: Protección y Privacidad de Datos
-- Actividad 3: Seudonimización (Pseudonymization) y Aislamiento de PII
-- Materia: Gestión de Seguridad y Desempeño de Bases de Datos
-- =============================================================================

\connect lab01_db;

-- 9.1 Crear los esquemas para aislamiento lógico de responsabilidades
CREATE SCHEMA IF NOT EXISTS pii;
CREATE SCHEMA IF NOT EXISTS analitica;

COMMENT ON SCHEMA pii IS 
'Esquema de alta confidencialidad que resguarda datos de identidad directa y mapas de correspondencia de tokens.';

COMMENT ON SCHEMA analitica IS 
'Esquema para analítica de datos, investigación y modelado estadístico sin PII directa.';

-- 9.2 Crear la tabla de correspondencia protegida
DROP TABLE IF EXISTS pii.mapa_cliente CASCADE;

CREATE TABLE pii.mapa_cliente (
    token UUID PRIMARY KEY,
    cliente_id BIGINT UNIQUE REFERENCES public.clientes(id) ON DELETE CASCADE,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE pii.mapa_cliente IS 
'Tabla puente de correspondencia token <-> id original. Acceso estrictamente restringido a sistemas autorizados.';

-- 9.3 Habilitar la extensión criptográfica para generar tokens UUID v4 seguros
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Generar un token único e impredecible para cada cliente
INSERT INTO pii.mapa_cliente (token, cliente_id)
SELECT gen_random_uuid(), id 
FROM public.clientes
ORDER BY id;

-- Verificación de la tabla de correspondencia
SELECT 
    token, 
    cliente_id, 
    creado_en 
FROM pii.mapa_cliente;

-- =============================================================================
-- 10. Crear el conjunto de datos para analítica (Sin identificadores directos)
-- =============================================================================

DROP TABLE IF EXISTS analitica.clientes CASCADE;

CREATE TABLE analitica.clientes AS 
SELECT  
    m.token AS cliente_token,  
    c.edad,  
    c.ciudad,  
    c.codigo_postal,  
    c.fecha_alta  
FROM pii.mapa_cliente m  
JOIN public.clientes c ON c.id = m.cliente_id;

-- Agregar restricciones de integridad sobre la tabla de analítica
ALTER TABLE analitica.clientes ADD CONSTRAINT pk_analitica_clientes PRIMARY KEY (cliente_token);

COMMENT ON TABLE analitica.clientes IS 
'Dataset seudonimizado para análisis y patrones demográficos. No expone nombre, correo, teléfono ni RFC.';

-- Verificar el dataset analítico resultante
SELECT * FROM analitica.clientes;
