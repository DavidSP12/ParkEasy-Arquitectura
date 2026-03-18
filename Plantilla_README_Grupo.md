# Taller: Documentación Arquitectural - ParkEasy
## Grupo [Número de grupo]

**Integrantes:**
- [Gabriel Alejandro Camacho Rivera] - [Código] - [Email]
- [David Santiago Piñeros Rodriguez] - [00020526922] - [pinerosrdavid@javeriana.edu.co]
- [Santiago Pineda Mora] - [Código]  - [Email]
- [Maria Angelica Piedrahita Ramirez] - [Código] - [Email]

**Fecha de entrega:** [19/03/2026] 

---

## 📋 CONTENIDO DE LA ENTREGA

Este ZIP contiene la documentación arquitectural completa del sistema ParkEasy:

~~~text
├── Taller_README_GrupoX.md                     (Este archivo)
├── Taller_SRS_ParkEasy_GrupoX.md               (Requisitos funcionales, no funcionales y drivers)
├── Taller_ADR-001_EstiloArquitectural_GrupoX.md (Decisión sobre Service-Based Architecture)
├── Taller_ADR-002_BaseDeDatos_GrupoX.md        (Decisión sobre motor PostgreSQL)
├── Taller_ADR-003_IntegracionLegacy_GrupoX.md  (Decisión sobre Anti-Corruption Layer)
├── Taller_ParkEasy_Architecture_GrupoX.dsl     (Vistas C4)
└── Taller_SAD_ParkEasy_GrupoX.md               (Documento Arquitectural Maestro)
~~~

---

## 🎨 CÓMO VISUALIZAR LAS VISTAS C4

### Opción 1: Structurizr Online (RECOMENDADO)

1. Ir a: [https://structurizr.com/dsl]
2. Abrir el archivo `Taller_ParkEasy_Architecture_GrupoX.dsl`
3. Copiar TODO el contenido.
4. Pegar en el editor de Structurizr en el navegador.
5. Click en "Render".
6. Ver las vistas en el menú izquierdo:
   - **SystemContext:** Vista de contexto (C4 Nivel 1) con actores y sistemas externos.
   - **Containers:** Vista de contenedores (C4 Nivel 2) mostrando nuestros servicios backend.
   - **ComponentsCoreService:** Vista de componentes (C4 Nivel 3) detallando el servicio de reservas.

---

## 🏗️ DECISIONES ARQUITECTURALES CLAVE

### 1. Estilo Arquitectural: Service-Based Architecture
**Decisión:** Adoptamos una arquitectura basada en macro-servicios (Core Parking, Payments, Integration).
**Alternativas consideradas:** Monolito tradicional y Microservicios puros.
**Por qué lo elegimos:** Un monolito representaba alto riesgo de caída total si el sistema Legacy fallaba, pero los microservicios introducían una complejidad operacional inmanejable para 4 desarrolladores. Service-Based ofrece el balance ideal entre tolerancia a fallos y productividad.
**Ver:** `Taller_ADR-001_EstiloArquitectural_GrupoX.md`

### 2. Base de Datos: PostgreSQL
**Decisión:** Utilizar un motor relacional centralizado (PostgreSQL) con esquemas separados.
**Alternativas consideradas:** MongoDB (NoSQL) y DynamoDB.
**Por qué lo elegimos:** La gestión de cupos (450 espacios) es un problema de concurrencia e inventario. Requeríamos soporte ACID y bloqueos a nivel de fila (*row-level locking*) que ofrece SQL para evitar matemática y físicamente la sobreventa de espacios.
**Ver:** `Taller_ADR-002_BaseDeDatos_GrupoX.md`

### 3. Integración con Legacy: Anti-Corruption Layer (ACL)
**Decisión:** Aislar la comunicación con el frágil sistema VB6 a través de un "Integration Service" independiente que actúa como capa anticorrupción.
**Alternativas consideradas:** Integración Point-to-Point (conexión directa) y colas simples.
**Por qué lo elegimos:** El protocolo SOAP antiguo supone el mayor riesgo de cuellos de botella. Al confinar esta integración en su propio servicio de forma asíncrona, garantizamos que abrir una talanquera siga tomando ≤ 5 segundos (DR-01).
**Ver:** `Taller_ADR-003_IntegracionLegacy_GrupoX.md`

---

## 📊 RESUMEN DE LA ARQUITECTURA

### Estilo Arquitectural
**Service-Based Architecture** desplegada en AWS.

### Componentes Principales
1. **Web App (PWA)** - React.js - Interfaz unificada responsiva.
2. **Core Parking Service** - Node.js + NestJS - Motor de reglas de inventario.
3. **Payment Service** - Node.js + NestJS - Dominio financiero y pasarela de pagos.
4. **Integration Service (ACL)** - Node.js + NestJS - Puente técnico hacia hardware LPR y VB6.

### Stack Tecnológico

| Capa | Tecnología |
|------|------------|
| **Frontend** | React.js 18 (PWA) |
| **Backend** | Node.js 20 LTS (NestJS) |
| **Base de Datos** | PostgreSQL 15 |
| **Cloud** | AWS (Fargate, RDS, CloudFront) |

---

## 💰 ESTIMACIÓN DE COSTOS

| Servicio | Costo mensual |
|----------|---------------|
| AWS ECS (Fargate) para 3 contenedores | $ 120.00 |
| Amazon RDS PostgreSQL (Multi-AZ) | $ 140.00 |
| AWS CloudFront + S3 (Hosting Web) | $ 15.00 |
| Application Load Balancer | $ 25.00 |
| **TOTAL** | **$ 300.00 / mes** |

**¿Cumple con presupuesto de $2.000.000/mes?** SÍ. Nuestra arquitectura es altamente eficiente y utiliza apenas una fracción ínfima del presupuesto disponible.

---

## 🎯 CÓMO CUMPLIMOS LOS DRIVERS

| Driver | Objetivo | Cómo lo cumplimos |
|--------|----------|-------------------|
| **DR-01: Performance** | ≤5 seg entrada/salida | Implementando el patrón ACL (Asíncrono) para el legado. |
| **DR-02: Disponibilidad** | ≥ 99.5% sin caídas | Base de datos Multi-AZ y separación de servicios en nube. |
| **DR-03: Presupuesto** | ≤ $2.000.000 USD/mes | Costos fijos en ECS en lugar de esquemas variables no controlados. |
| **DR-04: Restricción Equipo**| 4 devs, 8 meses | Optar por Service-Based (3 APIs) evita la parálisis de microservicios. |

---

## 📝 SUPUESTOS ASUMIDOS

1. **Estabilidad LPR:** Las cámaras decodifican la placa en sitio y solo envían el texto final a la nube.
2. **Latencia de Red:** Conectividad a Internet estable en garitas.
3. **Migración Contable:** La empresa planea dar de baja el sistema VB6 en un futuro, justificando el esfuerzo de un Integration Service separado.

---

## ⚠️ RIESGOS IDENTIFICADOS

| Riesgo | Mitigación |
|--------|------------|
| **Inestabilidad del SOAP VB6** | El *Integration Service* implementa patrón Retry y Circuit Breaker. |
| **Fallo en LPR (suciedad)** | Interfaz manual PWA para registro manual rápido. |
| **Bloqueo en Base de Datos** | Transacciones cortas y eficientes en la asignación de espacio. |

---

## 🔄 PROCESO DE TRABAJO DEL GRUPO

### División de Trabajo

| Integrante | Responsabilidades |
|------------|-------------------|
| [Nombre 1] | Liderazgo de SRS, Drivers y justificación de Estilo (ADR-001). |
| [Nombre 2] | Modelado de datos, justificación de Base de datos (ADR-002) y nube. |
| [Nombre 3] | Codificación en Structurizr DSL de las Vistas C4 y resolución de bugs C4. |
| [Nombre 4] | Documento SAD, Integración Legacy (ADR-003) y revisión final de calidad. |

### Metodología
Iniciamos con sesiones de *brainstorming* para analizar el enunciado (CourtBooker sirvió de referencia). Usamos GitHub y herramientas colaborativas para redactar documentos. Tras definir los 5 Drivers Arquitecturales, dividimos los ADRs equitativamente. Realizamos validaciones conjuntas para asegurar trazabilidad entre requerimientos (SRS) y arquitectura (SAD).

---

## 💡 APRENDIZAJES Y REFLEXIONES

### ¿Qué aprendimos?
Aprendimos que la mejor arquitectura responde directamente a las restricciones del negocio. Tener un equipo pequeño es un *driver* arquitectural tan determinante como procesar miles de transacciones. Además, interiorizamos el valor del patrón *Anti-Corruption Layer* para encapsular "deuda técnica".

### Desafíos enfrentados
El mayor desafío técnico fue equilibrar la sintaxis de Structurizr DSL para el modelo C4 y asegurar que los componentes del Nivel 3 encajaran bien. A nivel de diseño, el balance entre performance (DR-01) frente a la latencia forzosa del sistema Legacy (DR-05) fue difícil hasta que adoptamos procesamiento asíncrono.

### Si pudiéramos empezar de nuevo...
Detallaríamos el modelo de dominio de base de datos antes de definir contenedores, ya que el manejo de concurrencia de inventario demostró ser el verdadero núcleo técnico del MVP.

---

## 📚 REFERENCIAS CONSULTADAS

- Ejemplo completo: CourtBooker (material del curso).
- Structurizr DSL: [https://structurizr.com/help/dsl](https://structurizr.com/help/dsl)
- C4 Model: [https://c4model.com/](https://c4model.com/)
- AWS Pricing Calculator.

---

## ✅ VALIDACIÓN FINAL

Antes de entregar, verificamos:

- [x] Todos los archivos están incluidos en el ZIP.
- [x] Archivo .dsl renderiza correctamente en Structurizr.
- [x] SRS tiene 6 RF y 5 RNF con métricas ESPECÍFICAS.
- [x] 3 ADRs completos con alternativas y trade-offs.
- [x] SAD referencia correctamente todos los documentos.
- [x] Costos suman ≤ $2.000.000/mes.
- [x] Documentos profesionales sin errores ortográficos.
