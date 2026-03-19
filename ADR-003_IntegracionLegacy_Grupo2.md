# ADR-003: Implementar patrón Anti-Corruption Layer (ACL)

**Estado:** Aceptado  
**Fecha:** [19/03/2026] 
**Decisores:** 
- [Gabriel Alejandro Camacho Rivera] - [00020530317] - [gabrielcamachor@javeriana.edu.co]
- [David Santiago Piñeros Rodriguez] - [00020526922] - [pinerosrdavid@javeriana.edu.co]
- [Santiago Pineda Mora] - [00020519556]  - [santiago.pineda@javeriana.edu.co]
- [Maria Angelica Piedrahita Ramirez] - [00020522980] - [mariaapiedrahita@javeriana.edu.co]
**Relacionado con:** DR-05, DR-01  
**Grupo:** [2]

---

## Contexto y Problema
El requerimiento de negocio obliga a reportar todas las transacciones financieras al sistema de cobro Legacy en VB6 vía SOAP. Este sistema tiene pobre documentación y sufre de inestabilidad y alta latencia. Si el Core de ParkEasy se comunica directamente con él, la lentitud del VB6 afectará el tiempo de respuesta para abrir la talanquera (violando el DR-01).

## Drivers de Decisión
- **DR-05:** Integración forzosa con Legacy VB6 (Alta).
- **DR-01:** Performance de I/O ≤ 5 seg (Alta).

## Alternativas Consideradas

### Alternativa 1: Point-to-Point (Integración Directa)
**Descripción:** El servicio de pagos implementa directamente un cliente SOAP y llama al VB6 durante el proceso de salida.
**Pros:**
- ✅ Fácil y rápido de programar.
**Contras:**
- ❌ Fuerte acoplamiento: el modelo de datos de nuestro nuevo sistema debe adaptarse a las reglas no documentadas del XML del VB6.
- ❌ Bloqueo síncrono: Si el VB6 tarda 10 segundos en responder, el usuario espera 10 segundos en la talanquera.

### Alternativa 2: Cola de Mensajes Simple
**Descripción:** Enviar un mensaje a RabbitMQ/SQS y que un proceso suelto haga la llamada SOAP.
**Pros:**
- ✅ Resuelve el problema asíncrono.
**Contras:**
- ❌ No protege nuestro modelo de datos, la lógica de transformación XML sigue suelta o atada a quien encola.

## Decisión
Adoptamos el patrón **Anti-Corruption Layer (ACL)**, implementado a través de nuestro *Integration Service* dedicado. Los servicios de ParkEasy emitirán eventos estándar (JSON) hacia este servicio intermedio, el cual se encargará exclusivamente de transformar, encolar y gestionar los reintentos hacia el API SOAP del sistema VB6 y el hardware LPR.

## Justificación
El patrón ACL actúa como un "amortiguador" técnico y de diseño. Separa completamente el dominio moderno (reservas/pagos) de la deuda técnica (VB6). Al enviar los datos al ACL asíncronamente, el Core Service puede responder al conductor en milisegundos y abrir la talanquera (cumpliendo DR-01). El ACL tomará el tiempo que necesite para pelear con el SOAP, implementando patrones de reintento si el VB6 está caído momentáneamente, asegurando que los datos contables eventualmente lleguen sin afectar la operación física del parqueadero.

## Consecuencias

### ✅ Positivas:
1. **Performance blindado:** El conductor nunca experimentará la latencia del sistema Legacy.
2. **Reemplazo futuro:** Si la empresa decide dar de baja el VB6, solo se apaga el ACL; el Core Service no se toca.

### ⚠️ Negativas (y mitigaciones):
1. **Consistencia Eventual:**
   - **Riesgo:** Desfase de tiempo entre el cobro real y su aparición en los reportes del sistema contable antiguo.
   - **Mitigación:** Aceptación por parte de negocio de que el tablero legacy no tendrá datos al segundo exacto, sino a los minutos.

## Validación
- [x] Cumple con DR-05: Integra el legacy.
- [x] Cumple con DR-01: Evita bloqueos en el tiempo de respuesta.
