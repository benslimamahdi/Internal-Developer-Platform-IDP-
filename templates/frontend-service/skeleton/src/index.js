import React from 'react';
import ReactDOM from 'react-dom/client';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
    <React.StrictMode>
        <div style={{ fontFamily: 'sans-serif', textAlign: 'center', marginTop: '50px' }}>
            <h1>Hello from {'${{ values.name }}'}!</h1>
            <p>This app was scaffolded by the IDP.</p>
            <p>Owner: {'${{ values.owner }}'}</p>
        </div>
    </React.StrictMode>
);
