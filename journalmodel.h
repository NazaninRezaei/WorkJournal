#pragma once
#include <QObject>
#include <QAbstractListModel>
#include <QDate>
#include <QSettings>
#include <QQmlEngine>

struct Entry {
        QString id;
        QString kind = QStringLiteral("check"); // "check" or "note"
        QString title;
        QString text;
        bool done = false;
        QStringList tags;
        QStringList snippets;
        QStringList images; // base64 data URLs
};

struct Page {
        QDate date;
        QVector<Entry> entries;
};

class EntryListModel : public QAbstractListModel
{
        Q_OBJECT
        Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    public:
        enum Roles { IdRole = Qt::UserRole + 1, TextRole, DoneRole, ImagesRole, KindRole, TitleRole, TagsRole, SnippetsRole };
        explicit EntryListModel(QObject *parent = nullptr) : QAbstractListModel(parent) {}

        int rowCount(const QModelIndex &p = {}) const override { return p.isValid() ? 0 : m_entries.size(); }
        QVariant data(const QModelIndex &idx, int role) const override;
        QHash<int, QByteArray> roleNames() const override;

        void setEntries(const QVector<Entry> &e);
        QVector<Entry> entries() const { return m_entries; }

        Q_INVOKABLE void updateText(int row, const QString &text);
        Q_INVOKABLE void updateTitle(int row, const QString &title);
        Q_INVOKABLE void updateDone(int row, bool done);
        Q_INVOKABLE void addTag(int row, const QString &tag);
        Q_INVOKABLE void removeTag(int row, const QString &tag);
        Q_INVOKABLE void addImage(int row, const QString &dataUrl);
        Q_INVOKABLE void removeImage(int row, int imgIndex);
        Q_INVOKABLE void addEmpty();
        Q_INVOKABLE void addCheck();
        Q_INVOKABLE void addNote();
        Q_INVOKABLE void addCodeNote();
        Q_INVOKABLE void addSnippet(int row);
        Q_INVOKABLE void updateSnippet(int row, int snippetIndex, const QString &text);
        Q_INVOKABLE void removeSnippet(int row, int snippetIndex);
        Q_INVOKABLE void removeAt(int row);
        Q_INVOKABLE void addImageFromFile(int row, const QString &fileUrl);
        Q_INVOKABLE QString clipboardText() const;
        void appendEntry(const Entry &entry);

    signals:
        void countChanged();
        void changed();

    private:
        QVector<Entry> m_entries;
};

class JournalModel : public QAbstractListModel
{
        Q_OBJECT
        Q_PROPERTY(QString storageDir READ storageDir WRITE setStorageDir NOTIFY storageDirChanged)
        Q_PROPERTY(int currentIndex READ currentIndex WRITE setCurrentIndex NOTIFY currentIndexChanged)
        Q_PROPERTY(QDate currentDate READ currentDate WRITE setCurrentDate NOTIFY currentDateChanged)
        Q_PROPERTY(QString currentDateDisplay READ currentDateDisplay NOTIFY currentDateChanged)
        Q_PROPERTY(QString currentShamsiDisplay READ currentShamsiDisplay NOTIFY currentDateChanged)
        Q_PROPERTY(int pageCount READ pageCount NOTIFY pageCountChanged)
        Q_PROPERTY(EntryListModel* currentEntries READ currentEntries CONSTANT)
        Q_PROPERTY(QString themeName READ themeName WRITE setThemeName NOTIFY themeChanged)
        Q_PROPERTY(QVariantMap theme READ theme NOTIFY themeChanged)
        Q_PROPERTY(QStringList tagCatalog READ tagCatalog NOTIFY tagCatalogChanged)

    public:
        explicit JournalModel(QObject *parent = nullptr);

        enum PageRoles { DateRole = Qt::UserRole + 1 };

        int rowCount(const QModelIndex &p = {}) const override;
        QVariant data(const QModelIndex &idx, int role) const override;
        QHash<int, QByteArray> roleNames() const override;

        QString storageDir() const { return m_dir; }
        void setStorageDir(const QString &dir);

        int currentIndex() const { return m_currentIndex; }
        Q_INVOKABLE void setCurrentIndex(int i);

        QDate currentDate() const;
        void setCurrentDate(QDate d);

        QString currentDateDisplay() const;
        QString currentShamsiDisplay() const;
        int pageCount() const { return m_pages.size(); }
        EntryListModel* currentEntries() { return &m_currentEntries; }

        Q_INVOKABLE void nextPage();
        Q_INVOKABLE void prevPage();
        Q_INVOKABLE void goToToday();
        Q_INVOKABLE QVariantList search(const QString &query) const;
        Q_INVOKABLE void jumpToDate(QDate d);
        Q_INVOKABLE void changeCurrentDate(int gy, int gm, int gd) { setCurrentDate(QDate(gy, gm, gd)); }
        Q_INVOKABLE QVariantList notesForTag(const QString &tag) const;
        Q_INVOKABLE void copyEntryToToday(int row);

        QString themeName() const { return m_themeName; }
        void setThemeName(const QString &name);
        QVariantMap theme() const;
        QStringList tagCatalog() const { return m_tagCatalog; }

    signals:
        void storageDirChanged();
        void currentIndexChanged();
        void currentDateChanged();
        void pageCountChanged();
        void searchResultsChanged();
        void themeChanged();
        void tagCatalogChanged();

    private:
        void loadAll();
        void loadPageFromDisk(const QDate &date);
        void savePage(Page &p);
        void sortPages();
        void rebuildCurrentEntries();
        void openDate(const QDate &d);
        void rememberCurrentDate();
        void selectInitialPage();
        int indexForDate(const QDate &d) const;
        void syncTagCatalog();

        QString m_dir;
        QVector<Page> m_pages;
        int m_currentIndex = -1;
        EntryListModel m_currentEntries;
        QSettings m_settings;
        QString m_themeName = QStringLiteral("navy");
        QStringList m_tagCatalog;
};
