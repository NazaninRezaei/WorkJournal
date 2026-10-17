#include "shamsi.h"

void Shamsi::g2j(int gy, int gm, int gd, int &jy, int &jm, int &jd)
{
    static const int g_d_m[] = {0,31,59,90,120,151,181,212,243,273,304,334};
    int gy2 = (gm > 2) ? (gy + 1) : gy;
    long days = 355666 + (365L * gy) + ((gy2 + 3) / 4)
              - ((gy2 + 99) / 100) + ((gy2 + 399) / 400)
              + gd + g_d_m[gm - 1];
    jy = -1595 + (33 * (days / 12053));
    days %= 12053;
    jy += 4 * (days / 1461);
    days %= 1461;
    if (days > 365) { jy += (days - 1) / 365; days = (days - 1) % 365; }
    if (days < 186) { jm = 1 + (days / 31); jd = 1 + (days % 31); }
    else            { jm = 7 + ((days - 186) / 30); jd = 1 + ((days - 186) % 30); }
}

void Shamsi::j2g(int jy, int jm, int jd, int &gy, int &gm, int &gd)
{
    long jy2 = jy + 1595;
    long days = -355668 + (365L * jy2) + ((jy2 / 33) * 8)
              + (((jy2 % 33) + 3) / 4) + jd
              + ((jm < 7) ? (jm - 1) * 31 : ((jm - 7) * 30) + 186);
    gy = 400 * (days / 146097);
    days %= 146097;
    if (days > 36524) {
        gy += 100 * (--days / 36524);
        days %= 36524;
        if (days >= 365) days++;
    }
    gy += 4 * (days / 1461);
    days %= 1461;
    if (days > 365) { gy += (days - 1) / 365; days = (days - 1) % 365; }
    gd = days + 1;
    int sal_a[13];
    sal_a[0]=0;
    sal_a[1]=31;
    sal_a[2]=((gy%4==0 && gy%100!=0)||(gy%400==0))?29:28;
    sal_a[3]=31; sal_a[4]=30; sal_a[5]=31; sal_a[6]=30;
    sal_a[7]=31; sal_a[8]=31; sal_a[9]=30; sal_a[10]=31;
    sal_a[11]=30; sal_a[12]=31;
    gm = 1;
    while (gm <= 12 && gd > sal_a[gm]) { gd -= sal_a[gm]; ++gm; }
}

QVariantList Shamsi::fromGregorian(QDate d) const
{
    int jy, jm, jd;
    g2j(d.year(), d.month(), d.day(), jy, jm, jd);
    return { jy, jm, jd };
}

QDate Shamsi::toGregorian(int jy, int jm, int jd) const
{
    int gy, gm, gd;
    j2g(jy, jm, jd, gy, gm, gd);
    return QDate(gy, gm, gd);
}

QString Shamsi::monthName(int jm) const
{
    static const char *m[] = {"فروردین","اردیبهشت","خرداد","تیر","مرداد","شهریور",
                              "مهر","آبان","آذر","دی","بهمن","اسفند"};
    if (jm < 1 || jm > 12) return {};
    return QString::fromUtf8(m[jm - 1]);
}

QString Shamsi::weekdayName(QDate d) const
{
    static const char *w[] = {"شنبه","یکشنبه","دوشنبه","سه‌شنبه","چهارشنبه","پنجشنبه","جمعه"};
    // Qt numbers Monday as 1 … Saturday as 6, Sunday as 7. Saturday is the first Shamsi weekday.
    return QString::fromUtf8(w[(d.dayOfWeek() + 1) % 7]);
}

bool Shamsi::isLeap(int jy) const
{
    return ((25 * jy + 11) % 33) < 8;
}

int Shamsi::monthLength(int jy, int jm) const
{
    if (jm <= 6) return 31;
    if (jm <= 11) return 30;
    return isLeap(jy) ? 30 : 29;
}

QString Shamsi::format(QDate d) const
{
    auto s = fromGregorian(d);
    int jy = s[0].toInt(), jm = s[1].toInt(), jd = s[2].toInt();
    return QString("%1، %2 %3 %4").arg(weekdayName(d)).arg(jd).arg(monthName(jm)).arg(jy);
}
