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

"""Utility functions for system operations.

This module provides a collection of utility functions that assist in various
tasks across the system, enhancing code readability, reusability, and modularity.
"""

from imports import *
from constants import *
import global_vars
import threads
import widgets

def initialize_system():
    """Initialize threads and system variables."""
    global_vars.status_window = widgets.StatusWindow()
    global_vars.status_window.start()
    
    try:
        global_vars.device_thread = threads.DeviceThread()

        global_vars.device_thread.start()
            
        setup_app_resolution_variables()
        send_retrieve_and_set_fps_ticket()
    except RuntimeError as e:
        print(e)
        sys.exit()


def teardown_system(cursor_follow_thread):
    """Cleanup and teardown threads.
    
    Args:
        cursor_follow_thread (Thread): The thread that follows the cursor to be stopped and cleaned up.
    """
    if cursor_follow_thread and cursor_follow_thread.is_alive():
        cursor_follow_thread.stop()
        cursor_follow_thread.join()  # Wait for the thread to finish
        print("Cursor thread closed.")
    
    global_vars.device_thread.stop()
    global_vars.status_window.close()
    
    global_vars.device_thread.join()
    print("device_thread closed.")
    
    global_vars.status_window.join()
    print("status_window thread closed.")
    
    
def get_offset_input(axis: str):
    """Get user input for a specified axis offset.
    
    Args:
        axis (str): The name of the axis ('x' or 'y') to get the offset for.
        
    Returns:
        int: The user-entered offset value.
    """
    while True:
        try:
            offset_value = int(input(f"Enter the desired {axis} offset: "))
            return offset_value
        except ValueError:
            print("Please enter a valid number!")

def get_valid_batch_size():
    """Get a valid batch size from user input.
    
    Returns:
        int: A valid batch size that's at least 1.
    """
    while True:
        try:
            batch_size = int(input("Enter the desired batch size: "))

            if batch_size >= 1:
                return batch_size
            else:
                print("Please enter a batch size that is at least 1.")
        except ValueError:
            print("Please enter a valid number!")

def handle_cursor_follow_mode(cursor_follow_thread):
    """Handle cursor follow mode activation.
    
    Args:
        cursor_follow_thread (Thread): The thread that follows the cursor.
        
    Returns:
        Thread: The thread that follows the cursor, either the existing one or a newly created one.
    """
    if cursor_follow_thread and cursor_follow_thread.is_alive():
        message = ("Cursor follow mode is already enabled.")
        global_vars.status_window.send_status(widgets.StatusWindow.APPLICATION_INFO, message)
    else:
        cursor_follow_thread = threads.CursorFollowThread(updates_per_second=global_vars.sys_vars.get_fps())
        cursor_follow_thread.start()
        message = ("Cursor follow mode activated.")
        global_vars.status_window.send_status(widgets.StatusWindow.APPLICATION_INFO, message)
    return cursor_follow_thread


def deactivate_cursor_follow_mode(cursor_follow_thread):
    """Deactivate the cursor follow mode.
    
    Args:
        cursor_follow_thread (Thread): The thread that follows the cursor to be stopped.
    """
    if cursor_follow_thread and cursor_follow_thread.is_alive():
        cursor_follow_thread.stop()
        cursor_follow_thread.join()  # Wait for the thread to finish
        message = ("Cursor follow mode deactivated.")
        global_vars.status_window.send_status(widgets.StatusWindow.APPLICATION_INFO, message)
    else:
        message = ("Cursor follow mode is not currently active.")
        global_vars.status_window.send_status(widgets.StatusWindow.APPLICATION_INFO, message)

def define_capture_region_offset(x_offset, y_offset, matrix_width, matrix_height):
    """
    Define the capture region with an offset from the screen's top-left origin.
    
    Args:
        x_offset (int): Horizontal offset from the screen's top-left origin.
        y_offset (int): Vertical offset from the screen's top-left origin.
        matrix_width (int): Desired width of the capture matrix.
        matrix_height (int): Desired height of the capture matrix.
        
    Returns:
        tuple: A tuple representing (left, top, right, bottom) coordinates of the bounding box.
    """
    left = x_offset
    top = y_offset
    right = left + matrix_width
    bottom = top + matrix_height

    return (left, top, right, bottom)
    
def home_screen():
    """Display the main menu of the DisplayPort Example Design."""
    print("\nDisplayPort Example Design")
    print("\nMenu:")
    print("x: Set x offset.")
    print("y: Set y offset.")
    print("f: Activate cursor-follow mode")
    print("d: Deactivate cursor-follow mode")
    print("r: Perform AXI read.")
    print("w: Perform AXI write.")
    print("s: Calculate DisplayPort feed's FPS.")
    print("b: Update system's batch size.")
    print("z: Print this home screen.")
    print("q: Exit application.")

def set_x_position(x_offset_value):
    """Set the x position using a given offset value.
    
    The function ensures that the offset doesn't push the capture region off the screen.
    
    Args:
        x_offset_value (int): Desired x offset value.
    """
    # Ensure the offset doesn't push the box off the screen
    max_x_offset = global_vars.sys_vars.get_screen_width() - global_vars.sys_vars.get_matrix_size()
    x_offset_value = min(max_x_offset, max(0, x_offset_value))
    
    vmix_x_address = XPAR_V_MIX_0_S_AXI_CTRL_BASEADDR + XV_MIX_CTRL_ADDR_HWREG_LAYERSTARTX_0_DATA
    axi_write_ticket = global_vars.device_thread.schedule("write", {"address": vmix_x_address, "data": x_offset_value}, priority=SET_X_POSITION_QUEUE_PRIORITY)
    axi_write_ticket.wait()

    error_code = axi_write_ticket.error_code
    if error_code != 0:
        message = (f"An error has occurred in set_x_position. error_code: {error_code}")
        global_vars.status_window.send_status(widgets.StatusWindow.APPLICATION_INFO, message)
    else:
        message = (f"x offset set to {x_offset_value}.")
        global_vars.status_window.send_status(widgets.StatusWindow.POSITION_STATUS, message)

def set_y_position(y_offset_value):
    """Set the y position using a given offset value.
    
    The function ensures that the offset doesn't push the capture region off the screen.
    
    Args:
        y_offset_value (int): Desired y offset value.
    """
    # Ensure the offset doesn't push the box off the screen
    max_y_offset = global_vars.sys_vars.get_screen_height() - global_vars.sys_vars.get_matrix_size()
    y_offset_value = min(max_y_offset, max(0, y_offset_value))
    
    vmix_y_address = XPAR_V_MIX_0_S_AXI_CTRL_BASEADDR + XV_MIX_CTRL_ADDR_HWREG_LAYERSTARTY_0_DATA
    axi_write_ticket = global_vars.device_thread.schedule("write", {"address": vmix_y_address, "data": y_offset_value}, priority=SET_Y_POSITION_QUEUE_PRIORITY)
    axi_write_ticket.wait()

    error_code = axi_write_ticket.error_code
    if error_code != 0:
        message = (f"An error has occurred in set_y_position. error_code: {error_code}")
        global_vars.status_window.send_status(widgets.StatusWindow.APPLICATION_INFO, message)
    else:
        message = (f"y offset set to {y_offset_value}.")
        global_vars.status_window.send_status(widgets.StatusWindow.POSITION_STATUS, message)
    
def axi_read():
    """Prompt the user for a read address and perform the AXIL read operation.
    
    The function ensures that the provided address is in the correct format.
    """
    while True:
        read_address_str = input("Input a 32 bit read address in '0x...' format: ")
        try:
            if not read_address_str.startswith("0x"):
                raise ValueError("Address must start with '0x'.")

            read_address = int(read_address_str, 16)  # Convert the string to an integer using base 16
            if read_address > 0xFFFFFFFF:
                raise ValueError("Address exceeds 32 bits.")
            
            break  # Exit loop if input is valid
        except ValueError as e:
            print(e)
    
    
    axi_read_ticket = global_vars.device_thread.schedule("read", {"address": read_address}, priority=AXI_READ_QUEUE_PRIORITY)
    axi_read_ticket.wait()  # Wait for the ticket to complete

    read_data = axi_read_ticket.result
    error_code = axi_read_ticket.error_code
    if error_code != 0:
        message = (f"An error has occurred in axil_read. error_code: {error_code}")
        global_vars.status_window.send_status(widgets.StatusWindow.APPLICATION_INFO, message)
    else:
        message = (f"AXIL Read Data: {hex(read_data)}")
        global_vars.status_window.send_status(widgets.StatusWindow.APPLICATION_INFO, message)

def axi_write():
    """Prompt the user for a write address and data, and perform the AXIL write operation.
    
    The function ensures that the provided address and data are in the correct formats.
    """
    while True:
        write_address_str = input("Input a 32 bit write address in '0x...' format: ")
        try:
            if not write_address_str.startswith("0x"):
                raise ValueError("Address must start with '0x'.")

            write_address = int(write_address_str, 16)  # Convert the string to an integer using base 16
            if write_address > 0xFFFFFFFF:
                raise ValueError("Address exceeds 32 bits.")
            
            break  # Exit loop if input is valid
        except ValueError as e:
            print(e)

    while True:
        write_data_str = input("Input a 32 bit write data (decimal or '0x'/'0X' hex format): ")
        try:
            if write_data_str.lower().startswith("0x"):
                write_data = int(write_data_str, 16)  # Convert from hex
            else:
                write_data = int(write_data_str)  # Assume decimal format

            if write_data < 0 or write_data > 0xFFFFFFFF:
                raise ValueError("Data exceeds 32 bits.")

            break  # Exit loop if input is valid

        except ValueError as e:
            print(e)
            print("Please enter a valid 32 bit integer!")


    axi_write_ticket = global_vars.device_thread.schedule("write", {"address": write_address, "data": write_data}, priority=AXI_WRITE_QUEUE_PRIORITY)
    axi_write_ticket.wait()  # Wait for the ticket to complete

    error_code = axi_write_ticket.error_code
    if error_code != 0:
        message = (f"An error has occurred in axi_write. error_code: {error_code}")
        global_vars.status_window.send_status(widgets.StatusWindow.APPLICATION_INFO, message)
    else:
        message = (f"AXIL Write Successful.")
        global_vars.status_window.send_status(widgets.StatusWindow.APPLICATION_INFO, message)

def send_retrieve_and_set_fps_ticket():
    """Retrieve and set the FPS through sending the device ticket of the same name.
    
    The function requests the FPS from the system and updates the global status window.
    """
    fps_ticket = global_vars.device_thread.schedule("retrieve_and_set_fps", {}, priority=RETRIEVE_AND_SET_FPS_QUEUE_PRIORITY)
    fps_ticket.wait()  # Wait for the ticket to complete

    read_data = fps_ticket.result
    error_code = fps_ticket.error_code
    if error_code != 0:
        message = (f"An error has occurred with send_retrieve_and_set_fps_ticket. error_code: {error_code}")
        global_vars.status_window.send_status(widgets.StatusWindow.APPLICATION_INFO, message)
    else:
        message = (f"System reported a FPS of: {read_data}")
        global_vars.status_window.send_status(widgets.StatusWindow.APPLICATION_INFO, message)
    
def send_update_batch_size_ticket(size):
    """Update the batch size through sending the device ticket of the same name.
    
    Args:
        size (int): The desired batch size to be set.
    """
    global_vars.device_thread.capture_thread.disable_sending()
    global_vars.device_thread.cancel_send_frame_batch_tickets()
    if SHOW_BATCHED_FRAMES:
        global_vars.device_thread.capture_thread.display_thread.clear_buffer()

    batch_ticket = global_vars.device_thread.schedule("update_batch_size", {"size": size}, priority=RETRIEVE_AND_SET_FPS_QUEUE_PRIORITY)
    batch_ticket.wait()  # Wait for the ticket to complete
    
    error_code = batch_ticket.error_code
    if error_code != 0:
        message = (f"An error has occurred with send_update_batch_size_ticket. error_code: {error_code}")
        global_vars.status_window.send_status(widgets.StatusWindow.APPLICATION_INFO, message)
    else:
        global_vars.sys_vars.set_batch_size(size)
        global_vars.device_thread.capture_thread.enable_sending()
            
        message = (f"Set batch size to {size}")
        global_vars.status_window.send_status(widgets.StatusWindow.APPLICATION_INFO, message)

def setup_app_resolution_variables():
    """Setup application resolution variables using AXIL read operations.
    
    The function retrieves the screen width and height from the device and updates the global system variables.
    """
    # Width
    vmix_width_addr = XPAR_V_MIX_0_S_AXI_CTRL_BASEADDR + XV_MIX_CTRL_ADDR_HWREG_WIDTH_DATA
    axi_read_ticket = global_vars.device_thread.schedule("read", {"address": vmix_width_addr}, priority=1)
    axi_read_ticket.wait()  # Wait for the ticket to complete
    
    read_data = axi_read_ticket.result
    error_code = axi_read_ticket.error_code
    if error_code != 0:
        message = (f"An error has occurred. error_code: {error_code}")
        global_vars.status_window.send_status(widgets.StatusWindow.APPLICATION_INFO, message)
        raise RuntimeError("Issue retrieving screen width from device")
    
    global_vars.sys_vars.set_screen_width(read_data)
   
    # Height
    vmix_height_addr = XPAR_V_MIX_0_S_AXI_CTRL_BASEADDR + XV_MIX_CTRL_ADDR_HWREG_HEIGHT_DATA
    axi_read_ticket = global_vars.device_thread.schedule("read", {"address": vmix_height_addr}, priority=1)
    axi_read_ticket.wait()  # Wait for the ticket to complete
    
    read_data = axi_read_ticket.result
    error_code = axi_read_ticket.error_code
    if error_code != 0:
        message = (f"An error has occurred. error_code: {error_code}")
        global_vars.status_window.send_status(widgets.StatusWindow.APPLICATION_INFO, message)
        raise RuntimeError("Issue retrieving screen height from device")
    
    global_vars.sys_vars.set_screen_height(read_data)
    