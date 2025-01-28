import functions_framework
import random
from flask import jsonify
from policyengine import Simulation


@functions_framework.http
def main(request):
    randomNum = random.randint(1, 100)
    output = {"random": randomNum}
    return jsonify(output)