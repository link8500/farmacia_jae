# Imágenes ilustrativas de productos

## Procedencia y límites

Ocho envases genéricos creados con la herramienta integrada de generación de imágenes (habilidad `imagegen`), a petición del usuario para una demostración. No son fotografías de fabricantes, no se descargaron de bancos de imágenes y no requieren claves API para mostrarse. Los archivos finales se incluyen localmente en `images/products/`.

Son envases ficticios, no referencias para reconocer medicamentos reales. El color o forma de una tableta representada no acredita su identidad, autenticidad ni composición. No se añadieron instrucciones médicas. Las imágenes se identifican en la interfaz como ilustrativas; los nombres, códigos y presentaciones de las fichas siguen siendo la identificación operativa.

## Integración

- `ProductIllustrations` centraliza las claves, rutas y metadatos del catálogo visual.
- `ProductThumbnail` reutiliza el mismo encuadre y fallback accesible en Productos, formularios y Facturación. No hace peticiones a terceros.
- `Product.illustrationKey` conserva la elección en el guardado local y los respaldos, también al archivar/reactivar.
- El formulario permite elegir uno de los ocho recursos o «Sin imagen». Una clave desconocida muestra un icono local, sin romper la vista.
- Los respaldos anteriores, que no incluían el campo, reconocen únicamente las ocho fichas demo originales por ID, código y nombre exactos. Se acepta la presentación completa o su formato antiguo abreviado («Caja», «Frasco», «Tubo»), sin modificar la presentación guardada. No se cambia stock ni se asignan imágenes a otros productos por coincidencias parciales.
- Vaciar una selección se guarda explícitamente y no se vuelve a asignar una imagen en la siguiente recarga. No hace falta reiniciar ni borrar los datos del navegador.
- Para un catálogo real deberán sustituirse por fotografías autorizadas de los envases exactos.

## Recuperación de asociaciones antiguas

Si las fichas quedaron guardadas con `illustrationKey` vacío (por ejemplo, en
una sesión anterior a incorporar las fotos), se muestra **Recuperar imágenes**
en Compra → Productos, solo para administración. Tras confirmar, se asocian
en lote los recursos de los productos demo reconocidos que no tienen una clave
válida. Se mantienen selecciones válidas, productos ajenos al demo, precios,
presentaciones, estado, lotes, existencias y comprobantes. La reparación se
guarda y queda en auditoría. No requiere borrar el almacenamiento del navegador.

Una selección explícita de «Sin imagen» se sigue respetando al recargar. Solo
esta acción confirmada puede recuperar también esas fichas. Para otros artículos
se elige la ilustración desde **Editar ficha → Imagen de demostración**.

El icono de medicamento significa que no hay imagen asociada; un icono de
imagen rota identifica ahora un fallo al cargar el recurso. En desarrollo,
después de cambiar el estado inicial, usa **Hot Restart**, no solo Hot Reload:
este último conserva los objetos existentes y no equivale a cargar otra vez el
catálogo persistido. Si hiciera falta detener el proceso y abrir otra sesión de
Chrome, exporta primero un respaldo: Flutter puede usar un perfil temporal.
No usar «limpiar datos» para resolverlo. Al publicar, subir todo `build/web`,
incluido `assets/`.

## Archivos y prompts finales

Se utilizó el modo integrado, sin CLI ni API propia. Cada imagen se solicita por separado con el siguiente prompt completo; no se utilizan imágenes comerciales como referencia.

### `images/products/paracetamol.png`

```text
Use case: product-mockup.
Asset type: one square product illustration for an employee-facing pharmacy demonstration web app. This is a fictional generic packaging mockup, not a photograph of an actual medicine brand and not medical advice.
Style: highly polished photorealistic studio product photography. Pure white seamless opaque background, soft natural contact shadow, crisp matte-white cardboard and realistic foil/plastic materials, restrained neutral design with a thin muted teal accent. Centered single product grouping, consistent three-quarter camera angle, fully visible with generous clean margin. Strong readable silhouette at thumbnail scale. No people, hands, lifestyle props, branded symbols, real manufacturer logos, barcodes, registration numbers, claims or usage instructions. No collage or grid. No text outside the physical packaging. Keep any lettering simple, accurate and sparse; a small label on the physical package reads 'DEMO'. Intended only as an illustrative demo asset, no real-product identification.

Subject: A compact generic carton for Paracetamol 500 mg with one neat foil blister of white oblong tablets in front. Packaging text exactly 'PARACETAMOL', '500 mg', '10 tabletas', 'DEMO'.
```

### `images/products/amoxicilina.png`

```text
Use case: product-mockup.
Asset type: one square product illustration for an employee-facing pharmacy demonstration web app. This is a fictional generic packaging mockup, not a photograph of an actual medicine brand and not medical advice.
Style: highly polished photorealistic studio product photography. Pure white seamless opaque background, soft natural contact shadow, crisp matte-white cardboard and realistic foil/plastic materials, restrained neutral design with a thin muted teal accent. Centered single product grouping, consistent three-quarter camera angle, fully visible with generous clean margin. Strong readable silhouette at thumbnail scale. No people, hands, lifestyle props, branded symbols, real manufacturer logos, barcodes, registration numbers, claims or usage instructions. No collage or grid. No text outside the physical packaging. Keep any lettering simple, accurate and sparse; a small label on the physical package reads 'DEMO'. Intended only as an illustrative demo asset, no real-product identification.

Subject: A compact generic carton for Amoxicilina 500 mg with one neat foil blister of two-tone red-and-cream capsules in front. Packaging text exactly 'AMOXICILINA', '500 mg', '10 cápsulas', 'DEMO'.
```

### `images/products/loratadina.png`

```text
Use case: product-mockup.
Asset type: one square product illustration for an employee-facing pharmacy demonstration web app. This is a fictional generic packaging mockup, not a photograph of an actual medicine brand and not medical advice.
Style: highly polished photorealistic studio product photography. Pure white seamless opaque background, soft natural contact shadow, crisp matte-white cardboard and realistic foil/plastic materials, restrained neutral design with a thin muted teal accent. Centered single product grouping, consistent three-quarter camera angle, fully visible with generous clean margin. Strong readable silhouette at thumbnail scale. No people, hands, lifestyle props, branded symbols, real manufacturer logos, barcodes, registration numbers, claims or usage instructions. No collage or grid. No text outside the physical packaging. Keep any lettering simple, accurate and sparse; a small label on the physical package reads 'DEMO'. Intended only as an illustrative demo asset, no real-product identification.

Subject: A slim generic carton for Loratadina 10 mg with one small neat foil blister of round white tablets in front. Packaging text exactly 'LORATADINA', '10 mg', '10 tabletas', 'DEMO'.
```

### `images/products/ibuprofeno.png`

```text
Use case: product-mockup.
Asset type: one square product illustration for an employee-facing pharmacy demonstration web app. This is a fictional generic packaging mockup, not a photograph of an actual medicine brand and not medical advice.
Style: highly polished photorealistic studio product photography. Pure white seamless opaque background, soft natural contact shadow, crisp matte-white cardboard and realistic foil/plastic materials, restrained neutral design with a thin muted teal accent. Centered single product grouping, consistent three-quarter camera angle, fully visible with generous clean margin. Strong readable silhouette at thumbnail scale. No people, hands, lifestyle props, branded symbols, real manufacturer logos, barcodes, registration numbers, claims or usage instructions. No collage or grid. No text outside the physical packaging. Keep any lettering simple, accurate and sparse; a small label on the physical package reads 'DEMO'. Intended only as an illustrative demo asset, no real-product identification.

Subject: A compact generic carton for Ibuprofeno 400 mg with one neat foil blister of oval white tablets in front. Packaging text exactly 'IBUPROFENO', '400 mg', '10 tabletas', 'DEMO'.
```

### `images/products/omeprazol.png`

```text
Use case: product-mockup.
Asset type: one square product illustration for an employee-facing pharmacy demonstration web app. This is a fictional generic packaging mockup, not a photograph of an actual medicine brand and not medical advice.
Style: highly polished photorealistic studio product photography. Pure white seamless opaque background, soft natural contact shadow, crisp matte-white cardboard and realistic foil/plastic materials, restrained neutral design with a thin muted teal accent. Centered single product grouping, consistent three-quarter camera angle, fully visible with generous clean margin. Strong readable silhouette at thumbnail scale. No people, hands, lifestyle props, branded symbols, real manufacturer logos, barcodes, registration numbers, claims or usage instructions. No collage or grid. No text outside the physical packaging. Keep any lettering simple, accurate and sparse; a small label on the physical package reads 'DEMO'. Intended only as an illustrative demo asset, no real-product identification.

Subject: A compact generic carton for Omeprazol 20 mg with one neat foil blister of purple-and-white capsules in front. Packaging text exactly 'OMEPRAZOL', '20 mg', '10 cápsulas', 'DEMO'.
```

### `images/products/alcohol.png`

```text
Use case: product-mockup.
Asset type: one square product illustration for an employee-facing pharmacy demonstration web app. This is a fictional generic packaging mockup, not a photograph of an actual medicine brand and not medical advice.
Style: highly polished photorealistic studio product photography. Pure white seamless opaque background, soft natural contact shadow, crisp matte-white cardboard and realistic foil/plastic materials, restrained neutral design with a thin muted teal accent. Centered single product grouping, consistent three-quarter camera angle, fully visible with generous clean margin. Strong readable silhouette at thumbnail scale. No people, hands, lifestyle props, branded symbols, real manufacturer logos, barcodes, registration numbers, claims or usage instructions. No collage or grid. No text outside the physical packaging. Keep any lettering simple, accurate and sparse; a small label on the physical package reads 'DEMO'. Intended only as an illustrative demo asset, no real-product identification.

Subject: A single small amber medicinal alcohol bottle with a white screw cap and a minimal white paper label. No box or other objects. Label text exactly 'ALCOHOL MEDICINAL', '120 ml', 'DEMO'. Do not add any concentration because the demo catalog does not specify one.
```

### `images/products/vitamina-c.png`

```text
Use case: product-mockup.
Asset type: one square product illustration for an employee-facing pharmacy demonstration web app. This is a fictional generic packaging mockup, not a photograph of an actual medicine brand and not medical advice.
Style: highly polished photorealistic studio product photography. Pure white seamless opaque background, soft natural contact shadow, crisp matte-white cardboard and realistic foil/plastic materials, restrained neutral design with a thin muted teal accent. Centered single product grouping, consistent three-quarter camera angle, fully visible with generous clean margin. Strong readable silhouette at thumbnail scale. No people, hands, lifestyle props, branded symbols, real manufacturer logos, barcodes, registration numbers, claims or usage instructions. No collage or grid. No text outside the physical packaging. Keep any lettering simple, accurate and sparse; a small label on the physical package reads 'DEMO'. Intended only as an illustrative demo asset, no real-product identification.

Subject: A single tall white cylindrical tube of effervescent vitamin C tablets with a white plastic cap, a small restrained orange accent line, and one circular tablet next to the base. Label text exactly 'VITAMINA C', '1 g', '10 tabletas', 'DEMO'.
```

### `images/products/losartan.png`

```text
Use case: product-mockup.
Asset type: one square product illustration for an employee-facing pharmacy demonstration web app. This is a fictional generic packaging mockup, not a photograph of an actual medicine brand and not medical advice.
Style: highly polished photorealistic studio product photography. Pure white seamless opaque background, soft natural contact shadow, crisp matte-white cardboard and realistic foil/plastic materials, restrained neutral design with a thin muted teal accent. Centered single product grouping, consistent three-quarter camera angle, fully visible with generous clean margin. Strong readable silhouette at thumbnail scale. No people, hands, lifestyle props, branded symbols, real manufacturer logos, barcodes, registration numbers, claims or usage instructions. No collage or grid. No text outside the physical packaging. Keep any lettering simple, accurate and sparse; a small label on the physical package reads 'DEMO'. Intended only as an illustrative demo asset, no real-product identification.

Subject: A slightly larger generic carton for Losartán 50 mg with three neat overlapping foil blister strips of white tablets in front. Packaging text exactly 'LOSARTÁN', '50 mg', '30 tabletas', 'DEMO'.
```

