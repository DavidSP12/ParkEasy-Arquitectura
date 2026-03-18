# ADR-002: Adoptar PostgreSQL como Base de Datos Principal

**Estado:** Aceptado  
**Fecha:** [19/03/2026] 
**Decisores:** 
- [Gabriel Alejandro Camacho Rivera] - [Código]
- [David Santiago Piñeros Rodriguez] - [00020526922]
- [Santiago Pineda Mora] - [Código]
- [Maria Angelica Piedrahita Ramirez] - [Código]
**Relacionado con:** DR-01, RNF-04, DR-03
**Grupo:** [2]

---

## Contexto y Problema
El sistema manejará concurrencia crítica (múltiples usuarios intentando reservar el último espacio disponible) y registros transaccionales de dinero. Necesitamos elegir un motor de persistencia que ofrezca integridad absoluta, rendimiento adecuado y se ajuste al presupuesto.

## Drivers de Decisión
- **DR-01:** Performance ≤ 5 seg (Alta).
- **Integridad:** Evitar "sobreventa" de espacios a toda costa (Alta).
- **DR-03:** Costo operativo bajo (Alta).

## Alternativas Consideradas

### Alternativa 1: MongoDB (NoSQL)
**Descripción:** Base de datos orientada a documentos, altamente escalable.
**Pros:**
- ✅ Esquema flexible, rápido desarrollo.
- ✅ Gran desempeño en lecturas masivas.
**Contras:**
- ❌ Las transacciones ACID multi-documento son complejas de implementar y pueden degradar el performance, elevando el riesgo de condiciones de carrera en reservas.

### Alternativa 2: Amazon DynamoDB
**Descripción:** Base de datos NoSQL serverless de AWS.
**Pros:**
- ✅ Escalabilidad infinita automática.
**Contras:**
- ❌ Alto riesgo de sobrecostos no controlados si los patrones de acceso no se diseñan perfectamente.

## Decisión
Adoptamos **PostgreSQL**. Se utilizará una instancia gestionada (ej. RDS) para proveer persistencia a todos los servicios definidos en el ADR-001.

## Justificación
La naturaleza del dominio de ParkEasy es transaccional (un usuario toma un cupo, hace un pago, se genera una factura). PostgreSQL garantiza el cumplimiento ACID, usando bloqueos a nivel de fila (*row-level locking*) que evitan de forma nativa la sobreventa de cupos cuando hay reservas concurrentes. Aunque la escalabilidad horizontal de PostgreSQL es menor que NoSQL, el volumen proyectado (picos de 80 veh/hora, expansible a 1,200 cupos) es un volumen bajo/medio que una sola instancia de PostgreSQL manejada en la nube puede procesar en microsegundos, asegurando el cumplimiento del DR-01. Adicionalmente, cuenta con el tipo `JSONB` si necesitamos flexibilidad en la metadata de los tickets sin sacrificar integridad.

## Consecuencias

### ✅ Positivas:
1. **Consistencia fuerte:** Cero posibilidad matemática de sobreventa si se usa aislamiento transaccional correcto.
2. **Capacidades relacionales:** Facilita enormemente las consultas complejas para el dashboard administrativo (RF-06).

### ⚠️ Negativas (y mitigaciones):
1. **Cuello de botella único:**
   - **Riesgo:** Si la base de datos se cae, todo el sistema Service-Based colapsa.
   - **Mitigación:** Despliegue en configuración Multi-AZ (Alta Disponibilidad) para tener failover automático.

## Validación
- [x] Cumple con la necesidad de Integridad Transaccional.
- [x] Cumple con DR-03: Costos fijos predecibles comparados con On-Demand.