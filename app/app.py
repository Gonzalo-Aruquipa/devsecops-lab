from flask import Flask, request
import sqlite3

app = Flask(__name__)

@app.route("/buscar")
def buscar():
    termino = request.args.get("q", "")
    conexion = sqlite3.connect("database.db")
    # CORRECCIÓN SAST: Consulta parametrizada
    consulta = "SELECT * FROM productos WHERE nombre = ?"
    resultado = conexion.execute(consulta, (termino,))
    return str(resultado.fetchall())

@app.route("/evaluar")
def evaluar():
    # CORRECCIÓN SAST: Desactivación de ejecución dinámica
    return "Operación no permitida por políticas de seguridad", 400

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8080)
