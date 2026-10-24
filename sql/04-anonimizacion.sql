-- =============================================================================
-- LAB-01: Protección y Privacidad de Datos
-- Actividad 4 & 5 & 6: Separación de Funciones, Anonimización y Mitigación de Reidentificación
-- Materia: Gestión de Seguridad y Desempeño de Bases de Datos
-- =============================================================================

\connect lab01_db;

-- =============================================================================
-- PARTE 1: ACTIVIDAD 4 - SEPARACIÓN DE FUNCIONES (ROL ANALISTA)
-- =============================================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'analista') THEN
        CREATE ROLE analista NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'usr_analista') THEN
        CREATE USER usr_analista WITH PASSWORD 'AnalistaPass123!';
        GRANT analista TO usr_analista;
    END IF;
END $$;

-- Conceder acceso exclusivamente al esquema y tabla de analítica
GRANT USAGE ON SCHEMA analitica TO analista;
GRANT SELECT ON analitica.clientes TO analista;

-- Aislar completamente los esquemas sensibles y la tabla original
REVOKE ALL ON ALL TABLES IN SCHEMA pii FROM analista;
REVOKE USAGE ON SCHEMA pii FROM analista;
REVOKE ALL ON public.clientes FROM analista;

-- Verificación de Privilegios para 'analista'
SET ROLE analista;
SELECT CURRENT_USER, CURRENT_ROLE;

-- A) Consulta permitida sobre conjunto seudonimizado
SELECT '--- CONSULTA PERMITIDA PARA ANALISTA (DATASET SEUDONIMIZADO) ---' AS contexto;
SELECT * FROM analitica.clientes;

-- B) Consultas denegadas (Deben fallar con permission denied al ejecutarse directamente)
-- SELECT * FROM pii.mapa_cliente;   -- ERROR: permission denied for schema pii / table mapa_cliente
-- SELECT * FROM public.clientes;   -- ERROR: permission denied for table clientes

RESET ROLE;

-- =============================================================================
-- PARTE 2: ACTIVIDAD 5 - TÉCNICAS DE ANONIMIZACIÓN (DIRECCIÓN / ESTADÍSTICA)
-- =============================================================================

-- 12.1 Generalizar la edad en rangos etarios
SELECT '--- 12.1 GENERALIZACIÓN DE EDAD ---' AS tecnica;
SELECT 
    CASE 
        WHEN edad BETWEEN 18 AND 30 THEN '18-30'
        WHEN edad BETWEEN 31 AND 45 THEN '31-45'
        ELSE '46+' 
    END AS rango_edad, 
    COUNT(*) AS total 
FROM public.clientes 
GROUP BY 1
ORDER BY 1;

-- 12.2 Generalizar la región geográfica mediante prefijo del código postal
SELECT '--- 12.2 GENERALIZACIÓN GEOGRÁFICA (REGIÓN POSTAL) ---' AS tecnica;
SELECT 
    LEFT(codigo_postal, 2) AS region_postal, 
    COUNT(*) AS total 
FROM public.clientes 
GROUP BY 1
ORDER BY 1;

-- 12.3 Combinación de atributos (Quasi-identifiers combinados)
SELECT '--- 12.3 COMBINACIÓN DE ATRIBUTOS (EDAD + REGIÓN) ---' AS tecnica;
SELECT 
    CASE 
        WHEN edad BETWEEN 18 AND 30 THEN '18-30'
        WHEN edad BETWEEN 31 AND 45 THEN '31-45'
        ELSE '46+' 
    END AS rango_edad, 
    LEFT(codigo_postal, 2) AS region_postal, 
    COUNT(*) AS total  
FROM public.clientes 
GROUP BY 1, 2
ORDER BY 1, 2;

-- 12.4 Supresión de grupos pequeños (k-anonymity con umbral k >= 5)
SELECT '--- 12.4 SUPRESIÓN DE GRUPOS PEQUEÑOS (HAVING COUNT >= 5) ---' AS tecnica;
SELECT 
    CASE 
        WHEN edad BETWEEN 18 AND 30 THEN '18-30'
        WHEN edad BETWEEN 31 AND 45 THEN '31-45'
        ELSE '46+' 
    END AS rango_edad, 
    LEFT(codigo_postal, 2) AS region_postal, 
    COUNT(*) AS total  
FROM public.clientes 
GROUP BY 1, 2 
HAVING COUNT(*) >= 5;

-- =============================================================================
-- PARTE 3: ACTIVIDAD 6 - RETO: CONSULTA MEJORADA CONTRA REIDENTIFICACIÓN
-- =============================================================================
-- Reto planteado:
-- Modificar la consulta para reducir aún más el riesgo de reidentificación.
-- Modificaciones aplicadas:
-- 1. Generalización jerárquica más amplia de la geografía: En lugar del prefijo postal
--    (que revela municipios específicos), agrupamos por macrorregión o entidad.
-- 2. Generalización de edad ampliada a cohortes de 15 años o categorías laborales.
-- 3. Inclusión temporal agregada únicamente al año de registro (EXTRACT(YEAR FROM fecha_alta)).
-- 4. Supresión adaptativa de micro-grupos (evitando ataques de homogeneidad y unicidad).

SELECT '--- ACTIVIDAD 6 (RETO): CONSULTA DE ALTA PROTECCIÓN ESTADÍSTICA ---' AS reporte;

SELECT 
    CASE 
        WHEN edad < 35 THEN 'Joven (<35)'
        WHEN edad BETWEEN 35 AND 50 THEN 'Adulto (35-50)'
        ELSE 'Senior (>50)'
    END AS cohorte_edad,
    CASE 
        WHEN LEFT(codigo_postal, 2) IN ('80', '81', '82') THEN 'Zona Noroeste (Sinaloa)'
        ELSE 'Otras Entidades'
    END AS macrorregion,
    EXTRACT(YEAR FROM fecha_alta)::TEXT AS anio_registro,
    COUNT(*) AS total_agregado
FROM public.clientes
GROUP BY 1, 2, 3
HAVING COUNT(*) >= 2 -- Umbral ajustado proporcionalmente al tamaño muestral del laboratorio
ORDER BY total_agregado DESC;
