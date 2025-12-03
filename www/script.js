// Harmonic Bloom Audio Visualizer
class HarmonicBloom {
    constructor() {
        this.canvas = document.getElementById('visualizer');
        this.ctx = this.canvas.getContext('2d');
        this.status = document.getElementById('status');

        this.particles = [];
        this.audioContext = null;
        this.analyser = null;
        this.dataArray = null;
        this.bufferLength = 0;

        this.centerX = 0;
        this.centerY = 0;

        this.init();
    }

    init() {
        this.resizeCanvas();
        window.addEventListener('resize', () => this.resizeCanvas());
        this.setupAudio();
    }

    resizeCanvas() {
        this.canvas.width = window.innerWidth;
        this.canvas.height = window.innerHeight;
        this.centerX = this.canvas.width / 2;
        this.centerY = this.canvas.height / 2;
    }

    async setupAudio() {
        try {
            this.status.textContent = 'Requesting microphone access...';

            const stream = await navigator.mediaDevices.getUserMedia({
                audio: {
                    echoCancellation: false,
                    noiseSuppression: false,
                    autoGainControl: false
                }
            });

            this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
            this.analyser = this.audioContext.createAnalyser();
            this.analyser.fftSize = 256;
            this.analyser.smoothingTimeConstant = 0.8;

            const source = this.audioContext.createMediaStreamSource(stream);
            source.connect(this.analyser);

            this.bufferLength = this.analyser.frequencyBinCount;
            this.dataArray = new Uint8Array(this.bufferLength);

            // Hide status message
            setTimeout(() => {
                this.status.classList.add('hidden');
            }, 1000);

            // Start visualization
            this.animate();

        } catch (error) {
            console.error('Error accessing microphone:', error);
            this.status.textContent = 'Microphone access denied';
            this.status.style.color = 'rgba(255, 100, 100, 0.9)';
        }
    }

    createParticle(audioLevel, frequencyIndex) {
        const angle = (frequencyIndex / this.bufferLength) * Math.PI * 2;
        const speed = 1 + audioLevel * 3;

        // Color based on frequency range
        let hue;
        if (frequencyIndex < this.bufferLength / 3) {
            hue = 180; // Cyan for low frequencies
        } else if (frequencyIndex < (this.bufferLength * 2) / 3) {
            hue = 200; // Blue for mid frequencies
        } else {
            hue = 220; // Deep blue for high frequencies
        }

        const saturation = 70 + audioLevel * 30;
        const lightness = 50 + audioLevel * 20;

        return {
            x: this.centerX,
            y: this.centerY,
            vx: Math.cos(angle) * speed,
            vy: Math.sin(angle) * speed,
            size: 2 + audioLevel * 4,
            life: 1.0,
            decay: 0.01 + Math.random() * 0.01,
            color: `hsl(${hue}, ${saturation}%, ${lightness}%)`
        };
    }

    animate() {
        requestAnimationFrame(() => this.animate());

        // Get audio data
        this.analyser.getByteFrequencyData(this.dataArray);

        // Clear with fade effect for trails
        this.ctx.fillStyle = 'rgba(0, 0, 0, 0.05)';
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);

        // Calculate average audio level
        let sum = 0;
        for (let i = 0; i < this.bufferLength; i++) {
            sum += this.dataArray[i];
        }
        const avgLevel = sum / this.bufferLength / 255;

        // Create new particles based on audio input
        if (avgLevel > 0.1) {
            // Sample fewer frequencies but create particles more strategically
            for (let i = 0; i < this.bufferLength; i += 4) {
                const audioLevel = this.dataArray[i] / 255;
                if (audioLevel > 0.2) {
                    this.particles.push(this.createParticle(audioLevel, i));
                }
            }
        }

        // Draw center glow based on audio
        if (avgLevel > 0.05) {
            const glowRadius = 20 + avgLevel * 60;
            const gradient = this.ctx.createRadialGradient(
                this.centerX, this.centerY, 0,
                this.centerX, this.centerY, glowRadius
            );
            gradient.addColorStop(0, `rgba(51, 204, 230, ${avgLevel * 0.6})`);
            gradient.addColorStop(1, 'rgba(51, 204, 230, 0)');

            this.ctx.fillStyle = gradient;
            this.ctx.fillRect(
                this.centerX - glowRadius,
                this.centerY - glowRadius,
                glowRadius * 2,
                glowRadius * 2
            );
        }

        // Update and draw particles
        for (let i = this.particles.length - 1; i >= 0; i--) {
            const p = this.particles[i];

            // Update position
            p.x += p.vx;
            p.y += p.vy;

            // Update life
            p.life -= p.decay;

            // Remove dead particles
            if (p.life <= 0) {
                this.particles.splice(i, 1);
                continue;
            }

            // Draw particle with glow
            this.ctx.globalAlpha = p.life;
            this.ctx.fillStyle = p.color;

            // Draw glow
            const glowGradient = this.ctx.createRadialGradient(
                p.x, p.y, 0,
                p.x, p.y, p.size * 2
            );
            glowGradient.addColorStop(0, p.color);
            glowGradient.addColorStop(1, 'rgba(0, 0, 0, 0)');

            this.ctx.fillStyle = glowGradient;
            this.ctx.beginPath();
            this.ctx.arc(p.x, p.y, p.size * 2, 0, Math.PI * 2);
            this.ctx.fill();

            // Draw core
            this.ctx.fillStyle = p.color;
            this.ctx.beginPath();
            this.ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
            this.ctx.fill();
        }

        this.ctx.globalAlpha = 1;

        // Limit particle count for performance
        if (this.particles.length > 500) {
            this.particles = this.particles.slice(-500);
        }
    }
}

// Initialize when page loads
window.addEventListener('load', () => {
    new HarmonicBloom();
});
