const BASE = import.meta.env.VITE_API_URL || 'http://localhost:3000';

async function request(path, options = {}) {
  const res = await fetch(`${BASE}${path}`, {
    headers: { 'Content-Type': 'application/json', ...options.headers },
    ...options,
  });
  if (!res.ok) throw new Error(`API error ${res.status}: ${await res.text()}`);
  return res.status === 204 ? null : res.json();
}

// ── Ejemplo (reemplazar con funciones reales) ─────────────────────────────────
export const getEjemplos     = ()       => request('/ejemplo');
export const crearEjemplo    = (data)   => request('/ejemplo', { method: 'POST',   body: JSON.stringify(data) });
export const eliminarEjemplo = (id)     => request(`/ejemplo/${id}`, { method: 'DELETE' });
