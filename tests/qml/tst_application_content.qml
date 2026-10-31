// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import Owo.Visuals

Item {
    id: root
    width: 400
    height: 200
    Component {
        id: tileComponent
        AppTile {
            width: 240
            height: 120
            listMode: true
        }
    }
    Component {
        id: dockComponent
        DockItem {
            width: 64
            height: 64
        }
    }
    Component {
        id: statusComponent
        StatusCapsule {
            width: 240
            height: 64
        }
    }
    TestCase {
        name: "ApplicationContentBoundary"
        when: windowShown
        function test_applicationMetadataIsPlainText(): void {
            const title = "<b>Literal & title</b>";
            const detail = "<i>Application supplied detail</i>";
            const tile = createTemporaryObject(tileComponent, root, {
                "label": title,
                "detail": detail
            });
            verify(tile !== null);
            const label = findChild(tile, "applicationLabel");
            const description = findChild(tile, "applicationDetail");
            verify(label !== null && description !== null);
            compare(label.text, title);
            compare(description.text, detail);
            compare(label.textFormat, Text.PlainText);
            compare(description.textFormat, Text.PlainText);
            const dock = createTemporaryObject(dockComponent, root, {
                "label": title
            });
            verify(dock !== null);
            const tooltip = findChild(dock, "applicationToolTipText");
            verify(tooltip !== null);
            compare(tooltip.text, title);
            compare(tooltip.textFormat, Text.PlainText);
            const status = createTemporaryObject(statusComponent, root, {
                "valueText": title
            });
            verify(status !== null);
            const statusLabel = findChild(status, "statusValueLabel");
            const statusHint = findChild(status, "statusToolTipText");
            verify(statusLabel !== null && statusHint !== null);
            compare(statusLabel.text, title);
            compare(statusLabel.textFormat, Text.PlainText);
            compare(statusHint.textFormat, Text.PlainText);
        }
    }
}
