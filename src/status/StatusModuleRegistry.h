// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>
namespace klde {
class StatusModuleRegistry : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.ribbon")
    Q_PROPERTY(QVariantList modules READ modules NOTIFY changed)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY changed)
    Q_PROPERTY(bool compact READ compact WRITE setCompact NOTIFY changed)
    Q_PROPERTY(int margin READ margin WRITE setMargin NOTIFY changed)
    Q_PROPERTY(int spacing READ spacing WRITE setSpacing NOTIFY changed)
  public:
    explicit StatusModuleRegistry(QObject *parent = nullptr);
    ~StatusModuleRegistry() override;
    QVariantList modules() const { return m_modules; }
    bool enabled() const { return m_enabled; }
    bool compact() const { return m_compact; }
    int margin() const { return m_margin; }
    int spacing() const { return m_spacing; }
    void setEnabled(bool enabled);
    void setCompact(bool compact);
    void setMargin(int margin);
    void setSpacing(int spacing);
    Q_INVOKABLE bool setVisible(const QString &id, bool visible);
    Q_INVOKABLE bool setSection(const QString &id, int section);
    Q_INVOKABLE bool move(const QString &id, int delta);
    Q_INVOKABLE void reset();
  signals:
    void changed();

  private:
    QVariantList m_modules;
    bool m_enabled = true;
    bool m_compact = false;
    int m_margin = 16;
    int m_spacing = 6;
};
} // namespace klde
