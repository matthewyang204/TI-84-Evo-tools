use cxx_qt_build::{CxxQtBuilder, QmlModule};

fn main() {
    #[cfg(windows)]
    {
        let mut resources = winres::WindowsResource::new();
        resources.set_icon("assets/main-icon.ico");
        resources
            .compile()
            .expect("failed to embed the Windows application icon");
    }

    CxxQtBuilder::new_qml_module(QmlModule::new("org.example.tiscreen").qml_file("qml/Main.qml"))
        .qt_module("Network")
        .files(["src/backend.rs"])
        .cpp_files(["src/clipboard.cpp", "src/seticon.cpp"])
        .build();
}
