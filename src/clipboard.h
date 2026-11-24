#pragma once

#include <QString>

void copy_file_to_clipboard(const QString &path);
void copy_text_to_clipboard(const QString &text);
QString clipboard_file_path();
QString clipboard_text();
