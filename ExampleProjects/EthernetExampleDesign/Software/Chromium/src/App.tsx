import React from "react";

import "./App.css";

import { Application } from "@opalkellytech/frontpanel-react-components";

import FrontPanel from "./FrontPanel";

function App() {
    return (
        <div className="App">
            <header className="App-header">
                <Application>
                    <FrontPanel name="Ethernet Example" />
                </Application>
            </header>
        </div>
    );
}

export default App;
