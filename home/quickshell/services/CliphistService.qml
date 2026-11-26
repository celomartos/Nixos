pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property alias entries: entryModel

    // ------------------------------------------------------------
    // State
    // ------------------------------------------------------------

    property int revision: 0

    property bool loading: false
    property bool refreshPending: false

    property string errorMessage: ""
    property string historyOutput: ""
    property string lastHistoryOutput: ""

    property var previewQueue: []
    property var previewForceIds: []
    property var previewWorkers: []

    property var _idToIndex: ({})

    // ------------------------------------------------------------
    // Cache configuration
    // ------------------------------------------------------------

    readonly property int thumbnailSize: 58
    readonly property int cacheMaxAgeMinutes: 360

    // Unique to this Quickshell session.
    // Prevents old thumbnails from being reused after cliphist wipe.
    readonly property string cacheSessionId: String(Date.now())

    readonly property string cacheDirectory: {
        const cache = Quickshell.env("XDG_CACHE_HOME");

        if (cache)
            return cache + "/quickshell/cliphist";

        return (Quickshell.env("HOME") || "/tmp") + "/.cache/quickshell/cliphist";
    }

    readonly property int maxPreviewRetries: 1

    ListModel {
        id: entryModel
    }

    // ============================================================
    // HISTORY
    // ============================================================

    function refresh() {
        if (cacheCleanupProcess.running || listProcess.running) {
            root.refreshPending = true;
            return;
        }

        root.refreshPending = false;
        root.loading = true;
        root.errorMessage = "";
        root.historyOutput = "";

        cacheCleanupProcess.exec(["sh", "-c", 'mkdir -p "$1" && chmod 700 "$1" && ' + 'find "$1" -maxdepth 1 -type f -mmin +"$2" -delete && ' + 'find "$1" -maxdepth 1 -type f -name "*.tmp.*" -mmin +60 -delete', "qs-cliphist-cleanup", root.cacheDirectory, String(root.cacheMaxAgeMinutes)]);
    }

    Process {
        id: cacheCleanupProcess

        stderr: StdioCollector {
            onStreamFinished: {
                const message = this.text.trim();

                if (message.length > 0)
                    console.warn("[Clipboard Cache]", message);
            }
        }

        onExited: (code, status) => {
            if (code !== 0)
                console.warn("[Clipboard Cache] Cleanup exited with code", code);

            listProcess.exec(["cliphist", "list"]);
        }
    }

    Process {
        id: listProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.historyOutput = this.text;
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

            if (code === 0) {
                const output = root.historyOutput;

                // Do not rebuild the model if nothing changed.
                // This preserves loaded thumbnails when the menu
                // is closed and opened again.
                if (output !== root.lastHistoryOutput || entryModel.count === 0) {
                    root.lastHistoryOutput = output;
                    root.parseHistory(output);
                } else {
                    // Make sure any missing thumbnails are requested.
                    root.requestAllPreviews();
                }
            } else if (root.errorMessage.length === 0) {
                root.errorMessage = "Failed to load clipboard history.";
            }

            if (root.refreshPending) {
                root.refreshPending = false;

                Qt.callLater(() => {
                    root.refresh();
                });
            }
        }
    }

    // ============================================================
    // IMAGE FORMAT
    // ============================================================

    function normalizeFormat(format) {
        let value = String(format || "").trim().toLowerCase();

        value = value.replace(/^image\//, "");

        if (value === "jpeg")
            value = "jpg";

        const supported = ["png", "jpg", "gif", "bmp", "tiff", "webp"];

        return supported.includes(value) ? value : "";
    }

    function detectImageFormat(preview) {
        const match = String(preview || "").match(/^\[\[\s*binary data\b.*?\s+(png|jpe?g|bmp|gif|tiff|webp)\b/i);

        if (!match)
            return "";

        return root.normalizeFormat(match[1]);
    }

    // ============================================================
    // HISTORY PARSING
    // ============================================================

    function parseHistory(raw) {
        // Keep the existing entry state when the same clipboard
        // item is still present in the updated history.
        const oldEntries = {};

        for (let i = 0; i < entryModel.count; i++) {
            const entry = entryModel.get(i);
            oldEntries[String(entry.entryId)] = entry;
        }

        const lines = String(raw || "").split(/\r?\n/);
        const batch = [];

        for (const line of lines) {
            if (!line)
                continue;

            const separator = line.indexOf("\t");

            if (separator < 1)
                continue;

            const id = line.substring(0, separator).trim();
            const preview = line.substring(separator + 1).trim();

            if (!/^\d+$/.test(id))
                continue;

            const extension = root.detectImageFormat(preview);
            const isImage = extension.length > 0;

            const old = oldEntries[id];

            const sameEntry = old && old.preview === preview && old.extension === extension;

            const cachedReady = sameEntry && old.previewReady && old.previewUrl.length > 0;

            const active = root.isPreviewActive(id);
            const queued = root.previewQueue.includes(id);

            batch.push({
                entryId: id,
                preview: preview,
                isImage: isImage,
                extension: extension,
                previewUrl: cachedReady ? old.previewUrl : "",
                previewReady: cachedReady,
                previewLoading: isImage && !cachedReady && (active || queued),
                previewFailed: sameEntry ? old.previewFailed : false,
                previewRetries: sameEntry ? old.previewRetries : 0,
                summary: isImage ? extension.toUpperCase() + " image" : preview
            });
        }

        entryModel.clear();

        if (batch.length > 0)
            entryModel.append(batch);

        root.rebuildIndex();

        // Remove queued entries that no longer exist.
        root.previewQueue = root.previewQueue.filter(id => {
            return root.findEntryIndex(id) >= 0;
        });

        root.previewForceIds = root.previewForceIds.filter(id => {
            return root.findEntryIndex(id) >= 0;
        });

        root.revision++;

        // Start decoding every image, not just visible delegates.
        root.requestAllPreviews();
    }

    function rebuildIndex() {
        const map = {};

        for (let i = 0; i < entryModel.count; i++) {
            map[entryModel.get(i).entryId] = i;
        }

        root._idToIndex = map;
    }

    function findEntryIndex(id) {
        const index = root._idToIndex[String(id)];

        return index === undefined ? -1 : index;
    }

    // ============================================================
    // IMAGE PATHS
    // ============================================================

    function previewPath(id, extension) {
        return root.cacheDirectory + "/" + root.cacheSessionId + "-" + String(id) + "." + String(extension);
    }

    function fileUrl(path) {
        const encodedPath = String(path).split("/").map(segment => encodeURIComponent(segment)).join("/");

        return "file://" + encodedPath;
    }

    // ============================================================
    // PREVIEW WORKERS
    // ============================================================

    function isPreviewActive(id) {
        const entryId = String(id);

        for (const worker of root.previewWorkers) {
            if (worker.entryId === entryId)
                return true;
        }

        return false;
    }

    function requestAllPreviews() {
        for (let i = 0; i < entryModel.count; i++) {
            const entry = entryModel.get(i);

            if (entry.isImage)
                root.requestPreview(entry.entryId);
        }
    }

    function requestPreview(id, force) {
        const entryId = String(id);
        const index = root.findEntryIndex(entryId);

        if (index < 0)
            return;

        const entry = entryModel.get(index);
        const forced = Boolean(force);

        if (!entry.isImage)
            return;

        if (root.isPreviewActive(entryId))
            return;

        if (!forced) {
            if (entry.previewReady || entry.previewLoading || entry.previewFailed) {
                return;
            }
        } else {
            // A forced request must ignore the existing cache file.
            entryModel.setProperty(index, "previewUrl", "");
            entryModel.setProperty(index, "previewReady", false);
            entryModel.setProperty(index, "previewFailed", false);
        }

        // If it is already queued, just mark it for forced decoding.
        if (root.previewQueue.includes(entryId)) {
            if (forced && !root.previewForceIds.includes(entryId)) {
                root.previewForceIds = root.previewForceIds.concat([entryId]);
            }

            entryModel.setProperty(index, "previewLoading", true);

            return;
        }

        if (forced && !root.previewForceIds.includes(entryId)) {
            root.previewForceIds = root.previewForceIds.concat([entryId]);
        }

        entryModel.setProperty(index, "previewLoading", true);

        root.previewQueue = root.previewQueue.concat([entryId]);

        root.processNextPreview();
    }

    function processNextPreview() {
        if (root.previewWorkers.length === 0)
            return;

        const queue = root.previewQueue.slice();

        for (const worker of root.previewWorkers) {
            if (worker.running || worker.entryId !== "")
                continue;

            let id = "";

            // Find the next valid image.
            while (queue.length > 0) {
                const candidate = queue.shift();
                const index = root.findEntryIndex(candidate);

                if (index < 0)
                    continue;

                const entry = entryModel.get(index);

                if (!entry.isImage || entry.previewReady)
                    continue;

                if (root.isPreviewActive(candidate))
                    continue;

                id = candidate;
                break;
            }

            if (id === "")
                break;

            const index = root.findEntryIndex(id);
            const entry = entryModel.get(index);

            const forced = root.previewForceIds.includes(id);

            root.previewForceIds = root.previewForceIds.filter(item => item !== id);

            const outputPath = root.previewPath(id, entry.extension);

            worker.entryId = id;
            worker.outputPath = outputPath;

            entryModel.setProperty(index, "previewLoading", true);

            // Reuse an existing non-empty cache file unless this
            // request explicitly asks for a fresh decode.
            const script = 'umask 077; ' + 'mkdir -p "$1" && chmod 700 "$1" || exit 1; ' + 'if [ "$4" != "1" ] && [ -s "$2" ]; then ' + 'touch "$2" && exit 0; ' + 'fi; ' + 'tmp="$2.tmp.$$"; ' + 'trap \'rm -f "$tmp"\' EXIT; ' + 'if cliphist decode "$3" > "$tmp" && [ -s "$tmp" ]; then ' + 'mv -f "$tmp" "$2"; ' + 'else exit 1; fi';

            worker.exec(["sh", "-c", script, "qs-cliphist-preview", root.cacheDirectory, outputPath, id, forced ? "1" : "0"]);
        }

        root.previewQueue = queue;
    }

    function finishPreview(worker, code) {
        const id = worker.entryId;
        const outputPath = worker.outputPath;

        worker.entryId = "";
        worker.outputPath = "";

        if (id === "") {
            Qt.callLater(() => root.processNextPreview());
            return;
        }

        const index = root.findEntryIndex(id);

        if (index >= 0) {
            entryModel.setProperty(index, "previewLoading", false);

            if (code === 0) {
                const url = root.fileUrl(outputPath);

                entryModel.setProperty(index, "previewUrl", url);
                entryModel.setProperty(index, "previewReady", true);
                entryModel.setProperty(index, "previewFailed", false);
                entryModel.setProperty(index, "previewRetries", 0);
            } else {
                entryModel.setProperty(index, "previewUrl", "");
                entryModel.setProperty(index, "previewReady", false);

                const entry = entryModel.get(index);

                // Retry a failed decode once.
                if (entry.previewRetries < root.maxPreviewRetries) {
                    entryModel.setProperty(index, "previewRetries", entry.previewRetries + 1);

                    entryModel.setProperty(index, "previewFailed", false);

                    Qt.callLater(() => {
                        root.requestPreview(id, true);
                    });
                } else {
                    entryModel.setProperty(index, "previewFailed", true);

                    console.warn("[Clipboard] Failed to decode image:", id, "exit code:", code);
                }
            }

            root.revision++;
        }

        Qt.callLater(() => {
            root.processNextPreview();
        });
    }

    // ============================================================
    // PREVIEW PROCESSES
    // ============================================================

    Process {
        id: previewProcessA

        property string entryId: ""
        property string outputPath: ""

        stderr: StdioCollector {
            onStreamFinished: {
                const message = this.text.trim();

                if (message.length > 0)
                    console.warn("[Clipboard Preview A]", message);
            }
        }

        onExited: (code, status) => {
            root.finishPreview(previewProcessA, code);
        }
    }

    Process {
        id: previewProcessB

        property string entryId: ""
        property string outputPath: ""

        stderr: StdioCollector {
            onStreamFinished: {
                const message = this.text.trim();

                if (message.length > 0)
                    console.warn("[Clipboard Preview B]", message);
            }
        }

        onExited: (code, status) => {
            root.finishPreview(previewProcessB, code);
        }
    }

    // ============================================================
    // IMAGE LOAD ERROR
    // ============================================================

    function retryPreview(id) {
        const entryId = String(id);
        const index = root.findEntryIndex(entryId);

        if (index < 0)
            return;

        const entry = entryModel.get(index);

        if (!entry.isImage || root.isPreviewActive(entryId))
            return;

        if (entry.previewRetries >= root.maxPreviewRetries) {
            entryModel.setProperty(index, "previewUrl", "");
            entryModel.setProperty(index, "previewReady", false);
            entryModel.setProperty(index, "previewLoading", false);
            entryModel.setProperty(index, "previewFailed", true);

            root.revision++;
            return;
        }

        entryModel.setProperty(index, "previewRetries", entry.previewRetries + 1);

        root.requestPreview(entryId, true);
    }

    // Kept for compatibility with ClipboardWindow.qml.
    function invalidatePreview(id) {
        root.retryPreview(id);
    }

    // ============================================================
    // COPY
    // ============================================================

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

    // ============================================================
    // INITIALIZATION
    // ============================================================

    Component.onCompleted: {
        root.previewWorkers = [previewProcessA, previewProcessB];

        // Prepare thumbnails as soon as Quickshell starts,
        // instead of waiting for the clipboard menu to open.
        Qt.callLater(() => {
            root.refresh();
        });
    }
}
