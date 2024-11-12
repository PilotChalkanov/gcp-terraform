import os
import socket

from flask import Flask
app = Flask(__name__)

myhost = os.uname()[1]


def get_host_info():
   try:
      hostname = socket.gethostname()
      ip_address = socket.gethostbyname(hostname)

      return hostname, ip_address
   except Exception as e:
      return f"Error: {e}", None


@app.route('/health')
def health_check():
   print("HC")
   return 'ok'

@app.route('/backend_info')
def backend_info():
   hostname, ip_address = get_host_info()
   return f"Hello from host:{hostname} and ip: {ip_address} "

if __name__ == '__main__':
   host = "0.0.0.0"
   port = 5000
   print(f"Running REST server on {host}:{port}")
   app.run(host=host, port=port, debug=True)
