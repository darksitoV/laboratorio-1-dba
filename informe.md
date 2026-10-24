# INFORME TÉCNICO: LABORATORIO 01 — PROTECCIÓN Y PRIVACIDAD DE DATOS

* **Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
* **Unidad:** II — Seguridad, privacidad y control de acceso  
* **Tema:** 2.3 — Datos sensibles, privacidad y protección de la información  
* **Motor:** PostgreSQL 16 (Desplegado en Contenedores Podman)  
* **Alumno:** Genaro Isaac Cárdenas Soto (@darksitoV)  
* **Organización / Escenario:** Comercializadora Norte S.A. de C.V.  

---

## 1. INTRODUCCIÓN Y CONTEXTO OPERATIVO

El presente laboratorio aborda el diseño e implementación de controles técnicos de privacidad y protección de datos en PostgreSQL 16 para la empresa *Comercializadora Norte S.A. de C.V.*. A través de este ejercicio, se demuestra que **no existe una única técnica de protección aplicable a todos los casos de uso**, sino que la seguridad debe estructurarse en capas complementarias: clasificación, enmascaramiento dinámico, seudonimización, anonimización estadística, control de acceso basado en roles (RBAC) y políticas de ciclo de vida / retención.

---

## 2. ACTIVIDAD 1 — CLASIFICACIÓN DE LOS DATOS

### 2.1 Matriz de Clasificación de Atributos (`clientes`)

| Campo | ¿Identifica directamente? | ¿Puede contribuir a identificar? (Cuasi-identificador) | ¿Requiere protección? | Justificación Técnica y Regulatoria |
| :--- | :---: | :---: | :---: | :--- |
| **id** | Sí (Internamente) | Sí | Sí | Clave primaria autonumérica. En el contexto interno de la empresa identifica de forma unívoca el expediente del cliente. Requiere control de acceso e integridad referencial. |
| **nombre** | Sí | N/A | Sí | **Identificador directo principal**. Permite individualizar a la persona física en cualquier contexto social, legal y operativo. Alto riesgo de suplantación. |
| **correo** | Sí | N/A | Sí | **Identificador directo y dato de contacto unívoco**. Asociable a cuentas de usuario y comunicaciones privadas. Vulnerable a ataques de phishing y perfilado. |
| **telefono** | Sí | N/A | Sí | **Identificador directo y canal de contacto**. Permite geolocalización aproximada, contacto no deseado e ingeniería social. |
| **rfc** | Sí | N/A | Sí | **Identificador oficial unívoco en México**. Contiene fecha de nacimiento, iniciales y homoclave. Es un dato crítico cuyo compromiso facilita el robo de identidad fiscal. |
| **edad** | No | Sí | Sí (Generalización) | **Cuasi-identificador demográfico**. Por sí solo no individualiza, pero combinado con ubicación reduce el universo de búsqueda (*k-anonymity* bajo). |
| **ciudad** | No | Sí | Sí (Generalización) | **Cuasi-identificador geográfico**. Delimita la región de residencia. En ciudades con baja densidad demográfica el riesgo de singularidad se dispara. |
| **codigo_postal** | No | Sí | Sí (Supresión / Generalización) | **Cuasi-identificador geográfico de alta precisión**. Aisla colonias o zonas de unas cuantas cuadras; combinado con edad o ciudad individualiza casi al 100%. |
| **fecha_alta** | No | Sí | Sí (Auditoría / Retención) | **Metadato operativo y temporal**. Puede asociarse a eventos externos (promociones, facturación) y define la vigencia legal del expediente según la política de retención. |

### 2.2 Respuestas a las Preguntas de la Actividad 1

#### 1. ¿Qué campos identifican directamente a una persona?
Los campos **nombre**, **correo**, **telefono** y **rfc**. En el ámbito de la base de datos, el **id** funge como identificador unívoco interno. El RFC y el correo electrónico poseen la propiedad de unicidad formal e individualizan al titular sin necesidad de datos adicionales.

#### 2. ¿Qué campos no identifican por sí mismos pero podrían contribuir a hacerlo?
Los campos **edad**, **ciudad**, **codigo_postal** y **fecha_alta**. Se catalogan como **cuasi-identificadores**. Un código postal como `80100` o una edad de `47` años no revelan quién es el sujeto; sin embargo, al cruzarse entre sí o con bases de datos públicas (padrones, censos, redes sociales), reducen el espacio de búsqueda hasta lograr la reidentificación unívoca.

#### 3. ¿Qué combinación de campos podría incrementar el riesgo de reidentificación?
La combinación: `[codigo_postal + edad + ciudad]`. Según investigaciones de privacidad (como los teoremas de Latanya Sweeney), el 87% de la población puede ser singularizada con fecha de nacimiento/edad, género y código postal de 5 dígitos. Si además se conoce la `fecha_alta`, un atacante interno o externo puede correlacionar el registro con una transacción bancaria o factura emitida ese día.

#### 4. ¿Todos los datos que deben protegerse son necesariamente datos personales sensibles desde el punto de vista jurídico?
**No.** Jurídicamente (según la LFPDPPP en México y el RGPD en Europa), los datos personales *sensibles* son aquellos que tocan la esfera más íntima de su titular (salud, origen étnico, creencias religiosas, preferencia sexual, datos biométricos o afiliación sindical). Datos como el correo, teléfono o código postal son datos personales *ordinarios*, pero exigen protección obligatoria debido a que su exposición no autorizada vulnera la confidencialidad y facilita el fraude o la extorsión.

---

## 3. ACTIVIDAD 2 — ENMASCARAMIENTO (MASKING)

### 3.1 Justificación y Mecanismo Técnico
* **¿Qué se ocultó?**  
  Se ocultaron las partes sensibles de `correo` (dejando solo las 2 primeras letras y el dominio), `telefono` (ocultando los primeros 6 dígitos y mostrando los últimos 4) y `rfc` (ocultando los primeros 9 caracteres y mostrando solo la homoclave final de 4 dígitos).
* **¿Para quién?**  
  Para el rol de base de datos **`soporte`**.
* **¿Por qué?**  
  El personal del centro de soporte técnico solo necesita validar que el cliente con el que interactúa es quien dice ser (ej. *"¿me confirma los últimos 4 dígitos de su teléfono o RFC?"*), sin tener la facultad de extraer directorios masivos de contactos de clientes ni comercializarlos.
* **¿Qué mecanismo se utilizó?**  
  Se utilizó **enmascaramiento dinámico basado en Vistas de PostgreSQL (`CREATE VIEW v_clientes_soporte`)**, complementado con políticas estrictas de control de accesos (`GRANT SELECT ON VIEW`, `REVOKE ALL ON clientes`). De este modo, los datos almacenados físicamente permanecen íntegros, pero la capa de presentación que consume el rol filtra la visualización.

### 3.2 Respuestas a las Preguntas de la Actividad 2

#### 1. ¿Qué información continúa existiendo en la tabla original?
En la tabla `public.clientes` la información permanece **100% íntegra, exacta y sin alteraciones**. Los correos, teléfonos y RFCs reales siguen existiendo físicamente en los bloques de almacenamiento del motor para fines de facturación y auditoría administrativa.

#### 2. ¿Qué información puede visualizar el usuario soporte?
El usuario `soporte` únicamente visualiza los atributos expuestos por la vista: `id`, `nombre`, `correo` enmascarado (`an*****@example.test`), `telefono` ofuscado (`******4567`) y `rfc` enmascarado (`*********5ABC`). No tiene visibilidad de edad, ciudad, código postal ni fecha de alta, ni de los valores planos de contacto.

#### 3. ¿Por qué no es suficiente ocultar los datos únicamente en la aplicación?
Porque dejar la base de datos desprotegida asumiendo que la aplicación (frontend o backend) filtrará los datos incurre en una violación grave de defensa en profundidad:
* Cualquier desarrollador, soporte de TI o atacante con una conexión SQL (DBeaver, psql, pgAdmin) o mediante una inyección SQL (SQLi) podría extraer la tabla sin censura.
* La seguridad debe residir en la capa donde viven los datos (**Data Layer Security**).

#### 4. ¿Qué ocurriría si soporte tuviera acceso directo a clientes?
Se rompería el **principio de mínimo privilegio**. Cualquier agente de soporte con credenciales comprometidas o con intenciones maliciosas podría ejecutar un `SELECT * FROM clientes` y sustraer la base de datos completa de clientes con datos de contacto directos, provocando una brecha de datos (Data Leakage) con responsabilidad legal para la organización.

---

## 4. ACTIVIDAD 3 & 4 — SEUDONIMIZACIÓN Y SEPARACIÓN DE FUNCIONES

### 4.1 Generación de Tokens y Aislamiento de Esquemas
* **Mecanismo de generación:**  
  Se utilizó la función criptográfica `gen_random_uuid()` provista por la extensión `pgcrypto` de PostgreSQL. Esto genera identificadores únicos universales (UUID v4) generados mediante entropía pseudoaleatoria, haciéndolos matemáticamente imposibles de predecir o revertir algorítmicamente sin la tabla de correspondencia.
* **Ubicación del mapa de correspondencia:**  
  Se resguardó en un esquema aislado: `pii.mapa_cliente (token UUID, cliente_id BIGINT)`.
* **Conjunto para analítica:**  
  Se creó en el esquema `analitica.clientes`, vinculando el token con las variables demográficas (`edad`, `ciudad`, `codigo_postal`, `fecha_alta`), prescindiendo de nombre, correo, teléfono y RFC.

### 4.2 Respuestas a las Preguntas de la Actividad 4

#### 1. ¿Qué ocurriría si analista pudiera consultar también `pii.mapa_cliente`?
La seudonimización quedaría **completamente anulada**. El analista solo necesitaría ejecutar un `JOIN` entre `analitica.clientes` y `pii.mapa_cliente` y `public.clientes` para obtener la identidad de cada cliente analizado. La seudonimización solo es efectiva si la información adicional requerida para reidentificar se mantiene estrictamente separada y protegida bajo otra autoridad de acceso.

#### 2. ¿Qué principio de seguridad se está aplicando al separar ambos accesos?
Se aplica el principio de **Separación de Funciones (Separation of Duties - SoD)** y el **Principio de Mínimo Privilegio**. Ningún rol dentro del área analítica concentra los privilegios suficientes para realizar investigación y a la vez identificar individualmente a los titulares de la información.

#### 3. ¿Por qué la seudonimización no equivale a anonimización?
Porque la seudonimización es un tratamiento **reversible**. La información de enlace (el mapa de correspondencia) existe y se almacena en el sistema. Si se unen ambas piezas, la persona física vuelve a identificarse de manera directa. En cambio, la anonimización busca un estado irreversible donde la reidentificación razonable ya no sea factible.

#### 4. ¿Qué información permite volver a relacionar el token con una persona?
La clave foránea `cliente_id` alojada en la tabla `pii.mapa_cliente`, la cual conecta directamente el `UUID` generado con el registro primario de `public.clientes` que contiene el nombre y RFC.

---

## 5. ACTIVIDAD 5 & 6 — ANONIMIZACIÓN Y ANÁLISIS DE REIDENTIFICACIÓN

### 5.1 Transformaciones Aplicadas
1. **Generalización de edad:** Sustitución de valores escalares continuos por rangos etarios discretos (`18-30`, `31-45`, `46+`).
2. **Generalización geográfica:** Extracción de los 2 primeros dígitos del código postal (`LEFT(codigo_postal, 2)`), transformando una colonia específica en una macrorregión postal.
3. **Agregación combinada:** Agrupamiento estadístico `GROUP BY rango_edad, region_postal` calculando métricas agregadas (`COUNT(*)`).
4. **Supresión de grupos pequeños (k-anonimato con k = 5):** Mediante la cláusula `HAVING COUNT(*) >= 5`, se eliminan del reporte final aquellas celdas que contienen menos de 5 observaciones.

### 5.2 Respuestas a las Preguntas de la Actividad 6

#### 1. ¿Qué identificadores directos fueron eliminados?
Se eliminaron por completo: `id`, `nombre`, `correo`, `telefono`, `rfc` y el `token` seudonimizado.

#### 2. ¿Qué cuasi-identificadores permanecen?
Permanecen la `edad` (reducida a rangos) y el `codigo_postal` (reducido a prefijo de 2 dígitos).

#### 3. ¿Qué combinaciones de atributos podrían reducir el anonimato?
Si un atacante conoce que una persona reside en la zona postal `82` y tiene más de `46` años, y en la consulta agregada se reporta que únicamente existe 1 persona con esas características, el atacante tiene la certeza absoluta de que cualquier métrica asociada a ese grupo le pertenece a esa persona individual (Ataque de Inferencia / Singularidad).

#### 4. ¿Qué sucede cuando un grupo contiene pocos registros?
Se incrementa exponencialmente el riesgo de **Reidentificación por Homogeneidad** o **Ataque de Aislamiento**. Si un grupo tiene 1 o 2 sujetos, cualquier atributo sensible revelado sobre el grupo se atribuye con certeza casi total a las personas involucradas.

#### 5. ¿Qué atributos deberían generalizarse?
Debe ampliarse la generalización geográfica a nivel Estatal o Regional (ej. `'Zona Noroeste'`), y la variable temporal de registro debe generalizarse exclusivamente al año o eliminarse del reporte público.

#### 6. ¿Qué información debería suprimirse?
Deben suprimirse todos los registros o celdas cuyo conteo sea inferior al umbral de seguridad estipulado ($k \ge 5$).

#### 7. ¿Es correcto afirmar que el conjunto de datos es “100 % anónimo”? ¿Por qué?
**No es correcto.** No existe el "100% de anonimato absoluto" en conjuntos de microdatos multidimensionales. Con el avance de técnicas de minería de datos, machine learning y el enriquecimiento continuo con fuentes externas (Open Data, censos, redes sociales, registros de compras filtrados), siempre subsiste un riesgo residual de reidentificación. Afirmar anonimato total genera una falsa sensación de seguridad técnica.

### 5.3 Desarrollo del Reto (Actividad 6)
Para mitigar radicalmente el riesgo en conjuntos de datos corporativos, se diseñó la siguiente consulta avanzada en `sql/04-anonimizacion.sql`:
* **Generalización adaptativa de geografía:** En vez del prefijo postal (que en Sinaloa distingue municipios clave como Culiacán `80`, Los Mochis `81`, Mazatlán `82`), se generaliza a `'Zona Noroeste (Sinaloa)'`.
* **Agrupamiento generacional:** Se clasifica en cohortes estándar (`Joven <35`, `Adulto 35-50`, `Senior >50`).
* **Supresión con umbral dinámico:** Se restringe cualquier cohorte con baja representación.
* **Resultado:** Se elimina la capacidad de un observador externo de distinguir si un sujeto vive en Mazatlán o Culiacán, protegiendo a la persona contra ataques de vinculación local.

---

## 6. ACTIVIDAD 7 — RETENCIÓN Y CICLO DE VIDA DE LOS DATOS

### 6.1 Identificación y Criterios Operativos
* **Criterio establecido:** Se definió un periodo de retención de **5 años** para cuentas o clientes inactivos sin operaciones comerciales vigentes, con base en obligaciones fiscales (Art. 30 del Código Fiscal de la Federación en México que exige conservar documentación durante 5 años) y el principio de minimización de datos (Art. 11 LFPDPPP).
* **Consulta de identificación:**
  ```sql
  SELECT id, nombre, correo, fecha_alta, AGE(CURRENT_DATE, fecha_alta) 
  FROM public.clientes 
  WHERE fecha_alta < CURRENT_DATE - INTERVAL '5 years';
  ```
* **Registros afectados:** Clientes con `fecha_alta` anterior a la fecha límite calculada dinámicamente (`CURRENT_DATE - INTERVAL '5 years'`).

### 6.2 Procedimiento Seguro de Depuración (Gobernanza de Datos)
1. **Justificación del periodo:** Cumplimiento del plazo de caducidad de facultades de comprobación fiscal (5 años) y vencimiento de la finalidad contractual original.
2. **Aprobación formal:** Debe existir un flujo formal de autorización firmado por el **Oficial de Protección de Datos (DPO)**, el **Director Jurídico** y el **Líder DBA**.
3. **Respaldo previo mandatorio:**
   * Generación de un dump binario cifrado del conjunto de datos afectado mediante `pg_dump -t clientes --data-only`.
   * Cálculo y registro de una suma de verificación criptográfica (`SHA-256`) del archivo de respaldo en la bitácora de auditoría.
   * Almacenamiento del respaldo en bóveda fría de retención legal (Cold Storage / WORM).
4. **Evidencia que debe conservarse:** La tabla `auditoria.bitacora_retencion` debe registrar: ID del evento, cantidad de tuplas procesadas, política legal invocada, firmante, fecha/hora exacta y hash del archivo de respaldo generado. **No se conservan los datos borrados, sino la constancia inmutable del proceso de destrucción.**
5. **Procedimiento de recuperación ante borrado accidental:** En caso de falso positivo o requerimiento judicial extraordinario, el DBA restaura el backup mediante `pg_restore` en una base de datos de staging aislada y reinyecta únicamente el registro acreditado formalmente.

---

## 7. CONCLUSIONES GENERALES

| Caso de Uso | Técnica Recomendada | Justificación Técnica |
| :--- | :--- | :--- |
| **Área de Soporte Técnico** | **Enmascaramiento Dinámico (Vistas / RBAC)** | Permite contrastar y autenticar al cliente mediante últimos dígitos o iniciales sin exponer la base completa ni permitir la descarga de datos planos. |
| **Área de Analítica e Inteligencia** | **Seudonimización (Tokens UUID + Aislamiento SoD)** | Conserva la granularidad transaccional y temporal de cada individuo para modelos predictivos sin exponer su PII, aislando el mapa de correspondencia en esquemas restringidos. |
| **Publicación de Estadísticas / Dirección** | **Anonimización (Generalización + k-anonimato + Supresión)** | Genera datos agregados irreversibles para la toma de decisiones ejecutivas sin requerir identificar a ninguna persona individual. |

### ¿Por qué ninguna de estas técnicas sustituye al control de acceso?
Porque el **Control de Acceso (Access Control / RBAC)** es la primera línea de defensa perimetral. Si un actor malicioso o usuario no autorizado puede conectarse como superusuario (`postgres`) o leer tablas subyacentes, cualquier técnica de vista o tokenización queda vulnerada. La seguridad efectiva de bases de datos exige una estrategia de **Defensa en Profundidad**: el control de acceso restringe *quién entra*, y las técnicas de transformación y privacidad controlan *qué pueden ver o reconstruir* si llegaran a acceder.

---

## 8. PREGUNTAS DE REFLEXIÓN (SECCIÓN 20)

### 1. ¿Cuál es la diferencia entre enmascaramiento y seudonimización?
El **enmascaramiento** altera únicamente la visualización o presentación de un dato (ocultando caracteres con asteriscos u ofuscación) manteniendo el dato original intacto en la base de datos o presentándolo condicionalmente según privilegios. La **seudonimización** sustituye activamente un identificador directo por un valor artificial o token aleatorio, desacoplando los registros analíticos de la identidad del titular pero conservando la relación en una tabla protegida e independiente.

### 2. ¿Por qué la seudonimización no significa anonimización?
Porque la seudonimización es **reversible**. Si se dispone del mapa de correspondencia (`token <-> cliente_id`), es posible asociar nuevamente el expediente a la persona física identificable. Por el contrario, la anonimización busca romper ese vínculo de forma **irreversible**, impidiendo la reidentificación razonable incluso para los administradores del sistema.

### 3. ¿Por qué eliminar nombre y RFC no garantiza que un conjunto de datos sea anónimo?
Porque los atributos restantes pueden constituir un conjunto de **cuasi-identificadores**. Variables como edad, sexo, municipio, código postal, profesión y fechas de registro poseen suficiente poder discriminatorio para aislar a un individuo cuando se cruzan con otras fuentes de información públicas o comerciales.

### 4. ¿Qué función tienen los cuasi-identificadores?
Los cuasi-identificadores son piezas de información contextual que, aunque aisladas parecen inocuas, en combinación funcionan como una "huella digital indirecta" capaz de singularizar a un sujeto dentro de una población.

### 5. ¿Por qué es importante separar el mapa de seudonimización?
Porque si el mapa de seudonimización y el conjunto de datos de trabajo residen en el mismo espacio con permisos idénticos, cualquier usuario con acceso de lectura puede ejecutar una consulta con `JOIN` y desmantelar instantáneamente toda la arquitectura de privacidad.

### 6. ¿Qué principio de seguridad se aplica al impedir que el analista acceda al mapa?
Se aplica el principio de **Separación de Funciones (Separation of Duties)** y el principio de **Mínimo Privilegio (Least Privilege)**, evitando la concentración de capacidades críticas en un solo perfil operativo.

### 7. ¿Por qué una vista puede ser preferible a entregar acceso directo a la tabla?
Una vista (`VIEW`) actúa como una compuerta lógica desacoplada: permite restringir el acceso a nivel de fila y columna, aplicar fórmulas de enmascaramiento en tiempo real, ocultar la estructura física subyacente y revocar permisos sobre las tablas base sin alterar la lógica de negocio ni el código de las aplicaciones cliente.

### 8. ¿Qué diferencia existe entre proteger un dato para visualización y protegerlo contra acceso no autorizado?
Protegerlo para visualización (enmascaramiento de interfaz o vista) controla cómo se expone el dato a un usuario que posee autorización funcional para interactuar con la entidad. Protegerlo contra acceso no autorizado (cifrado en reposo, privilegios estrictos, autenticación multifactor, hardening) garantiza que ningún sujeto sin autorización explícita pueda leer, exportar o interceptar el dato crudo bajo ninguna circunstancia.

### 9. ¿Por qué la retención forma parte de la protección de datos?
Porque responde al principio de **Minimización de Datos y Limitación del Plazo de Conservación**. Los datos personales no deben conservarse por más tiempo del estrictamente necesario para cumplir las finalidades que motivaron su tratamiento. Al depurar sistemáticamente la información obsoleta, se reduce el volumen de datos expuestos ante cualquier incidente de seguridad.

### 10. ¿Qué riesgo existe si una organización conserva información indefinidamente?
1. **Incremento del impacto de brechas:** Una fuga de datos expone información de décadas de clientes, multiplicando multas regulatorias y daño reputacional.  
2. **Costos y responsabilidades legales innecesarias:** Obligación de responder a derechos de acceso, rectificación y cancelación (ARCO) sobre expedientes inútiles.  
3. **Degradación de rendimiento y costos de almacenamiento:** Índices pesados, respaldos prolongados y mayor superficie de ataque para amenazas internas y externas.
