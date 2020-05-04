import argparse
import email.parser
import email.policy
import os
import json
from socketserver import TCPServer, ThreadingMixIn, StreamRequestHandler

import pyzor.client
import pyzor.digest


class RequestHandler(StreamRequestHandler):

    def handle(self):
        cmd = self.rfile.readline().decode()[:-1]
        if cmd == "CHECK":
            self.handle_check()
        else:
            self.write_json({"error": "unknown command"})

    def handle_check(self):
        parser = email.parser.BytesParser(policy=email.policy.SMTP)
        msg = parser.parse(self.rfile)

        digest = pyzor.digest.DataDigester(msg).value
        # whitelist 'default' digest (all messages with empty/short bodies)
        if digest != 'da39a3ee5e6b4b0d3255bfef95601890afd80709':
            check = pyzor.client.Client().check(digest)

        self.write_json({k: v for k, v in check.items()})

    def write_json(self, d):
        j = json.dumps(d) + "\n"
        self.wfile.write(j.encode())


class Server(ThreadingMixIn, TCPServer):
    pass


def main():
    argp = argparse.ArgumentParser(description="Expose pyzor on a socket")
    argp.add_argument("addr", help="address to listen on")
    argp.add_argument("port", help="port to listen on")
    args = argp.parse_args()

    addr = (args.addr, int(args.port))

    srv = Server(addr, RequestHandler)
    try:
        srv.serve_forever()
    finally:
        srv.server_close()


if __name__ == "__main__":
    main()
