# Software Requirements Specification (SRS)
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

## 1. INTRODUCCIÓN

### 1.1 Propósito
Este documento describe las especificaciones de requisitos de software para ParkEasy, un sistema diseñado para digitalizar la gestión de 3 parqueaderos físicos mediante reservas anticipadas, pagos digitales y visibilidad de cupos en tiempo real.

### 1.2 Alcance
El Minimum Viable Product (MVP) reemplazará el uso de tickets físicos y control manual, integrando el software con hardware existente de cámaras de Reconocimiento de Placas (LPR) y conviviendo temporalmente con un sistema contable legacy en VB6.

### 1.3 Definiciones, Acrónimos y Abreviaciones

| Término | Definición |
|---------|------------|
| LPR | License Plate Recognition (Reconocimiento de Placas) |
| MVP | Minimum Viable Product |
| DIAN | Dirección de Impuestos y Aduanas Nacionales |
| ACL | Anti-Corruption Layer |

### 1.4 Referencias
- Enunciado del taller ParkEasy

---

## 2. DESCRIPCIÓN GENERAL DEL SISTEMA

### 2.1 Perspectiva del Producto
ParkEasy es el sistema central que orquestará la interacción entre los usuarios (web/móvil), el hardware de acceso físico (cámaras LPR), plataformas de pago de terceros y el registro contable en el sistema legacy de la empresa.

### 2.2 Funciones del Producto
1. Gestión de disponibilidad de parqueaderos en tiempo real.
2. Reservas anticipadas de espacios (hasta 2 horas).
3. Automatización de entrada/salida mediante lectura LPR.
4. Procesamiento de pagos digitales.
5. Emisión de facturación electrónica.

### 2.3 Características de Usuarios

| Tipo de Usuario | Descripción | Nivel de Expertise |
|-----------------|-------------|--------------------|
| **Conductor** | Cliente final que busca parquear y pagar. | Básico - usa interfaces móviles intuitivas. |
| **Operador** | Empleado en sitio para soporte y control manual. | Básico - educación básica. |
| **Administrador** | Gerente que supervisa métricas y finanzas. | Medio - usa reportes y dashboards. |

### 2.4 Restricciones del Sistema

**Restricciones técnicas:**
- Debe integrarse obligatoriamente con el API REST de las cámaras LPR existentes.
- Debe integrarse vía SOAP con el sistema de cobro legacy en VB6.

**Restricciones de negocio:**
- Presupuesto tope de infraestructura: $2.000.000 USD/mes.
- Equipo asignado: 4 desarrolladores.
- Tiempo para MVP: 8 meses.
- Tolerancia cero a downtime en horas pico (7am-10am, 5pm-8pm).

**Restricciones regulatorias:**
- Ley 1581 (Colombia) de Protección de Datos.
- Retención de facturas electrónicas por 5 años exigida por la DIAN.

---

## 3. REQUISITOS FUNCIONALES

### RF-01: Consulta de Disponibilidad en Tiempo Real
**Prioridad:** Alta  
**Descripción:** El sistema debe mostrar a los conductores la cantidad de espacios libres en cada uno de los 3 parqueaderos.
**Criterios de aceptación:**
- El inventario debe actualizarse con un retraso máximo de 5 segundos respecto a la base de datos.
- Debe indicar claramente cuando un parqueadero alcanza el 100% de ocupación.

### RF-02: Creación y Gestión de Reservas
**Prioridad:** Alta  
**Descripción:** Un conductor debe poder reservar un espacio con un máximo de 2 horas de antelación.
**Criterios de aceptación:**
- Al confirmar la reserva, el cupo disponible del parqueadero debe disminuir en 1.
- El sistema debe cancelar automáticamente la reserva y liberar el cupo si el conductor no ingresa tras cumplirse las 2 horas.

### RF-03: Autorización de Acceso LPR
**Prioridad:** Alta  
**Descripción:** El sistema debe procesar la lectura de placas enviada por las cámaras y comandar la apertura de la talanquera.
**Criterios de aceptación:**
- El sistema debe asociar la placa leída a una reserva activa si existe.
- Si no hay reserva, debe generar un nuevo ticket digital vinculado a la placa, siempre que haya cupo.

### RF-04: Procesamiento de Pagos Digitales
**Prioridad:** Alta  
**Descripción:** El sistema debe calcular la tarifa y procesar el cobro a través de tarjetas o billeteras digitales (Nequi/Daviplata).
**Criterios de aceptación:**
- El cálculo debe aplicar la regla de negocio: $4,000 COP primera hora, $3,000 COP horas adicionales, tope de $25,000 COP por día.
- El sistema debe emitir la factura electrónica tras confirmar el pago.

### RF-05: Intervención Manual de Operadores
**Prioridad:** Media  
**Descripción:** Los operadores deben poder registrar entradas y salidas de forma manual ante fallos del LPR.
**Criterios de aceptación:**
- El operador debe poder digitar la placa y emitir un ticket digital.
- Toda acción manual debe registrarse en una bitácora de auditoría con el ID del operador.

### RF-06: Dashboard de Ocupación y Finanzas
**Prioridad:** Media  
**Descripción:** Los administradores deben tener acceso a un panel con métricas operativas.
**Criterios de aceptación:**
- Debe mostrar ingresos totales filtrables por día, mes y sucursal.
- Debe incluir estadísticas de tiempos promedio de estadía.

---

## 4. REQUISITOS NO FUNCIONALES

### RNF-01: Performance
**ID:** RNF-01  
**Categoría:** Performance  
**Descripción:** Procesamiento rápido en los puntos de control de acceso físico.
**Métricas:**
- El tiempo total desde la recepción del evento LPR hasta la respuesta de apertura de talanquera debe ser ≤ 5 segundos en el 95% de las peticiones (P95).
**Justificación:** Evitar filas y congestión vehicular en las entradas durante picos de 80 vehículos/hora.

### RNF-02: Availability
**ID:** RNF-02  
**Categoría:** Availability  
**Descripción:** El sistema crítico de accesos y pagos debe estar disponible durante el horario operativo.
**Métricas:**
- Uptime general ≥ 99.5% entre las 6:00 am y las 11:00 pm.
- 0 minutos de downtime permitido para despliegues o mantenimiento entre 7am-10am y 5pm-8pm.
**Justificación:** Las caídas impactan directamente la facturación y generan caos en sitio.

### RNF-03: Scalability
**ID:** RNF-03  
**Categoría:** Scalability  
**Descripción:** La arquitectura debe soportar el plan de expansión de la empresa a mediano plazo.
**Métricas:**
- El sistema debe soportar un incremento del inventario de 450 a 1,200 espacios sin degradar el RNF-01 ni requerir reescritura de código.
**Justificación:** El negocio proyecta abrir nuevas sucursales (hasta 6 parqueaderos totales).

### RNF-04: Security
**ID:** RNF-04  
**Categoría:** Security  
**Descripción:** Protección de información de identificación personal y financiera.
**Métricas:**
- 100% de las bases de datos deben implementar cifrado AES-256 en reposo para proteger los registros de placas vehiculares.
- 0% de almacenamiento local de datos completos de tarjetas de crédito (usar tokenización PCI-DSS).
**Justificación:** Obligación legal (Ley 1581) y mitigación de riesgo financiero.

### RNF-05: Cost
**ID:** RNF-05  
**Categoría:** Cost  
**Descripción:** Límite estricto de gasto mensual en infraestructura de nube.
**Métricas:**
- El costo de los servicios Cloud de producción no debe exceder los $2,000,000 USD mensuales bajo ninguna condición de carga.
**Justificación:** Restricción dura de negocio especificada por la gerencia.

---

## 5. ALCANCE DEL MVP

### 5.1 Dentro de Alcance (MVP)
✅ Aplicación web responsiva (PWA) para conductores.
✅ Panel de administración web para operadores y gerencia.
✅ Integración con cámaras LPR (recepción de placas).
✅ Pasarela de pagos (Wompi/PSE).
✅ Reporte de transacciones al sistema Legacy VB6.

### 5.2 Fuera de Alcance (MVP)
❌ Aplicaciones nativas de iOS o Android (por limitación de tiempo de los 4 desarrolladores).
❌ Reemplazo total del sistema legacy VB6 (conviviremos con él mediante integración).
❌ Tarifas dinámicas por demanda (se usarán las tarifas fijas establecidas).

---

## 6. SUPUESTOS Y DEPENDENCIAS

### 6.1 Supuestos
1. Se asume que los parqueaderos cuentan con conexión a internet estable y de baja latencia para que las cámaras LPR se comuniquen con la nube.
2. Se asume que el volumen de 1,200 movimientos diarios se distribuye de manera que el pico máximo absoluto no supera los 150 vehículos por hora en un solo parqueadero.

### 6.2 Dependencias
1. **API LPR:** Proveedor del hardware de cámaras.
2. **Pasarela de Pagos:** Disponibilidad del servicio de terceros (Wompi/PSE).
3. **Legacy VB6:** Estabilidad del servidor on-premise de ParkEasy.

---
## 7. CRITERIOS DE ACEPTACIÓN DEL SISTEMA

El sistema ParkEasy será aceptado cuando:

- Se demuestre el flujo completo (End-to-End) en un entorno de pruebas: Lectura LPR -> Creación de ticket/reserva -> Pago digital -> Apertura de talanquera de salida.
- Pruebas de carga certifiquen que el sistema soporta picos de 80 vehículos/hora manteniendo un tiempo de respuesta ≤ 5 segundos en la apertura de la barrera (RNF-01).
- Se valide que el *Integration Service* (ACL) logra encolar y transmitir exitosamente los reportes financieros al sistema Legacy VB6 vía SOAP, sin bloquear el flujo de los usuarios.
- El dashboard administrativo muestre correctamente los ingresos diarios y la ocupación en tiempo real de al menos un parqueadero simulado.
- Se verifique que ninguna información de tarjetas de crédito se guarda en la base de datos de PostgreSQL (cumplimiento PCI-DSS delegado a la pasarela).

---

## 8. DRIVERS ARQUITECTURALES IDENTIFICADOS

| ID | Driver | Valor/Métrica                                    | Prioridad |
|----|--------|--------------------------------------------------|-----------|
| **DR-01**   | Performance (I/O) | ≤ 5 seg (P95)                | Alta      |
| **DR-02**   | Escalabilidad | 450→1,200 espacios               | Alta      |
| **DR-03**   | Costo | ≤ $2.000.000 USD/mes                     | Alta      |
| **DR-04**   | Restricción de Equipo | MVP en 8 meses, 4 devs   | Alta      |
| **DR-05**   | Integración Legacy | SOAP con VB6 inestable      | Alta      |

---

## APROBACIONES

| Rol | Nombre | Firma | Fecha |
|-----|--------|-------|-------|
| **Líder del Grupo** | [Nombre] | __________ | ___/___/___ |
| **Integrante 2** | [Nombre] | __________ | ___/___/___ |
| **Integrante 3** | [Nombre] | __________ | ___/___/___ |
| **Integrante 4** | [Nombre] | __________ | ___/___/___ |