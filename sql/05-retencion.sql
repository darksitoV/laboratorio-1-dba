-- =============================================================================
-- LAB-01: Protección y Privacidad de Datos
-- Actividad 7: Retención y Ciclo de Vida de los Datos
-- Materia: Gestión de Seguridad y Desempeño de Bases de Datos
-- =============================================================================

\connect lab01_db;

-- 14.1 Inserción de registros históricos para validar la regla de retención (> 5 años)
-- Nota: Se insertan con fechas controladas en el pasado para demostrar la consulta.
INSERT INTO public.clientes 
(nombre, correo, telefono, rfc, edad, ciudad, codigo_postal, fecha_alta)
VALUES
('Roberto Mendoza Antiguo', 'roberto.mendoza@example.test', '6679998877', 'MEAR700101XYZ', 54, 'Culiacán', '80000', CURRENT_DATE - INTERVAL '6 years 3 months'),
('Beatriz Soto Histórico', 'beatriz.soto@example.test',     '6678887766', 'SOHB750202JKL', 49, 'Mazatlán', '82000', CURRENT_DATE - INTERVAL '5 years 8 months')
ON CONFLICT DO NOTHING;

-- 14.2 Consulta para identificar los registros que exceden el periodo de retención (5 años)
SELECT '--- REGISTROS CANDIDATOS A PURGA / DEPURACIÓN (SUPERAN 5 AÑOS) ---' AS reporte;

SELECT 
    id, 
    nombre, 
    correo, 
    rfc, 
    fecha_alta,
    AGE(CURRENT_DATE, fecha_alta) AS tiempo_en_sistema,
    (CURRENT_DATE - INTERVAL '5 years')::DATE AS fecha_corte_limite
FROM public.clientes 
WHERE fecha_alta < CURRENT_DATE - INTERVAL '5 years';

-- Conteo de registros activos vs registros sujetos a retención
SELECT 
    CASE 
        WHEN fecha_alta < CURRENT_DATE - INTERVAL '5 years' THEN 'Sujeto a Purga / Archivado (> 5 años)'
        ELSE 'Vigente / Operativo (<= 5 años)'
    END AS estado_retencion,
    COUNT(*) AS total_registros
FROM public.clientes
GROUP BY 1;

-- =============================================================================
-- 14.3 Esquema y Bitácora de Auditoría para Procedimientos de Depuración Segura
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS auditoria;

CREATE TABLE IF NOT EXISTS auditoria.bitacora_retencion (
    id BIGSERIAL PRIMARY KEY,
    tabla_afectada VARCHAR(100) NOT NULL,
    registros_identificados INT NOT NULL,
    fecha_evaluacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    politica_aplicada VARCHAR(150) NOT NULL,
    aprobado_por VARCHAR(100),
    hash_respaldo VARCHAR(64),
    estado VARCHAR(30) DEFAULT 'IDENTIFICADO'
);

-- Registrar la identificación formal en la bitácora de auditoría
INSERT INTO auditoria.bitacora_retencion 
(tabla_afectada, registros_identificados, politica_aplicada, aprobado_por, estado)
SELECT 
    'public.clientes',
    COUNT(*),
    'Regla Retención LFPDPPP Art. 11 / Política Interna 5 Años',
    'Oficial de Privacidad (DPO) & DBA Lead',
    'PENDIENTE_APROBACION_Y_BACKUP'
FROM public.clientes 
WHERE fecha_alta < CURRENT_DATE - INTERVAL '5 years';

SELECT * FROM auditoria.bitacora_retencion;

-- RECORDATORIO CRÍTICO DE SEGURIDAD:
-- NO ejecutar DELETE sobre la tabla principal en esta fase.
-- La eliminación física requiere:
-- 1. Snapshot / pg_dump verificado del esquema.
-- 2. Firma y aprobación formal del área jurídica y DPO.
-- 3. Transacción ACID con bitácora criptográfica del evento.
