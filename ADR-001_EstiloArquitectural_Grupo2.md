# ADR-001: Adoptar Service-Based Architecture

**Estado:** Aceptado  
**Fecha:** [19/03/2026] 
**Decisores:** 
- [Gabriel Alejandro Camacho Rivera] - [Código]
- [David Santiago Piñeros Rodriguez] - [00020526922]
- [Santiago Pineda Mora] - [00020519556]
- [Maria Angelica Piedrahita Ramirez] - [00020522980]
**Relacionado con:** DR-02, DR-03, DR-04  
**Grupo:** [2]

---

## Contexto y Problema
Debemos definir la estructura fundamental del backend de ParkEasy. El sistema debe procesar reservas, integrar hardware (LPR) y sistemas antiguos (VB6). Operará inicialmente con un volumen medio (1,200 transacciones diarias) pero debe escalar a futuro. La mayor restricción es que el equipo consta únicamente de 4 desarrolladores con 8 meses para lanzar el MVP.

## Drivers de Decisión
- **DR-04:** Equipo pequeño (4 devs) y tiempo limitado (Alta).
- **DR-02:** Escalabilidad futura a 1,200 espacios (Alta).
- **DR-05:** Integración con legacy VB6 inestable (Alta).

## Alternativas Consideradas

### Alternativa 1: Arquitectura Monolítica
**Descripción:** Una única aplicación centralizada que contiene toda la lógica.
**Pros:**
- ✅ Desarrollo y despliegue rápido y sencillo.
- ✅ Menor complejidad de infraestructura (favorece DR-03).
**Contras:**
- ❌ Bajo aislamiento de fallos: Si el hilo que se comunica con el SOAP del VB6 se bloquea, afecta la disponibilidad de las reservas de todo el sistema.
- ❌ Dificultad para escalar independientemente las partes con más tráfico.

### Alternativa 2: Arquitectura de Microservicios
**Descripción:** División extrema del sistema en más de 10 pequeños servicios (uno para reservas, uno para LPR, uno para facturación, etc.).
**Pros:**
- ✅ Escalabilidad y aislamiento de fallos absoluto.
**Contras:**
- ❌ Overhead de infraestructura y despliegue inmanejable para 4 desarrolladores.
- ❌ Excesiva complejidad de consistencia de datos para un MVP en 8 meses (viola DR-04).

## Decisión
Adoptamos **Service-Based Architecture**. Dividiremos el dominio en un conjunto pequeño (macreservicios) de 3 servicios independientes:
1. **Core Parking Service:** Lógica de negocio de inventario y reservas.
2. **Payment Service:** Procesamiento de transacciones.
3. **Integration Service:** Manejo exclusivo de comunicación externa (LPR y VB6).

Se desplegarán independientemente pero compartirán lógicamente el motor de base de datos.

## Justificación
El estilo Service-Based provee el punto medio perfecto. Al extraer la comunicación inestable (Legacy) a un *Integration Service*, protegemos el Core de bloqueos por latencia, asegurando el performance (DR-01). Es una arquitectura que permite escalar de forma granular (DR-02) sin requerir el ejército de ingenieros DevOps que demandan los microservicios puros, garantizando que los 4 devs puedan terminar el MVP en tiempo (DR-04).

## Consecuencias

### ✅ Positivas:
1. **Aislamiento de riesgos:** La caída o lentitud del VB6 no impide que el sistema siga registrando accesos y abriendo talanqueras.
2. **Curva de aprendizaje:** Balance manejable entre modularidad y complejidad operativa.

### ⚠️ Negativas (y mitigaciones):
1. **Base de datos compartida:**
   - **Riesgo:** Acoplamiento a nivel de datos si los servicios cruzan tablas.
   - **Mitigación:** Aplicaremos schemas separados por servicio dentro del motor relacional, limitando el acceso cruzado.

## Validación
- [x] Cumple con DR-01: Aísla tareas pesadas.
- [x] Cumple con DR-02: Permite escalar contenedores independientemente.
- [x] Cumple con DR-04: Es mantenible por 4 desarrolladores.
