// SPDX-License-Identifier: GPL-3.0-or-later
#include "BlurBackend.h"

namespace klde {
void PreviewBlurBackend::setQuality(Quality quality) {
    if (quality <= High && m_quality != quality) {
        m_quality = quality;
        emit policyChanged();
    }
}
void PreviewBlurBackend::setRenderingAllowed(bool allowed) {
    if (m_renderingAllowed != allowed) {
        m_renderingAllowed = allowed;
        emit policyChanged();
    }
}
void PreviewBlurBackend::setGraphicsAvailable(bool available) {
    if (m_graphicsAvailable != available) {
        m_graphicsAvailable = available;
        emit policyChanged();
    }
}
BlurBackend::Strategy PreviewBlurBackend::strategyFor(bool ownsContent) const {
    if (m_quality == Off || !m_renderingAllowed) {
        return OpaqueFallback;
    }
    return ownsContent && m_graphicsAvailable ? OwnedContentGpu : OpaqueFallback;
}
} // namespace klde
