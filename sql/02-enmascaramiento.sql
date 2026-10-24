-- =============================================================================
-- LAB-01: Protección y Privacidad de Datos
-- Actividad 2: Enmascaramiento Dinámico mediante Vistas (Masking)
-- Materia: Gestión de Seguridad y Desempeño de Bases de Datos
-- =============================================================================

\connect lab01_db;

-- 8.1 Crear el rol para el personal de soporte técnico
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'soporte') THEN
        CREATE ROLE soporte NOLOGIN;
    END IF;
    -- Usuario interactivo para pruebas de conexión si se requiere sesión directa
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'usr_soporte') THEN
        CREATE USER usr_soporte WITH PASSWORD 'SoportePass123!';
        GRANT soporte TO usr_soporte;
    END IF;
END $$;

-- 8.2 Crear vista de acceso restringido con enmascaramiento parcial
CREATE OR REPLACE VIEW public.v_clientes_soporte AS 
SELECT  
    id,  
    nombre,
    CONCAT(
        LEFT(correo, 2), 
        '*****', 
        SUBSTRING(correo FROM POSITION('@' IN correo))
    ) AS correo,
    CONCAT('******', RIGHT(telefono, 4)) AS telefono,  
    CONCAT('*********', RIGHT(rfc, 4)) AS rfc 
FROM public.clientes;

-- Comentario documental en la vista
COMMENT ON VIEW public.v_clientes_soporte IS 
'Vista controlada para soporte técnico. Enmascara datos sensibles de contacto y fiscales, preservando nombre e id para atención.';

-- 8.3 Conceder acceso a la vista y revocar acceso a la tabla original
GRANT USAGE ON SCHEMA public TO soporte;  
GRANT SELECT ON public.v_clientes_soporte TO soporte;

-- Revocación explícita sobre la tabla base
REVOKE ALL ON public.clientes FROM soporte;

-- =============================================================================
-- 8.4 Pruebas de Verificación y Demostración de Seguridad
-- =============================================================================

-- A) Consulta como administrador (DBA / postgres)
SELECT '--- CONSULTA COMO ADMINISTRADOR (TABLA ORIGINAL) ---' AS contexto;
SELECT id, nombre, correo, telefono, rfc FROM public.clientes;

-- B) Cambiar contexto de seguridad al rol 'soporte'
SET ROLE soporte;
SELECT CURRENT_USER, CURRENT_ROLE;

-- B.1) Consulta a la vista enmascarada (DEBE FUNCIONAR)
SELECT '--- CONSULTA COMO ROL SOPORTE (VISTA ENMASCARADA - EXITOSA) ---' AS contexto;
SELECT * FROM public.v_clientes_soporte;

-- B.2) Intento de consulta directa a la tabla original (DEBE FALLAR CON ERROR DE PERMISOS)
-- Descomentar o ejecutar la siguiente línea en psql para registrar la evidencia del rechazo:
-- SELECT * FROM public.clientes;

-- Restaurar el rol administrativo
RESET ROLE;
SELECT '--- ROL RESTAURADO A ADMINISTRADOR ---' AS contexto;
SELECT CURRENT_USER, CURRENT_ROLE;
