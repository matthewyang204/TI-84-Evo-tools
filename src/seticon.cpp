#include "seticon.h"

#include <QGuiApplication>
#include <QIcon>
#include <QImage>
#include <QPixmap>

#ifdef _WIN32
#include <windows.h>

#include <vector>
#endif

void set_application_icon_from_exe_resource() {
#ifdef _WIN32
  const auto icon = static_cast<HICON>(LoadImageW(
      GetModuleHandleW(nullptr), MAKEINTRESOURCEW(1), IMAGE_ICON, 0, 0,
      LR_DEFAULTSIZE));
  if (!icon) {
    return;
  }

  ICONINFO icon_info{};
  if (!GetIconInfo(icon, &icon_info)) {
    DestroyIcon(icon);
    return;
  }

  BITMAP bitmap{};
  const auto bitmap_result = icon_info.hbmColor
      ? GetObjectW(icon_info.hbmColor, sizeof(bitmap), &bitmap)
      : 0;
  if (bitmap_result == 0 || bitmap.bmWidth <= 0 || bitmap.bmHeight <= 0) {
    if (icon_info.hbmColor) DeleteObject(icon_info.hbmColor);
    if (icon_info.hbmMask) DeleteObject(icon_info.hbmMask);
    DestroyIcon(icon);
    return;
  }

  BITMAPINFO bitmap_info{};
  bitmap_info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bitmap_info.bmiHeader.biWidth = bitmap.bmWidth;
  bitmap_info.bmiHeader.biHeight = -bitmap.bmHeight;
  bitmap_info.bmiHeader.biPlanes = 1;
  bitmap_info.bmiHeader.biBitCount = 32;
  bitmap_info.bmiHeader.biCompression = BI_RGB;
  std::vector<uchar> pixels(static_cast<size_t>(bitmap.bmWidth) *
                            static_cast<size_t>(bitmap.bmHeight) * 4);
  const auto device_context = GetDC(nullptr);
  const auto rows = GetDIBits(device_context, icon_info.hbmColor, 0,
                              static_cast<UINT>(bitmap.bmHeight), pixels.data(),
                              &bitmap_info, DIB_RGB_COLORS);
  ReleaseDC(nullptr, device_context);
  DeleteObject(icon_info.hbmColor);
  if (icon_info.hbmMask) DeleteObject(icon_info.hbmMask);
  DestroyIcon(icon);
  if (rows == 0) {
    return;
  }

  auto image = QImage(pixels.data(), bitmap.bmWidth, bitmap.bmHeight,
                      bitmap.bmWidth * 4, QImage::Format_ARGB32).copy();
  bool has_alpha = false;
  for (int y = 0; y < image.height() && !has_alpha; ++y) {
    for (int x = 0; x < image.width(); ++x) {
      if (qAlpha(image.pixel(x, y)) != 0) {
        has_alpha = true;
        break;
      }
    }
  }
  if (!has_alpha) {
    image = image.convertToFormat(QImage::Format_RGB32);
  }
  QGuiApplication::setWindowIcon(QIcon(QPixmap::fromImage(image)));
#endif
}
