#pragma once
#include <QObject>
#include <QString>
#include <QDate>
#include <QVector>

class Shamsi : public QObject
{
    Q_OBJECT
public:
    explicit Shamsi(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE QVariantList fromGregorian(QDate d) const;
    Q_INVOKABLE QDate toGregorian(int jy, int jm, int jd) const;
    Q_INVOKABLE QString monthName(int jm) const;
    Q_INVOKABLE QString weekdayName(QDate d) const;
    Q_INVOKABLE bool isLeap(int jy) const;
    Q_INVOKABLE int monthLength(int jy, int jm) const;
    Q_INVOKABLE QString format(QDate d) const; // "شنبه، 25 مهر 1405"

private:
    static void g2j(int gy, int gm, int gd, int &jy, int &jm, int &jd);
    static void j2g(int jy, int jm, int jd, int &gy, int &gm, int &gd);
};
