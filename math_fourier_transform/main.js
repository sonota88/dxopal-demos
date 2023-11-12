function puts(...args) {
  console.log(...args);
}

// theta: 0 ~ PI
function genFourier(theta, params) {
  const pi2 = Math.PI * 2;
  let v = 0;
  params.forEach(param => {
    const theta2 = ((1.0 / (param.cycle / pi2)) * theta);
    const theta3 = theta2
    v += param.cos * Math.cos(theta3);
    v += param.sin * Math.sin(theta3);
  });
  return v;
}

function playWave(freq) {
  const params = Opal.gvars.params;
  const ac = new AudioContext();
  const numChannels = 1;
  const sampleRate = ac.sampleRate;
  const numSamplesTotal = Math.floor(sampleRate * /* sec */ 1.0);
  const samplesPerCycle = sampleRate / freq;
  const abuf = ac.createBuffer(numChannels, numSamplesTotal, sampleRate);
  const samples = abuf.getChannelData(0);
  const pi = Math.PI;

  for (let i = 0; i < numSamplesTotal; i++) {
    const theta = (i / samplesPerCycle) * 2 * pi;
    const amp2 = (numSamplesTotal - i) / numSamplesTotal;
    samples[i] = genFourier(theta, params) * 0.1 * amp2;
  }

  const src = ac.createBufferSource();
  src.buffer = abuf;
  src.connect(ac.destination);

  if (ac.state === "suspended") {
    ac.resume();
  }
  src.start(0);
}
