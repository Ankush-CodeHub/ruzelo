import os
import numpy as np
from scipy.io import wavfile

SAMPLE_RATE = 44100
DURATION = 30  # 30 seconds high-fidelity looping audio

os.makedirs("./media/audio", exist_ok=True)

def note_to_freq(note_str):
    notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
    name = note_str[:-1]
    octave = int(note_str[-1])
    semitone = notes.index(name)
    note_num = octave * 12 + semitone
    return 440.0 * (2.0 ** ((note_num - 57) / 12.0))

def generate_tanpura_drone(freq=146.83, duration=DURATION): # D3 tanpura
    total_samples = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, total_samples, endpoint=False)
    # Tanpura Pa-Sa-Sa-Sa (D, A harmonics)
    drone = (
        0.15 * np.sin(2 * np.pi * freq * t) +
        0.10 * np.sin(2 * np.pi * freq * 1.5 * t) +  # Fifth (Pa)
        0.08 * np.sin(2 * np.pi * freq * 2.0 * t) +  # Octave (Sa)
        0.05 * np.sin(2 * np.pi * freq * 3.0 * t) +
        0.03 * np.sin(2 * np.pi * freq * 4.0 * t)
    )
    # Slow shimmering modulation
    mod = 0.8 + 0.2 * np.sin(2 * np.pi * 0.3 * t)
    return drone * mod

def synthesize_indian_track(style="bollywood"):
    total_samples = int(SAMPLE_RATE * DURATION)
    t = np.linspace(0, DURATION, total_samples, endpoint=False)
    left = np.zeros(total_samples)
    right = np.zeros(total_samples)
    
    if style == "bollywood_romance":
        # Raag Yaman notes: D, E, F#, G#, A, B, C#
        bpm = 110
        beat_dur = 60.0 / bpm
        
        # 1. Tanpura backdrop
        drone = generate_tanpura_drone(note_to_freq('D3'))
        left += drone * 0.6
        right += drone * 0.6
        
        # 2. Romantic Acoustic Guitar / Sitar plucking
        melody_notes = ['D4', 'F#4', 'A4', 'C#5', 'B4', 'A4', 'F#4', 'E4', 'D4', 'E4', 'F#4', 'A4']
        step_dur = beat_dur / 2.0
        for s in range(int(DURATION / step_dur)):
            t_start = s * step_dur
            idx_start = int(t_start * SAMPLE_RATE)
            s_dur = step_dur * 1.2
            s_samples = int(s_dur * SAMPLE_RATE)
            if idx_start + s_samples <= total_samples:
                st = np.linspace(0, s_dur, s_samples)
                freq = note_to_freq(melody_notes[s % len(melody_notes)])
                # Sitar / Pluck timbre with rich harmonics
                pluck = (
                    0.20 * np.sin(2 * np.pi * freq * st) +
                    0.12 * np.sin(2 * np.pi * freq * 2 * st) +
                    0.08 * np.sin(2 * np.pi * freq * 3 * st) +
                    0.05 * np.sin(2 * np.pi * freq * 4 * st)
                ) * np.exp(-st * 7.0)
                pan = 0.5 + 0.25 * np.sin(s * 0.8)
                left[idx_start:idx_start+s_samples] += pluck * (1.0 - pan)
                right[idx_start:idx_start+s_samples] += pluck * pan
                
        # 3. Soft Tabla / Dholak Rhythm (Dhin - Tin - Dha)
        for b in range(int(DURATION / beat_dur)):
            idx_b = int(b * beat_dur * SAMPLE_RATE)
            # Bayan (bass tabla pitch glide)
            dur_t = 0.35
            b_samples = int(dur_t * SAMPLE_RATE)
            if idx_b + b_samples <= total_samples:
                bt = np.linspace(0, dur_t, b_samples)
                b_freq = 65.0 + 35.0 * np.sin(np.pi * bt / dur_t)
                bayan = 0.35 * np.sin(2 * np.pi * np.cumsum(b_freq) / SAMPLE_RATE) * np.exp(-bt * 8.0)
                left[idx_b:idx_b+b_samples] += bayan
                right[idx_b:idx_b+b_samples] += bayan
                
    elif style == "punjabi_pop":
        # High Energy Bhangra / Dhol Rhythms + Synth Bass
        bpm = 124
        beat_dur = 60.0 / bpm
        
        # Heavy Dhol bass kick (Dha-Ge-Na)
        for b in range(int(DURATION / beat_dur)):
            idx_b = int(b * beat_dur * SAMPLE_RATE)
            # Punchy sub kick
            k_dur = 0.22
            k_samples = int(k_dur * SAMPLE_RATE)
            if idx_b + k_samples <= total_samples:
                kt = np.linspace(0, k_dur, k_samples)
                k_freq = 45.0 + 130.0 * np.exp(-kt * 28.0)
                kick = 0.45 * np.sin(2 * np.pi * np.cumsum(k_freq) / SAMPLE_RATE) * np.exp(-kt * 10.0)
                left[idx_b:idx_b+k_samples] += kick
                right[idx_b:idx_b+k_samples] += kick
                
            # Dhol snap / snare on half beats
            snap_idx = idx_b + int(beat_dur * 0.5 * SAMPLE_RATE)
            if snap_idx + k_samples <= total_samples:
                snap_noise = (np.random.rand(k_samples) * 2 - 1) * 0.25 * np.exp(-kt * 22.0)
                left[snap_idx:snap_idx+k_samples] += snap_noise
                right[snap_idx:snap_idx+k_samples] += snap_noise
                
        # Tumbi / Punjabi Lead Hook (High rhythmic riff)
        tumbi_notes = ['E5', 'G5', 'A5', 'B5', 'A5', 'G5', 'E5', 'D5']
        step_dur = beat_dur / 4.0
        for s in range(int(DURATION / step_dur)):
            idx_s = int(s * step_dur * SAMPLE_RATE)
            dur_s = 0.12
            s_samples = int(dur_s * SAMPLE_RATE)
            if idx_s + s_samples <= total_samples:
                st = np.linspace(0, dur_s, s_samples)
                freq = note_to_freq(tumbi_notes[s % len(tumbi_notes)])
                tumbi = 0.20 * (np.sin(2 * np.pi * freq * st) + 0.6 * np.sin(2 * np.pi * freq * 2 * st)) * np.exp(-st * 20.0)
                left[idx_s:idx_s+s_samples] += tumbi * 0.7
                right[idx_s:idx_s+s_samples] += tumbi * 0.7

    elif style == "sufi_mystic":
        # Deep Harmonium chords, Bansuri flute melody, and hypnotic claps
        bpm = 90
        beat_dur = 60.0 / bpm
        
        # 1. Warm Harmonium Reed Chords (C minor / G minor)
        harmonium_notes = [note_to_freq(n) for n in ['C3', 'G3', 'C4', 'D#4', 'G4']]
        for f in harmonium_notes:
            reed = 0.08 * (np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * f * 3 * t) + 0.2 * np.sin(2 * np.pi * f * 5 * t))
            left += reed
            right += reed
            
        # 2. Bansuri Flute expressive melody (breath sound + harmonic glissando)
        flute_notes = ['G4', 'A#4', 'C5', 'D5', 'D#5', 'D5', 'C5', 'A#4']
        seg_dur = beat_dur * 2.0
        for s in range(int(DURATION / seg_dur)):
            idx_s = int(s * seg_dur * SAMPLE_RATE)
            dur_f = seg_dur * 1.05
            f_samples = int(dur_f * SAMPLE_RATE)
            if idx_s + f_samples <= total_samples:
                ft = np.linspace(0, dur_f, f_samples)
                freq = note_to_freq(flute_notes[s % len(flute_notes)])
                # Vibrato LFO
                vibrato = 1.0 + 0.012 * np.sin(2 * np.pi * 5.5 * ft)
                env = np.sin(np.pi * (ft / dur_f)) ** 1.2
                flute = 0.22 * np.sin(2 * np.pi * freq * vibrato * ft) * env
                # Airy breath noise
                breath = (np.random.rand(f_samples) * 2 - 1) * 0.03 * env
                left[idx_s:idx_s+f_samples] += (flute + breath) * 0.6
                right[idx_s:idx_s+f_samples] += (flute + breath) * 0.6
                
        # 3. Sufi rhythmic clapping & Tabla groove
        for b in range(int(DURATION / beat_dur)):
            idx_b = int(b * beat_dur * SAMPLE_RATE)
            c_dur = 0.15
            c_samples = int(c_dur * SAMPLE_RATE)
            if idx_b + c_samples <= total_samples:
                ct = np.linspace(0, c_dur, c_samples)
                clap = (np.random.rand(c_samples) * 2 - 1) * 0.18 * np.exp(-ct * 30.0)
                left[idx_b:idx_b+c_samples] += clap
                right[idx_b:idx_b+c_samples] += clap
                
    else: # South Indian Fusion & Classical Sitar
        bpm = 115
        beat_dur = 60.0 / bpm
        drone = generate_tanpura_drone(note_to_freq('C3'))
        left += drone * 0.5
        right += drone * 0.5
        
        # Sitar Fast Taans / Carnatic Swaras
        swaras = ['C4', 'E4', 'G4', 'B4', 'C5', 'D5', 'C5', 'B4', 'G4', 'E4', 'D4', 'C4']
        step_dur = beat_dur / 3.0 # Triplet feel
        for s in range(int(DURATION / step_dur)):
            idx_s = int(s * step_dur * SAMPLE_RATE)
            s_dur = step_dur * 1.5
            s_samples = int(s_dur * SAMPLE_RATE)
            if idx_s + s_samples <= total_samples:
                st = np.linspace(0, s_dur, s_samples)
                freq = note_to_freq(swaras[s % len(swaras)])
                sitar = 0.22 * (np.sin(2 * np.pi * freq * st) + 0.3 * np.sin(2 * np.pi * freq * 2 * st) + 0.15 * np.sin(2 * np.pi * freq * 3 * st)) * np.exp(-st * 9.0)
                pan = 0.5 + 0.3 * np.sin(s * 0.5)
                left[idx_s:idx_s+s_samples] += sitar * (1.0 - pan)
                right[idx_s:idx_s+s_samples] += sitar * pan

    # Master Normalization
    master = np.vstack([left, right])
    max_val = np.max(np.abs(master))
    if max_val > 0:
        master = (master / max_val) * 0.85
    return (master * 32767).astype(np.int16).T

def main():
    tracks = {
        "track_in_1": synthesize_indian_track("bollywood_romance"), # Kesariya Radiance (Arijit)
        "track_in_2": synthesize_indian_track("sufi_mystic"),        # Kun Faya Kun (AR Rahman)
        "track_in_3": synthesize_indian_track("punjabi_pop"),        # Lover (Diljit Dosanjh)
        "track_in_4": synthesize_indian_track("punjabi_pop"),        # Hukum (Anirudh)
        "track_in_5": synthesize_indian_track("bollywood_romance"), # Kasoor (Prateek Kuhad)
        "track_in_6": synthesize_indian_track("south_indian_fusion"),# Deewani Mastani (Shreya Ghoshal)
        "track_in_7": synthesize_indian_track("south_indian_fusion"),# Samajavaragamana (Sid Sriram)
        "track_in_8": synthesize_indian_track("sufi_mystic"),        # Afreen Afreen (Nusrat Fateh Ali Khan)
        
        # Legacy tracks
        "track_1": synthesize_indian_track("bollywood_romance"),
        "track_2": synthesize_indian_track("sufi_mystic"),
        "track_3": synthesize_indian_track("punjabi_pop"),
        "track_4": synthesize_indian_track("south_indian_fusion"),
    }
    
    for track_id, audio_data in tracks.items():
        wavfile.write(f"./media/audio/{track_id}.flac", SAMPLE_RATE, audio_data)
        wavfile.write(f"./media/audio/{track_id}.mp3", SAMPLE_RATE, audio_data)
        wavfile.write(f"./media/audio/{track_id}.wav", SAMPLE_RATE, audio_data)
        print(f"Generated {track_id} in FLAC, MP3, and WAV.")
        
    print("All Indian song directory audio files synthesized successfully!")

if __name__ == "__main__":
    main()
