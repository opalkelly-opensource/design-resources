/**
 * Copyright (c) 2024-2025 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React from "react";

import ReactDOM from "react-dom/client";

import "./index.css";

//TODO: Use the correct bitfile for your ADC
//import "../assets/DAC-ADC-ExampleDesign-ADC-12-v2.0.bit";
import "../assets/DAC-ADC-ExampleDesign-ADC-14-v2.0.bit";

import App from "./App";

const root = ReactDOM.createRoot(document.getElementById("root") as HTMLElement);

root.render(
    <React.StrictMode>
        <App />
    </React.StrictMode>
);
