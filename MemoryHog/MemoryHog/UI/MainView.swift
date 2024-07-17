//
// Created by Joey Jarosz on 5/24/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct MainView: View {
    @Environment(\.scenePhase) var scenePhase
    
    @AppStorage("numberOfChunks") var numberOfChunksUD = ChunkGenerator.defaultNumberOfChunks
    @AppStorage("sizeOfChunksInBytes") var sizeOfChunksInBytesUD = ChunkGenerator.defaultSizeOfChunksInBytes
    @AppStorage("ignoreOSMemoryWarnings") var ignoreOSMemoryWarningsUD = false

    @State private var numberOfChunks: Int = ChunkGenerator.defaultNumberOfChunks
    @State private var sizeOfChunksInBytes: Double = ChunkGenerator.defaultSizeOfChunksInBytes

    @State private var dummyRefresher = false
    @State private var ignoreOSMemoryWarnings = false
    @State private var isGeneratingFiles = false
    @State private var isDeletingFiles = false
    @State private var isBusy = false
    @State private var isShowingError = false
    @State private var errorMessage: String?

    private let memoryWarningPublisher = NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
    private let generator = ChunkGenerator.shared
    
    private let formatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 3
        formatter.numberFormatter.minimumFractionDigits = 3
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Memory Chunks") {
                    Stepper("Chunk Size: \(convert(sizeOfChunksInBytes, from: .bytes, to: .megabytes).formatted())",
                            onIncrement: { incrementFileSizeValue() },
                            onDecrement: { decrementFileSizeValue() })

                    Stepper("Number of Chunks: \(numberOfChunks)",
                            value: $numberOfChunks,
                            in: 1...100,
                            step: ChunkGenerator.defaultNumberOfChunks)
                    
                    Toggle("Ignore OS Memory Warnings", isOn: $ignoreOSMemoryWarnings)

                    HStack {
                        deleteOneFileButton()
                        Spacer()
                        deleteAllFilesButton()
                        Spacer()
                        consumeMemoryButton()
                    }
                }
                
                Section {
                    HStack {
                        Text("Size:")
                        Spacer()
                        Text("\(formatter.string(from: convert(generator.memoryHogged(), from: .bytes, to: .gigabytes)))")
                            .monospaced()
                    }
                } header : {
                    Text("Eaten")
                        .padding(.top, -12)
                }

                Section {
                    HStack {
                        Text("Total:")
                        Spacer()
                        Text("\(formatter.string(from: convert(Double(ChunkGenerator.totalSystemMemoryInBytes), from: .bytes, to: .gigabytes)))")
                            .monospaced()
                    }
                    HStack {
                        Text("Used:")
                        Spacer()
                        Text("\(formatter.string(from: convert(Double(ChunkGenerator.usedMemoryInBytes), from: .bytes, to: .gigabytes)))")
                            .monospaced()
                    }
                    HStack {
                        Text("Available:")
                        Spacer()
                        Text("\(formatter.string(from: convert(Double(ChunkGenerator.availableCapacityInBytes), from: .bytes, to: .gigabytes)))")
                            .monospaced()
                    }
                } header : {
                    Text("Device Memory")
                        .padding(.top, -12)
                }
            }
            .navigationTitle("Memory Hog")
            .navigationBarTitleDisplayMode(.inline)
            .disabled(isBusy)
            .overlay {
                if isBusy {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.accentColor)
                }
            }
            .id(dummyRefresher)
            
            // Useful pull-to-refresh if you expect memory to be consumed by another app running in the background
            .refreshable {
                dummyRefresher.toggle()
            }
            
            // Useful when going back-and-forth between apps..
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    dummyRefresher.toggle()
                }
            }
            
            // When we use the initializer variant of the `Stepper` view that we are using we run into issues
            // when we try to read/write from `AppStorage` directly so we set/get them as seperate points in time...
            .onAppear {
                sizeOfChunksInBytes = sizeOfChunksInBytesUD
                numberOfChunks = numberOfChunksUD
                ignoreOSMemoryWarnings = ignoreOSMemoryWarningsUD
            }
            .onChange(of: sizeOfChunksInBytes) { value in
                sizeOfChunksInBytesUD = value
            }
            .onChange(of: numberOfChunks) { value in
                numberOfChunksUD = value
            }
            .onChange(of: ignoreOSMemoryWarnings) { value in
                ignoreOSMemoryWarningsUD = value
            }

            // Catch OS level memory warnings and do some cleanup. You can comment out this
            .onReceive(memoryWarningPublisher) { _ in
                guard !ignoreOSMemoryWarnings else {
                    return
                }
                
                generator.removeChunks()
                
                errorMessage = "Received a low memory warning from the OS. Purging existing EATEN memory to avoid crashing."
                isShowingError.toggle()
            }
        }
    }
    
    private func deleteOneFileButton() -> some View {
        Button("Delete\nLast", role: .destructive) {
            isBusy.toggle()
            
            Task {
                generator.removeChunks(1)
                isBusy.toggle()
            }
        }
        .buttonStyle(.borderedProminent)
    }

    private func deleteAllFilesButton() -> some View {
        Button("Delete All Chunks", role: .destructive) {
            isDeletingFiles.toggle()
        }
        .buttonStyle(.borderedProminent)
        .alert("Delete All Chunks", isPresented: $isDeletingFiles) {
            Button("DELETE", role: .destructive) {
                isBusy.toggle()
                
                Task {
                    generator.removeChunks()
                    isBusy.toggle()
                }
            }
        } message: {
            Text("Do you really want to delete all the chunks of memory consumed by this tool?")
        }
    }

    private func consumeMemoryButton() -> some View {
        Button("Consume Chunks", role: .none) {
            isGeneratingFiles.toggle()
            isBusy.toggle()
            
            Task {
                do {
                    try await generator.generate(numberOfChunks: numberOfChunks, sizeOfChunksInBytes: Int(sizeOfChunksInBytes))
                    isGeneratingFiles.toggle()
                    isBusy.toggle()
                } catch(let error) {
                    errorMessage = error.localizedDescription
                    isBusy.toggle()
                    isGeneratingFiles.toggle()
                    isShowingError.toggle()
                }
            }
            
        }
        .buttonStyle(.borderedProminent)
        .alert(isPresented: $isShowingError) {
            Alert(
                title: Text("Memory Consumption"),
                message: Text("\(errorMessage ?? "")")
            )
        }
    }

    // MARK - Stepper Support
    
    /// Increments the size of the files to be generated. The effective `step` value changes such that when the value is less than 100 it steps by 10, otherwise it steps by 100.
    /// This makes the range 10-100 by 10, 200-1000 by 100
    ///
    private func incrementFileSizeValue() {
        if sizeOfChunksInBytes >= (ChunkGenerator.defaultSizeOfChunksInBytes * 10) {
            return
        }
        if sizeOfChunksInBytes >= ChunkGenerator.defaultSizeOfChunksInBytes {
            sizeOfChunksInBytes += ChunkGenerator.defaultSizeOfChunksInBytes
        } else {
            sizeOfChunksInBytes += ChunkGenerator.defaultSizeOfChunksInBytes / 10
        }
    }
    
    /// Decrements the size of the files to be generated. The effective `step` value changes such that when the value is less than 100 it steps by 10, otherwise it steps by 100.
    /// This makes the range 10-100 by 10, 200-1000 by 100
    ///
    private func decrementFileSizeValue() {
        if sizeOfChunksInBytes <=  (ChunkGenerator.defaultSizeOfChunksInBytes / 10) {
            return
        }
        if sizeOfChunksInBytes <= ChunkGenerator.defaultSizeOfChunksInBytes {
            sizeOfChunksInBytes -= ChunkGenerator.defaultSizeOfChunksInBytes / 10
        } else {
            sizeOfChunksInBytes -= ChunkGenerator.defaultSizeOfChunksInBytes
        }
    }
    
    // MARK - Utilities
    
    private func convert(_ value: Double, from inUnit: UnitInformationStorage, to outUnit: UnitInformationStorage) -> Measurement<UnitInformationStorage> {
        return Measurement<UnitInformationStorage>(value: value, unit: inUnit).converted(to: outUnit)
    }
}

#Preview {
    MainView()
}
