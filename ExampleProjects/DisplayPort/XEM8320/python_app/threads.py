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

"""Thread classes for managing various device and display operations.

This module defines thread classes like DeviceThread, DisplayThread, and 
CaptureFramesThread. These threads handle different tasks simultaneously to 
ensure smooth operation.
"""

from imports import *
from constants import *
import global_vars
import utils
import widgets

import threading

class SystemVariables:
    """This is a class designed for managing system-related parameters such as batch size, frames per second (fps),
    matrix size, and screen dimensions.

    Internal Instance Attributes:
        _batch_size (int): Number of items processed together in a batch.
        _fps (int): Frames per second.
        _matrix_size (int): Size of the matrix.
        _screen_width (int): Width of the screen in pixels.
        _screen_height (int): Height of the screen in pixels.

    External Methods:
        get_batch_size: Retrieve the current batch size.
        set_batch_size: Set a new value for the batch size.
        get_fps: Retrieve the current frames per second.
        set_fps: Set a new value for frames per second.
        get_matrix_size: Retrieve the current matrix size.
        set_matrix_size: Set a new value for the matrix size.
        get_screen_width: Retrieve the current screen width.
        set_screen_width: Set a new width for the screen.
        get_screen_height: Retrieve the current screen height.
        set_screen_height: Set a new height for the screen.
    """
    def __init__(self, batch_size=5, fps=60, matrix_size=512, screen_width=1920, screen_height=1080):
        """Initialize the SystemVariables with the provided values.

        Args:
            batch_size (int): Number of items processed together in a batch.
            fps (int): Frames per second.
            matrix_size (int): Size of the matrix.
            screen_width (int): Width of the screen in pixels.
            screen_height (int): Height of the screen in pixels.
        
        Return:
            None
        """
        # Variables
        self._batch_size = batch_size
        self._fps = fps
        self._matrix_size = matrix_size
        self._screen_width = screen_width
        self._screen_height = screen_height
        
    def get_batch_size(self):
        return self._batch_size

    def set_batch_size(self, value):
        self._batch_size = value
    
    def get_fps(self):
        return self._fps

    def set_fps(self, value):
        self._fps = value
    
    def get_matrix_size(self):
        return self._matrix_size

    def set_matrix_size(self, value):
        self._matrix_size = value

    def get_screen_width(self):
        return self._screen_width

    def set_screen_width(self, value):
        self._screen_width = value
    
    def get_screen_height(self):
        return self._screen_height

    def set_screen_height(self, value):
        self._screen_height = value

            
class DeviceThread(threading.Thread):
    """This is a class designed for managing and interacting with an Opal Kelly device in a multithreaded
    application. The class has the ability to queue up and carry out tasks (referred to as "work tickets")
    on the device. It also maintains a priority queue for these tickets and keeps track of various
    statistics related to them.

    Class Attributes:
        MAX_OUTSTANDING_FRAME_TICKETS (int): Maximum number of allowed outstanding frame tickets.
    
    Sub-Classes:
        Ticket: Represents a task or operation to be processed.
        UpdateStatsThread: A thread responsible for updating statistics like pie chart and fps status.

    External Instance Attributes:
        capture_thread (CaptureFramesThread): Thread responsible for frame capture.
        
    Internal Instance Attributes:
        _pie_chart_thread (PieChartThread): Thread responsible for updating pie charts.
        _ticket_queue (PriorityQueue): Priority queue to hold work tickets for the device.
        _counter (itertools.count): Infinite _counter for ticket order management.
        _sent_fps_counter (int): Counter to keep track of frames per second.
        _last_status_time (float): Last recorded status update time.
        _func_lookup (dict): Dictionary to map ticket type strings to their respective function handlers.
        _ticket_stats (dict): Dictionary to hold statistics for various ticket types.
        _last_pie_chart_update (float): Last recorded pie chart update time.
        _sent_fps_counter_lock (Lock): Thread lock for sent FPS _counter.
        _ticket_stats_lock (Lock): Thread lock for ticket statistics.
        _update_thread (UpdateStatsThread): Thread responsible for updating statistics.
        _stop_event (Event): Event to signal stopping the thread.

    External Methods:
        run: Execute the device thread and process data from the queue.
        schedule: Schedule a function for execution.
        cancel_send_frame_batch_tickets: Remove 'send_frame_batch' type tickets from the queue.
        stop: Stop the DeviceThread.

    Internal Methods:
        _initialize_device: Initialize and configure the device.
        _get_num_send_frame_tickets: Retrieve the count of 'send_frame_batch' tickets in the queue.
        _display_device_info: Display device information.
        _update_pie_chart: Update the pie chart with ticket statistics.
        _update_ticket_stats: Update statistics for a given ticket function.
        _update_fps_status: Update the frames per second status.
        _send_frame_batch: Send a frame batch to the device.
        _update_batch_size: Update the batch size in the device.
        _axil_read: Read data from a specific address via AXIL.
        _axil_write: Write data to a specific address via AXIL.
        _retrieve_and_set_fps: Retrieve and set the frames per second for the device.
    """

    MAX_OUTSTANDING_FRAME_TICKETS = 5  # for example, adjust as needed
                
    class Ticket:
        """Represents a task ticket with a function, its arguments, priority, and status attributes.
        
        Attributes:
            func (callable): The function to be executed for the ticket.
            args (tuple): The arguments to be passed to the function.
            priority (int): The priority of the ticket.
            result (Any): The result returned by the function, initially set to None.
            error_code (int): Error status of the function execution. 0 means no error.
            _event (threading.Event): An event for synchronizing the ticket processing.
        """
        
        def __init__(self, func, args, priority):
            """Initializes a new Ticket instance.
            
            Args:
                func (callable): The function to be executed for the ticket.
                args (tuple): The arguments to be passed to the function.
                priority (int): The priority of the ticket.
            """
            self.func = func
            self.args = args
            self.priority = priority
            self.result = None
            self.error_code = 0  # 0 means no error, change accordingly
            self._event = threading.Event()

        def wait(self):
            """Waits for the ticket to be processed."""
            self._event.wait()

        def set_done(self):
            """Marks the ticket as processed."""
            self._event.set()

          
    class UpdateStatsThread(threading.Thread):
        """Represents a thread responsible for updating statistics like pie chart and fps status.
        
        Attributes:
            parent (Any): The parent object that holds the methods to update pie chart and fps.
            _stop_event (threading.Event): An event to stop the thread.
        """
        
        def __init__(self, parent):
            """Initializes a new UpdateStatsThread instance.
            
            Args:
                parent (Any): The parent object that holds the methods to update pie chart and fps.
            """
            super().__init__()
            self.parent = parent
            self._stop_event = threading.Event()
            
        def stop(self):
            """Stops the UpdateStatsThread."""
            self._stop_event.set()

        def run(self):
            """Continuously updates the pie chart and fps status while the thread is running."""
            while not self._stop_event.is_set():
                self.parent._update_pie_chart()
                self.parent._update_fps_status()
                time.sleep(STATS_UPDATE_INTERVAL)  # You can adjust this sleep duration as needed
      
    def __init__(self):
        """Initialize the DeviceThread instance.
        Sets up events, initializes the device, starts various threads, and sets up thread-safe variables.
            
        Returns:
            None
        
        Raises:
            RuntimeError: If there is an issue opening the device.
        """
        super(DeviceThread, self).__init__()
        
        # Initialize the device
        if not self._initialize_device():
            raise RuntimeError("Issue opening device.")
        
        # PriorityQueue to hold data to be sent to the device.
        self._ticket_queue = queue.PriorityQueue()
        self._counter = itertools.count()  # Infinite _counter

        self._sent_fps_counter = 0
        self._last_status_time = time.perf_counter()
            
        # Labels for the allowed ticket types, and the associated internal functions they call
        self._func_lookup = {
            "send_frame_batch": self._send_frame_batch,
            "read": self._axil_read,
            "write": self._axil_write,
            "retrieve_and_set_fps": self._retrieve_and_set_fps,
            "update_batch_size": self._update_batch_size
        }
        
        self._ticket_stats = {
            "send_frame_batch": {"count": 0, "duration": 0},
            "read": {"count": 0, "duration": 0},
            "write": {"count": 0, "duration": 0},
            "retrieve_and_set_fps": {"count": 0, "duration": 0},
            "update_batch_size": {"count": 0, "duration": 0}
        }

        self._last_pie_chart_update = time.perf_counter()
        
        # Initializing thread safety locks
        self._sent_fps_counter_lock = threading.Lock()
        self._ticket_stats_lock = threading.Lock()
        
        self._pie_chart_thread = widgets.PieChartThread()
        self._update_stats_thread = self.UpdateStatsThread(self)
        self.capture_thread = CaptureFramesThread(self)
        
        # Control flag for the device thread.
        self._stop_event = threading.Event()
    
    def run(self):
        """Device thread main function. Continuously fetches and processes tickets from the queue until stopped."""
        
        # Start the update thread
        self._update_stats_thread.start()
        
        # Start frame capture thread
        self.capture_thread.start()
        
        # Start pie chart thread
        self._pie_chart_thread.start()
        
        while not self._stop_event.is_set():
            try:
                _, _, ticket = self._ticket_queue.get(timeout=1)  # Block for up to 1 second waiting for an item.
                start_time = time.perf_counter()
                ticket.result, ticket.error_code = ticket.func(**ticket.args)
                duration = time.perf_counter() - start_time
                ticket.set_done()
                self._update_ticket_stats(ticket.func, duration)  # Update ticket statistics
            except queue.Empty:
                # Queue was empty, continue waiting for more items or the stop event.
                continue
            
    def schedule(self, func_name, args, priority):
        """Schedule a function to be executed with the given arguments and priority.

        Args:
            func_name (str): Name of the function to be scheduled.
            args (dict): Arguments to pass to the function.
            priority (int): Priority level of the function.

        Returns:
            Ticket: The scheduled function ticket to be able to wait
                    on its completion if required.
        
        Raises:
            ValueError: If the given function name is not found.
        """
        func = self._func_lookup.get(func_name)
        if not func:
            raise ValueError(f"Function '{func_name}' not found")
        
        # Check if this is a send_frame_batch type ticket and we've reached the max allowed.
        if func == self._send_frame_batch and self._get_num_send_frame_tickets() >= self.MAX_OUTSTANDING_FRAME_TICKETS:
            # If so, remove the oldest send_frame_batch type ticket.
            with self._ticket_queue.mutex:  # Lock the queue to safely modify its contents.
                oldest_ticket_index = next((i for i, (_, _, ticket) in enumerate(self._ticket_queue.queue) if ticket.func == self._send_frame_batch), None)
                if oldest_ticket_index is not None:
                    self._ticket_queue.queue.pop(oldest_ticket_index)
                    message = (f"Dropped send_frame_batch type ticket; max ({self.MAX_OUTSTANDING_FRAME_TICKETS}) reached. "
                               f"Blocks other ticket types. Consider increasing frame batching to improve bandwidth.")
                    global_vars.status_window.send_status(widgets.StatusWindow.DEVICE_QUEUE_STATUS, message)


        # Proceed to add the new ticket as before.
        count = next(self._counter)
        ticket = self.Ticket(func, args, priority)
        self._ticket_queue.put((priority, count, ticket))
        return ticket

    def cancel_send_frame_batch_tickets(self):
        """Removes all 'send_frame_batch' type tickets from the queue."""
        with self._ticket_queue.mutex:  # Lock the queue for the duration of the operation.
            # Create a new list excluding tickets where func is _send_frame_batch.
            self._ticket_queue.queue = [item for item in self._ticket_queue.queue if item[2].func != self._send_frame_batch]
            message = ("All send_frame_batch tickets have been flushed from the queue.")
            global_vars.status_window.send_status(widgets.StatusWindow.DEVICE_QUEUE_STATUS, message)
            
    def stop(self):
        """Stop the DeviceThread and all associated threads."""

        self.capture_thread.stop()
        self.capture_thread.join()
        print("DeviceThread capture_thread closed.")
        
        self._pie_chart_thread.stop_thread()
        self._pie_chart_thread.join()
        print("DeviceThread _pie_chart_thread closed.")
        
        self._update_stats_thread.stop()
        self._update_stats_thread.join()
        print("DeviceThread _update_thread closed.")
        
        self._stop_event.set()

    def _initialize_device(self):
        """Initialize and configure the device. Tries to open the device, retrieve its information, and set initial values.

        Returns:
            bool: True if initialization is successful, False otherwise.
        """
        
        # Attempt to open the first available device.
        self.fpdev = ok.FrontPanelDevices().Open()
        if not self.fpdev:
            print("A device could not be opened. Is one connected?")
            return False

        # Fetch device information.
        self.devInfo = ok.okTDeviceInfo()
        if self.fpdev.NoError != self.fpdev.GetDeviceInfo(self.devInfo):
            print("Unable to retrieve device information.")
            return False
        self._display_device_info()
        
        #Device should already be programmed. See if FrontPanel is available.
        if not self.fpdev.IsFrontPanelEnabled():
            print("FrontPanel support is not available.")
            return False
            
        print("FrontPanel support is available.")
        
        configuration = FrontPanelToAxiLiteBridge.Configuration(
            fpdev=self.fpdev,
            wire_in_addresses=FrontPanelToAxiLiteBridge.WireInAddresses(address=0x1d, data=0x1e, timeout=0x1f),
            wire_out_addresses=FrontPanelToAxiLiteBridge.WireOutAddresses(data=0x3e, status=0x3f),
            trigger_in_address_and_offsets=FrontPanelToAxiLiteBridge.TriggerInAddressAndOffsets(address=0x5f, write_bit_offset=0, read_bit_offset=1),
            hardware_timeout_ms=3000
        )
        
        self.axil_bridge = FrontPanelToAxiLiteBridge(configuration)
        
        transfers_in_line = global_vars.sys_vars.get_matrix_size() * 3 / 6
        transfers_in_frame = global_vars.sys_vars.get_matrix_size() * global_vars.sys_vars.get_matrix_size() * 3 / 6
        
        
        self.fpdev.SetWireInValue(0x10, int(transfers_in_line))
        self.fpdev.SetWireInValue(0x11, int(transfers_in_frame))
        self.fpdev.SetWireInValue(0x12, global_vars.sys_vars.get_batch_size())
        self.fpdev.UpdateWireIns()
        
        return True

    def _get_num_send_frame_tickets(self):
        """Get the count of 'send_frame_batch' type tickets in the queue.

        Returns:
            int: Count of 'send_frame_batch' type tickets.
        """
        with self._ticket_queue.mutex:  # Lock the queue to get a snapshot of its contents.
            return sum(1 for _, _, ticket in self._ticket_queue.queue if ticket.func == self._send_frame_batch)
            
    def _display_device_info(self):
        """Print details about the device."""
        print(f"Product: {self.devInfo.productName}")
        print(f"Firmware version: {self.devInfo.deviceMajorVersion}.{self.devInfo.deviceMinorVersion}")
        print(f"Serial Number: {self.devInfo.serialNumber}")
        print(f"Device ID: {self.devInfo.deviceID}")

    def _update_pie_chart(self):
        """Update the pie chart if the specified time step has elapsed.
        This function is called in the separate UpdateStatsThread so it doesn't slow down
        the main ticket consumer loop.
        """
        current_time = time.perf_counter()
        step_time_in_seconds = PIE_CHART_STEP_TIME_MS / 1000.0
        if current_time - self._last_pie_chart_update >= step_time_in_seconds:
            # Update the pie chart
            with self._ticket_stats_lock:
                self._pie_chart_thread.put_data(copy.deepcopy(self._ticket_stats))

                # Package up a message for the status window and clear the _ticket_stats
                messages = []
                for ticket_type, stats in self._ticket_stats.items():
                    messages.append(f"\n{ticket_type}: count={stats['count']}, duration={stats['duration']:.2f}s")
                    # Resetting counters and durations for the next interval
                    stats["count"] = 0
                    stats["duration"] = 0
                full_message = ", ".join(messages)
                
            global_vars.status_window.send_status(widgets.StatusWindow.TICKET_STATS, full_message)
            self._last_pie_chart_update = current_time
        
    def _update_fps_status(self):
        """Update the frames per second (fps) status at regular intervals.
        This function is called in the separate UpdateStatsThread so it doesn't slow down
        the main ticket consumer loop.
        """
        current_time = time.perf_counter()
        if current_time - self._last_status_time > STATUS_INTERVAL:
            message = (f"Device pulling frames out of queue at {self._sent_fps_counter / STATUS_INTERVAL} FPS")
            global_vars.status_window.send_status(widgets.StatusWindow.FPS_STATUS, message)
            self._sent_fps_counter = 0
            self._last_status_time = current_time

    def _update_ticket_stats(self, ticket_type, duration):
        """Update the statistics for the given ticket type.

        Args:
            ticket_type (string): The function whose stats need to be updated.
            duration (float): Time taken by the function to execute.
        """
        with self._ticket_stats_lock:
            for key, value in self._func_lookup.items():
                if value == ticket_type:
                    self._ticket_stats[key]["count"] += 1
                    self._ticket_stats[key]["duration"] += duration
                    break
                    
    def _send_frame_batch(self, data):
        """Internal function associated with the send_frame_batch ticket type.
        Send a batch of frames to the device.

        Args:
            data: Data to be sent as a frame batch.

        Returns:
            (None, int): Tuple containing None and an error code. (0 for no error).
        """
        with self._sent_fps_counter_lock:
            self._sent_fps_counter += global_vars.sys_vars.get_batch_size()
        
        self.fpdev.ActivateTriggerIn(0x40, 0)
        errorcode = self.fpdev.WriteToBlockPipeIn(0x80, 16384, data)
        
        while True:
            self.fpdev.UpdateWireOuts()
            status = self.fpdev.GetWireOutValue(0x30)
            test_done = status & 1
            test_fail = (status >> 1) & 1
            if test_done:
                if not test_fail:
                    error_code = 0
                else:
                    print("Error occurred during batch send")
                    error_code = -1
                break
            
        # return data (None if no return data), error_code (0 if no error)
        return None, error_code

    def _update_batch_size(self, size):
        """Internal function associated with the update_batch_size ticket type.
        Update the batch size on the device.

        Args:
            size (int): The new batch size.

        Returns:
            (None, int): Tuple containing None and an error code. (0 for no error).
        """
        # Update WireIn used to inform the gateware of new value for the batch size.
        error_code = self.fpdev.SetWireInValue(0x12, size)
        error_code |= self.fpdev.UpdateWireIns()
        error_code |= self.fpdev.ActivateTriggerIn(0x41, 0)
            
        # return data (None if no return data), error_code (0 if no error)
        return None, error_code
        
    def _axil_read(self, address):
        """Internal function associated with the read ticket type.
        Perform an AXIL read operation on the device.

        Args:
            address (int): The address to read from.

        Returns:
            (Any, int): Tuple containing the read data and an error code. (0 for no error).
        """
        response, data = self.axil_bridge.read(address)
        if response != FrontPanelToAxiLiteBridge.Response.OKAY:
            return None, -1

        # return data, error_code (0 if no error)
        return data, 0
        
    def _axil_write(self, address, data):
        """Internal function associated with the write ticket type.
        Perform an AXIL write operation on the device.
        
        Args:
            address (int): The address to write to.
            data: The data to write.

        Returns:
            (None, int): Tuple containing None and an error code. (0 for no error).
        """
        
        response = self.axil_bridge.write(address, data)
        if response != FrontPanelToAxiLiteBridge.Response.OKAY:
            return None, -1
            
        # return data (None if no return data), error_code (0 if no error)
        return None, 0
        
    def _retrieve_and_set_fps(self):
        """Internal function associated with the retrieve_and_set_fps ticket type.
        Retrieve and set frames per second (fps) values on the device.
            
        Returns:
            (Any, int): Tuple containing the retrieved data (or None) and an error code. (0 for no error).
        """
        response, dp_conf_LineRate = self.axil_bridge.read(XPAR_DPRXSS_0_BASEADDR + XDP_RX_OVER_LINK_BW_SET)
        if response != FrontPanelToAxiLiteBridge.Response.OKAY:
            return None, -1

        response, rxMsaMVid = self.axil_bridge.read(XPAR_DPRXSS_0_BASEADDR + XDP_RX_MSA_MVID)
        if response != FrontPanelToAxiLiteBridge.Response.OKAY:
            return None, -1
        rxMsaMVid &= 0x00FFFFFF

        response, rxMsaNVid = self.axil_bridge.read(XPAR_DPRXSS_0_BASEADDR + XDP_RX_MSA_NVID)
        if response != FrontPanelToAxiLiteBridge.Response.OKAY:
            return None, -1
        rxMsaNVid &= 0x00FFFFFF

        response, DpHres_total = self.axil_bridge.read(XPAR_DPRXSS_0_BASEADDR + XDP_RX_MSA_HTOTAL)
        if response != FrontPanelToAxiLiteBridge.Response.OKAY:
            return None, -1

        response, DpVres_total = self.axil_bridge.read(XPAR_DPRXSS_0_BASEADDR + XDP_RX_MSA_VTOTAL)
        if response != FrontPanelToAxiLiteBridge.Response.OKAY:
            return None, -1

        recv_clk_freq = (dp_conf_LineRate * 27.0 * rxMsaMVid) / rxMsaNVid
        recv_frame_clk = math.ceil((recv_clk_freq * 1000000.0) / (DpHres_total * DpVres_total))
        recv_frame_clk_int = int(recv_frame_clk)

        # Doing Approximation
        if recv_frame_clk_int in [59, 61]:
            recv_frame_clk_int = 60
        elif recv_frame_clk_int in [29, 31]:
            recv_frame_clk_int = 30
        elif recv_frame_clk_int in [76, 74]:
            recv_frame_clk_int = 75
        elif recv_frame_clk_int in [101, 99]:
            recv_frame_clk_int = 100
        elif recv_frame_clk_int in [121, 119]:
            recv_frame_clk_int = 120
            
        current_fps = global_vars.sys_vars.get_fps()
        if current_fps != recv_frame_clk_int:
            global_vars.sys_vars.set_fps(recv_frame_clk_int)  # Assuming global_vars is accessible
            message = (f"Hardware has undergone a change in FPS. Setting FPS to: {recv_frame_clk_int}")
            global_vars.status_window.send_status(widgets.StatusWindow.FPS_STATUS, message)
            
        return recv_frame_clk_int, 0

class DisplayThread(threading.Thread):
    """DisplayThread is a dedicated thread for managing and displaying
    batches of frames from a buffer in a real-time manner.
    
    Class Attributes:
        None

    Sub-Classes:
        None

    External Instance Attributes:
        None

    Internal Instance Attributes:
        _stop_signal (threading.Event): Signal to stop the thread's execution.
        _buffer_updated_event (threading.Event): Signal indicating the frame buffer has been updated.
        _frame_buffer (numpy.ndarray or None): Buffer to store the frame data.
        _lock (threading.Lock): Lock for thread-safe operations on frame buffer.

    External Methods:
        stop(): Signal the thread to stop its execution.
        clear_buffer(): Clear the frame buffer in a thread-safe manner.
        update_frame_buffer(data: bytes): Update the frame buffer with provided data.

    Internal Methods:
        run(): Main execution loop to check for updated frame buffer and process it.
    """
    def __init__(self):
        """Initializes the DisplayThread."""
        super(DisplayThread, self).__init__()
        self._stop_signal = threading.Event()
        self._buffer_updated_event = threading.Event()
        self._frame_buffer = None
        self._lock = threading.Lock()

    def run(self):
        """Main execution loop of the thread. Continuously checks for updated frame
        buffer, processes it, and displays the stitched frames.
        """
        while not self._stop_signal.is_set():
            # Wait for buffer update
            self._buffer_updated_event.wait(.1)

            # Process the buffer
            with self._lock:
                if self._frame_buffer is not None:
                    # Reshape and stitch frames
                    frames_np = self._frame_buffer.reshape(global_vars.sys_vars.get_batch_size(), global_vars.sys_vars.get_matrix_size(), global_vars.sys_vars.get_matrix_size(), 3)
                    rows = []
                    for i in range(0, len(frames_np), SHOW_BATCHED_FRAMES_FRAMES_PER_ROW):
                        chunk = frames_np[i:i+SHOW_BATCHED_FRAMES_FRAMES_PER_ROW]
                        while len(chunk) < SHOW_BATCHED_FRAMES_FRAMES_PER_ROW:
                            empty_frame = np.zeros((global_vars.sys_vars.get_matrix_size(), global_vars.sys_vars.get_matrix_size(), 3), dtype=np.uint8)
                            chunk = np.append(chunk, [empty_frame], axis=0)
                        rows.append(np.hstack(chunk))
                    stitched_frames = np.vstack(rows)
                    
                    # Convert and display image
                    bgr_image = cv2.cvtColor(stitched_frames, cv2.COLOR_RGB2BGR)
                    cv2.imshow("Stitched Frames", bgr_image)

            # Check for exit command
            if cv2.waitKey(1) & 0xFF == ord('q'):
                self._stop_signal.set()

            # Clear the event
            self._buffer_updated_event.clear()

    def stop(self):
        """Signals the thread to stop its execution."""
        self._stop_signal.set()
        
    def clear_buffer(self):
        """Clears the frame buffer in a thread-safe manner."""
        with self._lock:
            self._frame_buffer = None

    def update_frame_buffer(self, data):
        """Updates the frame buffer with the provided data and signals that
        the buffer has been updated.

        Args:
            data (bytes): The data to update the frame buffer with.
        """
        self._frame_buffer = np.frombuffer(data, dtype=np.uint8)
        self._buffer_updated_event.set()

   

class CaptureFramesThread(threading.Thread):
    """Manages the process of capturing frames in batches in real-time and sending them to 
    the device and display threads.

    Class Attributes:
        FPS_CHECK_INTERVAL (int): Interval for system FPS checks.
    
    Internal Instance Attributes:
        _stop_signal (Event): An event to signal the thread to stop its execution.
        _lock (Lock): A lock to ensure thread-safety when accessing internal data.
        _cam (object): Camera capture object for desktop captures.
        _fps_counter (int): FPS counter.
        _batch_frame_counter (int): Count of frames in the current batch.
        _data_buffer (bytearray): Buffer to hold frame data.
        _last_frame (np.array or None): Last captured frame.
        _send_packets_enabled (bool): Flag to determine if sending packets is enabled.
        _last_status_time (float): Last time status was updated.
        _device_thread (object or None): Instance of a device thread to which data is sent.
        _app (QApplication): Qt application object.
        _ex (object): Instance of a transparent overlay.
    
    External Instance Attributes:
        display_thread (DisplayThread or None): Instance of DisplayThread to which data is sent.
        last_fps_time (float): Last time FPS was checked.

    External Methods:
        run: Main execution loop of the thread.
        stop: Signals the thread to stop its execution and closes relevant resources.
        enable_sending: Enables sending of packets.
        disable_sending: Disables sending of packets and clears relevant data.

    Internal Methods:
        _ensure_target_fps: Ensure the target frames per second is achieved.
        _process_data: Process the given data for sending and displaying.
    """
    FPS_CHECK_INTERVAL = 1
    
    def __init__(self, device_thread_instance):
        """Initializes the CaptureFramesThread.

        Args:
            device_thread_instance (DeviceThread): An instance of the device thread to which data can be sent.
        """
        super(CaptureFramesThread, self).__init__()
        self._stop_signal = threading.Event()
        
        self._lock = threading.Lock()
        
        self._cam = dxshot.create()
        self._fps_counter = 0
        self._batch_frame_counter = 0
        self._data_buffer = bytearray()
        self._last_frame = None
        
        self._send_packets_enabled = True  # By default, sending is enabled
        
        self._last_status_time = time.perf_counter()
        self.last_fps_time = time.perf_counter()
        
        self._device_thread = device_thread_instance
        
        if SHOW_BATCHED_FRAMES:
            self.display_thread = DisplayThread()  # Assuming you have defined a DisplayThread class elsewhere
            self.display_thread.start()
        
        self._app = QApplication(sys.argv)
        self._ex = widgets.RegionOfInterestOverlay(X_OFFSET, Y_OFFSET, global_vars.sys_vars.get_matrix_size(), global_vars.sys_vars.get_matrix_size(), BORDER_THICKNESS)
        
    def run(self):  
        """Main execution loop of the thread. Continuously captures frames in batches and sends 
        them to device and display threads.
        """
        while not self._stop_signal.is_set():
            with self._lock:
                if self._send_packets_enabled:
                    frame_start_time = time.perf_counter()

                    frame = self._cam.grab(region=utils.define_capture_region_offset(X_OFFSET, Y_OFFSET, global_vars.sys_vars.get_matrix_size(), global_vars.sys_vars.get_matrix_size()))
                    if frame is None:
                        frame = self._last_frame
                        
                    self._last_frame = frame

                    self._data_buffer.extend(frame)
                    
                    self._batch_frame_counter += 1
                    self._fps_counter += 1

                    if self._batch_frame_counter == global_vars.sys_vars.get_batch_size():
                        self._process_data(self._data_buffer)
                        self._batch_frame_counter = 0
                        self._data_buffer = bytearray()

                    frame_end_time = time.perf_counter()
                    self._ensure_target_fps(frame_end_time - frame_start_time, USE_SPIN_WAIT)
                    
                    current_time = time.perf_counter()
                    if current_time - self._last_status_time > STATUS_INTERVAL:
                        message = (f"Placing frames into the device queue at {self._fps_counter / STATUS_INTERVAL} FPS")
                        global_vars.status_window.send_status(widgets.StatusWindow.FPS_STATUS, message)
                        self._fps_counter = 0
                        self._last_status_time = current_time
                        
                    if current_time - self.last_fps_time > self.FPS_CHECK_INTERVAL:
                        self._device_thread.schedule("retrieve_and_set_fps", {}, priority=RETRIEVE_AND_SET_FPS_QUEUE_PRIORITY)
                        self.last_fps_time = current_time
                
        del self._cam

    def stop(self):
        """Signals the thread to stop its execution and closes relevant resources."""
        if self.display_thread:
            self.display_thread.stop()
            self.display_thread.join()
            print("CaptureFramesThread display_thread closed.")
    
        self._stop_signal.set()

    def _ensure_target_fps(self, frame_duration, use_spin_wait):
        """Ensures that the thread captures frames at the target FPS by introducing necessary delays.

        Args:
            frame_duration (float): Duration taken to process the current frame.
            use_spin_wait (bool): If True, uses a spin wait mechanism. Otherwise, uses time.sleep.
        """
        target_frame_duration = 1.0 / global_vars.sys_vars.get_fps()  # Duration each frame should ideally take.
            
        if frame_duration < target_frame_duration:
            wait_time = target_frame_duration - frame_duration
            if use_spin_wait:
                target_time = time.perf_counter() + wait_time
                while time.perf_counter() < target_time:
                    pass
            else:
                time.sleep(wait_time)

    def enable_sending(self):
        """Enables sending of packets in a thread-safe manner."""
        with self._lock:
            self._send_packets_enabled = True

    def disable_sending(self):
        """Disables sending of packets and clears relevant data in a thread-safe manner."""
        with self._lock:
            self._send_packets_enabled = False
            self._batch_frame_counter = 0
            self._data_buffer = bytearray()

        
    def _process_data(self, data): 
        """Processes the provided data: sends it to the device and updates the frame buffer for display.

        Args:
            data (bytes): The data to be processed.
        """
        if not self._device_thread == None:
            send_batch_ticket = self._device_thread.schedule("send_frame_batch", {"data": data}, priority=SEND_FRAME_BATCH_QUEUE_PRIORITY)
            
        if self.display_thread:
            self.display_thread.update_frame_buffer(data)
                
class CursorFollowThread(threading.Thread):
    """CursorFollowThread class is responsible for tracking the position of the mouse cursor 
    in real-time and updating global positions using utility functions. It is designed 
    to manage positions accurately even across multiple monitors.

    Class Attributes:
        None

    Sub-Classes:
        None

    External Instance Attributes:
        None

    Internal Instance Attributes:
        _step_time (float): Time interval between each position update.
        _stop_signal (Event): An event to signal the thread to stop its execution.

    External Methods:
        run: Main execution loop of the thread which continuously tracks the mouse cursor's position.
        stop: Signals the thread to stop its execution.

    Internal Methods:
        None
    """
    def __init__(self, updates_per_second):
        """Initializes the CursorFollowThread.

        Args:
            updates_per_second (int): The number of times per second the cursor position should be checked.
        """
        super().__init__()
        
        # Compute the step_time based on updates_per_second
        self._step_time = 1.0 / updates_per_second
        
        self._stop_signal = threading.Event()
    
    def run(self):
        """Main execution loop of the thread. Continuously tracks the position of 
        the mouse cursor and updates x and y positions.
        """
        try:
            while not self._stop_signal.is_set():
                x, y = pyautogui.position()
                
                # Applying modulo to handle dual monitor setup and roll over.
                x = x % global_vars.sys_vars.get_screen_width()
                y = y % global_vars.sys_vars.get_screen_height()
                
                utils.set_x_position(x)
                utils.set_y_position(y)
                
                time.sleep(self._step_time)
        except Exception as e:
            print(f"An error occurred during cursor follow mode: {e}")

    def stop(self):
        """Signals the thread to stop its execution."""
        self._stop_signal.set()
        