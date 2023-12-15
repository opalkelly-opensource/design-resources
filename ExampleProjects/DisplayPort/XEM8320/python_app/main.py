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

"""Main application loop for a console-based user interface.

This module drives the core of the application. It waits for user keypresses
and dispatches appropriate actions based on the input received.
"""

from imports import *
from constants import *
import global_vars
import utils
import threads
import widgets
       
def main():
    utils.initialize_system()

    cursor_follow_thread = None  # Initialization for the cursor follow thread
    
    while True:
        utils.home_screen()
        choice = input("\nEnter your choice: ").lower()

        if choice == "x":
            x_offset_value = utils.get_offset_input('x')
            utils.set_x_position(x_offset_value)
        elif choice == "y":
            y_offset_value = utils.get_offset_input('y')
            utils.set_y_position(y_offset_value)
        elif choice == "f":
            cursor_follow_thread = utils.handle_cursor_follow_mode(cursor_follow_thread)
        elif choice == "d":
            utils.deactivate_cursor_follow_mode(cursor_follow_thread)
        elif choice == "r":
            utils.axi_read()
        elif choice == "w":
            utils.axi_write()
        elif choice == "s":
            utils.send_retrieve_and_set_fps_ticket()
        elif choice == "b":
            requested_batch_size = utils.get_valid_batch_size()
            utils.send_update_batch_size_ticket(requested_batch_size)
        elif choice == "z":
            utils.home_screen()
        elif choice == "q":
            break
        else:
            print("Invalid choice. Type 'z' to see the menu again.")

    utils.teardown_system(cursor_follow_thread)

    # Exit the program
    sys.exit()

if __name__ == "__main__":
    main()