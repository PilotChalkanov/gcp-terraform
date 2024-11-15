import os

import requests
from requests import request

from flask import Flask
app = Flask(__name__)

myhost = os.uname()[1]

host = 'http://10.0.2.10:5000'
# host = 'http://127.0.0.1:5001'
lb_endpoint = host + '/' + 'backend_info'


@app.route('/health')
def health_check():
   print("HC")
   return 'ok'

@app.route('/hello')
def backend_info():
   resp = requests.get(lb_endpoint)
   print(resp.text)
   return resp.text

if __name__ == '__main__':
   host = "0.0.0.0"
   port = 5000
   print(f"Running REST server on {host}:{port}")
   app.run(host=host, port=port, debug=True)
