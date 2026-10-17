# Taskbar Thermals Fix

[English](README.md) · [Pobierz instalator](https://github.com/Artllex/taskbar-thermals-fix/releases/latest) · [Zgłoś problem](https://github.com/Artllex/taskbar-thermals-fix/issues)

Poprawka utrzymująca **panel temperatur Taskbar Thermals przy otwartym menu Start w Windows 11**, również po sekwencji **Start → kliknięcie pustego miejsca na pasku zadań**.

To niezależna poprawka zgodności dla [Taskbar Thermals autorstwa Quenchh](https://github.com/Quenchh/taskbar-thermals), działająca jako lokalny moduł [Windhawk](https://windhawk.net/). Instalator udostępnia też opcjonalną poprawkę aplikacji dotyczącą robienia zrzutów ekranu.

## Pobieranie i instalacja

1. Zainstaluj i uruchom **Taskbar Thermals** oraz standardową, nieprzenośną wersję **Windhawk x64**.
2. Pobierz `TaskbarThermalsFix-1.0.0-Setup.exe` z sekcji [Releases](https://github.com/Artllex/taskbar-thermals-fix/releases/latest).
3. Uruchom instalator i wybierz polski lub angielski. Instalacja standardowa dodaje wyłącznie moduł zgodności z menu Start.
4. Opcjonalnie zaznacz składnik **poprawki zrzutów ekranu** i wskaż obecny plik `TaskbarThermals.exe`.

Instalacja modułu Windhawk wymaga zgody administratora. Instalator ponownie uruchamia Taskbar Thermals, aby poprawka zaczęła działać. Zachowuje ustawienia temperatur, historię, logi, konfigurację autostartu i pozostałe mody Windhawk.

Opcjonalny składnik aplikacji obsługuje **oficjalny plik Taskbar Thermals 1.1.0 wymagający środowiska .NET** oraz udokumentowaną wersję lokalną `1.1.0-local.7`. Dla innych wersji, w tym wariantu standalone, można zainstalować sam moduł menu Start. Instalator odrzuca nieznane pliki zamiast je nadpisywać. Opcjonalna poprawka zachowuje wymaganie oryginalnej aplikacji dotyczące .NET 8 Desktop Runtime.

## Zakres poprawki

| Objaw | Składnik |
| --- | --- |
| Panel znika pod menu Start | Moduł zgodności Windhawk |
| Panel długo nie wraca po kliknięciu Startu, a następnie paska | Moduł zgodności Windhawk |
| Narzędzie zrzutów powoduje ukrycie panelu przez aplikację | Opcjonalna poprawka Taskbar Thermals |
| Kliknięcie paska na chwilę zasłania panel | Opcjonalna poprawka aplikacji reaguje na zmianę kolejności okien i skraca interwał awaryjnego odświeżania |

Windows przenosi pasek do osobnej warstwy okien podczas korzystania ze Startu. Zwykłe okno „zawsze na wierzchu” nie przechodzi za nim do tej warstwy. Moduł synchronizuje wyłącznie zweryfikowane okno Taskbar Thermals w chwili, gdy Eksplorator zmienia warstwę paska. Korzysta z prywatnych interfejsów Windows, dlatego zgodność z przyszłymi kompilacjami systemu wymaga sprawdzania. Podstawa techniczna: [badania ADeltaX dotyczące warstw okien](https://blog.adeltax.com/window-z-order-in-windows-10/).

## Autostart i odinstalowanie

Włączony moduł jest zapisany w konfiguracji Windhawk i ładuje się wraz z nim. Aby działał po zalogowaniu, pozostaw włączony autostart Windhawk i dotychczasowy autostart Taskbar Thermals. Instalator nie dodaje drugiego wpisu autostartu ani nie zmienia obecnego.

Usuwanie: **Ustawienia Windows → Aplikacje → Zainstalowane aplikacje → Taskbar Thermals Fix → Odinstaluj**. Deinstalator przywraca wcześniejszą konfigurację i źródło tego samego modułu, jeżeli istniały, albo usuwa jego nowy wpis. Dla opcjonalnej poprawki aplikacji przywraca kopię pliku tylko wtedy, gdy obecny plik nadal pochodzi z tego instalatora. Jeśli później samodzielnie zaktualizujesz program, nowszy plik pozostanie, a kopia oryginału zostanie zachowana w `%ProgramData%\TaskbarThermalsFix`.

## Sprawdzenie działania

Środowisko początkowej weryfikacji: **Windows 11 25H2 x64, kompilacja 26200.9711; Windhawk 1.7.3; Taskbar Thermals 1.1.0 / local.7**.

- Działające rozwiązanie sprawdzono na obrazie ekranu przy otwartym Starcie, po kliknięciu paska i podczas robienia zrzutu, w tym przez trzy powtórzenia kliknięcia przycisku Start.
- Backend instalatora ma odizolowane testy instalacji, aktualizacji, cofania zmian, odtwarzania wcześniejszego modułu, odrzucania nieznanych plików i zachowania nowszej aplikacji użytkownika.
- Początkowa weryfikacja nie obejmowała rzeczywistego restartu Windows. Uwzględniono zapis konfiguracji i wczesne ładowanie Eksploratora; test po restarcie jest odrębnym sprawdzeniem.

## Budowanie ze źródeł

Wymagania: Windows x64, **.NET SDK 8.0.426** (wersja przypięta w `global.json`), **dystrybucja offline Windhawk 1.7.3** z kompilatorem i SDK oraz **Inno Setup 6**.

```powershell
.\scripts\build.ps1
.\tests\installer.tests.ps1
```

Parametry `-Dotnet`, `-WindhawkPath` i `-InnoCompiler` pozwalają wskazać narzędzia. Wyniki trafiają do `build/` i `dist/`. Dokładne wersje i skróty zależności są zapisane w `vendor/TaskbarThermals/packages.lock.json`. Automatyczny workflow buduje i testuje pakiet; publikacja wydania jest osobną operacją.

## Licencja i autorzy

Moduł zgodności, instalator i nowy kod: **MIT**, plik [LICENSE](LICENSE). Dołączony kod Taskbar Thermals zachowuje **licencję MIT i informację o autorze Quenchh**. Zmodyfikowana aplikacja bazuje na commicie `23207757799d2df6d22f2a42825cea81404ccbde`; zmiany dotyczą wykrywania okien systemowych, reakcji na zmianę kolejności okien paska i interwału jego odświeżania.

Zależności aplikacji zachowują swoje licencje, w tym MPL-2.0. Szczegóły zawierają [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md), wersje źródeł i zależności oraz teksty licencji dołączone do pakietu. Windhawk jest instalowany oddzielnie i nie jest rozpowszechniany w tym instalatorze. Projekt nie jest oficjalnym wydaniem Quenchh ani Windhawk.
