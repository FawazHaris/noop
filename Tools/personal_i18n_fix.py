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
