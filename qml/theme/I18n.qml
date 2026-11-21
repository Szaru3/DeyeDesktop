pragma Singleton
import QtQuick

QtObject {
    id: root

    property string lang: "en"
    readonly property bool isPl: lang === "pl"

    readonly property var plMap: ({
        // Login
        "Sign in to your Deye Cloud account": "Zaloguj się na swoje konto Deye Cloud",
        "Account": "Konto",
        "Email Address": "Adres e-mail",
        "Password": "Hasło",
        "Account password": "Hasło do konta",
        "Show": "Pokaż",
        "Hide": "Ukryj",
        "Remember credentials on this computer": "Zapamiętaj dane logowania na tym komputerze",
        "Developer API Settings": "Ustawienia API deweloperskiego",
        "Region, App ID & App Secret": "Region, App ID i App Secret",
        "Configured": "Skonfigurowano",
        "Cloud Region": "Region chmury",
        "Company ID (optional)": "ID firmy (opcjonalnie)",
        "Leave empty for personal accounts": "Pozostaw puste dla kont prywatnych",
        "Sign In": "Zaloguj się",
        "Signing in...": "Logowanie…",
        "Preview Demo Mode": "Podgląd trybu demo",
        "Language": "Język",

        // Navigation & Header
        "Navigation menu": "Menu nawigacji",
        "Overview": "Przegląd",
        "Devices": "Urządzenia",
        "Alerts": "Alerty",
        "Plant Info": "Informacje",
        "Sign Out": "Wyloguj",
        "Dismiss": "Zamknij",
        "Updated": "Zaktualizowano",
        "No Plant Selected": "Nie wybrano instalacji",
        "Real-time plant overview": "Podgląd instalacji w czasie rzeczywistym",

        // Status
        "Online": "Online",
        "Partial": "Częściowo",
        "Offline": "Offline",
        "Unknown": "Nieznany",
        "Active": "Aktywny",
        "Resolved": "Rozwiązany",
        "Fault": "Awaria",
        "Warning": "Ostrzeżenie",

        // Flow Graph & KPI Cards
        "Flow Graph": "Przepływ energii",
        "Inverter": "Falownik",
        "Microinverter": "Mikrofalownik",
        "Battery": "Bateria",
        "Data Logger": "Rejestrator",
        "Smart Meter": "Licznik energii",
        "Device": "Urządzenie",
        "On grid": "Podłączono",
        "Exporting": "Eksport",
        "Solar Generation": "Produkcja PV",
        "Producing power": "Produkcja energii",
        "Standby / Night": "Czuwanie / Noc",
        "Charging": "Ładowanie",
        "Discharging": "Rozładowywanie",
        "Idle": "Spoczynek",
        "Grid": "Sieć",
        "Importing from grid": "Pobór z sieci",
        "Exporting to grid": "Eksport do sieci",
        "Balanced": "Zbilansowano",
        "Home Load": "Zużycie domu",
        "Current consumption": "Aktualny pobór",

        // Charts
        "Power Profile": "Profil mocy",
        "PV": "PV",
        "Battery SOC": "Naładowanie baterii",
        "No power profile data for this date": "Brak danych profilu mocy dla tej daty",
        "Generation & Usage History": "Historia produkcji i zużycia",
        "Production": "Produkcja",
        "Discharge": "Rozładowanie",
        "Purchased": "Pobrane z sieci",
        "Consumption": "Zużycie",
        "Charge": "Ładowanie",
        "Grid Feed-in": "Oddane do sieci",
        "No history data for this period": "Brak danych historycznych dla tego okresu",
        "All Years": "Wszystkie lata",

        // Devices & Rename
        "Loading devices…": "Ładowanie urządzeń…",
        "No Devices Found": "Nie znaleziono urządzeń",
        "No inverters, data loggers, or batteries were returned for this plant.": "Brak falowników, rejestratorów lub baterii dla tej instalacji.",
        "Rename device": "Zmień nazwę urządzenia",
        "Rename Device": "Zmień nazwę urządzenia",
        "Default": "Domyślna",
        "Saved locally on this computer (does not modify Deye Cloud).": "Zapisywane lokalnie na tym komputerze (nie zmienia nazwy w Deye Cloud).",
        "Reset": "Resetuj",
        "Cancel": "Anuluj",
        "Save": "Zapisz",
        "Settings": "Ustawienia",

        // Alerts
        "No Alerts": "Brak alertów",
        "No active faults or recent warnings were reported for this plant in the last 7 days.": "Brak aktywnych awarii i ostrzeżeń dla tej instalacji w ciągu ostatnich 7 dni.",
        "Started": "Początek",

        // Plant Info
        "Plant Name": "Nazwa instalacji",
        "Plant ID": "ID instalacji",
        "Address": "Adres",
        "Not specified": "Nie podano",
        "Installed Capacity": "Moc zainstalowana",
        "Connection Status": "Status połączenia",
        "Last Update": "Ostatnia aktualizacja",

        // Inverter Settings Dialog
        "Reload": "Odśwież",
        "Close": "Zamknij",
        "Loading current config…": "Wczytywanie konfiguracji…",
        "System": "System",
        "Time of Use": "Harmonogram (TOU)",
        "Advanced": "Zaawansowane",
        "Apply": "Zastosuj",
        "Enabled": "Włączone",
        "Disabled": "Wyłączone",
        "Enable": "Włącz",
        "System Work Mode": "Tryb pracy systemu",
        "Energy Pattern": "Priorytet energii",
        "Solar Sell": "Eksport nadwyżek PV",
        "Export Limit Control": "Kontrola limitu eksportu",
        "Max Sell Power (W)": "Maks. moc eksportu (W)",
        "Max Solar Power (W)": "Maks. moc PV (W)",
        "Grid Peak Shaving": "Ograniczanie szczytów sieci",
        "Battery Type": "Typ baterii",
        "Grid Charge Mode": "Ładowanie z sieci",
        "Generator Charge Mode": "Ładowanie z generatora",
        "Max Charge Current (A)": "Maks. prąd ładowania (A)",
        "Max Discharge Current (A)": "Maks. prąd rozładowania (A)",
        "Grid Charge Current (A)": "Prąd ładowania z sieci (A)",
        "Generator Charge Current (A)": "Prąd ładowania z generatora (A)",
        "Battery Capacity (Ah)": "Pojemność baterii (Ah)",
        "Shutdown SOC (%)": "SOC wyłączenia (%)",
        "Low Battery SOC (%)": "Niski poziom baterii (%)",
        "Restart SOC (%)": "SOC ponownego uruchomienia (%)",
        "Grid Charge Start SOC (%)": "SOC startu ładowania z sieci (%)",
        "Generator Charge Start SOC (%)": "SOC startu ładowania z generatora (%)",
        "Equalization Voltage (V)": "Napięcie wyrównawcze (V)",
        "Absorption Voltage (V)": "Napięcie absorpcji (V)",
        "Float Voltage (V)": "Napięcie podtrzymania (V)",
        "Time of Use Schedule": "Harmonogram Time of Use",
        "Slot": "Okno",
        "Start Time": "Start",
        "SOC (%)": "SOC (%)",
        "Power (W)": "Moc (W)",
        "Gen": "Gen",
        "Apply Time of Use Schedule": "Zastosuj harmonogram TOU",
        "Custom Modbus / Control Command": "Własna komenda Modbus / sterowania",
        "Send Custom Command": "Wyślij komendę"
    })

    function t(key) {
        if (isPl && plMap[key] !== undefined) {
            return plMap[key];
        }
        return key;
    }
}
