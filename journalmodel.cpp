#include "journalmodel.h"
#include "shamsi.h"
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QStandardPaths>
#include <QUuid>
#include <QUrl>
#include <QGuiApplication>
#include <QClipboard>

static QString cleanTag(const QString &tag)
{
    QString clean = tag.trimmed();
    if (clean.startsWith(QLatin1Char('#')))
        clean = clean.mid(1).trimmed();
    return clean;
}

static QVariantMap themeMap(const QString &name)
{
    QVariantMap t;
    auto put = [&](const char *key, const char *value) {
        t.insert(QLatin1String(key), QString::fromLatin1(value));
    };
    if (name == QLatin1String("midnight")) {
        put("bg", "#0a0d14"); put("surface", "#121722"); put("book", "#0e121c"); put("card", "#1a2030");
        put("line", "#2e3650"); put("text", "#eef1f8"); put("muted", "#9aa4bb"); put("faint", "#6b7590");
        put("accent", "#8fa8ff"); put("accentInk", "#0a0d14"); put("chip", "#1f2638"); put("danger", "#ef8fa6");
        put("button", "#1b2232"); put("buttonHover", "#2a3448"); put("buttonDown", "#3a4662"); put("buttonLine", "#333c55");
    } else if (name == QLatin1String("forest")) {
        put("bg", "#0d1a14"); put("surface", "#15261f"); put("book", "#11201a"); put("card", "#1a352a");
        put("line", "#345441"); put("text", "#eaf6ef"); put("muted", "#8fae9c"); put("faint", "#6f8d7d");
        put("accent", "#86d6a6"); put("accentInk", "#0d1a14"); put("chip", "#203d2f"); put("danger", "#e89a9a");
        put("button", "#1c3a2d"); put("buttonHover", "#2a4f3e"); put("buttonDown", "#37654f"); put("buttonLine", "#345441");
    } else if (name == QLatin1String("plum")) {
        put("bg", "#160f1c"); put("surface", "#211828"); put("book", "#1b1223"); put("card", "#2a1c34");
        put("line", "#4a3460"); put("text", "#f6edfa"); put("muted", "#b8a2c5"); put("faint", "#8f789b");
        put("accent", "#dbaef5"); put("accentInk", "#160f1c"); put("chip", "#3f2a50"); put("danger", "#ef9fbe");
        put("button", "#2e1f3c"); put("buttonHover", "#402d54"); put("buttonDown", "#52386c"); put("buttonLine", "#4a3460");
    } else if (name == QLatin1String("sand")) {
        put("bg", "#f4efe7"); put("surface", "#fffdf9"); put("book", "#fbf8f2"); put("card", "#ffffff");
        put("line", "#e0d2be"); put("text", "#2a241d"); put("muted", "#786a58"); put("faint", "#a39480");
        put("accent", "#9a5f33"); put("accentInk", "#fffdf9"); put("chip", "#efe3d2"); put("danger", "#9a4242");
        put("button", "#ede1cf"); put("buttonHover", "#e2d2ba"); put("buttonDown", "#d5c1a4"); put("buttonLine", "#d9cbb5");
    } else {
        put("bg", "#0c1424"); put("surface", "#141f36"); put("book", "#111b30"); put("card", "#1a2742");
        put("line", "#2f4870"); put("text", "#e9effa"); put("muted", "#90a2c0"); put("faint", "#6e84a6");
        put("accent", "#82b4ff"); put("accentInk", "#0c1424"); put("chip", "#1e365e"); put("danger", "#ef9aad");
        put("button", "#1c2f4e"); put("buttonHover", "#284066"); put("buttonDown", "#345588"); put("buttonLine", "#345070");
    }
    return t;
}

/* ---------------- EntryListModel ---------------- */

QVariant EntryListModel::data(const QModelIndex &idx, int role) const
{
    if (!idx.isValid() || idx.row() >= m_entries.size()) return {};
    const Entry &e = m_entries[idx.row()];
    switch (role) {
    case IdRole:     return e.id;
    case TextRole:   return e.text;
    case DoneRole:   return e.done;
    case ImagesRole: return e.images;
    case KindRole:   return e.kind;
    case TitleRole:  return e.title;
    case TagsRole:   return e.tags;
    case SnippetsRole: return e.snippets;
    }
    return {};
}

QHash<int, QByteArray> EntryListModel::roleNames() const
{
    return { {IdRole,"id"}, {TextRole,"text"}, {DoneRole,"done"},
             {ImagesRole,"images"}, {KindRole,"kind"}, {TitleRole,"title"},
             {TagsRole,"tags"}, {SnippetsRole,"snippets"} };
}

void EntryListModel::setEntries(const QVector<Entry> &e)
{
    beginResetModel();
    m_entries = e;
    endResetModel();
    emit countChanged();
}

void EntryListModel::updateText(int row, const QString &text)
{
    if (row < 0 || row >= m_entries.size()) return;
    m_entries[row].text = text;
    auto i = index(row);
    emit dataChanged(i, i, {TextRole});
    emit changed();
}

void EntryListModel::updateTitle(int row, const QString &title)
{
    if (row < 0 || row >= m_entries.size()) return;
    m_entries[row].title = title;
    auto i = index(row);
    emit dataChanged(i, i, {TitleRole});
    emit changed();
}

void EntryListModel::updateDone(int row, bool done)
{
    if (row < 0 || row >= m_entries.size()) return;
    m_entries[row].done = done;
    auto i = index(row);
    emit dataChanged(i, i, {DoneRole});
    emit changed();
}

void EntryListModel::addImage(int row, const QString &dataUrl)
{
    if (row < 0 || row >= m_entries.size()) return;
    m_entries[row].images.append(dataUrl);
    auto i = index(row);
    emit dataChanged(i, i, {ImagesRole});
    emit changed();
}

void EntryListModel::removeImage(int row, int imgIndex)
{
    if (row < 0 || row >= m_entries.size()) return;
    if (imgIndex < 0 || imgIndex >= m_entries[row].images.size()) return;
    m_entries[row].images.removeAt(imgIndex);
    auto i = index(row);
    emit dataChanged(i, i, {ImagesRole});
    emit changed();
}

void EntryListModel::addTag(int row, const QString &tag)
{
    if (row < 0 || row >= m_entries.size()) return;
    const QString clean = cleanTag(tag);
    if (clean.isEmpty()) return;
    for (const QString &existing : m_entries[row].tags)
        if (existing.compare(clean, Qt::CaseInsensitive) == 0) return;
    m_entries[row].tags.append(clean);
    auto i = index(row);
    emit dataChanged(i, i, {TagsRole});
    emit changed();
}

void EntryListModel::removeTag(int row, const QString &tag)
{
    if (row < 0 || row >= m_entries.size()) return;
    const QString clean = cleanTag(tag);
    auto &tags = m_entries[row].tags;
    for (int i = 0; i < tags.size(); ++i) {
        if (tags[i].compare(clean, Qt::CaseInsensitive) != 0) continue;
        tags.removeAt(i);
        auto idx = index(row);
        emit dataChanged(idx, idx, {TagsRole});
        emit changed();
        return;
    }
}

void EntryListModel::addEmpty()
{
    addCheck();
}

void EntryListModel::addCheck()
{
    beginInsertRows({}, m_entries.size(), m_entries.size());
    Entry e;
    e.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    e.kind = QStringLiteral("check");
    m_entries.append(e);
    endInsertRows();
    emit countChanged();
    emit changed();
}

void EntryListModel::addNote()
{
    beginInsertRows({}, m_entries.size(), m_entries.size());
    Entry e;
    e.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    e.kind = QStringLiteral("note");
    m_entries.append(e);
    endInsertRows();
    emit countChanged();
    emit changed();
}

void EntryListModel::addCodeNote()
{
    beginInsertRows({}, m_entries.size(), m_entries.size());
    Entry e;
    e.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    e.kind = QStringLiteral("note");
    e.snippets.append(QString());
    m_entries.append(e);
    endInsertRows();
    emit countChanged();
    emit changed();
}

void EntryListModel::addSnippet(int row)
{
    if (row < 0 || row >= m_entries.size()) return;
    m_entries[row].snippets.append(QString());
    auto i = index(row);
    emit dataChanged(i, i, {SnippetsRole});
    emit changed();
}

void EntryListModel::updateSnippet(int row, int snippetIndex, const QString &text)
{
    if (row < 0 || row >= m_entries.size()) return;
    if (snippetIndex < 0 || snippetIndex >= m_entries[row].snippets.size()) return;
    if (m_entries[row].snippets[snippetIndex] == text) return;
    m_entries[row].snippets[snippetIndex] = text;
    auto i = index(row);
    emit dataChanged(i, i, {SnippetsRole});
    emit changed();
}

void EntryListModel::removeSnippet(int row, int snippetIndex)
{
    if (row < 0 || row >= m_entries.size()) return;
    if (snippetIndex < 0 || snippetIndex >= m_entries[row].snippets.size()) return;
    m_entries[row].snippets.removeAt(snippetIndex);
    auto i = index(row);
    emit dataChanged(i, i, {SnippetsRole});
    emit changed();
}

QString EntryListModel::clipboardText() const
{
    const QClipboard *clipboard = QGuiApplication::clipboard();
    return clipboard ? clipboard->text() : QString();
}

void EntryListModel::appendEntry(const Entry &entry)
{
    beginInsertRows({}, m_entries.size(), m_entries.size());
    m_entries.append(entry);
    endInsertRows();
    emit countChanged();
    emit changed();
}

void EntryListModel::addImageFromFile(int row, const QString &fileUrl)
{
    if (row < 0 || row >= m_entries.size()) return;

    const QUrl url(fileUrl);
    const QString path = url.isLocalFile() ? url.toLocalFile() : fileUrl;
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) return;

    const QString ext = QFileInfo(path).suffix().toLower();
    QString mime = QStringLiteral("application/octet-stream");
    if (ext == QLatin1String("jpg") || ext == QLatin1String("jpeg"))
        mime = QStringLiteral("image/jpeg");
    else if (ext == QLatin1String("png"))
        mime = QStringLiteral("image/png");
    else if (ext == QLatin1String("gif"))
        mime = QStringLiteral("image/gif");
    else if (ext == QLatin1String("webp"))
        mime = QStringLiteral("image/webp");
    else if (ext == QLatin1String("bmp"))
        mime = QStringLiteral("image/bmp");

    const QString dataUrl = QStringLiteral("data:%1;base64,%2")
            .arg(mime, QString::fromLatin1(file.readAll().toBase64()));
    addImage(row, dataUrl);
}

void EntryListModel::removeAt(int row)
{
    if (row < 0 || row >= m_entries.size()) return;
    beginRemoveRows({}, row, row);
    m_entries.removeAt(row);
    endRemoveRows();
    emit countChanged();
    emit changed();
}

/* ---------------- JournalModel ---------------- */

JournalModel::JournalModel(QObject *parent) : QAbstractListModel(parent)
{
    m_dir = m_settings.value("storageDir").toString();
    if (m_dir.isEmpty()) {
        m_dir = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)
                + "/Journal";
    }
    QDir().mkpath(m_dir);

    m_themeName = m_settings.value(QStringLiteral("theme"), QStringLiteral("navy")).toString();
    if (!QStringList{QStringLiteral("navy"), QStringLiteral("midnight"), QStringLiteral("forest"),
                     QStringLiteral("plum"), QStringLiteral("sand")}.contains(m_themeName))
        m_themeName = QStringLiteral("navy");

    connect(&m_currentEntries, &EntryListModel::changed, this, [this]{
        if (m_currentIndex < 0 || m_currentIndex >= m_pages.size()) return;
        m_pages[m_currentIndex].entries = m_currentEntries.entries();
        savePage(m_pages[m_currentIndex]);
        syncTagCatalog();
    });

    loadAll();

    // Keep a page for today, then reopen whichever day was open last.
    QDate today = QDate::currentDate();
    bool found = false;
    for (auto &p : m_pages) if (p.date == today) { found = true; break; }
    if (!found) {
        Page p; p.date = today;
        Entry e; e.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
        p.entries.append(e);
        m_pages.append(p);
        savePage(m_pages.last());
        sortPages();
    }
    selectInitialPage();
}

void JournalModel::setStorageDir(const QString &dir)
{
    if (dir == m_dir) return;
    // save current page first
    if (m_currentIndex >= 0 && m_currentIndex < m_pages.size()) {
        m_pages[m_currentIndex].entries = m_currentEntries.entries();
        savePage(m_pages[m_currentIndex]);
    }
    m_dir = dir;
    QDir().mkpath(m_dir);
    m_settings.setValue("storageDir", m_dir);
    emit storageDirChanged();
    loadAll();
    selectInitialPage();
    emit pageCountChanged();
    emit currentIndexChanged();
    emit currentDateChanged();
}

int JournalModel::rowCount(const QModelIndex &p) const
{
    return p.isValid() ? 0 : m_pages.size();
}

QVariant JournalModel::data(const QModelIndex &idx, int role) const
{
    if (!idx.isValid() || idx.row() >= m_pages.size()) return {};
    const Page &p = m_pages[idx.row()];
    if (role == DateRole) return p.date;
    return {};
}

QHash<int, QByteArray> JournalModel::roleNames() const
{
    return { {DateRole,"date"} };
}

void JournalModel::setCurrentIndex(int i)
{
    if (i < 0 || i >= m_pages.size() || i == m_currentIndex) return;
    if (m_currentIndex >= 0 && m_currentIndex < m_pages.size()) {
        m_pages[m_currentIndex].entries = m_currentEntries.entries();
        savePage(m_pages[m_currentIndex]);
    }
    m_currentIndex = i;
    rebuildCurrentEntries();
    rememberCurrentDate();
    emit currentIndexChanged();
    emit currentDateChanged();
}

int JournalModel::indexForDate(const QDate &d) const
{
    for (int i = 0; i < m_pages.size(); ++i)
        if (m_pages[i].date == d)
            return i;
    return -1;
}

void JournalModel::rememberCurrentDate()
{
    if (m_currentIndex < 0 || m_currentIndex >= m_pages.size())
        return;
    m_settings.setValue(QStringLiteral("lastDate"), m_pages[m_currentIndex].date.toString(Qt::ISODate));
}

void JournalModel::selectInitialPage()
{
    const QDate last = QDate::fromString(m_settings.value(QStringLiteral("lastDate")).toString(), Qt::ISODate);
    int i = last.isValid() ? indexForDate(last) : -1;
    if (i < 0)
        i = qMax(0, m_pages.size() - 1);
    m_currentIndex = i;
    rebuildCurrentEntries();
}

QDate JournalModel::currentDate() const
{
    if (m_currentIndex < 0 || m_currentIndex >= m_pages.size()) return QDate::currentDate();
    return m_pages[m_currentIndex].date;
}

void JournalModel::setCurrentDate(QDate d)
{
    openDate(d);
}

void JournalModel::openDate(const QDate &d)
{
    if (!d.isValid()) return;

    for (int i = 0; i < m_pages.size(); ++i) {
        if (m_pages[i].date == d) {
            setCurrentIndex(i);
            return;
        }
    }

    if (m_currentIndex >= 0 && m_currentIndex < m_pages.size()) {
        m_pages[m_currentIndex].entries = m_currentEntries.entries();
        savePage(m_pages[m_currentIndex]);
    }

    Page p;
    p.date = d;
    Entry e;
    e.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    p.entries.append(e);
    savePage(p);

    int insertAt = 0;
    while (insertAt < m_pages.size() && m_pages[insertAt].date < d)
        ++insertAt;

    beginInsertRows({}, insertAt, insertAt);
    m_pages.insert(insertAt, p);
    endInsertRows();

    m_currentIndex = insertAt;
    rebuildCurrentEntries();
    rememberCurrentDate();
    emit pageCountChanged();
    emit currentIndexChanged();
    emit currentDateChanged();
}

QString JournalModel::currentDateDisplay() const
{
    return currentDate().toString("dddd, yyyy-MM-dd");
}

QString JournalModel::currentShamsiDisplay() const
{
    Shamsi s;
    return s.format(currentDate());
}

void JournalModel::nextPage()
{
    openDate(currentDate().addDays(1));
}

void JournalModel::prevPage()
{
    openDate(currentDate().addDays(-1));
}

void JournalModel::goToToday()
{
    openDate(QDate::currentDate());
}

void JournalModel::copyEntryToToday(int row)
{
    if (m_currentIndex < 0 || m_currentIndex >= m_pages.size()) return;
    const QVector<Entry> live = m_currentEntries.entries();
    if (row < 0 || row >= live.size()) return;

    Entry copy = live[row];
    copy.id = QUuid::createUuid().toString(QUuid::WithoutBraces);

    const QDate today = QDate::currentDate();
    if (m_pages[m_currentIndex].date == today) {
        m_currentEntries.appendEntry(copy);
        return;
    }

    m_pages[m_currentIndex].entries = live;
    savePage(m_pages[m_currentIndex]);

    const int todayIndex = indexForDate(today);
    if (todayIndex >= 0) {
        m_pages[todayIndex].entries.append(copy);
        savePage(m_pages[todayIndex]);
        return;
    }

    Page p;
    p.date = today;
    p.entries.append(copy);
    savePage(p);

    int insertAt = 0;
    while (insertAt < m_pages.size() && m_pages[insertAt].date < today)
        ++insertAt;

    beginInsertRows({}, insertAt, insertAt);
    m_pages.insert(insertAt, p);
    endInsertRows();
    if (insertAt <= m_currentIndex)
        ++m_currentIndex;
    emit pageCountChanged();
    emit currentIndexChanged();
}

void JournalModel::jumpToDate(QDate d) { setCurrentDate(d); }

QVariantList JournalModel::search(const QString &query) const
{
    QVariantList out;
    if (query.trimmed().isEmpty()) return out;
    QString q = query.toLower();
    for (int pi = 0; pi < m_pages.size(); ++pi) {
        for (const Entry &e : m_pages[pi].entries) {
            const QString blob = (e.title + QLatin1Char(' ') + e.text + QLatin1Char(' ')
                                  + e.tags.join(QLatin1Char(' ')) + QLatin1Char(' ')
                                  + e.snippets.join(QLatin1Char(' '))).toLower();
            if (blob.contains(q)) {
                QVariantMap m;
                m["pageIndex"] = pi;
                m["date"] = m_pages[pi].date.toString("yyyy-MM-dd");
                m["text"] = (e.kind == QLatin1String("note") && !e.title.isEmpty() ? e.title : e.text).left(120);
                m["entryId"] = e.id;
                out.append(m);
                if (out.size() >= 50) return out;
            }
        }
    }
    return out;
}

void JournalModel::loadAll()
{
    beginResetModel();
    m_pages.clear();
    QDir dir(m_dir);
    for (const QString &f : dir.entryList({"*.json"}, QDir::Files, QDir::Name)) {
        QDate d = QDate::fromString(QFileInfo(f).completeBaseName(), "yyyy-MM-dd");
        if (!d.isValid()) continue;
        QFile file(m_dir + "/" + f);
        if (!file.open(QIODevice::ReadOnly)) continue;
        auto doc = QJsonDocument::fromJson(file.readAll());
        Page p; p.date = d;
        QJsonArray arr = doc.object()["entries"].toArray();
        for (auto v : arr) {
            QJsonObject o = v.toObject();
            Entry e;
            e.id = o["id"].toString();
            e.kind = o["kind"].toString() == QLatin1String("note") ? QStringLiteral("note") : QStringLiteral("check");
            e.title = o["title"].toString();
            e.text = o["text"].toString();
            e.done = o["done"].toBool();
            for (auto tv : o["tags"].toArray()) e.tags.append(tv.toString());
            for (auto sv : o["snippets"].toArray()) e.snippets.append(sv.toString());
            for (auto iv : o["images"].toArray()) e.images.append(iv.toString());
            p.entries.append(e);
        }
        m_pages.append(p);
    }
    if (m_pages.isEmpty()) {
        Page p; p.date = QDate::currentDate();
        Entry e; e.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
        p.entries.append(e);
        m_pages.append(p);
        savePage(m_pages[0]);
    }
    sortPages();
    endResetModel();
    emit pageCountChanged();
    syncTagCatalog();
}

void JournalModel::sortPages()
{
    std::sort(m_pages.begin(), m_pages.end(),
              [](const Page &a, const Page &b){ return a.date < b.date; });
}

void JournalModel::savePage(Page &p)
{
    QJsonObject root;
    root["date"] = p.date.toString("yyyy-MM-dd");
    QJsonArray arr;
    for (const Entry &e : p.entries) {
        QJsonObject o;
        o["id"] = e.id;
        o["kind"] = e.kind;
        o["title"] = e.title;
        o["text"] = e.text;
        o["done"] = e.done;
        QJsonArray tags;
        for (const QString &tag : e.tags) tags.append(tag);
        o["tags"] = tags;
        QJsonArray snippets;
        for (const QString &snippet : e.snippets) snippets.append(snippet);
        o["snippets"] = snippets;
        QJsonArray imgs;
        for (const QString &s : e.images) imgs.append(s);
        o["images"] = imgs;
        arr.append(o);
    }
    root["entries"] = arr;
    QString path = m_dir + "/" + p.date.toString("yyyy-MM-dd") + ".json";
    QFile f(path);
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate))
        f.write(QJsonDocument(root).toJson());
}

void JournalModel::rebuildCurrentEntries()
{
    QVector<Entry> e;
    if (m_currentIndex >= 0 && m_currentIndex < m_pages.size())
        e = m_pages[m_currentIndex].entries;
    m_currentEntries.setEntries(e);
}

void JournalModel::loadPageFromDisk(const QDate &) { /* handled in loadAll */ }

void JournalModel::setThemeName(const QString &name)
{
    const QStringList known{QStringLiteral("navy"), QStringLiteral("midnight"), QStringLiteral("forest"),
                            QStringLiteral("plum"), QStringLiteral("sand")};
    if (!known.contains(name) || name == m_themeName) return;
    m_themeName = name;
    m_settings.setValue(QStringLiteral("theme"), m_themeName);
    emit themeChanged();
}

QVariantMap JournalModel::theme() const
{
    return themeMap(m_themeName);
}

QVariantList JournalModel::notesForTag(const QString &tag) const
{
    QVariantList out;
    const QString want = cleanTag(tag);
    if (want.isEmpty()) return out;
    Shamsi shamsi;
    for (const Page &page : m_pages) {
        for (const Entry &e : page.entries) {
            bool matched = false;
            for (const QString &have : e.tags) {
                if (have.compare(want, Qt::CaseInsensitive) == 0) { matched = true; break; }
            }
            if (!matched) continue;
            QVariantMap m;
            m["date"] = page.date.toString(QStringLiteral("yyyy-MM-dd"));
            m["shamsi"] = shamsi.format(page.date);
            m["title"] = e.title;
            m["text"] = e.text.left(160);
            m["kind"] = e.kind;
            out.append(m);
        }
    }
    return out;
}

void JournalModel::syncTagCatalog()
{
    QStringList catalog = m_tagCatalog;
    if (catalog.isEmpty())
        catalog = m_settings.value(QStringLiteral("tagCatalog")).toStringList();
    auto add = [&](const QString &raw) {
        const QString tag = cleanTag(raw);
        if (tag.isEmpty()) return;
        for (const QString &existing : catalog)
            if (existing.compare(tag, Qt::CaseInsensitive) == 0) return;
        catalog.append(tag);
    };
    add(QStringLiteral("remember"));
    add(QStringLiteral("bug"));
    for (const Page &page : m_pages)
        for (const Entry &e : page.entries)
            for (const QString &tag : e.tags)
                add(tag);
    if (catalog == m_tagCatalog) return;
    m_tagCatalog = catalog;
    m_settings.setValue(QStringLiteral("tagCatalog"), m_tagCatalog);
    emit tagCatalogChanged();
}
