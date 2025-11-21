package main

import (
	"crypto/rand"
	_ "embed"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sync"
	"time"

	_ "image/jpeg"
	_ "image/png"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/canvas"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/dialog"
	"fyne.io/fyne/v2/driver/desktop"
	"fyne.io/fyne/v2/layout"
	"fyne.io/fyne/v2/theme"
	"fyne.io/fyne/v2/widget"
	"golang.org/x/sys/windows/registry"
)

//go:embed favicon.png
var iconData []byte

const (
	httpPort       = ":8080"
	broadcastPort  = 5000
	configFileName = "config.json"
	appName        = "pc-remote-server"
	registryKey    = `Software\Microsoft\Windows\CurrentVersion\Run`
)

type Config struct {
	Password string `json:"password"`
}

var (
	currentConfig Config
	configMutex   sync.RWMutex
	translations  map[string]map[string]string
	currentLang   string = "en"
	isDarkTheme   bool   = true
	a             fyne.App
	w             fyne.Window
	trayMenu      *fyne.Menu
	titleLabel    *widget.Label
	infoLabel     *widget.Label
	ipLabel       *widget.Label
	passLabel     *widget.Label
	themeLabel    *widget.Label
	langLabel     *widget.Label
	startupCheck  *widget.Check
	copyBtn       *widget.Button
	saveBtn       *widget.Button
	themeSelect   *widget.Select
	langSelect    *widget.Select
)

func init() {
	translations = map[string]map[string]string{
		"en": {
			"title":         "Remote Server Active",
			"info":          "App running in background.\nUse mobile app to connect.",
			"ip_label":      "IP Address",
			"pass_label":    "Secret Key",
			"copy_btn":      "Copy Key",
			"save_btn":      "Save New Key",
			"theme_label":   "Theme",
			"lang_label":    "Language",
			"theme_dark":    "Dark",
			"theme_light":   "Light",
			"startup_label": "Run at Windows startup",
			"toast_saved":   "Password Saved to Disk!",
			"toast_copied":  "Password Copied!",
			"about_title":   "About",
			"about_text":    "Hi there!\nThanks for using our program.\n\nDeveloped by vados2343 for comfortable PC control.",
			"cfg_error":     "Config Error",
			"cfg_err_txt":   "Could not save config file!",
			"reg_error":     "Registry Error",
			"reg_err_txt":   "Could not update startup registry key!",
		},
		"ru": {
			"title":         "Сервер Активен",
			"info":          "Приложение работает в фоне.\nИспользуйте телефон для подключения.",
			"ip_label":      "IP Адрес",
			"pass_label":    "Секретный Ключ",
			"copy_btn":      "Копировать Ключ",
			"save_btn":      "Сохранить Новый Ключ",
			"theme_label":   "Тема",
			"lang_label":    "Язык",
			"theme_dark":    "Тёмная",
			"theme_light":   "Светлая",
			"startup_label": "Запускать вместе с Windows",
			"toast_saved":   "Пароль сохранен на диск!",
			"toast_copied":  "Пароль скопирован!",
			"about_title":   "О программе",
			"about_text":    "Привет!\nСпасибо, что пользуетесь нашей программой.\n\nРазработано vados2343 для удобного управления ПК.",
			"cfg_error":     "Ошибка конфига",
			"cfg_err_txt":   "Не удалось сохранить файл настроек!",
			"reg_error":     "Ошибка реестра",
			"reg_err_txt":   "Не удалось обновить запись автозапуска!",
		},
		"uk": {
			"title":         "Сервер Активний",
			"info":          "Додаток працює у фоні.\nВикористовуйте телефон для підключення.",
			"ip_label":      "IP Адреса",
			"pass_label":    "Секретний Ключ",
			"copy_btn":      "Копіювати Ключ",
			"save_btn":      "Зберегти Новий Ключ",
			"theme_label":   "Тема",
			"lang_label":    "Мова",
			"theme_dark":    "Темна",
			"theme_light":   "Світла",
			"startup_label": "Запускати разом з Windows",
			"toast_saved":   "Пароль збережено на диск!",
			"toast_copied":  "Пароль скопійовано!",
			"about_title":   "Про програму",
			"about_text":    "Привіт!\nДякуємо, що користуєтесь нашою програмою.\n\nРозроблено vados2343 для зручного керування ПК.",
			"cfg_error":     "Помилка конфігу",
			"cfg_err_txt":   "Не вдалося зберегти файл налаштувань!",
			"reg_error":     "Помилка реєстру",
			"reg_err_txt":   "Не вдалося оновити запис автозапуску!",
		},
		"it": {
			"title":         "Server Attivo",
			"info":          "App in esecuzione in background.\nUsa l'app mobile per connetterti.",
			"ip_label":      "Indirizzo IP",
			"pass_label":    "Chiave Segreta",
			"copy_btn":      "Copia Chiave",
			"save_btn":      "Salva Nuova Chiave",
			"theme_label":   "Tema",
			"lang_label":    "Lingua",
			"theme_dark":    "Scuro",
			"theme_light":   "Chiaro",
			"startup_label": "Esegui all'avvio di Windows",
			"toast_saved":   "Password Salvata su Disco!",
			"toast_copied":  "Password Copiata!",
			"about_title":   "Info",
			"about_text":    "Ciao!\nGrazie per aver utilizzato il nostro programma.\n\nSviluppato da vados2343 per un controllo PC più confortevole.",
			"cfg_error":     "Errore Config",
			"cfg_err_txt":   "Impossibile salvare il file di configurazione!",
			"reg_error":     "Errore Registro",
			"reg_err_txt":   "Impossibile aggiornare la chiave di avvio!",
		},
	}
}

func tr(key string) string {
	if mapStrings, ok := translations[currentLang]; ok {
		if val, ok := mapStrings[key]; ok {
			return val
		}
	}
	return key
}

func updateUI() {
	titleLabel.SetText(tr("title"))
	infoLabel.SetText(tr("info"))
	ipLabel.SetText(tr("ip_label"))
	passLabel.SetText(tr("pass_label"))
	themeLabel.SetText(tr("theme_label"))
	langLabel.SetText(tr("lang_label"))
	copyBtn.SetText(tr("copy_btn"))
	saveBtn.SetText(tr("save_btn"))
	startupCheck.SetText(tr("startup_label"))

	themeSelect.Options = []string{tr("theme_dark"), tr("theme_light")}
	if isDarkTheme {
		themeSelect.SetSelected(tr("theme_dark"))
	} else {
		themeSelect.SetSelected(tr("theme_light"))
	}
	themeSelect.Refresh()
}

func generateRandomKey() string {
	bytes := make([]byte, 8)
	if _, err := rand.Read(bytes); err != nil {
		return "vados2343Secure"
	}
	return hex.EncodeToString(bytes)
}

func getConfigPath() string {
	configDir, err := os.UserConfigDir()
	if err != nil {
		configDir, _ = os.Getwd()
	}
	appDir := filepath.Join(configDir, appName)
	if _, err := os.Stat(appDir); os.IsNotExist(err) {
		os.MkdirAll(appDir, 0755)
	}
	return filepath.Join(appDir, configFileName)
}

func loadConfig() {
	configMutex.Lock()
	defer configMutex.Unlock()

	configPath := getConfigPath()

	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		currentConfig.Password = generateRandomKey()
		saveConfigInternal(configPath)
		return
	}

	file, err := os.Open(configPath)
	if err != nil {
		currentConfig.Password = generateRandomKey()
		return
	}
	defer file.Close()

	decoder := json.NewDecoder(file)
	err = decoder.Decode(&currentConfig)
	if err != nil || currentConfig.Password == "" {
		currentConfig.Password = generateRandomKey()
	}
}

func saveConfig(newPass string) bool {
	configMutex.Lock()
	defer configMutex.Unlock()
	currentConfig.Password = newPass
	configPath := getConfigPath()
	return saveConfigInternal(configPath)
}

func saveConfigInternal(path string) bool {
	file, err := os.Create(path)
	if err != nil {
		return false
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	err = encoder.Encode(currentConfig)
	return err == nil
}

func getPassword() string {
	configMutex.RLock()
	defer configMutex.RUnlock()
	return currentConfig.Password
}

func getStartupStatus() bool {
	k, err := registry.OpenKey(registry.CURRENT_USER, registryKey, registry.QUERY_VALUE)
	if err != nil {
		return false
	}
	defer k.Close()

	val, _, err := k.GetStringValue(appName)
	if err != nil {
		return false
	}
	return val != ""
}

func setStartupStatus(enabled bool) error {
	k, err := registry.OpenKey(registry.CURRENT_USER, registryKey, registry.SET_VALUE)
	if err != nil {
		return err
	}
	defer k.Close()

	if enabled {
		exe, err := os.Executable()
		if err != nil {
			return err
		}
		cmd := fmt.Sprintf(`"%s"`, exe)
		return k.SetStringValue(appName, cmd)
	} else {
		return k.DeleteValue(appName)
	}
}

func authMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		keys, ok := r.URL.Query()["key"]
		if !ok || len(keys[0]) < 1 || keys[0] != getPassword() {
			http.Error(w, "Forbidden", http.StatusUnauthorized)
			return
		}
		next(w, r)
	}
}

func getLocalIP() string {
	conn, err := net.Dial("udp", "8.8.8.8:80")
	if err != nil {
		return "Unknown"
	}
	defer conn.Close()
	return conn.LocalAddr().(*net.UDPAddr).IP.String()
}

func startBroadcasting() {
	addr, err := net.ResolveUDPAddr("udp", fmt.Sprintf("255.255.255.255:%d", broadcastPort))
	if err != nil {
		return
	}
	conn, err := net.DialUDP("udp", nil, addr)
	if err != nil {
		return
	}
	defer conn.Close()

	ticker := time.NewTicker(3 * time.Second)
	defer ticker.Stop()

	for range ticker.C {
		ip := getLocalIP()
		message := fmt.Sprintf("PC-REMOTE|http://%s%s", ip, httpPort)
		conn.Write([]byte(message))
	}
}

func executeCommand(command string, args ...string) error {
	var cmd *exec.Cmd
	if runtime.GOOS == "windows" {
		cmd = exec.Command(command, args...)
	} else {
		cmd = exec.Command("sudo", append([]string{command}, args...)...)
	}
	return cmd.Run()
}

func shutdownHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	io.WriteString(w, "Success")
	go func() {
		time.Sleep(1 * time.Second)
		executeCommand("shutdown", "/s", "/t", "0", "/f")
	}()
}

func rebootHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	io.WriteString(w, "Success")
	go func() {
		time.Sleep(1 * time.Second)
		executeCommand("shutdown", "/r", "/t", "0", "/f")
	}()
}

type tappableIcon struct {
	widget.Icon
	onTap func()
}

func newTappableIcon(res fyne.Resource, tapped func()) *tappableIcon {
	icon := &tappableIcon{onTap: tapped}
	icon.SetResource(res)
	icon.ExtendBaseWidget(icon)
	return icon
}

func (t *tappableIcon) Tapped(_ *fyne.PointEvent) {
	if t.onTap != nil {
		t.onTap()
	}
}

func showAboutDialog(win fyne.Window, iconRes fyne.Resource) {
	img := canvas.NewImageFromResource(iconRes)
	img.FillMode = canvas.ImageFillContain
	img.SetMinSize(fyne.NewSize(64, 64))

	text := widget.NewLabel(tr("about_text"))
	text.Alignment = fyne.TextAlignCenter

	content := container.NewVBox(
		container.NewCenter(img),
		widget.NewSeparator(),
		text,
	)

	dlg := dialog.NewCustom(tr("about_title"), "OK", content, win)
	dlg.Show()
}

func main() {
	loadConfig()
	localIP := getLocalIP()

	a = app.New()
	a.Settings().SetTheme(theme.DarkTheme())
	isDarkTheme = true

	iconResource := fyne.NewStaticResource("favicon.png", iconData)
	a.SetIcon(iconResource)

	w = a.NewWindow("PC Remote")

	titleLabel = widget.NewLabelWithStyle(tr("title"), fyne.TextAlignCenter, fyne.TextStyle{Bold: true})
	infoLabel = widget.NewLabel(tr("info"))
	infoLabel.Alignment = fyne.TextAlignCenter
	ipLabel = widget.NewLabel(tr("ip_label"))
	passLabel = widget.NewLabel(tr("pass_label"))
	themeLabel = widget.NewLabel(tr("theme_label"))
	langLabel = widget.NewLabel(tr("lang_label"))

	if desk, ok := a.(desktop.App); ok {
		desk.SetSystemTrayIcon(iconResource)
		trayMenu = fyne.NewMenu("PC Remote",
			fyne.NewMenuItem("Show Window", func() {
				w.Show()
			}),
			fyne.NewMenuItem("Quit", func() {
				a.Quit()
			}),
		)
		desk.SetSystemTrayMenu(trayMenu)
	}

	logo := newTappableIcon(iconResource, func() {
		showAboutDialog(w, iconResource)
	})

	logoContainer := container.NewGridWrap(fyne.NewSize(80, 80), logo)
	header := container.NewVBox(container.NewCenter(logoContainer), titleLabel)

	ipEntry := widget.NewEntry()
	ipEntry.SetText(localIP)
	ipEntry.Disable()

	keyEntry := widget.NewPasswordEntry()
	keyEntry.SetText(getPassword())

	saveBtn = widget.NewButtonWithIcon(tr("save_btn"), theme.DocumentSaveIcon(), func() {
		success := saveConfig(keyEntry.Text)
		if success {
			a.SendNotification(fyne.NewNotification("PC Remote", tr("toast_saved")))
		} else {
			dialog.ShowError(fmt.Errorf(tr("cfg_err_txt")), w)
		}
	})

	copyBtn = widget.NewButtonWithIcon(tr("copy_btn"), theme.ContentCopyIcon(), func() {
		w.Clipboard().SetContent(keyEntry.Text)
		a.SendNotification(fyne.NewNotification("PC Remote", tr("toast_copied")))
	})

	startupCheck = widget.NewCheck(tr("startup_label"), func(checked bool) {
		err := setStartupStatus(checked)
		if err != nil {
			dialog.ShowError(fmt.Errorf("%s: %v", tr("reg_err_txt"), err), w)
			startupCheck.SetChecked(!checked)
		}
	})
	startupCheck.SetChecked(getStartupStatus())

	themeSelect = widget.NewSelect([]string{tr("theme_dark"), tr("theme_light")}, func(s string) {
		if s == tr("theme_dark") {
			a.Settings().SetTheme(theme.DarkTheme())
			isDarkTheme = true
		} else if s == tr("theme_light") {
			a.Settings().SetTheme(theme.LightTheme())
			isDarkTheme = false
		}
	})
	themeSelect.SetSelected(tr("theme_dark"))

	langSelect = widget.NewSelect([]string{"English", "Русский", "Українська", "Italiano"}, func(s string) {
		switch s {
		case "English":
			currentLang = "en"
		case "Русский":
			currentLang = "ru"
		case "Українська":
			currentLang = "uk"
		case "Italiano":
			currentLang = "it"
		}
		updateUI()
	})
	langSelect.SetSelected("English")

	settingsGrid := container.NewGridWithColumns(2,
		container.NewVBox(themeLabel, themeSelect),
		container.NewVBox(langLabel, langSelect),
	)

	form := container.NewVBox(
		ipLabel,
		ipEntry,
		passLabel,
		keyEntry,
		container.NewGridWithColumns(2, copyBtn, saveBtn),
		widget.NewSeparator(),
		startupCheck,
		widget.NewSeparator(),
		settingsGrid,
	)

	mainContent := container.NewVBox(
		header,
		widget.NewSeparator(),
		form,
		widget.NewSeparator(),
		infoLabel,
	)

	card := widget.NewCard("", "", mainContent)
	windowContent := container.New(layout.NewCenterLayout(), container.NewPadded(card))

	w.SetContent(windowContent)
	w.Resize(fyne.NewSize(500, 650))
	w.SetFixedSize(true)

	w.SetCloseIntercept(func() {
		w.Hide()
	})

	go func() {
		http.HandleFunc("/shutdown", authMiddleware(shutdownHandler))
		http.HandleFunc("/reboot", authMiddleware(rebootHandler))
		http.ListenAndServe(httpPort, nil)
	}()

	go func() {
		startBroadcasting()
	}()

	w.Show()
	a.Run()
}
