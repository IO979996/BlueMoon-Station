/**
 * BYOND may serialize dense 1-based lists as JSON objects `{ "1": a, "2": b }`
 * instead of arrays. If the client only accepts `Array.isArray`, the UI shows
 * zero components. Wiremod builds lists with `+=` and usually yields arrays.
 */
export function byondListToArray(raw) {
  if (raw == null) {
    return [];
  }
  if (Array.isArray(raw)) {
    return raw;
  }
  if (typeof raw !== 'object') {
    return [];
  }
  const keys = Object.keys(raw);
  if (!keys.length) {
    return [];
  }
  if (!keys.every((k) => /^\d+$/.test(k))) {
    return [];
  }
  return keys
    .sort((a, b) => Number(a) - Number(b))
    .map((k) => raw[k]);
}

export function normalizeCircuitComponent(comp) {
  if (!comp || typeof comp !== 'object') {
    return comp;
  }
  return {
    ...comp,
    input_ports: byondListToArray(comp.input_ports),
    output_ports: byondListToArray(comp.output_ports),
  };
}
