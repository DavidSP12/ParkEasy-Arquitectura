# Software Architecture Document (SAD)
## Sistema de Gestión de Parqueaderos - "ParkEasy"

**Versión:** 1.0  
**Fecha:** [19/03/2026]  
**Grupo:** [2]  
**Integrantes:**
- [Gabriel Alejandro Camacho Rivera] - [Código]
- [David Santiago Piñeros Rodriguez] - [00020526922]
- [Santiago Pineda Mora] - [Código]
- [Maria Angelica Piedrahita Ramirez] - [Código]

---

## CONTROL DE VERSIONES

| Versión | Fecha | Autor | Cambios |
|---------|-------|-------|---------|
| 0.1 | [Fecha inicial] | [Nombres] | Borrador inicial |
| 1.0 | [Fecha actual] | [Grupo completo] | Versión final para entrega |

---

## 1. INTRODUCCIÓN

### 1.1 Propósito del Documento
Este documento describe la arquitectura del sistema ParkEasy, una plataforma centralizada para automatizar reservas, accesos LPR y pagos digitales en parqueaderos de Bogotá.
Sirve como registro de decisiones técnicas (ADRs), vista estructural para los desarrolladores e instrumento de validación académica de atributos de calidad.

### 1.2 Audiencia

| Rol | Uso de este documento |
|-----|----------------------|
| **Desarrolladores** | Referencia de estructura, dependencias y restricciones a programar. |
| **Arquitectos** | Validar que el diseño cumple con métricas de performance y presupuesto. |
| **Profesor** | Evaluar competencias de diseño arquitectural. |

### 1.3 Referencias
- **[SRS]** `Taller_SRS_ParkEasy_GrupoX.md` - Documento de requisitos
- **[DSL]** `Taller_ParkEasy_Architecture_GrupoX.dsl` - Vistas C4 en Structurizr
- **[ADR-001]** `Taller_ADR-001_EstiloArquitectural_GrupoX.md`
- **[ADR-002]** `Taller_ADR-002_BaseDeDatos_GrupoX.md`
- **[ADR-003]** `Taller_ADR-003_IntegracionLegacy_GrupoX.md`

### 1.4 Alcance
Este documento cubre la arquitectura del **MVP** de ParkEasy.

**Dentro de alcance:**
- Interfaz PWA y Web Admin.
- Core de Reservas y Pagos.
- Integración Anti-Corrupción con LPR y Legacy.

**Fuera de alcance:**
- Desarrollo de apps móviles nativas.

---

## 2. DESCRIPCIÓN GENERAL DE LA ARQUITECTURA

### 2.1 Filosofía de Diseño
1. **Pragmatismo sobre sobreingeniería:** Preferimos arquitecturas modulares (Service-Based) pero operativamente amigables para encajar en la restricción de 4 desarrolladores.
2. **Resiliencia Externa:** El núcleo del negocio debe funcionar independientemente de la caída de servicios externos de hardware (LPR) o software antiguo (VB6).

### 2.2 Estilo Arquitectural Principal
**Service-Based Architecture** (ver [ADR-001]).
Dividimos el sistema en tres macrocomponentes de backend (Core, Payments e Integration) que corren de manera independiente.
**Justificación:** Balance óptimo entre la capacidad de escalamiento (DR-03) y el esfuerzo de mantenimiento del equipo (DR-04).

### 2.3 Drivers Arquitecturales (ASRs)

| ID | Driver | Valor | Prioridad |
|----|--------|-------|-----------|
| **DR-01** | Performance | Entrada/salida en ≤ 5 segundos | Alta |
| **DR-02** | Escalabilidad | 450 → 1,200 espacios | Alta |
| **DR-03** | Costo | ≤ $2.000.000 USD/mes | Alta |
| **DR-04** | Restricción Equipo | MVP en 8 meses (4 devs) | Alta |
| **DR-05** | Integración Legacy | SOAP VB6 inestable | Alta |

---

## 3. VISTAS ARQUITECTURALES (C4)

**Archivo Structurizr DSL:** `Taller_ParkEasy_Architecture_GrupoX.dsl`

**Cómo visualizar:**
1. Ir a https://structurizr.com/dsl
2. Copiar contenido del archivo .dsl y hacer click en "Render".

### 3.1 C4 Nivel 1: Context Diagram
**Propósito:** Mostrar los actores (Conductor, Operador, Admin) y dependencias externas (LPR, Wompi, VB6 Legacy).

### 3.2 C4 Nivel 2: Container Diagram
**Propósito:** Exhibir los contenedores (Web App, Core Parking Service, Payment Service, Integration Service, Database).

### 3.3 C4 Nivel 3: Component Diagrams
**Propósito:** Desglosar el `Core Parking Service` en sus controladores (REST/Webhooks) y servicios de gestión de disponibilidad (Availability Manager).

---

## 4. DECISIONES ARQUITECTURALES (ADRs)

### 4.1 ADR-001: Adoptar Service-Based Architecture
**Estado:** Aceptado  
**Resumen:** Separar el dominio en 3 servicios granulares desplegados independientemente.
**Trade-off aceptado:** Mayor complejidad de orquestación frente a un Monolito, a cambio de escalabilidad y tolerancia a fallos.

### 4.2 ADR-002: Adoptar PostgreSQL
**Estado:** Aceptado  
**Resumen:** Emplear una base de datos relacional para todo el estado del sistema.
**Trade-off aceptado:** Renunciar a la hiper-escalabilidad horizontal del NoSQL para asegurar Integridad Transaccional estricta (vital para reservas e inventario).

### 4.3 ADR-003: Implementar Anti-Corruption Layer (ACL)
**Estado:** Aceptado  
**Resumen:** Crear el "Integration Service" como puente para traducir y aislar la latencia del Legacy VB6 y el hardware LPR.
**Trade-off aceptado:** Costo extra de desarrollar y mantener un servicio solo para mapeos técnicos y reintentos.

---

## 5. TECNOLOGÍAS Y HERRAMIENTAS

### 5.1 Stack Tecnológico

| Capa | Tecnología | Versión | Justificación |
|------|------------|---------|---------------|
| **Frontend** | React.js | 18.x | Ecosistema probado para PWA e interfaces de administración. |
| **Backend** | Node.js / NestJS | 20 LTS | Rápida iteración, asincronismo y tipado con TypeScript. |
| **Database** | PostgreSQL | 15.x | Soporte ACID y JSONB (Ver ADR-002). |

### 5.2 Servicios Cloud

**Proveedor:** AWS

| Servicio | Uso | Costo estimado/mes |
|----------|-----|-------------------|
| **AWS ECS (Fargate)** | Hosting de los 3 servicios backend | $[Completar: Ej. 150.00] |
| **AWS RDS (PostgreSQL)** | Base de datos Multi-AZ | $[Completar: Ej. 85.00] |
| **AWS CloudFront + S3** | Hosting y CDN del Frontend | $[Completar: Ej. 15.00] |
| **TOTAL** | | **$[Completar: Ej. 250.00]/mes** |

**Validación:** ¿Cumple con DR-03 (presupuesto ≤ $2.000.0000/mes)? SÍ.

---

## 6. SEGURIDAD Y DESPLIEGUE

### 6.1 Protección de Datos
**Cumplimiento Ley 1581 (Colombia):**
- Datos de placas encriptados con AES-256 en base de datos.
- Las tarjetas de crédito no tocan nuestro backend (Tokenización PCI-DSS de Wompi).

### 6.2 Estrategia de Despliegue
**Método:** Rolling Update a través de AWS ECS.
**Ambientes:** Development -> Staging -> Production.

---

## 7. RIESGOS Y DEUDA TÉCNICA

### 7.1 Riesgos Técnicos Identificados

| ID | Riesgo | Probabilidad | Impacto | Mitigación |
|----|--------|--------------|---------|------------|
| **R-01** | **Caída profunda del Legacy VB6** | Alta | Medio | El ACL encola los registros y reintenta asíncronamente; la operación local no se detiene. |
| **R-02** | **Cámaras LPR sucias o ilegibles** | Media | Alto | Operadores en sitio con iPad/Tablet pueden abrir forzadamente digitando la placa en el sistema. |

---

## APROBACIONES

| Rol | Nombre | Firma | Fecha |
|-----|--------|-------|-------|
| **Líder del Grupo** | [Nombre] | __________ | ___/___/___ |
| **Arquitecto** | [Nombre] | __________ | ___/___/___ |
| **Desarrollador 1** | [Nombre] | __________ | ___/___/___ |
| **Desarrollador 2** | [Nombre] | __________ | ___/___/___ |