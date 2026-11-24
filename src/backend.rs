use cxx_qt_lib::QString;
use std::pin::Pin;

#[cxx_qt::bridge]
pub mod ffi {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        include!("ti-evo-tools/src/clipboard.h");
        type QString = cxx_qt_lib::QString;

        fn copy_file_to_clipboard(path: &QString);
        fn copy_text_to_clipboard(text: &QString);
        fn clipboard_file_path() -> QString;
        fn clipboard_text() -> QString;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qproperty(QString, status)]
        #[qproperty(QString, image_url, cxx_name = "imageUrl")]
        #[qproperty(QString, files_text, cxx_name = "filesText")]
        #[qproperty(QString, files_json, cxx_name = "filesJson")]
        #[qproperty(bool, busy)]
        type CaptureBackend = super::CaptureBackendRust;

        #[qinvokable]
        fn capture(self: Pin<&mut Self>, include_cursor: bool);

        #[qinvokable]
        #[cxx_name = "refreshFiles"]
        fn refresh_files(self: Pin<&mut Self>);

        #[qinvokable]
        #[cxx_name = "uploadFile"]
        fn upload_file(self: Pin<&mut Self>, path: &QString, archived: bool);

        #[qinvokable]
        #[cxx_name = "deleteFile"]
        fn delete_file(
            self: Pin<&mut Self>,
            display_name: &QString,
            wire_name: &QString,
            kind: i32,
        );

        #[qinvokable]
        #[cxx_name = "setMemoryTarget"]
        fn set_memory_target(
            self: Pin<&mut Self>,
            display_name: &QString,
            wire_name: &QString,
            kind: i32,
            archived: bool,
        );

        #[qinvokable]
        #[cxx_name = "getFile"]
        fn get_file(
            self: Pin<&mut Self>,
            display_name: &QString,
            wire_name: &QString,
            kind: i32,
            path: &QString,
        );

        #[qinvokable]
        #[cxx_name = "copyFile"]
        fn copy_file(
            self: Pin<&mut Self>,
            display_name: &QString,
            wire_name: &QString,
            kind: i32,
        );

        #[qinvokable]
        #[cxx_name = "sendClipboard"]
        fn send_clipboard(
            self: Pin<&mut Self>,
            display_name: &QString,
            kind: i32,
            archived: bool,
        );
    }

    impl cxx_qt::Threading for CaptureBackend {}
}

pub struct CaptureBackendRust {
    status: QString,
    image_url: QString,
    files_text: QString,
    files_json: QString,
    busy: bool,
}

impl Default for CaptureBackendRust {
    fn default() -> Self {
        Self {
            status: QString::from("Connect a TI calculator, then press Capture"),
            image_url: QString::default(),
            files_text: QString::default(),
            files_json: QString::from("[]"),
            busy: false,
        }
    }
}

impl ffi::CaptureBackend {
    pub fn capture(mut self: Pin<&mut Self>, include_cursor: bool) {
        if *self.busy() {
            return;
        }

        self.as_mut().set_busy(true);
        self.as_mut()
            .set_status(QString::from("Contacting calculator…"));

        let qt_thread = cxx_qt::Threading::qt_thread(self.as_ref().get_ref());
        std::thread::spawn(move || {
            let result = crate::usb::capture_screen(include_cursor);
            qt_thread
                .queue(move |mut backend| {
                    match result {
                        Ok(path) => {
                            let url = QUrlPath::from_path(&path);
                            backend.as_mut().set_image_url(QString::from(&url.0));
                            backend
                                .as_mut()
                                .set_status(QString::from("Screen captured"));
                        }
                        Err(error) => {
                            backend
                                .as_mut()
                                .set_status(QString::from(&format!("Capture failed: {error}")));
                        }
                    }
                    backend.as_mut().set_busy(false);
                })
                .ok();
        });
    }

    pub fn refresh_files(mut self: Pin<&mut Self>) {
        if *self.busy() {
            return;
        }

        self.as_mut().set_busy(true);
        self.as_mut()
            .set_status(QString::from("Reading calculator files…"));

        let qt_thread = cxx_qt::Threading::qt_thread(self.as_ref().get_ref());
        std::thread::spawn(move || {
            let result =
                crate::usb::directory().and_then(|payload| crate::directory::listing(&payload));
            qt_thread
                .queue(move |mut backend| {
                    match result {
                        Ok(listing) => {
                            backend
                                .as_mut()
                                .set_files_text(QString::from(&listing.text));
                            backend
                                .as_mut()
                                .set_files_json(QString::from(&listing.files_json));
                            backend
                                .as_mut()
                                .set_status(QString::from("Device files loaded"));
                        }
                        Err(error) => {
                            backend
                                .as_mut()
                                .set_status(QString::from(&format!("File check failed: {error}")));
                        }
                    }
                    backend.as_mut().set_busy(false);
                })
                .ok();
        });
    }

    pub fn upload_file(mut self: Pin<&mut Self>, path: &QString, archived: bool) {
        if *self.busy() {
            return;
        }

        let path = std::path::PathBuf::from(path.to_string());
        self.as_mut().set_busy(true);
        self.as_mut()
            .set_status(QString::from("Sending file to calculator…"));

        let qt_thread = cxx_qt::Threading::qt_thread(self.as_ref().get_ref());
        std::thread::spawn(move || {
            let result = crate::usb::send_host_file_to(&path, archived);
            qt_thread
                .queue(move |mut backend| {
                    match result {
                        Ok(description) => backend.as_mut().set_status(QString::from(&format!(
                            "File sent successfully: {description}"
                        ))),
                        Err(error) => backend
                            .as_mut()
                            .set_status(QString::from(&format!("File send failed: {error}"))),
                    }
                    backend.as_mut().set_busy(false);
                })
                .ok();
        });
    }

    pub fn delete_file(
        mut self: Pin<&mut Self>,
        display_name: &QString,
        wire_name: &QString,
        kind: i32,
    ) {
        if *self.busy() {
            return;
        }

        let display_name = display_name.to_string();
        let wire_name = wire_name.to_string();
        let kind = match u8::try_from(kind) {
            Ok(kind) => kind,
            Err(_) => {
                self.as_mut()
                    .set_status(QString::from("Delete failed: invalid EVO variable type"));
                return;
            }
        };
        self.as_mut().set_busy(true);
        self.as_mut()
            .set_status(QString::from(&format!("Deleting {display_name}…")));

        let qt_thread = cxx_qt::Threading::qt_thread(self.as_ref().get_ref());
        std::thread::spawn(move || {
            let result = crate::usb::delete_variable(&wire_name, kind).and_then(|()| {
                crate::usb::directory().and_then(|payload| crate::directory::listing(&payload))
            });
            qt_thread
                .queue(move |mut backend| {
                    match result {
                        Ok(listing) => {
                            backend
                                .as_mut()
                                .set_files_text(QString::from(&listing.text));
                            backend
                                .as_mut()
                                .set_files_json(QString::from(&listing.files_json));
                            backend.as_mut().set_status(QString::from(&format!(
                                "Deleted {display_name} from the calculator"
                            )));
                        }
                        Err(error) => backend
                            .as_mut()
                            .set_status(QString::from(&format!("Delete failed: {error}"))),
                    }
                    backend.as_mut().set_busy(false);
                })
                .ok();
        });
    }

    pub fn set_memory_target(
        mut self: Pin<&mut Self>,
        display_name: &QString,
        wire_name: &QString,
        kind: i32,
        archived: bool,
    ) {
        if *self.busy() {
            return;
        }

        let display_name = display_name.to_string();
        let wire_name = wire_name.to_string();
        let kind = match u8::try_from(kind) {
            Ok(kind) => kind,
            Err(_) => {
                self.as_mut().set_status(QString::from(
                    "Move failed: invalid EVO variable type",
                ));
                return;
            }
        };
        let target = if archived { "archive" } else { "RAM" };
        self.as_mut().set_busy(true);
        self.as_mut().set_status(QString::from(&format!(
            "Moving {display_name} to {target}…"
        )));

        let qt_thread = cxx_qt::Threading::qt_thread(self.as_ref().get_ref());
        std::thread::spawn(move || {
            let result = crate::usb::move_variable(&wire_name, kind, archived).and_then(|()| {
                crate::usb::directory().and_then(|payload| crate::directory::listing(&payload))
            });
            qt_thread
                .queue(move |mut backend| {
                    match result {
                        Ok(listing) => {
                            backend.as_mut().set_files_text(QString::from(&listing.text));
                            backend.as_mut().set_files_json(QString::from(&listing.files_json));
                            backend.as_mut().set_status(QString::from(&format!(
                                "Moved {display_name} to {target}"
                            )));
                        }
                        Err(error) => backend.as_mut().set_status(QString::from(&format!(
                            "Move failed: {error}"
                        ))),
                    }
                    backend.as_mut().set_busy(false);
                })
                .ok();
        });
    }

    pub fn get_file(
        mut self: Pin<&mut Self>,
        display_name: &QString,
        wire_name: &QString,
        kind: i32,
        path: &QString,
    ) {
        if *self.busy() {
            return;
        }

        let display_name = display_name.to_string();
        let wire_name = wire_name.to_string();
        let path = std::path::PathBuf::from(path.to_string());
        if path.as_os_str().is_empty() {
            self.as_mut()
                .set_status(QString::from("Get failed: the save dialog returned no local path"));
            return;
        }
        let kind = match u8::try_from(kind) {
            Ok(kind) => kind,
            Err(_) => {
                self.as_mut().set_status(QString::from("Get failed: invalid EVO variable type"));
                return;
            }
        };
        self.as_mut().set_busy(true);
        self.as_mut().set_status(QString::from(&format!("Getting {display_name}…")));

        let qt_thread = cxx_qt::Threading::qt_thread(self.as_ref().get_ref());
        std::thread::spawn(move || {
            let result = download_variable(&wire_name, kind).and_then(|contents| {
                let contents = if kind == 15 {
                    if let Some(source) = extract_python_source(&contents)? {
                        let mut output = path.clone();
                        output.set_extension("py");
                        std::fs::write(&output, source.as_bytes())
                            .map_err(|error| format!("could not save Python source: {error}"))?;
                        return Ok(output);
                    }
                    let mut output = path.clone();
                    output.set_extension("8xpy2");
                    std::fs::write(&output, &contents)
                        .map_err(|error| format!("could not save Python module: {error}"))?;
                    return Ok(output);
                } else {
                    contents
                };
                std::fs::write(&path, contents)
                    .map_err(|error| format!("could not save file: {error}"))
                    .map(|()| path.clone())
            });
            qt_thread
                .queue(move |mut backend| {
                    match result {
                        Ok(saved_path) => backend.as_mut().set_status(QString::from(&format!(
                            "Saved {display_name} to {}",
                            saved_path.display()
                        ))),
                        Err(error) => backend.as_mut().set_status(QString::from(&format!(
                            "Get failed: {error}"
                        ))),
                    }
                    backend.as_mut().set_busy(false);
                })
                .ok();
        });
    }

    pub fn copy_file(
        mut self: Pin<&mut Self>,
        display_name: &QString,
        wire_name: &QString,
        kind: i32,
    ) {
        if *self.busy() {
            return;
        }

        let display_name = display_name.to_string();
        let wire_name = wire_name.to_string();
        let kind = match u8::try_from(kind) {
            Ok(kind) => kind,
            Err(_) => {
                self.as_mut().set_status(QString::from("Copy failed: invalid EVO variable type"));
                return;
            }
        };
        self.as_mut().set_busy(true);
        self.as_mut().set_status(QString::from(&format!("Preparing {display_name} for clipboard…")));

        let qt_thread = cxx_qt::Threading::qt_thread(self.as_ref().get_ref());
        std::thread::spawn(move || {
            let result = download_variable(&wire_name, kind).and_then(|contents| {
                if kind == 15 {
                    if let Some(source) = extract_python_source(&contents)? {
                        return Ok(ClipboardPayload::Text(source));
                    }
                }
                let directory = std::env::temp_dir().join("ti-evo-tools-clipboard");
                std::fs::create_dir_all(&directory)
                    .map_err(|error| format!("could not prepare clipboard file: {error}"))?;
                let path = directory.join(format!(
                    "{}.{}",
                    safe_file_stem(&display_name),
                    extension_for_type(kind)
                ));
                std::fs::write(&path, contents)
                    .map_err(|error| format!("could not prepare clipboard file: {error}"))?;
                Ok(ClipboardPayload::File(path))
            });
            qt_thread
                .queue(move |mut backend| {
                    match result {
                        Ok(ClipboardPayload::File(path)) => {
                            let path_string = QString::from(&path.to_string_lossy().to_string());
                            ffi::copy_file_to_clipboard(&path_string);
                            backend.as_mut().set_status(QString::from(&format!(
                                "Copied {display_name} to clipboard"
                            )));
                        }
                        Ok(ClipboardPayload::Text(source)) => {
                            let text = QString::from(&source);
                            ffi::copy_text_to_clipboard(&text);
                            backend.as_mut().set_status(QString::from(&format!(
                                "Copied Python source for {display_name} to clipboard"
                            )));
                        }
                        Err(error) => backend.as_mut().set_status(QString::from(&format!(
                            "Copy failed: {error}"
                        ))),
                    }
                    backend.as_mut().set_busy(false);
                })
                .ok();
        });
    }

    pub fn send_clipboard(
        mut self: Pin<&mut Self>,
        display_name: &QString,
        kind: i32,
        archived: bool,
    ) {
        if *self.busy() {
            return;
        }

        let display_name = display_name.to_string();
        let kind = match u8::try_from(kind) {
            Ok(kind) => kind,
            Err(_) => {
                self.as_mut()
                    .set_status(QString::from("Clipboard send failed: invalid EVO type"));
                return;
            }
        };
        let clipboard_path = ffi::clipboard_file_path().to_string();
        let clipboard_text = ffi::clipboard_text().to_string();
        if clipboard_path.is_empty() && clipboard_text.is_empty() {
            self.as_mut()
                .set_status(QString::from("Clipboard send failed: clipboard is empty"));
            return;
        }
        self.as_mut().set_busy(true);
        self.as_mut().set_status(QString::from(&format!(
            "Preparing clipboard data as {display_name} (type {kind})…"
        )));

        let qt_thread = cxx_qt::Threading::qt_thread(self.as_ref().get_ref());
        std::thread::spawn(move || {
            let variable = if !clipboard_path.is_empty() {
                let path = std::path::PathBuf::from(&clipboard_path);
                crate::ti_file::read(&path).and_then(|variable| {
                    if variable.kind != kind {
                        return Err(format!(
                            "clipboard file has EVO type {}, but type {kind} was selected",
                            variable.kind
                        ));
                    }
                    Ok(variable)
                })
            } else {
                crate::ti_file::from_clipboard(
                    &display_name,
                    kind,
                    clipboard_text.as_bytes(),
                )
            };
            let result = variable
                .map(|mut variable| {
                    variable.archived = archived;
                    variable
                })
                .and_then(crate::usb::send_variable_file);

            qt_thread
                .queue(move |mut backend| {
                    match result {
                        Ok(description) => backend.as_mut().set_status(QString::from(&format!(
                            "Clipboard variable sent successfully: {description}"
                        ))),
                        Err(error) => backend.as_mut().set_status(QString::from(&format!(
                            "Clipboard send failed: {error}"
                        ))),
                    }
                    backend.as_mut().set_busy(false);
                })
                .ok();
        });
    }
}

enum ClipboardPayload {
    File(std::path::PathBuf),
    Text(String),
}

fn extract_python_source(contents: &[u8]) -> Result<Option<String>, String> {
    let body = contents
        .get(..contents.len().saturating_sub(2))
        .ok_or("Python variable is too short")?;
    let payload = cbor_find_bytes(body, "data")
        .ok_or("could not read Python variable data")?;

    // evo_usb_py stores source programs as TI AppVars inside the CBOR `data`
    // field: header, name, source length, 00 02, UTF-8 source, NUL.
    if payload.len() < 18 || payload.get(..4) != Some(&[0x13, 0x01, 0, 0]) {
        return Ok(None);
    }
    let name_len = usize::from(payload[8]);
    let source_len_offset = 12usize
        .checked_add(name_len)
        .and_then(|offset| offset.checked_add(1))
        .ok_or("invalid Python AppVar header")?;
    let source_offset = source_len_offset + 4;
    let source_len_bytes = payload
        .get(source_len_offset..source_len_offset + 2)
        .ok_or("invalid Python AppVar source length")?;
    if payload.get(source_len_offset + 2..source_offset) != Some(&[0, 2]) {
        return Err("unrecognized Python AppVar format".into());
    }
    let source_len = usize::from(u16::from_le_bytes([source_len_bytes[0], source_len_bytes[1]]));
    let source = payload
        .get(source_offset..source_offset + source_len)
        .ok_or("Python source is truncated")?;
    String::from_utf8(source.to_vec())
        .map(Some)
        .map_err(|_| "Python source is not valid UTF-8".into())
}

fn cbor_find_bytes(input: &[u8], key: &str) -> Option<Vec<u8>> {
    let mut cursor = 0;
    let map = cbor_read_head(input, &mut cursor)?;
    if map >> 56 != 5 {
        return None;
    }
    let count = map & 0x00ff_ffff_ffff_ffff;
    if count == 0x00ff_ffff_ffff_ffff {
        while input.get(cursor) != Some(&0xff) {
            let key_bytes = cbor_read_text(input, &mut cursor)?;
            if key_bytes == key {
                return cbor_read_bytes(input, &mut cursor);
            }
            cbor_skip(input, &mut cursor)?;
        }
        return None;
    }
    for _ in 0..count {
        let key_bytes = cbor_read_text(input, &mut cursor)?;
        if key_bytes == key {
            return cbor_read_bytes(input, &mut cursor);
        }
        cbor_skip(input, &mut cursor)?;
    }
    None
}

fn cbor_read_head(input: &[u8], cursor: &mut usize) -> Option<u64> {
    let first = *input.get(*cursor)?;
    *cursor += 1;
    let additional = first & 31;
    if additional == 31 {
        return Some((u64::from(first >> 5) << 56) | 0x00ff_ffff_ffff_ffff);
    }
    let value = match additional {
        0..=23 => u64::from(additional),
        24 => u64::from(*input.get(*cursor)?),
        25 => u64::from(u16::from_be_bytes(input.get(*cursor..*cursor + 2)?.try_into().ok()?)),
        26 => u64::from(u32::from_be_bytes(input.get(*cursor..*cursor + 4)?.try_into().ok()?)),
        27 => u64::from_be_bytes(input.get(*cursor..*cursor + 8)?.try_into().ok()?),
        _ => return None,
    };
    if additional >= 24 && additional <= 27 {
        *cursor += 1usize << (additional - 24);
    }
    Some((u64::from(first >> 5) << 56) | value)
}

fn cbor_read_text(input: &[u8], cursor: &mut usize) -> Option<String> {
    let head = cbor_read_head(input, cursor)?;
    if head >> 56 != 3 || head & 0x00ff_ffff_ffff_ffff == 0x00ff_ffff_ffff_ffff {
        return None;
    }
    let len = (head & 0x00ff_ffff_ffff_ffff) as usize;
    let value = input.get(*cursor..*cursor + len)?;
    *cursor += len;
    String::from_utf8(value.to_vec()).ok()
}

fn cbor_read_bytes(input: &[u8], cursor: &mut usize) -> Option<Vec<u8>> {
    let head = cbor_read_head(input, cursor)?;
    if head >> 56 != 2 || head & 0x00ff_ffff_ffff_ffff == 0x00ff_ffff_ffff_ffff {
        return None;
    }
    let len = (head & 0x00ff_ffff_ffff_ffff) as usize;
    let value = input.get(*cursor..*cursor + len)?.to_vec();
    *cursor += len;
    Some(value)
}

fn cbor_skip(input: &[u8], cursor: &mut usize) -> Option<()> {
    let head = cbor_read_head(input, cursor)?;
    let major = head >> 56;
    let len = (head & 0x00ff_ffff_ffff_ffff) as usize;
    if major == 2 || major == 3 {
        *cursor += len;
    } else if major == 4 {
        if len == 0x00ff_ffff_ffff_ffffusize {
            while input.get(*cursor) != Some(&0xff) { cbor_skip(input, cursor)?; }
            *cursor += 1;
        } else {
            for _ in 0..len { cbor_skip(input, cursor)?; }
        }
    } else if major == 5 {
        if len == 0x00ff_ffff_ffff_ffffusize {
            while input.get(*cursor) != Some(&0xff) {
                cbor_skip(input, cursor)?;
                cbor_skip(input, cursor)?;
            }
            *cursor += 1;
        } else {
            for _ in 0..len { cbor_skip(input, cursor)?; cbor_skip(input, cursor)?; }
        }
    }
    input.get(..*cursor)?;
    Some(())
}

fn download_variable(wire_name: &str, kind: u8) -> Result<Vec<u8>, String> {
    if wire_name.is_empty()
        || !wire_name.bytes().all(|byte| {
            byte.is_ascii_alphanumeric() || matches!(byte, b'%' | b'-' | b'_' | b'.' | b'~')
        })
    {
        return Err("invalid EVO variable name".into());
    }

    let uri = format!("hh01/xfr/var?name={wire_name}&type={kind}");
    let mut contents = crate::usb::request_uri(&uri, true, true)?;
    let checksum = evo_checksum(&contents);
    contents.extend_from_slice(&checksum.to_be_bytes());
    Ok(contents)
}

fn evo_checksum(body: &[u8]) -> u16 {
    if body.len() < 3 {
        return 0;
    }
    let adjusted = body.len() - 3;
    let mut word_count = adjusted >> 1;
    if adjusted & 1 != 0 && word_count > 0 {
        word_count -= 1;
    }
    (0..word_count).fold(0u16, |checksum, index| {
        checksum ^ u16::from_le_bytes([body[index * 2], body[index * 2 + 1]])
    })
}

fn extension_for_type(kind: u8) -> &'static str {
    match kind {
        0 => "8xn2",
        1 => "8xl2",
        2 => "8xp2",
        3 => "8xd2",
        4 => "8ci2",
        5 => "8ca2",
        6 => "8xm2",
        7 => "8xy2",
        8 => "8xv2",
        10 => "8xs2",
        12 => "8xw2",
        13 => "8xz2",
        14 => "8xt2",
        15 => "8xpy2",
        18 => "8mp2",
        _ => "bin",
    }
}

fn safe_file_stem(name: &str) -> String {
    let safe = name
        .chars()
        .map(|character| {
            if character.is_alphanumeric() || matches!(character, '.' | '_' | '-') {
                character
            } else {
                '_'
            }
        })
        .collect::<String>();
    if safe.is_empty() { "variable".into() } else { safe }
}

struct QUrlPath(String);

impl QUrlPath {
    fn from_path(path: &std::path::Path) -> Self {
        let path = path
            .to_string_lossy()
            .replace('%', "%25")
            .replace(' ', "%20");
        Self(format!("file://{path}?v={}", timestamp()))
    }
}

fn timestamp() -> u128 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map_or(0, |duration| duration.as_millis())
}
