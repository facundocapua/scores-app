# Requisitos de la App Store para una app gratis y offline

Investigación del ticket #7 (hijo del mapa #1). Fecha de consulta: 2026-11-14. Todas las fuentes son de developer.apple.com. Lo que no pude verificar en una fuente primaria está marcado como **no verificado**.

## Resumen

- Hace falta la membresía paga del Apple Developer Program (99 USD por año) para subir a TestFlight y a la App Store.
- La URL de política de privacidad es obligatoria para apps iOS, aunque no se recopile nada, y además debe estar accesible dentro de la app.
- Etiqueta de privacidad: se responde "No, we do not collect data from this app" (en la ficha se muestra como "Data Not Collected"). Sin SDKs de terceros que transmitan datos, aplica.
- Nombre: 2 a 30 caracteres. Subtítulo: máximo 30 caracteres. Hay que elegir un nombre único, sin marcas ajenas ni términos de relleno.
- Una app que solo anota puntos de Generala, Burako y Truco no es "gambling" ni "simulated gambling" según las definiciones de Apple; el rating esperable es 4+ (inferencia).

## Membresía y costo

- Apple Developer Program: 99 USD por año de membresía (o en moneda local donde esté disponible). Hay exención de cuota solo para organizaciones sin fines de lucro, instituciones educativas acreditadas y entidades de gobierno. Se puede inscribir como individuo u organización. [What's included](https://developer.apple.com/programs/whats-included/)
- Para crear el registro de la app en App Store Connect, el Account Holder tiene que haber firmado el último acuerdo en la sección Business, y el usuario necesita rol Account Holder, App Manager o Admin. [Add a new app](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app)

## Política de privacidad

- Campo "Privacy Policy URL": obligatorio para iOS y macOS. [App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
- La página de detalles de privacidad dice "Privacy Policy (Required)" y no prevé excepción para apps que no recopilan datos. [App privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- Guideline 5.1.1(i): "All apps must include a link to their privacy policy in the App Store Connect metadata field and within the app in an easily accessible manner". Debe identificar qué datos recopila (si los hay), cómo y para qué, y explicar retención/borrado. [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- Consecuencia para la spec: la app necesita un acceso visible a la política (por ejemplo en una pantalla "Acerca de") y hay que alojar una página pública (puede ser una página estática simple) que diga que todo queda en el dispositivo.
- El campo Support URL también es obligatorio y debe llevar a información de contacto real (email, dirección o teléfono). [Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)

## Etiqueta de privacidad ("Data Not Collected")

- En App Store Connect la opción es "No, we do not collect data from this app." Al elegirla no hay más preguntas. Pueden responder Account Holder, Admin o App Manager, y hay que hacer clic en Publish. [Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)
- Definición de "collect": transmitir datos fuera del dispositivo de forma que el desarrollador o terceros puedan accederlos por más tiempo del necesario para atender el pedido en tiempo real. Los datos procesados solo en el dispositivo no se consideran recopilados. [App privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- Las respuestas deben incluir lo que recopilen los SDKs de terceros. Para mantener "Data Not Collected" hay que evitar analíticas, crash reporters de terceros y publicidad. SwiftData local sin sincronización iCloud no transmite nada (coincide con "Out of scope" del mapa).

## Localización solo en español y disponibilidad por país

- Los metadatos se localizan por idioma. El idioma principal (Primary Language) se usa cuando no hay metadatos localizados para un país o región. [App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
- App Store Connect ofrece "Spanish (Spain)" y "Spanish (Mexico)" (no hay "Argentina" ni "Latin America"). Según la tabla de localizaciones, México y muchos países latinoamericanos usan Spanish (Mexico) por defecto. En Xcode el idioma de la app se declara como `es` o `es-419`, y los identificadores no coinciden con los de App Store Connect. [App Store localizations](https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations/), [hilo de foros](https://developer.apple.com/forums/thread/727207)
- Implicancia: no hay un "español rioplatense" propio. Conviene elegir Spanish (Mexico) como idioma principal de la ficha (cubre Latinoamérica) y evaluar si se agrega Spanish (Spain). Una ficha solo en español es válida.
- Disponibilidad: se elige en Pricing and Availability antes de enviar a revisión (todos los países, países específicos o pre-order). Hay un checkbox para incluir automáticamente nuevos países. Quitar un país no corta las actualizaciones a quienes ya la bajaron. [Manage availability](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-for-your-app-on-the-app-store/)
- Para una app gratis sin juego con dinero real no aparece ninguna restricción regional propia. Brasil exige licencia solo para apuestas de cuota fija.

## Nombre y subtítulo

- Nombre: 2 a 30 caracteres, localizable, editable hasta enviar a revisión. Subtítulo: máximo 30 caracteres. [App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
- Guideline 2.3.7: "Choose a unique app name ... don't try to pack any of your metadata with trademarked terms, popular app names, pricing information, or other irrelevant phrases just to game the system. App names must be limited to 30 characters." Los subtítulos "should not include inappropriate content, reference other apps, or make unverifiable product claims". Nombres, subtítulos, capturas y previews no deben incluir precios ni términos no específicos del tipo de metadato. [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- Guideline 4.1(c): no se puede usar el ícono, marca o nombre de producto de otro desarrollador sin su aprobación. 4.1(a): no copiar con cambios menores el nombre de otra app.
- Guideline 2.3.8: "For Kids" y "For Children" están reservados a la Kids Category; evitarlos.
- Unicidad: App Store Connect dice que un nombre se puede usar para una app por localización y se valida al crear el registro. Si otro desarrollador usa el nombre y uno tiene derechos de marca, se puede presentar un reclamo. [Add a new app](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app) La regla 2.3.7 pide un nombre único, pero esa página no detalla el alcance exacto, y **no verifiqué** la reserva de 180 días que suele mencionarse. Consecuencia práctica: reservar el nombre creando el registro de la app apenas se decida (requiere la membresía), antes de invertir en identidad visual.
- Palabras clave (relacionado): hasta 100 bytes, cada una de más de 2 caracteres, sin repetir el nombre de la app ni usar nombres de otras apps o empresas. Descripción hasta 4.000 caracteres. Texto promocional hasta 170. [Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
- Marcas de los juegos: "Generala", "Truco" y "Burako" son denominaciones tradicionales de juegos, pero **no verifiqué** si existen marcas registradas sobre ellos (por ejemplo en INPI Argentina) ni en otras jurisdicciones. Ese chequeo no es de Apple y queda para el ticket del nombre (#2). Mencionar nombres de otras apps de puntaje en el nombre o subtítulo está prohibido (2.3.7).

## Assets requeridos

- Ícono: 1024 x 1024 px, PNG, sin canal alfa ni transparencia, sin esquinas redondeadas (el sistema aplica la máscara). La página de especificaciones de ícono no me cargó, así que esto está **parcialmente verificado** (resultados de búsqueda y foros de developer.apple.com). Con iOS 26 se pueden usar íconos por capas armados con Icon Composer. App Store Connect rechaza un ícono con alfa. [Foro](https://developer.apple.com/forums/thread/654407)
- Capturas, íconos y previews deben ser aptos para 4+ aunque la app tenga mayor rating (2.3.8).
- Capturas (iPhone): al menos 1 y hasta 10 por tamaño; JPEG, JPG o PNG sin alfa. Tamaño requerido: iPhone con Dynamic Island (medio), 1179 x 2556 o 1206 x 2622 px en vertical. También se piden las de "Face ID (large)", 1284 x 2778 o 1242 x 2688, salvo que se entreguen las de Dynamic Island (large) 1260 x 2736, 1290 x 2796 o 1320 x 2868. Si la interfaz es consistente, basta el tamaño más alto y App Store Connect escala el resto. Al ser solo iPhone, no hacen falta capturas de iPad. [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications)
- Las capturas de iPhone Duo pasan a ser obligatorias en abril de 2027 para apps compiladas con el SDK de iOS 27.1 o posterior (según la misma página); revisar al momento de enviar.
- Otros campos obligatorios de la ficha: descripción, palabras clave, Support URL, Privacy Policy URL, categoría y rating de edad. Previews en video: opcionales (hasta 3). [Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)

## TestFlight

- Testers internos: hasta 100 usuarios de App Store Connect. Los builds se prueban hasta 90 días. [TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview)
- Testers externos: hasta 10.000, por mail o link público. Hay que crear primero un grupo interno. Agregar el primer build a un grupo externo dispara Beta App Review; los builds siguientes pueden no requerir revisión completa. Se pueden enviar hasta 6 builds a revisión de TestFlight en 24 horas. [Add internal testers](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers/), [Invite external testers](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers/)
- Para compartir con testers externos se piden descripción del beta e información de revisión beta. [Provide test information](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information/)
- Los testers internos son usuarios de App Store Connect, por lo que la membresía de 99 USD es necesaria ya para el MVP vía TestFlight (inferencia a partir de lo anterior). Para gente fuera de la cuenta hace falta un grupo externo con Beta App Review. No verifiqué si los builds internos pasan por alguna revisión; la documentación consultada solo asocia la revisión a los grupos externos.
- Hace falta el registro de la app para subir builds, así que el nombre se reserva en ese momento (editable hasta enviar a revisión de la App Store).

## Rating por edad y "simulated gambling"

- Apple define: Gambling = apostar con dinero real o moneda del juego canjeable por dinero real, incluye juegos de cartas de casino (18+). Simulated Gambling = apostar sin dinero real ni moneda canjeable (infrecuente 13+, frecuente 18+). [Age ratings values and definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions)
- Una app que solo lleva la cuenta de partidas jugadas en la vida real, sin apuestas ni simulación del juego, no encaja en esas definiciones. Se responde "None" en gambling y simulated gambling, y el rating esperable es 4+ (**inferencia**: Apple no trata este caso explícitamente).
- No incluir mecánicas de apuesta (por ejemplo dinero en juego o pozo) ni simular reparto de cartas o dados; si se agregara un simulador habría que revisar el cuestionario.
- Guideline 5.3.4 aplica a "real money gaming" y prohíbe ayudas de juego ilegales, como los contadores de cartas. Un anotador de puntos no es de ese tipo. La 5.3 regula juego con dinero real, sorteos y loterías. [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- Evitar vocabulario de apuestas en nombre, subtítulo y descripción.

## Otras guidelines relevantes

- 4.2 Minimum Functionality: la app debe ser "useful, unique, or app-like"; un anotador con historial y jugadores guardados cumple razonablemente.
- 2.5.1 / 2.5.2: solo APIs públicas y app autocontenida; ser offline no requiere nada especial. **No verificado**: la declaración de cifrado para exportación (`ITSAppUsesNonExemptEncryption`).
- Kids Category (1.3): no hace falta marcar la app como Kids y agrega restricciones.

## Implicancias para el ticket de nombre (#2) y la spec

1. Nombre máximo 30 caracteres y subtítulo máximo 30 (sin precios, sin referencias a otras apps, sin afirmaciones no verificables).
2. Nombre único, sin marcas ni nombres de otras apps. Verificar disponibilidad creando el registro de la app y chequear marcas por separado.
3. Reservar el nombre pronto: hace falta la membresía de 99 USD.
4. Hay que producir: ícono 1024 x 1024 sin alfa, capturas 1290 x 2796 o equivalentes, política de privacidad pública con URL, Support URL con contacto real, y una pantalla "Acerca de" con enlace a la política.
5. Mantener "Data Not Collected": sin analíticas ni SDKs de terceros.
