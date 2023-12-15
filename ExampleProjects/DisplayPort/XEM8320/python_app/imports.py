# ----------------------------------------------------------------------------------------
# Copyright (c) 2023 Opal Kelly Incorporated
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# ----------------------------------------------------------------------------------------

"""Centralized library imports with installation checks.

This module imports essential libraries required by the system. If a library is
missing, it provides instructions for its installation using pip.
"""

# Standard library imports
import time
import math
import sys
import threading
import queue
import itertools
import copy
import os

# Use the tested versions from requirements.txt for the following imports
# Related third-party imports
import numpy as np
import cv2
import tkinter as tk
from tkinter import Canvas, scrolledtext
import pyautogui
from PyQt5.QtWidgets import QApplication, QWidget
from PyQt5.QtGui import QPainter, QColor, QPen, QFont, QFontMetrics
from PyQt5.QtCore import Qt

# Add the 'libraries' directory to the sys.path
sys.path.append(os.path.join(os.path.dirname(__file__), '../../../HDLComponents/FrontPanelToAxiLiteBridge/python_api'))

# Check for non-pip modules and notify the user if they're missing, while providing the tested version
non_pip_modules_info = {
    'dxshot': {
        'link': 'https://github.com/AI-M-BOT/DXcam/releases',
        'tested_version': '1.2'
    },
    'ok': {
        'link': 'https://docs.opalkelly.com/fpsdk/getting-started/',
        'tested_version': '5.2.12'
    },
    'FrontPanelToAxiLiteBridge': {
        'link': 'https://github.com/opalkelly-opensource/design-resources/tree/main/HDLComponents/FrontPanelToAxiLiteBridge',
        'tested_version': 'Commit: 23e2a32511735cf32c3b74614ed093b6dd2ea579'
    }
}

for module, module_info in non_pip_modules_info.items():
    try:
        __import__(module)
    except ImportError:
        print(f"Error: Module {module} (tested version: {module_info['tested_version']}) not found.")
        print(f"Please download and install it from: {module_info['link']}")
        exit()

# Local application/library specific imports
import dxshot
import ok
from FrontPanelToAxiLiteBridge import FrontPanelToAxiLiteBridge
