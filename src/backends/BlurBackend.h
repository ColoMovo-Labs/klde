// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

namespace klde {
class BlurBackend : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.blur")
    Q_PROPERTY(Quality quality READ quality WRITE setQuality NOTIFY policyChanged)
    Q_PROPERTY(bool nativeAvailable READ nativeAvailable CONSTANT)
    Q_PROPERTY(bool ownedContentAvailable READ ownedContentAvailable NOTIFY policyChanged)
    Q_PROPERTY(
        bool renderingAllowed READ renderingAllowed WRITE setRenderingAllowed NOTIFY policyChanged)

  public:
    enum Quality : quint8 { Off, Low, Medium, High };
    Q_ENUM(Quality)
    enum Strategy : quint8 { OpaqueFallback, OwnedContentGpu, NativeBackdrop };
    Q_ENUM(Strategy)
    using QObject::QObject;
    virtual Quality quality() const = 0;
    virtual bool nativeAvailable() const = 0;
    virtual bool ownedContentAvailable() const = 0;
    virtual bool renderingAllowed() const = 0;
    virtual void setQuality(Quality quality) = 0;
    virtual void setRenderingAllowed(bool allowed) = 0;
    Q_INVOKABLE virtual Strategy strategyFor(bool ownsContent) const = 0;
  signals:
    void policyChanged();
};

class PreviewBlurBackend final : public BlurBackend {
    Q_OBJECT
  public:
    using BlurBackend::BlurBackend;
    Quality quality() const override { return m_quality; }
    bool nativeAvailable() const override { return false; }
    bool ownedContentAvailable() const override { return m_graphicsAvailable; }
    bool renderingAllowed() const override { return m_renderingAllowed; }
    void setQuality(Quality quality) override;
    void setRenderingAllowed(bool allowed) override;
    Strategy strategyFor(bool ownsContent) const override;
    void setGraphicsAvailable(bool available);

  private:
    Quality m_quality = Medium;
    bool m_graphicsAvailable = false;
    bool m_renderingAllowed = true;
};
} // namespace klde
