import React from "react";

import ReactDOM from "react-dom/client";

import "./index.css";

import App from "./App";

import "@radix-ui/themes/styles.css";

import { Theme } from "@radix-ui/themes";

const root = ReactDOM.createRoot(document.getElementById("root") as HTMLElement);

root.render(
    <Theme appearance="dark">
        <React.StrictMode>
            <App />
        </React.StrictMode>
    </Theme>
);
