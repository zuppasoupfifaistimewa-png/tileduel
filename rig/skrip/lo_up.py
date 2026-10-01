import socket, fcntl, struct
SIOCGIFFLAGS, SIOCSIFFLAGS, IFF_UP = 0x8913, 0x8914, 0x1
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
flags = struct.unpack('16sH', fcntl.ioctl(s, SIOCGIFFLAGS, struct.pack('16sH', b'lo', 0)))[1]
fcntl.ioctl(s, SIOCSIFFLAGS, struct.pack('16sH', b'lo', flags | IFF_UP))
t = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); t.bind(("127.0.0.1", 7999)); t.sendto(b"x", ("127.0.0.1", 7999)); print("LO_UP", t.recv(10))
