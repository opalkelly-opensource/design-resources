import React from "react";

import ReactDOM from "react-dom/client";

import "./index.css";

//TODO: Replace 'frontpanel.bit' with the name of the configuration file.
//import "../assets/frontpanel.bit";

import App from "./App";

const root = ReactDOM.createRoot(document.getElementById("root") as HTMLElement);

root.render(
    <React.StrictMode>
        <App />
    </React.StrictMode>
);
