#!/usr/bin/env python3
"""Bridge the VM's 127.0.0.1:<port> to the Windows host's <port>.

WHY THIS EXISTS
---------------
`flutter drive` asks adb to forward the device's Dart VM service to a host port, then
connects to that port on **its own localhost**. When the adb *server* runs on Windows
and `flutter drive` runs on this VM, the listener is created on Windows and the VM
dials a port where nothing listens:

    SocketException: Connection refused (errno = 111), address = 127.0.0.1, port = 54090

Under WSL2 this worked by accident: WSL2 shares Windows' network namespace, so
"localhost" was the same machine. The VirtualBox VM does not, which broke the capture
pipeline silently during the WSL2 -> VM migration.

Measured 2026-09-12: the VM CAN reach the Windows host directly on the host-only
network (192.168.56.1). So no reverse tunnel is required — only a local listener that
relays to the host.

Pair this with `flutter drive --host-vmservice-port=<port>`, which pins the host-side
port so it is predictable. Without pinning, adb picks a fresh random port on every
retry and no static bridge can follow it.

    python3 vmservice_bridge.py 61999 &
    flutter drive ... --host-vmservice-port=61999
"""
import socket, sys, threading

HOST_IP = "192.168.56.1"


def pump(src, dst):
    try:
        while True:
            data = src.recv(65536)
            if not data:
                break
            dst.sendall(data)
    except OSError:
        pass
    finally:
        for s in (src, dst):
            try:
                s.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass
            try:
                s.close()
            except OSError:
                pass


def serve(port, host_ip):
    listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listener.bind(("127.0.0.1", port))
    listener.listen(64)
    print(f"bridge: 127.0.0.1:{port} -> {host_ip}:{port}", flush=True)
    while True:
        client, _ = listener.accept()
        try:
            upstream = socket.create_connection((host_ip, port), timeout=10)
        except OSError as e:
            print(f"bridge: upstream {host_ip}:{port} refused ({e})", flush=True)
            client.close()
            continue
        threading.Thread(target=pump, args=(client, upstream), daemon=True).start()
        threading.Thread(target=pump, args=(upstream, client), daemon=True).start()


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 61999
    host_ip = sys.argv[2] if len(sys.argv) > 2 else HOST_IP
    serve(port, host_ip)
