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
