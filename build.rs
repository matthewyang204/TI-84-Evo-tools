use cxx_qt_build::{CxxQtBuilder, QmlModule};

fn main() {
    #[cfg(windows)]
    {
        let mut resources = winres::WindowsResource::new();
        resources.set_icon("assets/main-icon.ico");
        resources.set("ProductVersion", env!("CARGO_PKG_VERSION"));
        resources
            .compile()
            .expect("failed to embed the Windows application icon");
    }

    let mut builder = CxxQtBuilder::new_qml_module(
        QmlModule::new("org.example.tiscreen").qml_file("qml/Main.qml"),
    )
    .qt_module("Network")
    .files(["src/backend.rs"])
    .cpp_files(["src/clipboard.cpp"]);

    #[cfg(windows)]
    {
        builder = builder.cpp_file("src/seticon.cpp");
    }

    builder.build();
}
