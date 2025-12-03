import Foundation
import AVFoundation
import Accelerate

class AudioSpectrumProcessor: ObservableObject {
    static let shared = AudioSpectrumProcessor()

    private let engine = AVAudioEngine()
    private let bufferSize = 1024

    // Raw frequency data (0.0 to 1.0) for 256 bands
    @Published var frequencyData: [Float] = Array(repeating: 0.0, count: 256)
    // Overall loudness (Amplitude)
    @Published var amplitude: Float = 0.0

    private var fftSetup: vDSP_DFT_Setup?

    init() {
        setupAudio()
    }

    func start() {
        if !engine.isRunning {
            try? engine.start()
        }
    }

    func stop() {
        engine.stop()
    }

    private func setupAudio() {
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        // Prepare FFT Setup (Logarithmic scale for better visual distribution)
        let log2n = vDSP_Length(log2(Float(bufferSize)))
        fftSetup = vDSP_DFT_zop_CreateSetup(nil, vDSP_Length(bufferSize), vDSP_DFT_Direction.FORWARD)

        // Install Tap to capture audio data
        inputNode.removeTap(onBus: 0) // Clear any existing tap
        inputNode.installTap(onBus: 0, bufferSize: UInt32(bufferSize), format: format) { [weak self] (buffer, time) in
            self?.processAudio(buffer: buffer)
        }

        engine.prepare()
    }

    private func processAudio(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frames = Int(buffer.frameLength)

        // 1. Calculate Amplitude (RMS)
        var rms: Float = 0
        vDSP_measqv(channelData, 1, &rms, vDSP_Length(frames))
        rms *= 10 // Boost generic gain

        // 2. Perform FFT (Frequency Analysis)
        var realIn = [Float](repeating: 0, count: bufferSize)
        var imagIn = [Float](repeating: 0, count: bufferSize)
        var realOut = [Float](repeating: 0, count: bufferSize)
        var imagOut = [Float](repeating: 0, count: bufferSize)

        // Copy buffer data
        for i in 0..<min(frames, bufferSize) {
            realIn[i] = channelData[i]
        }

        // Execute FFT
        if let setup = fftSetup {
            vDSP_DFT_Execute(setup, &realIn, &imagIn, &realOut, &imagOut)
        }

        // 3. Calculate Magnitudes
        var magnitudes = [Float](repeating: 0.0, count: 256)

        for i in 0..<256 {
            if i < bufferSize {
                let mag = sqrt(realOut[i]*realOut[i] + imagOut[i]*imagOut[i])
                // Normalize and boost for visual impact
                magnitudes[i] = min(1.0, mag / 20.0)
            }
        }

        // Publish updates on Main Thread
        DispatchQueue.main.async {
            self.frequencyData = magnitudes
            self.amplitude = rms
        }
    }
}
