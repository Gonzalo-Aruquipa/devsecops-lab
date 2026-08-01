from flask import Flask, request
import sqlite3

app = Flask(__name__)

# FALLA 1: Credencial o Token Hardcodeado (Secret Scanning)
API_KEY = "AKIAZ3XK7QW2MNPLRTYV"

@app.route("/buscar")
def buscar():
    termino = request.args.get("q", "")
    conexion = sqlite3.connect("database.db")
    # FALLA 2: Inyección SQL por concatenación de strings (SAST)
    consulta = "SELECT * FROM productos WHERE nombre = '" + termino + "'"
    resultado = conexion.execute(consulta)
    return str(resultado.fetchall())

@app.route("/evaluar")
def evaluar():
    expresion = request.args.get("expr", "1+1")
    # FALLA 3: Uso inseguro de eval() sobre entrada de usuario (SAST)
    return str(eval(expresion))

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
