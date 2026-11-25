import SwiftUI
import SwiftData

/// Displays a grid of progress photos for a patient and allows capturing new ones.
/// Photos are stored in the app's Documents directory and linked via ConsultationRecord.
struct ProgressPhotoView: View {
    private enum ProgressPhotoCover: Identifiable {
        case camera
        case viewer(PhotoEntry)

        var id: String {
            switch self {
            case .camera:
                return "camera"
            case .viewer(let entry):
                return "viewer-\(entry.id)"
            }
        }
    }

    let patientId: UUID
    let patientName: String

    @Environment(\.modelContext) private var modelContext
    @State private var photos: [PhotoEntry] = []
    @State private var activeCover: ProgressPhotoCover?
    @State private var showLibrarySheet = false
    @State private var showSourcePicker = false
    @State private var hasLoaded = false
    @State private var showDeleteConfirmation = false
    @State private var isMutatingPhoto = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.sectionSpacing) {
                if photos.isEmpty {
                    emptyState
                } else {
                    photoGrid
                }
            }
            .padding()
        }
        .background(AppTheme.surfaceWhite.ignoresSafeArea())
        .navigationTitle("Fotos de progreso")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                GuardedButton {
                    openSourcePicker()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(AppTheme.deepOrange)
                }
                .disabled(isAnyModalPresented)
            }
        }
        .confirmationDialog("Agregar foto", isPresented: $showSourcePicker) {
            Button("Tomar foto") {
                guard activeCover == nil, !showLibrarySheet else { return }
                activeCover = .camera
            }
            Button("Elegir de la galería") {
                guard activeCover == nil, !showLibrarySheet else { return }
                showLibrarySheet = true
            }
            Button("Cancelar", role: .cancel) {}
        }
        .sheet(isPresented: $showLibrarySheet) {
            PhotoLibraryPickerView { image in
                savePhoto(image)
            }
        }
        .fullScreenCover(item: $activeCover) { cover in
            switch cover {
            case .camera:
                CameraCaptureView { image in
                    savePhoto(image)
                }
                .ignoresSafeArea()
            case .viewer(let entry):
                fullScreenPhotoView(entry)
            }
        }
        .onAppear {
            guard !hasLoaded else { return }
            loadPhotos()
            hasLoaded = true
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.deepOrange.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.deepOrange.opacity(0.5))
            }

            Text("Sin fotos de progreso")
                .font(AppTheme.subheadFont)

            Text("Documenta visualmente la evolución del paciente con fotos periódicas. Podrás compararlas en una galería organizada por fecha.")
                .font(AppTheme.captionFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            GuardedButton {
                openSourcePicker()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                    Text("Agregar primera foto")
                        .fontWeight(.semibold)
                }
                .font(.system(.subheadline, design: .rounded))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.deepOrange)
            .disabled(isAnyModalPresented)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var isAnyModalPresented: Bool {
        activeCover != nil || showLibrarySheet || showSourcePicker
    }

    private func openSourcePicker() {
        guard !isAnyModalPresented else { return }
        showSourcePicker = true
    }

    // MARK: - Photo Grid

    private var photoGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(photos.count) foto\(photos.count == 1 ? "" : "s")")
                .font(AppTheme.subheadFont)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
            ], spacing: 10) {
                ForEach(photos) { entry in
                    GuardedButton {
                        guard !isAnyModalPresented else { return }
                        HapticManager.impact(.light)
                        activeCover = .viewer(entry)
                    } label: {
                        photoThumbnail(entry)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            HapticManager.impact(.medium)
                            deletePhoto(entry)
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private func photoThumbnail(_ entry: PhotoEntry) -> some View {
        VStack(spacing: 4) {
            if let image = UIImage(contentsOfFile: entry.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 130)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.tertiary)
                    }
            }
            Text(entry.date, format: .dateTime.day().month(.abbreviated))
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Full Screen Photo

    private func fullScreenPhotoView(_ entry: PhotoEntry) -> some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let image = UIImage(contentsOfFile: entry.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    GuardedButton {
                        activeCover = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(entry.date, format: .dateTime.day().month(.wide).year())
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    GuardedButton {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Eliminar foto", isPresented: $showDeleteConfirmation) {
                Button("Cancelar", role: .cancel) {}
                Button("Eliminar", role: .destructive) {
                    deletePhoto(entry)
                }
            } message: {
                Text("¿Seguro que quieres eliminar esta foto? Esta acción no se puede deshacer.")
            }
        }
    }

    // MARK: - Photo Management

    private func savePhoto(_ image: UIImage) {
        guard !isMutatingPhoto else { return }
        isMutatingPhoto = true
        defer { isMutatingPhoto = false }

        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let photosDir = documentsDir.appendingPathComponent("ProgressPhotos", isDirectory: true)

        // Ensure directory exists
        try? FileManager.default.createDirectory(at: photosDir, withIntermediateDirectories: true)

        let fileName = "\(patientId.uuidString)_\(Int(Date.now.timeIntervalSince1970)).jpg"
        let fileURL = photosDir.appendingPathComponent(fileName)

        guard let data = image.jpegData(compressionQuality: 0.8) else { return }

        do {
            try data.write(to: fileURL)
            HapticManager.notification(.success)
            loadPhotos()
        } catch {
            HapticManager.notification(.error)
        }
    }

    private func deletePhoto(_ entry: PhotoEntry) {
        guard !isMutatingPhoto else { return }
        isMutatingPhoto = true
        defer { isMutatingPhoto = false }

        do {
            try FileManager.default.removeItem(atPath: entry.path)
            HapticManager.notification(.success)
            activeCover = nil
            loadPhotos()
        } catch {
            HapticManager.notification(.error)
        }
    }

    private func loadPhotos() {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let photosDir = documentsDir.appendingPathComponent("ProgressPhotos", isDirectory: true)

        guard let files = try? FileManager.default.contentsOfDirectory(atPath: photosDir.path) else {
            photos = []
            return
        }

        let prefix = patientId.uuidString
        photos = files
            .filter { $0.hasPrefix(prefix) && $0.hasSuffix(".jpg") }
            .compactMap { fileName -> PhotoEntry? in
                let path = photosDir.appendingPathComponent(fileName).path
                // Extract timestamp from filename: UUID_TIMESTAMP.jpg
                let parts = fileName.replacingOccurrences(of: ".jpg", with: "").split(separator: "_")
                guard parts.count >= 6,
                      let timestamp = TimeInterval(parts.last ?? "") else {
                    // Fallback: use file modification date
                    let attrs = try? FileManager.default.attributesOfItem(atPath: path)
                    let date = (attrs?[.modificationDate] as? Date) ?? .now
                    return PhotoEntry(id: fileName, path: path, date: date)
                }
                return PhotoEntry(id: fileName, path: path, date: Date(timeIntervalSince1970: timestamp))
            }
            .sorted { $0.date > $1.date }
    }
}

// MARK: - Supporting Types

struct PhotoEntry: Identifiable {
    let id: String
    let path: String
    let date: Date
}
