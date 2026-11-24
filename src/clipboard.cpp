#include "clipboard.h"

#include <QClipboard>
#include <QGuiApplication>
#include <QMimeData>
#include <QUrl>

void copy_file_to_clipboard(const QString &path) {
  auto *mime_data = new QMimeData();
  mime_data->setUrls({QUrl::fromLocalFile(path)});
  QGuiApplication::clipboard()->setMimeData(mime_data);
}

void copy_text_to_clipboard(const QString &text) {
  QGuiApplication::clipboard()->setText(text);
}

QString clipboard_file_path() {
  const auto urls = QGuiApplication::clipboard()->mimeData()->urls();
  for (const auto &url : urls) {
    if (url.isLocalFile()) {
      return url.toLocalFile();
    }
  }
  return QString();
}

QString clipboard_text() {
  return QGuiApplication::clipboard()->text();
}
