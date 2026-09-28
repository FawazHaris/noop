#!/usr/bin/env python3
from pathlib import Path
import json

CATALOG = Path("Strand/Resources/Localizable.xcstrings")
LANGS = ["de", "es", "fr", "it", "pl", "pt-PT", "ru", "zh-Hans", "zh-Hant"]
ENTRIES = {}

def add(key, values):
    assert len(values) == len(LANGS), (key, len(values))
    ENTRIES[key] = {
        "localizations": {
            lang: {"stringUnit": {"state": "translated", "value": value}}
            for lang, value in zip(LANGS, values)
        }
    }

def no_translate(key):
    ENTRIES[key] = {"shouldTranslate": False}

no_translate("%02d:%02d – %02d:%02d")

add("7-day trends", [
    "7-Tage-Trends", "Tendencias de 7 días", "Tendances sur 7 jours",
    "Tendenze su 7 giorni", "Trendy z 7 dni", "Tendências de 7 dias",
    "Тенденции за 7 дней", "7 天趋势", "7 天趨勢"
])

add("A long train, the wake-style buzz. Your real wake is the strap's own alarm, which fires even if this phone is asleep.", [
    "Eine lange Vibrationsfolge im Weckstil. Dein eigentlicher Wecker ist der Alarm des Armbands selbst und funktioniert auch, wenn dieses Telefon schläft.",
    "Una vibración larga, al estilo de un despertador. Tu despertador real es la alarma de la propia pulsera, que funciona incluso si este teléfono está inactivo.",
    "Une longue séquence de vibrations, façon réveil. Ton vrai réveil est l’alarme du bracelet lui-même, qui fonctionne même si ce téléphone est en veille.",
    "Una lunga sequenza di vibrazioni in stile sveglia. La vera sveglia è l’allarme del bracciale stesso, che funziona anche se questo telefono è in standby.",
    "Długa seria wibracji w stylu budzika. Właściwy alarm działa w samej opasce i uruchomi się nawet wtedy, gdy ten telefon jest uśpiony.",
    "Uma sequência longa de vibrações, ao estilo de despertador. O verdadeiro despertador é o alarme da própria pulseira e funciona mesmo com este telefone em repouso.",
    "Длинная серия вибраций в стиле будильника. Настоящий будильник — это сигнал самого браслета, он сработает, даже если телефон спит.",
    "一段较长的唤醒式振动。真正的闹钟由腕带自身运行，即使手机处于睡眠状态也会响。",
    "一段較長的喚醒式振動。真正的鬧鐘由腕帶本身運作，即使手機處於睡眠狀態也會響。"
])

add("A wake time. Wake schedules can be copied into the strap's single alarm.", [
    "Eine Weckzeit. Weckpläne können in den einzigen Alarm des Armbands kopiert werden.",
    "Una hora de despertar. Los horarios de despertar pueden copiarse a la única alarma de la pulsera.",
    "Une heure de réveil. Les horaires de réveil peuvent être copiés vers l’unique alarme du bracelet.",
    "Un orario di sveglia. Le pianificazioni di sveglia possono essere copiate nell’unico allarme del bracciale.",
    "Godzina pobudki. Harmonogramy pobudki można skopiować do jedynego alarmu opaski.",
    "Uma hora de despertar. Os horários de despertar podem ser copiados para o único alarme da pulseira.",
    "Время пробуждения. Расписания пробуждения можно скопировать в единственный будильник браслета.",
    "一个唤醒时间。唤醒计划可以复制到腕带唯一的闹钟中。",
    "一個唤醒時間。唤醒排程可以複製到腕帶唯一的鬧鐘中。"
])

add("Actions", [
    "Aktionen", "Acciones", "Commandes", "Azioni", "Działania",
    "Ações", "Действия", "操作", "操作"
])

add("Alarm soon", [
    "Alarm in Kürze", "Alarma pronto", "Alarme bientôt", "Sveglia a breve",
    "Alarm wkrótce", "Alarme em breve", "Скоро будильник", "闹钟即将响起", "鬧鐘即將響起"
])

add("An app-side reminder. NOOP buzzes your wrist while it's running, and posts a phone notification as a fallback when it isn't.", [
    "Eine Erinnerung in der App. Solange NOOP läuft, vibriert dein Armband; andernfalls sendet die App ersatzweise eine Benachrichtigung auf dem Telefon.",
    "Un recordatorio de la app. NOOP hace vibrar tu muñeca mientras está en ejecución y, cuando no lo está, envía una notificación al teléfono como alternativa.",
    "Un rappel côté application. NOOP fait vibrer ton poignet tant que l’app fonctionne et, sinon, envoie une notification sur le téléphone en solution de secours.",
    "Un promemoria dell’app. NOOP fa vibrare il polso mentre è in esecuzione e, quando non lo è, invia una notifica sul telefono come alternativa.",
    "Przypomnienie po stronie aplikacji. Gdy NOOP działa, opaska wibruje; gdy nie działa, aplikacja wysyła zastępcze powiadomienie na telefon.",
    "Um lembrete da app. O NOOP faz a pulseira vibrar enquanto está em execução e, quando não está, envia uma notificação no telefone como alternativa.",
    "Напоминание со стороны приложения. Пока NOOP работает, браслет вибрирует; в противном случае приложение отправляет резервное уведомление на телефон.",
    "应用内提醒。NOOP 运行时会让腕带振动；未运行时则以手机通知作为备用提醒。",
    "App 內提醒。NOOP 執行時會讓腕帶振動；未執行時則以手機通知作為備用提醒。"
])

add("App schedules", [
    "App-Zeitpläne", "Horarios de la app", "Programmations de l’app",
    "Pianificazioni dell’app", "Harmonogramy aplikacji", "Horários da app",
    "Расписания приложения", "App 计划", "App 排程"
])

add("Arm as strap alarm", [
    "Als Armband-Alarm aktivieren", "Configurar como alarma de la pulsera",
    "Activer comme alarme du bracelet", "Imposta come allarme del bracciale",
    "Ustaw jako alarm opaski", "Ativar como alarme da pulseira",
    "Установить как будильник браслета", "设为腕带闹钟", "設為腕帶鬧鐘"
])

add("Attached: ", [
    "Angehängt: ", "Adjunto: ", "Joint : ", "Allegato: ", "Dołączono: ",
    "Anexado: ", "Прикреплено: ", "已附加：", "已附加："
])

add("Battery warning (3 short)", [
    "Batteriewarnung (3 kurze)", "Aviso de batería (3 cortas)",
    "Alerte batterie (3 courtes)", "Avviso batteria (3 brevi)",
    "Ostrzeżenie baterii (3 krótkie)", "Aviso de bateria (3 curtas)",
    "Предупреждение о батарее (3 коротких)", "电量警告（3 次短振动）", "電量警告（3 次短振動）"
])

add("Bluetooth is off", [
    "Bluetooth ist ausgeschaltet", "Bluetooth está desactivado", "Le Bluetooth est désactivé",
    "Il Bluetooth è disattivato", "Bluetooth jest wyłączony", "O Bluetooth está desligado",
    "Bluetooth выключен", "蓝牙已关闭", "藍牙已關閉"
])

add("Bluetooth off", [
    "Bluetooth aus", "Bluetooth desactivado", "Bluetooth désactivé",
    "Bluetooth disattivato", "Bluetooth wyłączony", "Bluetooth desligado",
    "Bluetooth выключен", "蓝牙关闭", "藍牙關閉"
])

add("Bonded means an encrypted pairing — the channel the strap needs for buzzes, alarms and history. On wrist defaults to true until the strap reports otherwise.", [
    "„Gekoppelt“ bedeutet eine verschlüsselte Verbindung — diesen Kanal benötigt das Armband für Vibrationen, Alarme und Verlauf. „Am Handgelenk“ gilt zunächst als aktiv, bis das Armband etwas anderes meldet.",
    "Vinculado significa un emparejamiento cifrado: el canal que la pulsera necesita para vibraciones, alarmas e historial. «En la muñeca» se considera verdadero hasta que la pulsera indique lo contrario.",
    "Associé signifie un appairage chiffré — le canal dont le bracelet a besoin pour les vibrations, les alarmes et l’historique. « Au poignet » est considéré actif jusqu’à ce que le bracelet indique le contraire.",
    "Associato indica un abbinamento cifrato, il canale necessario al bracciale per vibrazioni, allarmi e cronologia. «Al polso» è considerato attivo finché il bracciale non segnala diversamente.",
    "Powiązanie oznacza szyfrowane parowanie — kanał potrzebny opasce do wibracji, alarmów i historii. Stan „na nadgarstku” jest domyślnie uznawany za aktywny, dopóki opaska nie zgłosi inaczej.",
    "Emparelhado significa um emparelhamento encriptado — o canal de que a pulseira precisa para vibrações, alarmes e histórico. «No pulso» é considerado ativo até a pulseira indicar o contrário.",
    "Связано означает зашифрованное сопряжение — канал, который нужен браслету для вибраций, будильников и истории. Состояние «на запястье» считается активным, пока браслет не сообщит обратное.",
    "“已绑定”表示已建立加密配对，这是腕带进行振动、闹钟和历史同步所需的通道。在腕带报告其他状态前，默认视为已佩戴。",
    "「已綁定」表示已建立加密配對，這是腕帶進行振動、鬧鐘和歷史同步所需的通道。在腕帶回報其他狀態前，預設視為已佩戴。"
])

add("Classic layout", [
    "Klassisches Layout", "Diseño clásico", "Disposition classique", "Layout classico",
    "Układ klasyczny", "Esquema clássico", "Классическая компоновка", "经典布局", "經典版面"
])

add("Connect and pair your strap first.", [
    "Verbinde und kopple zuerst dein Armband.", "Conecta y vincula primero tu pulsera.",
    "Connecte et associe d’abord ton bracelet.", "Connetti e associa prima il bracciale.",
    "Najpierw połącz i sparuj opaskę.", "Liga e emparelha primeiro a pulseira.",
    "Сначала подключите и сопрягите браслет.", "请先连接并配对腕带。", "請先連接並配對腕帶。"
])

add("Connected, but no history sync has completed yet. Open the Wrist screen and sync to catch up.", [
    "Verbunden, aber noch keine Verlaufssynchronisierung abgeschlossen. Öffne die Handgelenk-Ansicht und synchronisiere, um aufzuholen.",
    "Conectado, pero aún no se ha completado ninguna sincronización del historial. Abre la pantalla Muñeca y sincroniza para ponerte al día.",
    "Connecté, mais aucune synchronisation de l’historique n’est encore terminée. Ouvre l’écran Poignet et synchronise pour rattraper le retard.",
    "Connesso, ma nessuna sincronizzazione della cronologia è ancora stata completata. Apri la schermata Polso e sincronizza per recuperare.",
    "Połączono, ale synchronizacja historii nie została jeszcze zakończona. Otwórz ekran Nadgarstek i zsynchronizuj dane.",
    "Ligado, mas ainda não foi concluída nenhuma sincronização do histórico. Abre o ecrã Pulso e sincroniza para atualizar.",
    "Подключено, но синхронизация истории ещё не завершалась. Откройте экран «Запястье» и выполните синхронизацию.",
    "已连接，但尚未完成历史同步。打开“腕带”页面并同步以补齐数据。",
    "已連接，但尚未完成歷史同步。開啟「腕帶」頁面並同步以補齊資料。"
])

add("Connected, but no live heart rate", [
    "Verbunden, aber keine Live-Herzfrequenz", "Conectado, pero sin frecuencia cardiaca en directo",
    "Connecté, mais sans fréquence cardiaque en direct", "Connesso, ma senza frequenza cardiaca in tempo reale",
    "Połączono, ale brak tętna na żywo", "Ligado, mas sem frequência cardíaca em direto",
    "Подключено, но нет пульса в реальном времени", "已连接，但无实时心率", "已連接，但無即時心率"
])

add("Connected, but the last completed history sync was about %lld h ago. Open the Wrist screen and sync to catch up.", [
    "Verbunden, aber die letzte abgeschlossene Verlaufssynchronisierung war vor etwa %lld Std. Öffne die Handgelenk-Ansicht und synchronisiere, um aufzuholen.",
    "Conectado, pero la última sincronización completa del historial fue hace unas %lld h. Abre la pantalla Muñeca y sincroniza para ponerte al día.",
    "Connecté, mais la dernière synchronisation complète de l’historique date d’environ %lld h. Ouvre l’écran Poignet et synchronise pour rattraper le retard.",
    "Connesso, ma l’ultima sincronizzazione completa della cronologia risale a circa %lld h fa. Apri la schermata Polso e sincronizza per recuperare.",
    "Połączono, ale ostatnia zakończona synchronizacja historii była około %lld godz. temu. Otwórz ekran Nadgarstek i zsynchronizuj dane.",
    "Ligado, mas a última sincronização completa do histórico foi há cerca de %lld h. Abre o ecrã Pulso e sincroniza para atualizar.",
    "Подключено, но последняя завершённая синхронизация истории была около %lld ч назад. Откройте экран «Запястье» и выполните синхронизацию.",
    "已连接，但上次完成历史同步约在 %lld 小时前。打开“腕带”页面并同步以补齐数据。",
    "已連接，但上次完成歷史同步約在 %lld 小時前。開啟「腕帶」頁面並同步以補齊資料。"
])

add("Connected, no live reading", [
    "Verbunden, keine Live-Messung", "Conectado, sin lectura en directo",
    "Connecté, aucune mesure en direct", "Connesso, nessuna lettura in tempo reale",
    "Połączono, brak odczytu na żywo", "Ligado, sem leitura em direto",
    "Подключено, нет показаний в реальном времени", "已连接，无实时读数", "已連接，無即時讀數"
])

add("Event (2 short)", [
    "Ereignis (2 kurze)", "Evento (2 cortas)", "Événement (2 courtes)", "Evento (2 brevi)",
    "Zdarzenie (2 krótkie)", "Evento (2 curtas)", "Событие (2 коротких)", "事件（2 次短振动）", "事件（2 次短振動）"
])

add("Everything here is read-only: NOOP reports what the strap says. Protocol-level diagnostics stay behind the Test Centre gate.", [
    "Alles hier ist schreibgeschützt: NOOP zeigt nur an, was das Armband meldet. Diagnosen auf Protokollebene bleiben hinter dem Test-Centre-Zugang.",
    "Todo aquí es de solo lectura: NOOP muestra lo que informa la pulsera. Los diagnósticos a nivel de protocolo permanecen detrás del acceso al Centro de pruebas.",
    "Tout ici est en lecture seule : NOOP affiche ce que rapporte le bracelet. Les diagnostics au niveau du protocole restent derrière l’accès au Centre de test.",
    "Tutto qui è di sola lettura: NOOP riporta ciò che comunica il bracciale. La diagnostica a livello di protocollo resta dietro l’accesso al Centro test.",
    "Wszystko tutaj jest tylko do odczytu: NOOP pokazuje to, co zgłasza opaska. Diagnostyka na poziomie protokołu pozostaje za dostępem do Centrum testów.",
    "Tudo aqui é só de leitura: o NOOP mostra o que a pulseira comunica. Os diagnósticos ao nível do protocolo permanecem atrás do acesso ao Centro de testes.",
    "Здесь всё только для чтения: NOOP показывает данные, которые сообщает браслет. Диагностика уровня протокола остаётся за доступом к Центру тестирования.",
    "此处所有内容均为只读：NOOP 仅显示腕带报告的信息。协议级诊断仍位于测试中心入口之后。",
    "此處所有內容均為唯讀：NOOP 僅顯示腕帶回報的資訊。協定層級診斷仍位於測試中心入口之後。"
])

add("Firmware %@", [
    "Firmware %@", "Firmware %@", "Micrologiciel %@", "Firmware %@", "Oprogramowanie sprzętowe %@",
    "Firmware %@", "Прошивка %@", "固件 %@", "韌體 %@"
])

add("Firmware: not reported yet this session", [
    "Firmware: in dieser Sitzung noch nicht gemeldet", "Firmware: aún no indicada en esta sesión",
    "Micrologiciel : pas encore signalé pour cette session", "Firmware: non ancora segnalato in questa sessione",
    "Oprogramowanie sprzętowe: jeszcze nie zgłoszono w tej sesji", "Firmware: ainda não indicado nesta sessão",
    "Прошивка: в этом сеансе ещё не сообщалась", "固件：本次会话尚未报告", "韌體：本次工作階段尚未回報"
])

add("Haptic", [
    "Haptik", "Háptica", "Haptique", "Feedback aptico", "Haptyka",
    "Háptica", "Тактильный сигнал", "触觉反馈", "觸覺回饋"
])

add("How do my last 7 days compare to my baseline?", [
    "Wie schneiden meine letzten 7 Tage im Vergleich zu meinem Ausgangswert ab?",
    "¿Cómo se comparan mis últimos 7 días con mi referencia?",
    "Comment mes 7 derniers jours se comparent-ils à ma référence ?",
    "Come si confrontano gli ultimi 7 giorni con il mio valore di riferimento?",
    "Jak moje ostatnie 7 dni wypadają na tle wartości bazowej?",
    "Como se comparam os meus últimos 7 dias com a minha referência?",
    "Как мои последние 7 дней соотносятся с базовым уровнем?",
    "我最近 7 天与基线相比如何？", "我最近 7 天與基準相比如何？"
])

add("Kind", [
    "Art", "Tipo", "Type", "Tipo", "Rodzaj", "Tipo", "Тип", "类型", "類型"
])

add("Last strap sync was %lld h ago", [
    "Letzte Armband-Synchronisierung vor %lld Std.", "La última sincronización de la pulsera fue hace %lld h",
    "Dernière synchronisation du bracelet il y a %lld h", "Ultima sincronizzazione del bracciale %lld h fa",
    "Ostatnia synchronizacja opaski była %lld godz. temu", "A última sincronização da pulseira foi há %lld h",
    "Последняя синхронизация браслета была %lld ч назад", "腕带上次同步是在 %lld 小时前", "腕帶上次同步是在 %lld 小時前"
])

add("Link", [
    "Verbindung", "Enlace", "Connexion", "Collegamento", "Połączenie",
    "Ligação", "Связь", "连接", "連線"
])

add("Liquid layout", [
    "Liquid-Layout", "Diseño Liquid", "Disposition Liquid", "Layout Liquid", "Układ Liquid",
    "Esquema Liquid", "Компоновка Liquid", "Liquid 布局", "Liquid 版面"
])


add("Live and streaming", [
    "Live und aktiv", "En directo y transmitiendo", "En direct et en streaming",
    "In diretta e in streaming", "Na żywo i przesyłanie aktywne", "Em direto e a transmitir",
    "В реальном времени, поток активен", "实时传输中", "即時傳輸中"
])

add("Live stream", [
    "Live-Stream", "Transmisión en directo", "Flux en direct", "Flusso in diretta",
    "Strumień na żywo", "Transmissão em direto", "Поток в реальном времени",
    "实时数据流", "即時資料流"
])

add("No data attached — data access is off in Coach settings.", [
    "Keine Daten angehängt — der Datenzugriff ist in den Coach-Einstellungen deaktiviert.",
    "No hay datos adjuntos: el acceso a datos está desactivado en los ajustes de Coach.",
    "Aucune donnée jointe — l’accès aux données est désactivé dans les réglages du Coach.",
    "Nessun dato allegato: l’accesso ai dati è disattivato nelle impostazioni del Coach.",
    "Brak dołączonych danych — dostęp do danych jest wyłączony w ustawieniach Coacha.",
    "Sem dados anexados — o acesso aos dados está desativado nas definições do Coach.",
    "Данные не прикреплены — доступ к данным отключён в настройках Coach.",
    "未附加数据——Coach 设置中的数据访问已关闭。",
    "未附加資料——Coach 設定中的資料存取已關閉。"
])

add("No schedules yet. Add one for wake times you can copy to the strap, or reminders NOOP fires while it's running.", [
    "Noch keine Zeitpläne. Füge einen für Weckzeiten hinzu, die du auf das Armband kopieren kannst, oder für Erinnerungen, die NOOP während der Ausführung auslöst.",
    "Aún no hay horarios. Añade uno para horas de despertar que puedas copiar a la pulsera o para recordatorios que NOOP active mientras está en ejecución.",
    "Aucune programmation pour l’instant. Ajoute-en une pour des heures de réveil à copier sur le bracelet ou pour des rappels déclenchés par NOOP pendant son fonctionnement.",
    "Nessuna pianificazione. Aggiungine una per gli orari di sveglia da copiare sul bracciale o per i promemoria che NOOP attiva mentre è in esecuzione.",
    "Brak harmonogramów. Dodaj godzinę pobudki, którą można skopiować na pasek, albo przypomnienie uruchamiane przez NOOP podczas działania.",
    "Ainda não há horários. Adiciona um para horas de despertar que possas copiar para o bracelete ou para lembretes que o NOOP ativa enquanto está em execução.",
    "Расписаний пока нет. Добавьте время пробуждения, которое можно скопировать на браслет, или напоминание, которое NOOP запускает во время работы.",
    "尚无计划。你可以添加可复制到腕带的唤醒时间，或由 NOOP 在运行时触发的提醒。",
    "尚無排程。你可以加入可複製到腕帶的喚醒時間，或由 NOOP 在執行時觸發的提醒。"
])

add("No strap alarm armed", [
    "Kein Armband-Alarm aktiviert", "No hay ninguna alarma de la pulsera activada",
    "Aucune alarme du bracelet activée", "Nessun allarme del bracciale attivato",
    "Brak aktywnego alarmu paska", "Nenhum alarme do bracelete ativado",
    "Будильник браслета не установлен", "腕带闹钟未启用", "腕帶鬧鐘未啟用"
])

add("No strap link. Reconnect, or open Devices to pair your strap.", [
    "Keine Verbindung zum Armband. Stelle die Verbindung wieder her oder öffne Geräte, um dein Armband zu koppeln.",
    "Sin conexión con la pulsera. Vuelve a conectarla o abre Dispositivos para vincularla.",
    "Aucune connexion au bracelet. Reconnecte-le ou ouvre Appareils pour l’associer.",
    "Nessuna connessione al bracciale. Riconnettilo oppure apri Dispositivi per associarlo.",
    "Brak połączenia z paskiem. Połącz ponownie albo otwórz Urządzenia, aby sparować pasek.",
    "Sem ligação ao bracelete. Volta a ligar ou abre Dispositivos para emparelhar o bracelete.",
    "Нет связи с браслетом. Подключитесь снова или откройте «Устройства», чтобы выполнить сопряжение.",
    "未连接腕带。请重新连接，或打开“设备”以配对腕带。",
    "未連接腕帶。請重新連線，或開啟「裝置」以配對腕帶。"
])

add("Numbers come from your synced strap history. Live readings need a connected strap; the layout menu switches back to NOOP's built-in layouts.", [
    "Die Werte stammen aus dem synchronisierten Verlauf deines Armbands. Live-Messungen benötigen ein verbundenes Armband; über das Layout-Menü kannst du zu den integrierten NOOP-Layouts zurückkehren.",
    "Los valores proceden del historial sincronizado de tu pulsera. Las lecturas en directo requieren una pulsera conectada; el menú de diseño permite volver a los diseños integrados de NOOP.",
    "Les valeurs proviennent de l’historique synchronisé de ton bracelet. Les mesures en direct nécessitent un bracelet connecté ; le menu de disposition permet de revenir aux dispositions intégrées de NOOP.",
    "I valori provengono dalla cronologia sincronizzata del bracciale. Le letture in tempo reale richiedono un bracciale connesso; il menu del layout consente di tornare ai layout integrati di NOOP.",
    "Wartości pochodzą z zsynchronizowanej historii paska. Odczyty na żywo wymagają połączonego paska; menu układu pozwala wrócić do wbudowanych układów NOOP.",
    "Os valores vêm do histórico sincronizado do bracelete. As leituras em direto exigem um bracelete ligado; o menu de esquema permite voltar aos esquemas integrados do NOOP.",
    "Значения берутся из синхронизированной истории браслета. Для показаний в реальном времени нужен подключённый браслет; меню компоновки позволяет вернуться к встроенным вариантам NOOP.",
    "数值来自已同步的腕带历史记录。实时读数需要已连接的腕带；布局菜单可切回 NOOP 的内置布局。",
    "數值來自已同步的腕帶歷史記錄。即時讀數需要已連接的腕帶；版面選單可切回 NOOP 的內建版面。"
])

add("On the strap", [
    "Auf dem Armband", "En la pulsera", "Sur le bracelet", "Sul bracciale",
    "Na pasku", "No bracelete", "На браслете", "腕带上", "腕帶上"
])

add("One light buzz. Used by app-side reminders; silenced inside quiet hours.", [
    "Eine leichte Vibration. Wird für Erinnerungen der App verwendet und während der Ruhezeiten stummgeschaltet.",
    "Una vibración suave. Se usa para recordatorios de la app y se silencia durante las horas de descanso.",
    "Une légère vibration. Utilisée pour les rappels de l’app et désactivée pendant les heures calmes.",
    "Una vibrazione leggera. Usata per i promemoria dell’app e silenziata durante le ore di quiete.",
    "Jedna lekka wibracja. Używana przez przypomnienia aplikacji i wyciszana w godzinach ciszy.",
    "Uma vibração ligeira. Usada pelos lembretes da app e silenciada durante as horas de silêncio.",
    "Одна лёгкая вибрация. Используется для напоминаний приложения и отключается в тихие часы.",
    "一次轻微振动。用于应用内提醒，并会在安静时段静音。",
    "一次輕微振動。用於 App 內提醒，並會在安靜時段靜音。"
])

add("One specific day", [
    "Ein bestimmter Tag", "Un día concreto", "Un jour précis", "Un giorno specifico",
    "Jeden konkretny dzień", "Um dia específico", "Один конкретный день", "指定某一天", "指定某一天"
])

add("One-off wakes stay app-side because the strap alarm repeats by weekday.", [
    "Einmalige Weckzeiten bleiben in der App, weil der Alarm des Armbands nach Wochentagen wiederholt wird.",
    "Las alarmas de una sola vez permanecen en la app porque la alarma de la pulsera se repite por día de la semana.",
    "Les réveils ponctuels restent dans l’app, car l’alarme du bracelet se répète selon les jours de la semaine.",
    "Le sveglie una tantum restano nell’app perché l’allarme del bracciale si ripete per giorno della settimana.",
    "Jednorazowe pobudki pozostają w aplikacji, ponieważ alarm paska powtarza się według dni tygodnia.",
    "Os despertares únicos ficam na app porque o alarme do bracelete se repete por dia da semana.",
    "Одноразовые пробуждения остаются в приложении, потому что будильник браслета повторяется по дням недели.",
    "一次性唤醒保留在应用内，因为腕带闹钟按星期重复。",
    "一次性喚醒保留在 App 內，因為腕帶鬧鐘按星期重複。"
])

add("Open Devices", [
    "Geräte öffnen", "Abrir Dispositivos", "Ouvrir Appareils", "Apri Dispositivi",
    "Otwórz Urządzenia", "Abrir Dispositivos", "Открыть «Устройства»", "打开“设备”", "開啟「裝置」"
])

add("Open alarms", [
    "Alarme öffnen", "Abrir alarmas", "Ouvrir les alarmes", "Apri allarmi",
    "Otwórz alarmy", "Abrir alarmes", "Открыть будильники", "打开闹钟", "開啟鬧鐘"
])

add("Paired, not connected", [
    "Gekoppelt, nicht verbunden", "Vinculada, sin conexión", "Associé, non connecté",
    "Associato, non connesso", "Sparowany, bez połączenia", "Emparelhado, sem ligação",
    "Сопряжено, не подключено", "已配对，未连接", "已配對，未連線"
])

add("Paired, offline", [
    "Gekoppelt, offline", "Vinculada, sin conexión", "Associé, hors ligne",
    "Associato, offline", "Sparowany, offline", "Emparelhado, offline",
    "Сопряжено, офлайн", "已配对，离线", "已配對，離線"
])

add("Pattern", [
    "Muster", "Patrón", "Motif", "Schema", "Wzorzec", "Padrão", "Шаблон", "模式", "模式"
])

add("Personal glance", [
    "Persönliche Übersicht", "Vista personal", "Aperçu personnel", "Panoramica personale",
    "Widok osobisty", "Visão pessoal", "Личный обзор", "个人概览", "個人概覽"
])

add("Pulls your strap's stored history immediately.", [
    "Ruft den gespeicherten Verlauf deines Armbands sofort ab.",
    "Obtiene inmediatamente el historial guardado en tu pulsera.",
    "Récupère immédiatement l’historique stocké sur ton bracelet.",
    "Recupera immediatamente la cronologia memorizzata sul bracciale.",
    "Natychmiast pobiera historię zapisaną na pasku.",
    "Obtém imediatamente o histórico guardado no bracelete.",
    "Немедленно загружает историю, сохранённую на браслете.",
    "立即拉取腕带中存储的历史记录。",
    "立即拉取腕帶中儲存的歷史記錄。"
])

add("Reconnect strap", [
    "Armband erneut verbinden", "Volver a conectar la pulsera", "Reconnecter le bracelet",
    "Riconnetti il bracciale", "Połącz pasek ponownie", "Voltar a ligar o bracelete",
    "Переподключить браслет", "重新连接腕带", "重新連接腕帶"
])

add("Reconnecting…", [
    "Verbindung wird wiederhergestellt…", "Reconectando…", "Reconnexion…", "Riconnessione…",
    "Ponowne łączenie…", "A voltar a ligar…", "Повторное подключение…", "正在重新连接…", "正在重新連線…"
])

add("Refresh data", [
    "Daten aktualisieren", "Actualizar datos", "Actualiser les données", "Aggiorna dati",
    "Odśwież dane", "Atualizar dados", "Обновить данные", "刷新数据", "重新整理資料"
])

add("Reminder", [
    "Erinnerung", "Recordatorio", "Rappel", "Promemoria", "Przypomnienie",
    "Lembrete", "Напоминание", "提醒", "提醒"
])

add("Reminder (1 short)", [
    "Erinnerung (1 kurze)", "Recordatorio (1 corta)", "Rappel (1 courte)",
    "Promemoria (1 breve)", "Przypomnienie (1 krótka)", "Lembrete (1 curta)",
    "Напоминание (1 короткая)", "提醒（1 次短振动）", "提醒（1 次短振動）"
])

add("Reminder buzzes stay silent inside this window. The strap wake-alarm always fires.", [
    "Erinnerungsvibrationen bleiben in diesem Zeitraum stumm. Der Weckalarm des Armbands wird immer ausgelöst.",
    "Las vibraciones de recordatorio permanecen en silencio durante este intervalo. La alarma de despertar de la pulsera siempre se activa.",
    "Les vibrations de rappel restent silencieuses pendant cette période. L’alarme de réveil du bracelet se déclenche toujours.",
    "Le vibrazioni dei promemoria restano silenziose in questo intervallo. L’allarme di sveglia del bracciale si attiva sempre.",
    "Wibracje przypomnień są wyciszone w tym przedziale. Alarm pobudki paska zawsze się uruchamia.",
    "As vibrações de lembrete ficam silenciosas neste intervalo. O alarme de despertar do bracelete dispara sempre.",
    "Вибрации напоминаний отключены в этом интервале. Будильник браслета срабатывает всегда.",
    "此时间段内提醒振动保持静音。腕带唤醒闹钟始终会响。",
    "此時間區段內提醒振動保持靜音。腕帶喚醒鬧鐘始終會響。"
])

add("Schedule enabled", [
    "Zeitplan aktiviert", "Horario activado", "Programmation activée", "Pianificazione attivata",
    "Harmonogram włączony", "Horário ativado", "Расписание включено", "计划已启用", "排程已啟用"
])

add("Scheduled reminder from NOOP. Open the app to sync and feel it on your wrist.", [
    "Geplante Erinnerung von NOOP. Öffne die App zum Synchronisieren, damit du sie am Handgelenk spürst.",
    "Recordatorio programado de NOOP. Abre la app para sincronizar y sentirlo en la muñeca.",
    "Rappel programmé par NOOP. Ouvre l’app pour synchroniser et le sentir au poignet.",
    "Promemoria programmato da NOOP. Apri l’app per sincronizzare e sentirlo al polso.",
    "Zaplanowane przypomnienie z NOOP. Otwórz aplikację, aby zsynchronizować i poczuć je na nadgarstku.",
    "Lembrete agendado pelo NOOP. Abre a app para sincronizar e senti-lo no pulso.",
    "Запланированное напоминание NOOP. Откройте приложение для синхронизации, чтобы почувствовать его на запястье.",
    "NOOP 的计划提醒。打开应用进行同步，即可在手腕上感受到提醒。",
    "NOOP 的排程提醒。開啟 App 進行同步，即可在手腕上感受到提醒。"
])

add("Strap hasn't synced yet", [
    "Armband wurde noch nicht synchronisiert", "La pulsera aún no se ha sincronizado",
    "Le bracelet n’a pas encore été synchronisé", "Il bracciale non è ancora stato sincronizzato",
    "Pasek nie został jeszcze zsynchronizowany", "O bracelete ainda não foi sincronizado",
    "Браслет ещё не синхронизировался", "腕带尚未同步", "腕帶尚未同步"
])

add("Strap wake-alarm. It buzzes from the strap's own firmware, even if your phone is asleep.", [
    "Weckalarm des Armbands. Er wird von der Firmware des Armbands selbst ausgelöst, auch wenn dein Telefon schläft.",
    "Alarma de despertar de la pulsera. Vibra mediante el firmware de la propia pulsera, incluso si tu teléfono está inactivo.",
    "Alarme de réveil du bracelet. Elle vibre grâce au micrologiciel du bracelet lui-même, même si ton téléphone est en veille.",
    "Allarme di sveglia del bracciale. Vibra tramite il firmware del bracciale stesso, anche se il telefono è in standby.",
    "Alarm pobudki paska. Wibracja jest uruchamiana przez oprogramowanie samego paska, nawet gdy telefon jest uśpiony.",
    "Alarme de despertar do bracelete. Vibra através do firmware do próprio bracelete, mesmo que o telefone esteja em repouso.",
    "Будильник браслета. Вибрация запускается прошивкой самого браслета, даже если телефон спит.",
    "腕带唤醒闹钟。由腕带自身固件触发振动，即使手机处于睡眠状态也会响。",
    "腕帶喚醒鬧鐘。由腕帶本身韌體觸發振動，即使手機處於睡眠狀態也會響。"
])

add("Streaming", [
    "Streaming", "Transmitiendo", "Diffusion en direct", "Streaming", "Przesyłanie",
    "A transmitir", "Поток активен", "传输中", "傳輸中"
])

add("Sync due", [
    "Synchronisierung fällig", "Sincronización pendiente", "Synchronisation requise",
    "Sincronizzazione necessaria", "Synchronizacja wymagana", "Sincronização pendente",
    "Требуется синхронизация", "需要同步", "需要同步"
])

text = CATALOG.read_text(encoding="utf-8")
catalog = json.loads(text)
pending = [(key, value) for key, value in ENTRIES.items() if key not in catalog.get("strings", {})]
if not pending:
    print("No new entries to add.")
    raise SystemExit(0)

marker = '  "strings": {'
idx = text.find(marker)
if idx < 0:
    raise SystemExit("String catalog marker not found")

block = "\n" + "\n".join(
    "    " + json.dumps(key, ensure_ascii=False) + ": " +
    json.dumps(value, ensure_ascii=False, separators=(",", ":")) + ","
    for key, value in pending
)
text = text[:idx + len(marker)] + block + text[idx + len(marker):]
CATALOG.write_text(text, encoding="utf-8")
print(f"Added {len(pending)} personal localization entries.")
