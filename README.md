# Spectrum 

Spectrum ist eine moderne, native Radio-App für macOS und iOS, entwickelt mit SwiftUI und SwiftData. Die App nutzt die offene Radio-Browser API, um Zugriff auf tausende Radiosender weltweit zu ermöglichen, sortiert nach Ländern und Genres.

## Features

- **Globale Sendersuche:** Blitzschnelle API-Suche nach Sendern, Ländern und Genres
- **Intelligente Gruppierung:** Automatische Zusammenfassung von Hauptsendern und ihren Unterkanälen/Regionalstationen
- **Robustes Streaming:** Filtert automatisch nicht abspielbare Stream-Formate (wie `.pls` und `.m3u`) sowie Sender ohne Logo für ein sauberes Nutzungserlebnis heraus
- **Favoritenverwaltung:** Blitzschnelles Sichern von Lieblingssendern direkt im persistenten Speicher mittels SwiftData
- **Moderner Full-Player:** Dynamischer, atmosphärisch weichgezeichneter Hintergrund basierend auf dem Sender-Favicon (inklusive nativer Steuerung und 3D-Effekten)
- **Plattformübergreifend:** Optimierte UI-Komponenten für iOS (Sheets, Swipe-Gesteln) und macOS

## Screenshots

| Discover & Suche | Moderner Full-Player | Favoriten-Ansicht |
| :---: | :---: | :---: |
| ![Discover](screenshots/discover.png) | ![Player](screenshots/player.png) | ![Favorites](screenshots/favorites.png) |

## Voraussetzungen

- **iOS 17.0+** / **macOS 14.0+**

## Datenquelle & Lizenzhinweise

Diese App nutzt die kostenlose und gemeinschaftlich gepflegte **Radio-Browser API**.

- **API-Provider:** [radio-browser.info](https://www.radio-browser.info/)
- **Daten-Lizenz:** Die Daten der Musikstationen stehen unter der **Open Database License (ODbL)** bzw. sind als **CC0 (Public Domain)** deklariert.

---

*Haftungsausschluss: Spectrum ist ein reiner Verzeichnis-Player. Die Urheberrechte der Audio-Streams liegen vollständig bei den jeweiligen Rundfunkanstalten und Plattformbetreibern.*
