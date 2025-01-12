import serial
import serial.tools.list_ports
import time
import threading


class BluetoothBridge:
    def __init__(self):
        self.ser1 = None  # COM6 (发送方)
        self.ser2 = None  # COM5 (接收方)
        self.running = False

    def connect_devices(self):
        """Connect to both Bluetooth devices with fixed ports"""
        try:
            self.ser1 = serial.Serial('COM6', 9600, timeout=1)
            print("Successfully connected to COM6 (Sender)")

            self.ser2 = serial.Serial('COM5', 9600, timeout=1)
            print("Successfully connected to COM5 (Receiver)")

            return True

        except serial.SerialException as e:
            print(f"Connection Error: {e}")
            self.close_connections()
            return False

    def read_and_forward(self, from_serial, to_serial, direction):
        """Read data from one device and forward to another"""
        while self.running:
            try:
                if from_serial.in_waiting:
                    # Read the data
                    received_bytes = from_serial.read(from_serial.in_waiting)

                    # Display data in different formats
                    hex_data = ' '.join([f'{b:02X}' for b in received_bytes])
                    binary_data = ' '.join([f'{b:08b}' for b in received_bytes])
                    decimal_data = ' '.join([f'{b}' for b in received_bytes])

                    print(f"\n{direction}:")
                    print(f"Hex: {hex_data}")
                    print(f"Binary: {binary_data}")
                    print(f"Decimal: {decimal_data}")

                    # Forward the data
                    if direction == "COM6->COM5":  # 只转发从COM6到COM5的数据
                        to_serial.write(received_bytes)

                time.sleep(0.01)

            except Exception as e:
                print(f"Error in {direction}: {e}")
                continue

    def start_bridge(self):
        """Start the bridging operation"""
        self.running = True

        # Create two threads for bidirectional communication
        thread1 = threading.Thread(target=self.read_and_forward,
                                   args=(self.ser1, self.ser2, "COM6->COM5"))
        thread2 = threading.Thread(target=self.read_and_forward,
                                   args=(self.ser2, self.ser1, "COM5->COM6"))

        thread1.daemon = True
        thread2.daemon = True

        thread1.start()
        thread2.start()

        print("Bridge is running... Press Ctrl+C to stop")

        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            self.stop_bridge()

    def stop_bridge(self):
        """Stop the bridging operation"""
        self.running = False
        time.sleep(0.5)  # Allow threads to finish
        self.close_connections()
        print("\nBridge stopped")

    def close_connections(self):
        """Close all serial connections"""
        if self.ser1 and self.ser1.is_open:
            self.ser1.close()
        if self.ser2 and self.ser2.is_open:
            self.ser2.close()


def main():
    bridge = BluetoothBridge()

    # Connect and start bridging
    if bridge.connect_devices():
        bridge.start_bridge()


if __name__ == "__main__":
    main()