// SPDX-License-Identifier: GPL-3.0-or-later
#include <QApplication>
#include <QCommandLineParser>
#include <QEvent>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLabel>
#include <QLineEdit>
#include <QPushButton>
#include <QSaveFile>
#include <QTimer>
#include <QVBoxLayout>
#include <QWidget>

class AuditClient final : public QWidget {
  public:
    explicit AuditClient(QString path) : m_path(std::move(path)) {
        setWindowTitle("owoDE native CI application");
        resize(480, 360);
        setStyleSheet("QWidget { background: #f8e9c5; color: #253249; } QLineEdit { background: "
                      "white; padding: 12px; }");
        auto *layout = new QVBoxLayout(this);
        layout->addWidget(new QLabel("A real Qt Wayland application", this));
        m_input = new QLineEdit(this);
        m_input->setPlaceholderText("Keyboard focus target");
        layout->addWidget(m_input);
        layout->addStretch();
        auto *button = new QPushButton("Real application button", this);
        layout->addWidget(button);
        connect(m_input, &QLineEdit::textChanged, this, [this] { schedule(); });
        qApp->installEventFilter(this);
    }

  protected:
    bool eventFilter(QObject *object, QEvent *event) override {
        if (event->type() == QEvent::MouseButtonPress)
            ++m_clicks;
        if (event->type() == QEvent::MouseButtonPress || event->type() == QEvent::WindowActivate ||
            event->type() == QEvent::WindowDeactivate || event->type() == QEvent::Resize ||
            event->type() == QEvent::Show)
            schedule();
        return QWidget::eventFilter(object, event);
    }

  private:
    void schedule() {
        if (m_pending)
            return;
        m_pending = true;
        QTimer::singleShot(0, this, [this] {
            m_pending = false;
            QSaveFile file(m_path);
            if (file.open(QIODevice::WriteOnly)) {
                file.write(QJsonDocument(QJsonObject{{"active", isActiveWindow()},
                                                     {"clicks", m_clicks},
                                                     {"text", m_input->text()},
                                                     {"width", width()},
                                                     {"height", height()}})
                               .toJson());
                file.commit();
            }
        });
    }
    QString m_path;
    QLineEdit *m_input = nullptr;
    int m_clicks = 0;
    bool m_pending = false;
};

int main(int argc, char **argv) {
    QApplication app(argc, argv);
    app.setApplicationName("owode-native-test-client");
    if (qEnvironmentVariable("OWODE_NATIVE_TEST_ISOLATED") != "1")
        return 2;
    QCommandLineParser parser;
    parser.addOption({"state", "Cloud test state file", "path"});
    parser.process(app);
    if (parser.value("state").isEmpty())
        return 3;
    AuditClient client(parser.value("state"));
    client.show();
    return app.exec();
}
