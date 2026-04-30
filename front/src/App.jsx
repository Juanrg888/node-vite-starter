import { useState, useEffect } from 'react';
import { getEjemplos } from './api/client';

export default function App() {
  const [items, setItems] = useState([]);

  useEffect(() => {
    getEjemplos().then(setItems).catch(console.error);
  }, []);

  return (
    <main style={{ padding: '2rem', fontFamily: 'sans-serif' }}>
      <h1>node-vite-starter</h1>
      <p>Reemplaza este componente con tu app.</p>
      <pre>{JSON.stringify(items, null, 2)}</pre>
    </main>
  );
}
