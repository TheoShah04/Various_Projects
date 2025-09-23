import serial
import struct
import random
import time

COM_PORT = "COM6"
BAUD = 115200
WIDTH = 32   # FPGA data width in bits
DEPTH = 8    # number of elements per array
TIMEOUT = 0.1  # UART read timeout in seconds

def send_array(ser, arr):
    """Send an array of integers as binary words."""
    for val in arr:
        ser.write(struct.pack("<I", val))
    ser.flush()

def read_available(ser):
    """Read all available bytes and print them in hex."""
    n = ser.in_waiting
    if n > 0:
        data = ser.read(n)
        print("RX:", ' '.join(f"{b:02X}" for b in data))

def main():
    ser = serial.Serial(COM_PORT, BAUD, timeout=TIMEOUT)
    time.sleep(0.1)  # let UART settle

    try:
        for trial in range(5):
            # generate unsorted array
            arr = [random.randint(0, 1000) for _ in range(DEPTH)]
            print(f"TX {trial}: {arr}")

            # send array
            send_array(ser, arr)

            # read bytes as they come in
            start_time = time.time()
            received = bytearray()
            while len(received) < DEPTH*4:
                n = ser.in_waiting
                if n > 0:
                    chunk = ser.read(n)
                    received.extend(chunk)
                    print("RX chunk:", ' '.join(f"{b:02X}" for b in chunk))
                # timeout after 2 seconds per array
                if time.time() - start_time > 2:
                    print("⚠ Timeout waiting for FPGA response")
                    break
                time.sleep(0.01)

            # if we got enough bytes, unpack
            if len(received) == DEPTH*4:
                rx_array = list(struct.unpack("<" + "I"*DEPTH, received))
                print(f"RX full array: {rx_array}")
                if rx_array == sorted(arr):
                    print("PASS")
                else:
                    print("FAIL")
            else:
                print(f"RX incomplete ({len(received)} bytes)")

    finally:
        ser.close()

if __name__ == "__main__":
    main()
