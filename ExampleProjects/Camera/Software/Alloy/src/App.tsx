import React from "react";

import "./App.css";

import CameraView from "./CameraView";

function App() {
    return (
        <div className="RootPanel">
            <CameraView name="Camera" />
        </div>
    );
}

export default App;
