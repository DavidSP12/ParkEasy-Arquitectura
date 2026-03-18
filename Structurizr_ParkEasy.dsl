workspace "ParkEasy - Sistema de Gestión de Parqueaderos" "Arquitectura del sistema ParkEasy - Grupo [X]" {

    model {
        # =================================================================
        # NIVEL 1: PERSONAS (USUARIOS EXTERNOS)
        # =================================================================
        driver = person "Conductor" "Persona que busca reservar y parquear su vehículo usando PWA."
        operator = person "Operador" "Personal en casetas que atiende incidentes de manera manual."
        administrator = person "Administrador" "Gerente que supervisa reportes, finanzas y ocupación."
        
        # =================================================================
        # SISTEMAS EXTERNOS
        # =================================================================
        lprSystem = softwareSystem "Sistema de Cámaras LPR" "Hardware en sitio de reconocimiento de placas con API REST." "External System"
        legacyBilling = softwareSystem "Sistema de Cobro Legacy" "Sistema contable antiguo en VB6 (protocolo SOAP/XML)." "External System"
        paymentGateway = softwareSystem "Pasarela Wompi" "Plataforma para procesamiento de pagos digitales." "External System"
        notificationService = softwareSystem "Servicio de Notificaciones" "Plataforma de envío de facturas vía Email." "External System"
        
        # =================================================================
        # SISTEMA PRINCIPAL: PARKEASY
        # =================================================================
        parkEasy = softwareSystem "ParkEasy" "Sistema central de gestión que permite reservas, control LPR y pagos digitales." {
            
            # NIVEL 2: CONTAINERS (Service-Based Architecture)
            webApp = container "Aplicación Web (PWA)" "Interfaz responsiva para conductores, operadores y administradores." "React.js" "Web Browser"
            
            paymentService = container "Payment Service" "Motor transaccional para liquidar tarifas y conectar con pasarela." "Node.js / TypeScript" "Service"

            integrationService = container "Integration Service (ACL)" "Capa Anti-Corrupción que absorbe la comunicación LPR y Legacy VB6." "Node.js / TypeScript" "Service"
            
            database = container "Base de Datos Principal" "Persiste espacios, reservas, tickets activos y reportes financieros." "PostgreSQL" "Database"
            
            # EL CORRECCIÓN ESTÁ AQUÍ: Los componentes van DENTRO de las llaves del servicio
            coreParkingService = container "Core Parking Service" "Gestiona inventario de espacios, disponibilidad y lógicas de reserva." "Node.js / TypeScript" "Service" {
                
                # NIVEL 3: COMPONENTS (Dentro de Core Parking Service)
                reservationController = component "Reservation Controller" "Expone endpoints REST para app web y móvil." "NestJS Controller"
                availabilityManager = component "Availability Manager" "Controla las reglas de negocio de ocupación y tiempo de reserva." "NestJS Service"
                lprWebhookHandler = component "LPR Webhook Handler" "Recibe y enruta eventos asíncronos de ingreso/salida vehicular." "NestJS Controller"
                parkingRepository = component "Parking Repository" "Capa DAO para abstracción de consultas a base de datos." "TypeORM"
            }
        }
        
        # =================================================================
        # RELACIONES - NIVEL 1 (CONTEXT)
        # =================================================================
        driver -> parkEasy "Consulta cupos, reserva y paga" "HTTPS"
        operator -> parkEasy "Fuerza aperturas y consulta cámaras" "HTTPS"
        administrator -> parkEasy "Revisa balances y estadísticas" "HTTPS"
        
        parkEasy -> lprSystem "Comanda apertura de barreras / Lee placas" "REST/JSON"
        parkEasy -> legacyBilling "Sincroniza transacciones para contabilidad" "SOAP/XML"
        parkEasy -> paymentGateway "Autoriza cobros de tarjetas/Nequi" "REST/JSON"
        parkEasy -> notificationService "Dispara correos de facturación" "HTTPS"
        
        # =================================================================
        # RELACIONES - NIVEL 2 (CONTAINER)
        # =================================================================
        driver -> webApp "Usa desde su móvil" "HTTPS"
        operator -> webApp "Usa terminal en garita" "HTTPS"
        administrator -> webApp "Accede al Backoffice" "HTTPS"
        
        webApp -> coreParkingService "Peticiones de reserva y cupo" "HTTP/JSON"
        webApp -> paymentService "Inicia checkout de ticket" "HTTP/JSON"
        
        integrationService -> coreParkingService "Notifica llegada de vehículo (LPR)" "HTTP/JSON"
        paymentService -> integrationService "Envía info para reporte contable" "Asíncrono"

        coreParkingService -> database "Lee/Escribe estado" "TCP/5432"
        paymentService -> database "Lee/Escribe pagos" "TCP/5432"
        
        integrationService -> lprSystem "Llama API de cámaras" "HTTP/JSON"
        integrationService -> legacyBilling "Traduce modelo a XML y notifica" "SOAP/XML"
        paymentService -> paymentGateway "Genera cobro real" "HTTP/JSON"
        paymentService -> notificationService "Solicita envío de correo" "HTTP/JSON"

        # =================================================================
        # RELACIONES - NIVEL 3 (COMPONENT)
        # =================================================================
        webApp -> reservationController "POST /reservations" "HTTP/JSON"
        integrationService -> lprWebhookHandler "POST /webhook/lpr-event" "HTTP/JSON"
        
        reservationController -> availabilityManager "Solicita bloqueo de cupo" "Method Call"
        lprWebhookHandler -> availabilityManager "Confirma ingreso real" "Method Call"
        
        availabilityManager -> parkingRepository "Persiste los cambios de estado" "Method Call"
        parkingRepository -> database "Comitea transacción SQL" "TCP/5432"
    }

    views {
        systemContext parkEasy "SystemContext" "Diagrama de contexto C4 Nivel 1" {
            include *
            autoLayout lr
        }
        
        container parkEasy "Containers" "Diagrama de contenedores C4 Nivel 2" {
            include *
            autoLayout lr
        }
        
        component coreParkingService "ComponentsCoreService" "Diagrama de Componentes C4 Nivel 3 (Core Service)" {
            include *
            autoLayout lr
        }
        
        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "External System" {
                background #999999
                color #ffffff
            }
            element "Service" {
                background #1168bd
                color #ffffff
                shape RoundedBox
            }
            element "Web Browser" {
                shape WebBrowser
                background #438dd5
                color #ffffff
            }
            element "Database" {
                shape Cylinder
                background #2b7042
                color #ffffff
            }
        }
        theme default
    }
}