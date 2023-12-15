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

"""Threaded GUI components for the application's design.

This module comprises class threads dedicated to GUI components. These threads
support the graphical representation and interaction elements of the application.
"""

from imports import *
from constants import *
import global_vars
import utils
import threads

class StatusWindow(threading.Thread):
    """This class manages a window that displays various system statuses in a GUI. The statuses are updated
    in real-time and are organized into different boxes corresponding to different types of statuses. Each
    status update is timestamped with a message counter to provide chronological context.

    Class Attributes:
        FPS_STATUS (int): Identifier for frames per second status updates.
        DEVICE_QUEUE_STATUS (int): Identifier for device queue status updates.
        POSITION_STATUS (int): Identifier for position status updates.
        TICKET_STATS (int): Identifier for ticket statistics updates.
        APPLICATION_INFO (int): Identifier for application information updates.
        STATUS_LABELS (dict): Dictionary mapping each status type to its corresponding label.

    External Instance Attributes:
        None
    
    Internal Instance Attributes:
        _update_queue (Queue): Queue holding status update messages.
        _root (tk.Tk): The main window of the GUI.
        _boxes (dict): Dictionary holding text boxes for each status type.
        _message_counters (dict): Dictionary holding counters for messages of each status type.

    External Methods:
        send_status: Add a status message to the queue for a given status type.
        run: Main loop for the GUI window.
        clear_status: Clear the content of a specific status box.
        close: Close the status window.

    Internal Methods:
        _update_boxes: Check the queue for new messages and update the GUI boxes accordingly.
        _on_close: Handle the window close event and cleanup.
    """
    FPS_STATUS = 0
    DEVICE_QUEUE_STATUS = 1
    POSITION_STATUS = 2
    TICKET_STATS = 3
    APPLICATION_INFO = 4

    STATUS_LABELS = {
        FPS_STATUS: "System Frames per Second",
        DEVICE_QUEUE_STATUS: "Queue Status",
        POSITION_STATUS: "Position Status",
        TICKET_STATS: "Ticket Statistics",
        APPLICATION_INFO: "Application Information"
    }
    
    def __init__(self):
        """Initialize the StatusWindow."""
        super().__init__()
        self._update_queue = queue.Queue()
        self._root = None
        self._boxes = {}
        self._daemon = True  # This ensures that the thread will exit when the main program exits
        
        # Initialize message counters for each status type
        self._message_counters = {key: 0 for key in self.STATUS_LABELS}

    def send_status(self, box_idx, message):
        """Add a status message to the queue for a given status type.

        Args:
            box_idx (int): The identifier of the status type.
            message (str): The status message to be added.
        """
        self._update_queue.put((box_idx, message))
        
    def run(self):
        """The main loop for the GUI window."""
        self._root = tk.Tk()
        self._root.title("Status Window")
        self._root.protocol("WM_DELETE_WINDOW", self._on_close)  # Handle the window close event

        # Initialize the row and column counters
        current_row = 0
        current_col = 0
        boxes_per_row = 2  # number of boxes you want in each row

        for status_code, label_text in self.STATUS_LABELS.items():
            frame = tk.Frame(self._root, pady=10)
            frame.grid(row=current_row, column=current_col, padx=10, pady=10)
            
            label = tk.Label(frame, text=label_text)
            label.pack(anchor=tk.W)
            
            box = scrolledtext.ScrolledText(frame, height=10, width=75, wrap=tk.WORD, state=tk.DISABLED)
            box.pack(padx=10, pady=5)
            self._boxes[status_code] = box

            # Create a button for each status box to clear it
            clear_btn = tk.Button(frame, text="Clear", command=lambda idx=status_code: self.clear_status(idx))
            clear_btn.pack(pady=5)

            # Update column and row for next iteration
            current_col += 1
            if current_col >= boxes_per_row:
                current_col = 0
                current_row += 1

        self._update_boxes()
        self._root.mainloop()


    def _update_boxes(self):
        """Check the queue for new messages and update the GUI boxes accordingly."""
        while not self._update_queue.empty():
            box_idx, message = self._update_queue.get()
            box = self._boxes[box_idx]
            box.config(state=tk.NORMAL)
            
            # Increment counter and prepend it to the message
            self._message_counters[box_idx] += 1
            message = f"[{self._message_counters[box_idx]}] {message}"
            
            # Insert new message
            box.insert(tk.END, message + "\n")
            
            # Limit to 10 status updates
            content = box.get("1.0", tk.END).strip().split("\n")
            while len(content) > 10:
                box.delete("1.0", "2.0")
                content = box.get("1.0", tk.END).strip().split("\n")
                
            box.config(state=tk.DISABLED)
            box.see(tk.END)  # Move scrollbar to the bottom
            
        self._root.after(100, self._update_boxes)  # Check for updates every 100ms

    def clear_status(self, box_idx):
        """Clear the content of the specified status box and reset its message counter.
        
        Args:
            box_idx (int): The identifier of the status type for the box to be cleared.
        """
        if box_idx in self._boxes:
            box = self._boxes[box_idx]
            box.config(state=tk.NORMAL)
            box.delete("1.0", tk.END)  # Clear the content of the box
            box.config(state=tk.DISABLED)

            # Reset the message counter for the specified status box
            self._message_counters[box_idx] = 0
            
    def _on_close(self):
        """Handle the tkinter window close event. It stops the thread."""
        # This function is called when the tkinter window is closed.
        self.close()  # Signal the thread to stop
        
    def close(self):
        """Close the status window."""
        if self._root:
            self._root.quit()

class PieChartThread(threading.Thread):
    """This class is designed to display ticket statistics in the form of a pie chart using a tkinter GUI.
    The class has an internal queue to receive and process the ticket statistics. The pie chart
    is updated at a regular interval using the tkinter main loop.

    External Instance Attributes:
        None
        
    Internal Instance Attributes:
        _canvas (Canvas): The canvas on which the pie chart is drawn.
        _queue (queue.Queue): Queue to hold ticket statistics for updating the pie chart.
        _stop_event (Event): Event to signal stopping the thread.
        _root (tk.Tk): The main tkinter window instance.
        
    External Methods:
        put_data: Put data into the internal queue for processing.
        run: Start the tkinter main loop and setup the pie chart.
        stop_thread: Signal the thread to stop.

    Internal Methods:
        _update_pie_chart: Update the pie chart with the latest ticket statistics.
        _on_close: Handle the window close event and cleanup.
    """
    def __init__(self):
        """Initialize PieChartThread."""
        super().__init__()
        self._queue = queue.Queue()  # Create an internal queue
        self._stop_event = threading.Event()  # Initialize the event

    def run(self):
        """Initialize tkinter environment, setup the canvas, and start the main loop."""
        self._root = tk.Tk()
        self._canvas = Canvas(self._root, width=300, height=400)
        self._canvas.pack()
        self._root.after(100, self._update_pie_chart)
        self._root.protocol("WM_DELETE_WINDOW", self._on_close)  # Handle the window close event
        self._root.mainloop()

    def _update_pie_chart(self):
        """Update the pie chart using the latest ticket statistics from the queue."""
        if self._stop_event.is_set():  # Check if the stop event is set
            self._root.quit()  # Stop the tkinter main loop
            
        
        update_required = True
        try:
            # Try to get data from the internal queue
            ticket_stats = self._queue.get_nowait()
        except queue.Empty:
            # If the queue is empty, use a default value or skip the update
            update_required = False
        
        if update_required:
            self._canvas.delete("all")

            total_duration_in_seconds = sum(val["duration"] for val in ticket_stats.values())

            if total_duration_in_seconds * 1000 < PIE_CHART_STEP_TIME_MS:
                idle_duration_ms = PIE_CHART_STEP_TIME_MS - total_duration_in_seconds * 1000
                ticket_stats["Idle Time"] = {"duration": idle_duration_ms / 1000}
            else:
                ticket_stats["Idle Time"] = {"duration": 0}

            updated_total_duration_in_seconds = sum(val["duration"] for val in ticket_stats.values())
            total_duration_in_ms = updated_total_duration_in_seconds * 1000
            normalization_factor = PIE_CHART_STEP_TIME_MS / total_duration_in_ms

            start = 0
            color_index = 0
            colors = ['red', 'green', 'blue', 'purple', 'orange', 'yellow']

            # Draw the key at the top of the canvas with vertical spacing
            for key, _ in ticket_stats.items():
                color = colors[color_index]
                self._canvas.create_rectangle(10, 10 + (color_index * 30), 30, 30 + (color_index * 30), fill=color)
                self._canvas.create_text(40, 20 + (color_index * 30), text=key, anchor="w")
                color_index += 1

            PIE_CHART_OFFSET = 100
            for key, value in ticket_stats.items():
                color = colors.pop(0)

                # Calculate the extent (angle in degrees) for this slice of the pie
                extent_raw = (value["duration"] * normalization_factor * 1000 / PIE_CHART_STEP_TIME_MS) * 360
                extent = round(extent_raw)  # Round to the closest degree

                # If an item is taking up the entire step
                if abs(extent - 360) < 0.001:  # Small tolerance to account for floating point inaccuracies
                    self._canvas.create_oval(50, 80 + PIE_CHART_OFFSET, 250, 280 + PIE_CHART_OFFSET, fill=color)
                    break  # No need to draw other sections as this takes up the entire pie
                else:
                    self._canvas.create_arc(50, 80 + PIE_CHART_OFFSET, 250, 280 + PIE_CHART_OFFSET, start=start,
                                           extent=extent, fill=color)
                    start += extent

        self._root.after(PIE_CHART_STEP_TIME_MS, self._update_pie_chart)

    def stop_thread(self):
        """Set the stop event to signal the thread to stop its execution."""
        self._stop_event.set()  # Set the event to signal the thread to stop

    def _on_close(self):
        """Handle the tkinter window close event. It stops the thread."""
        # This function is called when the tkinter window is closed.
        self.stop_thread()  # Signal the thread to stop

    def put_data(self, data):
        """Put data into the internal queue. The data will be used to update the pie chart.

        Args:
            data (dict): Dictionary containing ticket statistics.
        """
        # Put data into the internal queue
        self._queue.put(data)
    
class RegionOfInterestOverlay(QWidget):
    """A custom QWidget designed to visually highlight a specific region of interest for screen captures
    performed by the CaptureFramesThread. This overlay provides a visual indication through text and
    a rectangular border.

    External Instance Attributes:
        x_offset (int): X-coordinate offset for the overlay.
        y_offset (int): Y-coordinate offset for the overlay.
        matrix_width (int): Width of the overlay matrix.
        matrix_height (int): Height of the overlay matrix.
        border_thickness (int): Thickness of the rectangle border.

    Internal Instance Attributes:
        None

    External Methods:
        paintEvent: Overridden method to handle painting on the overlay widget.

    Internal Methods:
        _initUI: Initialize the user interface and settings for the overlay widget.
    """
    def __init__(self, x_offset, y_offset, matrix_width, matrix_height, border_thickness):
        """Initialize the TransparentOverlay widget with given parameters.

        Args:
            x_offset (int): X-coordinate offset for the overlay.
            y_offset (int): Y-coordinate offset for the overlay.
            matrix_width (int): Width of the overlay matrix.
            matrix_height (int): Height of the overlay matrix.
            border_thickness (int): Thickness of the rectangle border.
        """
        super().__init__()
        
        self.x_offset = x_offset - border_thickness
        self.y_offset = y_offset - border_thickness - 50  # Increased space for larger text
        self.matrix_width = matrix_width + 2 * border_thickness
        self.matrix_height = matrix_height + 2 * border_thickness + 50  # Adjusting height for text
        self.border_thickness = border_thickness

        self._initUI()

    def _initUI(self):
        """Initialize the user interface and settings for the overlay widget."""
        self.setWindowFlags(Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool)
        self.setAttribute(Qt.WA_NoSystemBackground, True)
        self.setAttribute(Qt.WA_TranslucentBackground, True)
        self.setGeometry(self.x_offset, self.y_offset, self.matrix_width, self.matrix_height)
        self.show()

    def paintEvent(self, event):
        """Overridden method to handle painting on the overlay widget. This method is called 
        internally by the Qt framework when the widget needs to be redrawn.

        Args:
            event (QEvent): Event object containing details about the paint event.
        """
        qp = QPainter(self)

        # Set font size and color for text
        font = QFont()
        font.setPointSize(20)  # You can adjust the size here
        qp.setFont(font)
        qp.setPen(QColor(255, 0, 0))  # Red color

        # Draw Text
        text = "Region of Interest"
        font_metrics = QFontMetrics(qp.font())
        text_width = font_metrics.width(text)
        qp.drawText((self.matrix_width - text_width) // 2, 40, text)  # Adjusted position for larger text

        # Draw Rectangle
        qp.setPen(QPen(QColor(255, 0, 0), self.border_thickness))  # Red color, adjustable thickness
        qp.drawRect(self.border_thickness // 2, 50 + self.border_thickness // 2, 
                    self.matrix_width - self.border_thickness, self.matrix_height - self.border_thickness - 50)
                    