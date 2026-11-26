pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property alias entries: entryModel

    // `revision` só muda quando o HISTÓRICO muda (parseHistory).
    property int revision: 0

    property bool loading: false
    property string errorMessage: ""

    // Cache em memória: entryId -> file:// URL já decodificada.
    property var previewCache: ({})

    property var previewQueue: []
    property string activePreviewId: ""
    property string activePreviewPath: ""

    property string metadataOutput: ""
    property string metadataError: ""

    // Guarda a última saída de metadados para pular parseHistory
    // quando o histórico não mudou entre aberturas do painel.
    property string lastMetadataOutput: ""

    // Índice O(1) para findEntryIndex.
    property var _idToIndex: ({})

    // ── Configuração da limpeza ─────────────────────────────────────────────
    // Arquivos de preview mais antigos que isso (em dias) são removidos.
    readonly property int cacheMaxAgeDays: 0

    // Flag para garantir que a limpeza rode no máximo uma vez por sessão.
    property bool _cacheCleanupDone: false

    // ── Tamanho da thumbnail usado no sourceSize ────────────────────────────
    // Deve bater com `thumbnailSize` em ClipboardWindow.qml para que o cache
    // do Qt (QPixmapCache) seja efetivamente reaproveitado pelos delegates.
    readonly property int thumbnailSize: 58

    readonly property string cacheDirectory: {
        const cache = Quickshell.env("XDG_CACHE_HOME");

        if (cache)
            return cache + "/quickshell/cliphist";

        return (Quickshell.env("HOME") || "/tmp") + "/.cache/quickshell/cliphist";
    }

    // Componente usado apenas para pré-carregar a imagem no cache do Qt.
    // Não é exibido — apenas força a decodificação para popular o QPixmapCache.
    Component {
        id: preloadImageComponent

        Image {
            asynchronous: true
            cache: true
            sourceSize: Qt.size(root.thumbnailSize, root.thumbnailSize)
            visible: false
        }
    }

    ListModel {
        id: entryModel
    }

    // =====================================================================
    // HISTORY
    // =====================================================================

    function refresh() {
        if (metadataProcess.running || listProcess.running)
            return;

        loading = true;
        errorMessage = "";
        metadataOutput = "";
        metadataError = "";

        metadataProcess.exec(["cliphist", "list", "-fields", "id,format,preview"]);
    }

    Process {
        id: metadataProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.metadataOutput = this.text;
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root.metadataError = this.text.trim();
            }
        }

        onExited: (code, status) => {
            if (code === 0) {
                const output = root.metadataOutput;

                // Se o histórico não mudou, não reconstrói o modelo.
                if (output === root.lastMetadataOutput && entryModel.count > 0) {
                    root.loading = false;
                    root._runCacheCleanupIfNeeded();
                    return;
                }

                const count = root.parseHistory(output, true);

                if (count > 0 || output.trim() === "") {
                    root.lastMetadataOutput = output;
                    root.loading = false;
                    root._runCacheCleanupIfNeeded();
                    return;
                }
            }

            // Fallback para versões antigas do cliphist sem `-fields`.
            root.metadataOutput = "";
            listProcess.exec(["cliphist", "list"]);
        }
    }

    Process {
        id: listProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.parseHistory(this.text, false);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const message = this.text.trim();

                if (message.length > 0)
                    root.errorMessage = message;
            }
        }

        onExited: (code, status) => {
            root.loading = false;

            if (code !== 0 && root.errorMessage.length === 0) {
                root.errorMessage = "Failed to load clipboard history.";
            }

            root._runCacheCleanupIfNeeded();
        }
    }

    // =====================================================================
    // LIMPEZA DE CACHE
    // =====================================================================

    // Dispara a limpeza apenas uma vez por sessão (ou após reload do shell).
    function _runCacheCleanupIfNeeded() {
        if (root._cacheCleanupDone)
            return;

        root._cacheCleanupDone = true;
        root._cleanupCache();
    }

    function _cleanupCache() {
        // `find` remove arquivos com mais de N dias.
        // O `mkdir -p` garante que o diretório exista antes do find.
        const script = 'mkdir -p "$1" && find "$1" -maxdepth 1 -type f -mtime +"$2" -delete';

        cacheCleanupProcess.exec(["sh", "-c", script, "qs-cliphist-cache-cleanup", root.cacheDirectory, String(root.cacheMaxAgeDays),]);
    }

    Process {
        id: cacheCleanupProcess

        stderr: StdioCollector {
            onStreamFinished: {
                const message = this.text.trim();

                if (message.length > 0)
                    console.warn("[Clipboard Cache Cleanup]", message);
            }
        }

        onExited: (code, status) => {
            if (code !== 0)
                console.warn("[Clipboard Cache Cleanup] exited with code", code);
        }
    }

    // =====================================================================
    // IMAGE FORMAT
    // =====================================================================

    function normalizeFormat(format) {
        let value = String(format || "").trim().toLowerCase();

        value = value.replace(/^image\//, "");

        if (value === "jpeg")
            value = "jpg";

        const supported = ["png", "jpg", "gif", "bmp", "tiff", "webp"];

        return supported.includes(value) ? value : "";
    }

    function detectImageFormat(preview) {
        const match = String(preview || "").match(/^\[\[\s*binary data\b.*?\s+(png|jpe?g|gif|bmp|tiff|webp)\s+\d+x\d+\s*\]\]/i);

        if (!match)
            return "";

        return root.normalizeFormat(match[1]);
    }

    // =====================================================================
    // PARSE
    // =====================================================================

    function parseHistory(raw, hasMetadata) {
        entryModel.clear();

        const lines = String(raw || "").split(/\r?\n/);
        const batch = [];

        for (const line of lines) {
            if (!line)
                continue;

            let id = "";
            let format = "";
            let preview = "";

            if (hasMetadata) {
                const firstTab = line.indexOf("\t");
                const secondTab = line.indexOf("\t", firstTab + 1);

                if (firstTab < 1 || secondTab < 0)
                    continue;

                id = line.substring(0, firstTab).trim();
                format = line.substring(firstTab + 1, secondTab).trim();
                preview = line.substring(secondTab + 1).trim();
            } else {
                const separator = line.indexOf("\t");

                if (separator < 1)
                    continue;

                id = line.substring(0, separator).trim();
                preview = line.substring(separator + 1).trim();
            }

            if (!/^\d+$/.test(id))
                continue;

            let extension = root.normalizeFormat(format);

            if (!extension)
                extension = root.detectImageFormat(preview);

            const isImage = extension.length > 0;

            const cachedUrl = isImage ? (root.previewCache[id] || "") : "";
            const previewReady = cachedUrl.length > 0;

            batch.push({
                entryId: id,
                preview: preview,
                isImage: isImage,
                extension: extension,
                previewUrl: cachedUrl,
                previewReady: previewReady,
                previewLoading: false,
                summary: isImage ? extension.toUpperCase() + " image" : preview
            });
        }

        if (batch.length > 0)
            entryModel.append(batch);

        root._rebuildIndex();

        root.previewQueue = [];

        if (!previewProcess.running) {
            root.activePreviewId = "";
            root.activePreviewPath = "";
        }

        root.revision++;

        return entryModel.count;
    }

    function _rebuildIndex() {
        const map = {};

        for (let i = 0; i < entryModel.count; i++)
            map[entryModel.get(i).entryId] = i;

        root._idToIndex = map;
    }

    // =====================================================================
    // IMAGE PREVIEWS
    // =====================================================================

    function findEntryIndex(id) {
        const i = root._idToIndex[String(id)];
        return (i === undefined) ? -1 : i;
    }

    function previewPath(id, extension) {
        return root.cacheDirectory + "/" + String(id) + "." + String(extension);
    }

    function requestPreview(id) {
        const entryId = String(id);
        const index = findEntryIndex(entryId);

        if (index < 0)
            return;

        const entry = entryModel.get(index);

        if (!entry.isImage || entry.previewReady || entry.previewLoading)
            return;

        const cached = root.previewCache[entryId];

        if (cached) {
            entryModel.setProperty(index, "previewUrl", cached);
            entryModel.setProperty(index, "previewReady", true);
            return;
        }

        if (entryId === root.activePreviewId || root.previewQueue.includes(entryId))
            return;

        entryModel.setProperty(index, "previewLoading", true);

        root.previewQueue = root.previewQueue.concat([entryId]);

        root.processNextPreview();
    }

    function processNextPreview() {
        if (previewProcess.running || root.activePreviewId !== "")
            return;

        const queue = root.previewQueue.slice();

        while (queue.length > 0) {
            const id = queue.shift();
            const index = findEntryIndex(id);

            if (index < 0)
                continue;

            const entry = entryModel.get(index);

            if (!entry.isImage || entry.previewReady)
                continue;

            const outputPath = root.previewPath(id, entry.extension);

            root.activePreviewId = id;
            root.activePreviewPath = outputPath;
            root.previewQueue = queue;

            previewProcess.exec(["sh", "-c", 'umask 077; mkdir -p "$1" || exit 1; tmp="$2.tmp.$$"; trap \'rm -f "$tmp"\' EXIT; if cliphist decode "$3" > "$tmp" && [ -s "$tmp" ]; then mv -f "$tmp" "$2"; else exit 1; fi', "qs-cliphist-preview", root.cacheDirectory, outputPath, id]);

            return;
        }

        root.previewQueue = queue;
    }

    Process {
        id: previewProcess

        stderr: StdioCollector {
            onStreamFinished: {
                const message = this.text.trim();

                if (message.length > 0)
                    console.warn("[Clipboard Preview]", message);
            }
        }

        onExited: (code, status) => {
            const id = root.activePreviewId;
            const outputPath = root.activePreviewPath;

            root.activePreviewId = "";
            root.activePreviewPath = "";

            const index = root.findEntryIndex(id);

            if (index >= 0) {
                entryModel.setProperty(index, "previewLoading", false);

                if (code === 0) {
                    const url = "file://" + encodeURI(outputPath);

                    root.previewCache[id] = url;

                    entryModel.setProperty(index, "previewUrl", url);
                    entryModel.setProperty(index, "previewReady", true);

                    // ── PRÉ-CARREGAMENTO NO QPixmapCache ────────────────
                    // Cria um Image invisível com o mesmo `sourceSize` e
                    // `cache: true` do delegate. Isso força o Qt a
                    // decodificar a imagem JÁ e guardá-la no cache global,
                    // de modo que, quando o delegate for criado, ele lê
                    // do cache em vez de ir ao disco.
                    // O objeto se autodestrói quando o carregamento
                    // termina (Ready) ou falha (Error).
                    const preload = preloadImageComponent.createObject(root, {
                        source: url
                    });

                    if (preload) {
                        preload.statusChanged.connect(() => {
                            if (preload.status === Image.Ready || preload.status === Image.Error)
                                preload.destroy();
                        });
                    }
                }
            }

            Qt.callLater(() => {
                root.processNextPreview();
            });
        }
    }

    // =====================================================================
    // COPY
    // =====================================================================

    Process {
        id: copyProcess
    }

    function copy(id) {
        const entryId = String(id);

        if (!/^\d+$/.test(entryId))
            return;

        if (copyProcess.running)
            return;

        copyProcess.exec(["sh", "-c", 'cliphist decode "$1" | wl-copy', "qs-cliphist-copy", entryId]);
    }
}
