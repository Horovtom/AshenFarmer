### USAGE ###
# Have these three things on your hotbar: 1 - spammable ranged spell, 2 - drink, 3 - target nearest enemy macro:

# /cleartarget
# /targetenemy [noharm]

# Launch the AshenFarmer addon
# Run this python script in console
# Focus WoW window and mouseover the big red square
# Press spacebar
# When you want to turn the bot off, press ESC
# Then turn off the AshenFarmer addon

from pynput import keyboard
import sched, time
import win32ui, win32api
import win32con, ctypes, ctypes.wintypes
from threading import Thread

clicker = None
capture = None

class CaptureKeys:
    def on_release(self, key):
        print('{0} released'.format(key))
        if key == keyboard.Key.space:
            clicker.start()
        elif key == keyboard.Key.esc:
            clicker.stop()
            return False
 
    # Collect events until released
    def main(self):
        with keyboard.Listener(
                on_release=self.on_release) as listener:
            listener.join()
 
    def start_listener(self):
        keyboard.Listener.start
        self.main()

class Clicker: 
    def __init__(self, interval):
        self.window = win32ui.FindWindow(None, "World of Warcraft")
        if (self.window is None):
            raise Exception("Window not found!")

        self.interval = interval
        self.keyboard = keyboard.Controller()
        self.scheduler = sched.scheduler(time.time, time.sleep)
        self.char_to_press = None
        self.running = False

        self.dc = self.window.GetWindowDC()
        self.chars = {"cast": '1', "drink": '2', "target": '3', "nop": None}

        self.scheduler_event = self.scheduler.enter(self.interval, 1, self.click, (self.scheduler,))
        self.scheduler_thread = Thread(target=self.scheduler.run) 

    def start(self):
        if self.running:
            return
        print("Starting...")
        self.running = True
        self.scheduler_thread.start()

    def stop(self):
        if not self.running:
            return
        print("Stopping...")
        self.running = False
        self.scheduler.cancel(self.scheduler_event)
        self.scheduler_thread.join()

    def check_command(self):
        # Grab cursor position
        pos = win32api.GetCursorPos()
        color = self.dc.GetPixel(pos[0], pos[1])
        print(color)
        if color == 65280:
            print("Sending CAST command")
            return self.chars["cast"]
        elif color == 255:
            print("Sending TARGET command")            
            return self.chars["target"]
        elif color == 16711680:
            print("Sending DRINK command")
            return self.chars["drink"]
        else:
            return self.chars["nop"]

    def click(self, sc):
        if self.char_to_press is not None:
            self.keyboard.press(self.char_to_press)
            self.keyboard.release(self.char_to_press)
        self.scheduler_event = self.scheduler.enter(self.interval, 1, self.click, (sc,))
        self.char_to_press = self.check_command()



if __name__ == '__main__':
    cast_time = float(input("Enter cast time of your spammable spell: "))
    capture = CaptureKeys()
    clicker = Clicker(cast_time)    
    capture.start_listener()
