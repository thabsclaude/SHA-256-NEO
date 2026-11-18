"""Send one educational miner work packet over the Nexys A7 USB-UART port.
Requires: python -m pip install pyserial
"""
import argparse
import sys
try:
    import serial
except ImportError:  # Keep --help available when pySerial is not installed.
    serial = None


def parse_hex(text: str, size: int, label: str) -> bytes:
    value = text.removeprefix("0x").replace(" ", "").replace("_", "")
    try:
        data = bytes.fromhex(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"{label} must be hexadecimal") from exc
    if len(data) != size:
        raise argparse.ArgumentTypeError(f"{label} must be exactly {size} bytes ({size * 2} hex characters)")
    return data


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("port", help="serial port, e.g. COM5")
    parser.add_argument("header", help="80-byte block header hex; nonce bytes 76..79 are replaced")
    parser.add_argument("target", help="256-bit target as 32-byte big-endian hex")
    parser.add_argument("nonce_start", type=lambda x: int(x, 0), help="first nonce (0..0xffffffff)")
    parser.add_argument("nonce_end", type=lambda x: int(x, 0), help="last nonce, inclusive")
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--timeout", type=float, default=60.0, help="response timeout in seconds")
    args = parser.parse_args()

    try:
        header = parse_hex(args.header, 80, "header")
        target = parse_hex(args.target, 32, "target")
    except argparse.ArgumentTypeError as exc:
        parser.error(str(exc))
    if not (0 <= args.nonce_start <= args.nonce_end <= 0xFFFFFFFF):
        parser.error("nonce range must satisfy 0 <= start <= end <= 0xffffffff")

    if serial is None:
        print("pySerial is required; install it with: py -m pip install pyserial", file=sys.stderr)
        return 2

    packet = (b"W" + header + target + args.nonce_start.to_bytes(4, "big")
              + args.nonce_end.to_bytes(4, "big"))
    try:
        with serial.Serial(args.port, args.baud, timeout=args.timeout, write_timeout=args.timeout) as link:
            link.reset_input_buffer()
            link.write(packet)
            link.flush()
            reply = link.read(1)
            if reply == bytes([0xEE]):
                print("FPGA reported a packet timeout (0xEE); the packet was discarded.", file=sys.stderr)
                return 1
            if len(reply) == 1:
                reply += link.read(36)
    except serial.SerialException as exc:
        print(f"Serial error: {exc}", file=sys.stderr)
        return 2

    if len(reply) != 37:
        print(f"Timed out: expected 37 response bytes, received {len(reply)}", file=sys.stderr)
        return 1
    status, nonce_bytes, digest = reply[0], reply[1:5], reply[5:]
    if status == 1:
        print(f"FOUND nonce=0x{int.from_bytes(nonce_bytes, 'big'):08x}")
        print(f"SHA256d digest={digest.hex()}")
    elif status == 0:
        print("No target match in the requested nonce range.")
    else:
        print(f"Invalid response status 0x{status:02x}: {reply.hex()}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())


