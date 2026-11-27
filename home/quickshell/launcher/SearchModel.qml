import QtQuick

// Keeps category assignment and search ranking separate from the window UI.
QtObject {
    id: searchModel

    required property var applications
    required property var categories
    required property var excludedCategories
    required property string categoryId
    required property string queryText

    function primaryCategoryIdFor(entry) {
        const entryCategories = entry.categories || [];
        if (entryCategories.length === 0)
            return null;

        for (const cat of categories) {
            if (cat.id === "all")
                continue;
            if ((cat.desktopCategories || []).some(c => entryCategories.includes(c)))
                return cat.id;
        }
        return null;
    }

    function categorySortIndex(id) {
        if (!id)
            return categories.length;
        for (let i = 0; i < categories.length; i++) {
            if (categories[i].id === id)
                return i;
        }
        return categories.length;
    }

    function searchRelevanceScore(entry, query, terms) {
        const name = String(entry.name || "").toLowerCase();
        const genericName = String(entry.genericName || "").toLowerCase();
        const comment = String(entry.comment || "").toLowerCase();
        const id = String(entry.id || "").toLowerCase();
        const keywords = (entry.keywords || []).join(" ").toLowerCase();
        let score = 0;

        if (name === query) score += 1000;
        else if (name.startsWith(query)) score += 800;
        else if (name.split(/\s+/).some(word => word.startsWith(query))) score += 600;
        else if (name.includes(query)) score += 400;

        if (genericName === query) score += 500;
        else if (genericName.startsWith(query)) score += 400;
        else if (genericName.split(/\s+/).some(word => word.startsWith(query))) score += 300;
        else if (genericName.includes(query)) score += 200;

        const keywordWords = keywords.split(/[\s,]+/);
        if (keywordWords.some(word => word === query)) score += 250;
        else if (keywordWords.some(word => word.startsWith(query))) score += 150;
        else if (keywords.includes(query)) score += 100;
        if (comment.includes(query)) score += 50;
        if (id.includes(query)) score += 25;

        if (terms.length > 1 && terms.every(term => name.includes(term)))
            score += 900;
        return score;
    }

    readonly property var filteredApplications: {
        const categoryId = searchModel.categoryId;
        const query = searchModel.queryText.trim().toLowerCase();
        const terms = query.length > 0 ? query.split(/\s+/).filter(term => term.length > 0) : [];
        const hasQuery = terms.length > 0;
        const entries = [...applications].filter(entry => {
            const name = String(entry.name || "").trim();
            if (!name || !entry.id || entry.noDisplay)
                return false;
            if (categoryId !== "all") {
                if (primaryCategoryIdFor(entry) !== categoryId)
                    return false;
                const blocked = categoryId === "settings" ? ["System", "AudioVideo", "Audio"] : excludedCategories;
                if ((entry.categories || []).some(category => blocked.includes(category)))
                    return false;
            }
            if (hasQuery) {
                const searchableText = [entry.name || "", entry.genericName || "", entry.comment || "", entry.id || "", (entry.keywords || []).join(" "), (entry.categories || []).join(" ")].join(" ").toLowerCase();
                if (!terms.every(term => searchableText.includes(term)))
                    return false;
            }
            return true;
        });

        if (hasQuery) {
            return entries.map(entry => ({ entry, score: searchRelevanceScore(entry, query, terms) })).sort((a, b) => {
                if (b.score !== a.score)
                    return b.score - a.score;
                return a.entry.name.toLowerCase().localeCompare(b.entry.name.toLowerCase());
            }).map(item => item.entry);
        }

        return entries.map(entry => ({ entry, categoryIndex: categorySortIndex(primaryCategoryIdFor(entry)) })).sort((a, b) => {
            if (a.categoryIndex !== b.categoryIndex)
                return a.categoryIndex - b.categoryIndex;
            return a.entry.name.toLowerCase().localeCompare(b.entry.name.toLowerCase());
        }).map(item => item.entry);
    }
}
