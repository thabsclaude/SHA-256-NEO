"""Live hash-rate dashboard for the FPGA miner.

Splits a nonce range into chunks, sends each chunk as one work packet, and
prints a running hash rate and progress bar. The UART transfer time is
subtracted so the rate reflects the FPGA search time, not the serial link.

Example (impossible target, so every nonce is searched):
    py python/uart_miner_dashboard.py COM7 <80-byte header hex> 00 0 0xffffff

Requires: python -m pip install pyserial
"""
import argparse
import sys
import time

from uart_miner_host import parse_hex

try:
    import serial
except ImportError:
    serial = None

PACKET_BYTES = 1 + 80 + 32 + 4 + 4
REPLY_BYTES = 37


def format_rate(hps: float) -> str:
    if hps >= 1e6:
        return f"{hps / 1e6:.3f} MH/s"
    if hps >= 1e3:
        return f"{hps / 1e3:.1f} kH/s"
    return f"{hps:.0f} H/s"


def bar(fraction: float, width: int = 30) -> str:
    filled = int(round(fraction * width))
    return "[" + "#" * filled + "-" * (width - filled) + "]"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("port", help="serial port, e.g. COM7")
    parser.add_argument("header", help="80-byte block header hex; nonce bytes 76..79 are replaced")
    parser.add_argument("target", help="target as 32-byte hex, or 00 for an impossible all-zero target, or ff for all-ones")
    parser.add_argument("nonce_start", type=lambda x: int(x, 0))
    parser.add_argument("nonce_end", type=lambda x: int(x, 0), help="inclusive")
    parser.add_argument("--chunk", type=lambda x: int(x, 0), default=1 << 20,
                        help="nonces per work packet (default 1048576, about 2 s of work)")
    parser.add_argument("--baud", type=int, default=115200)
    args = parser.parse_args()

    if args.target.lower() in ("00", "0"):
        target = bytes(32)
    elif args.target.lower() == "ff":
        target = bytes([0xFF] * 32)
    else:
        target = None
    try:
        header = parse_hex(args.header, 80, "header")
        if target is None:
            target = parse_hex(args.target, 32, "target")
    except argparse.ArgumentTypeError as exc:
        parser.error(str(exc))
    if not (0 <= args.nonce_start <= args.nonce_end <= 0xFFFFFFFF) or args.chunk < 1:
        parser.error("need 0 <= nonce_start <= nonce_end <= 0xffffffff and chunk >= 1")
    if serial is None:
        print("pySerial is required: py -m pip install pyserial", file=sys.stderr)
        return 2

    # Serial transfer time per chunk (10 bits per byte on the wire), removed from the timing.
    link_seconds = (PACKET_BYTES + REPLY_BYTES) * 10 / args.baud
    total = args.nonce_end - args.nonce_start + 1
    done_hashes = 0
    fpga_seconds = 0.0
    nonce = args.nonce_start
    try:
        with serial.Serial(args.port, args.baud, timeout=60, write_timeout=60) as link:
            while nonce <= args.nonce_end:
                last = min(nonce + args.chunk - 1, args.nonce_end)
                packet = (b"W" + header + target + nonce.to_bytes(4, "big") + last.to_bytes(4, "big"))
                link.reset_input_buffer()
                began = time.perf_counter()
                link.write(packet)
                link.flush()
                reply = link.read(1)
                if reply == bytes([0xEE]):
                    print("\nFPGA reported a packet timeout (0xEE).", file=sys.stderr)
                    return 1
                if len(reply) == 1:
                    reply += link.read(REPLY_BYTES - 1)
                if len(reply) != REPLY_BYTES:
                    print(f"\nTimed out: received {len(reply)} of {REPLY_BYTES} reply bytes.", file=sys.stderr)
                    return 1
                elapsed = max(time.perf_counter() - began - link_seconds, 1e-9)
                status = reply[0]
                found_nonce = int.from_bytes(reply[1:5], "big")
                if status == 1:
                    hashed = found_nonce - nonce + 1
                    done_hashes += hashed
                    fpga_seconds += elapsed
                    print(f"\nFOUND nonce=0x{found_nonce:08x}")
                    print(f"SHA256d digest={reply[5:].hex()}")
                    print(f"Hashes: {done_hashes:,} in {fpga_seconds:.2f} s")
                    return 0
                if status != 0:
                    print(f"\nInvalid status 0x{status:02x}", file=sys.stderr)
                    return 1
                done_hashes += last - nonce + 1
                fpga_seconds += elapsed
                rate = done_hashes / fpga_seconds
                print(f"\r{bar(done_hashes / total)} {100 * done_hashes / total:5.1f}%  "
                      f"{format_rate(rate)}  {done_hashes:,}/{total:,} nonces  {fpga_seconds:.1f} s",
                      end="", flush=True)
                nonce = last + 1
    except serial.SerialException as exc:
        print(f"\nSerial error: {exc}", file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        print("\nStopped by user.")
        return 130

    print(f"\nNo target match in range. Average rate: {format_rate(done_hashes / fpga_seconds)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
