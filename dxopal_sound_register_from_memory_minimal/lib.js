class JsMemorySound {
  constructor(params) {
    if (params.durationMsec == null) {
      throw new Error("durationMsec is required");
    }

    this.sampleRate    = params.sampleRate || 44100;
    this.numChannels   = params.numChannels || 2;
    this.bitsPerSample = params.bitsPerSample || 16;

    const headerSize = 44;
    const durSec = params.durationMsec / 1000.0;
    this.numSamples = Math.floor(this.sampleRate * durSec);
    const bytesPerSample = this.bitsPerSample / 8;
    const blockAlign = this.numChannels * bytesPerSample;
    this.dataSize = this.numSamples * blockAlign;

    this.buffer = new ArrayBuffer(headerSize + this.dataSize);
    this.view = new DataView(this.buffer);

    this.offset = 0;
  }

  writeString(str) {
    for (let i = 0; i < str.length; i++) {
      this.addUint8(str.charCodeAt(i));
    }
  }

  generate(samples) {
    const bytesPerSample = this.bitsPerSample / 8;
    const byteRate = this.sampleRate * this.numChannels * bytesPerSample;
    const blockAlign = this.numChannels * bytesPerSample;

    // RIFF chunk
    this.writeString("RIFF");
    this.addUint32(36 + this.dataSize);
    this.writeString("WAVE");

    // fmt subchunk
    this.writeString("fmt ");
    this.addUint32(16);
    this.addUint16(1); // 1: PCM
    this.addUint16(this.numChannels);
    this.addUint32(this.sampleRate);
    this.addUint32(byteRate);
    this.addUint16(blockAlign);
    this.addUint16(this.bitsPerSample);

    // data subchunk
    this.writeString("data");
    this.addUint32(this.dataSize);
    this.writeData(samples);
  }

  addUint8(val, width = 1) {
    this.view.setUint8(this.offset, val, true);
    this.offset += width;
  }
  addUint16(val, width = 2) {
    this.view.setUint16(this.offset, val, true);
    this.offset += width;
  }
  addInt16(val, width = 2) {
    this.view.setInt16(this.offset, val, true);
    this.offset += width;
  }
  addUint32(val, width = 4) {
    this.view.setUint32(this.offset, val, true);
    this.offset += width;
  }

  clamp(val, min, max) {
    let v = val;
    v = Math.max(v, min);
    v = Math.min(v, max);
    return v;
  }

  toInt16(val) {
    const val2 = Math.round(val * 32_767);
    return this.clamp(val2, -32_768, 32_767);
  }

  writeData(samples) {
    let fn;
    if (Array.isArray(samples)) {
      fn = (i, _) => samples[i];
    } else if (typeof samples === "function") {
      fn = samples;
    } else {
      throw new Error("samples must be Array or Function");
    }

    for (let i = 0; i < this.numSamples; i++) {
      const tSec = i / this.sampleRate;
      const val = fn(i, tSec);          // -1.0 <= .. <= 1.0
      const intVal = this.toInt16(val); // -32_768 <= .. <= 32_767
      this.addInt16(intVal);
    }
  }

  toBase64() {
    return new Uint8Array(this.buffer).toBase64();
  }

  static fromArrayBuffer(abuf, duration_msec) {
    const length = abuf.length;
    const numChannels = abuf.numberOfChannels;

    const samples = new Float32Array(length);
    for (let i = 0; i < length; i++) {
      let v = 0;
      for (let ch = 0; ch < numChannels; ch++) {
        const chData = abuf.getChannelData(ch);
        v += chData[i];
      }
      samples[i] = v / numChannels;
    }

    const jsms = new JsMemorySound({
      bitsPerSample: 16,
      numChannels: 1,
      sampleRate: abuf.sampleRate,
      durationMsec: duration_msec,
    });

    jsms.generate((i, _) => samples[i]);

    return jsms;
  }
}
