# URU2.COM — reproductor IPTV para iPhone y iPad

App iOS de URU2.COM, basada en el proyecto de código abierto
[Another IPTV Player](https://github.com/bsogulcan/another-iptv-player) (MIT).

- Bundle ID: `com.uru2.player`
- Nombre en pantalla: URU2.COM
- Web: https://www.uru2.com · Contacto: contacto@uru2.com

## Cambios respecto del original

- Nombre, ícono y bundle ID de URU2.COM; modo oscuro fijo y verde de la marca (#1DDD90).
- Se quitaron las propinas ("Apoyar la aplicación") y el enlace a GitHub.
- "Acerca de": web uru2.com, contacto y licencias de código abierto.
- Soporte y reportes de errores van a contacto@uru2.com.
- Categorías de Uruguay primero ("Uruguay" o "UY" en el nombre), en TV en vivo, películas, series y listas M3U.
- Carátulas y logos de canales:
  - se aceptan servidores de imágenes con certificado HTTPS autofirmado (solo imágenes);
  - más tiempo de espera y más conexiones por servidor;
  - las URLs mal formadas se corrigen (espacios, `//host`, `host/...` sin `http://`);
  - `backdrop_path` como texto suelto, no solo como lista;
  - si la película o serie viene sin carátula en el listado, se usa la de la ficha.

- Banner arriba en Películas y Series con las 8 últimas agregadas (de la lista del usuario).
- "Top 10 películas" y "Top 10 series": ranking de `https://botcode.jp2000.xyz/uru2/most_watched.json`
  (solo IDs), cruzado con la lista del usuario. Solo se activa con listas de `tv.uru2.com`
  (`URU2Ranking.rankedHosts`) y solo se muestra si coinciden al menos 5 títulos.

## Compilar sin Mac (Codemagic)

1. Cuenta de Apple Developer (USD 99/año).
2. En App Store Connect → Users and Access → Integrations, creá una API key con rol
   *App Manager* y descargá el `.p8`.
3. En developer.apple.com → Identifiers, registrá el App ID `com.uru2.player`.
   Después, en App Store Connect → Apps → "+", creá la app con ese bundle ID.
4. En Codemagic: conectá este repo y en Team settings → Integrations → Developer Portal
   cargá la API key con el nombre **URU2 ASC**.
5. En Codemagic → Team settings → Code signing identities:
   - en *iOS certificates*, generá un certificado *Apple Distribution*;
   - en *iOS provisioning profiles*, bajá o creá el perfil *App Store* de `com.uru2.player`.
6. Ejecutá el workflow **URU2.COM iOS → TestFlight**. La primera compilación tarda
   más porque descarga FFmpeg/KSPlayer.

## Licencias

- Código base: MIT (ver `LICENSE`; el aviso también aparece en la app).
- KSPlayer (motor de video): **GPL-3.0**. Mientras se use la versión gratuita, el código
  de esta app tiene que estar publicado (repositorio público).
- FFmpegKit: LGPL. GRDB, GRDBQuery, Nuke: MIT.
