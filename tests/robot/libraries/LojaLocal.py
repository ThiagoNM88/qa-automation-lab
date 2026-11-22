"""Servidor descartável para testar pagamentos simulados sem contas ou dados reais."""
from pathlib import Path
from queue import Queue, Empty
import shutil
import subprocess
from threading import Thread
from robot.api.deco import keyword, library


@library(scope="SUITE", auto_keywords=False)
class LojaLocal:
    def __init__(self):
        self.process = None

    @keyword("Iniciar loja local")
    def iniciar(self):
        node = shutil.which("node")
        if not node:
            raise RuntimeError("Node.js não encontrado no PATH.")
        root = Path(__file__).resolve().parents[3]
        self.process = subprocess.Popen(
            [node, str(root / "scripts" / "robot-local-target.mjs")],
            cwd=root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, encoding="utf-8",
        )
        output = Queue()
        Thread(target=lambda: output.put(self.process.stdout.readline()), daemon=True).start()
        try:
            url = output.get(timeout=20).strip()
            if not url.startswith("http://127.0.0.1:"):
                raise RuntimeError(f"Não foi possível iniciar a loja local: {url}")
            return url
        except (Empty, RuntimeError):
            self.encerrar()
            raise RuntimeError("Loja local não ficou pronta em 20 segundos. Verifique o Node.js.") from None

    @keyword("Encerrar loja local")
    def encerrar(self):
        if self.process is not None:
            if self.process.poll() is None:
                self.process.terminate()
                try:
                    self.process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    self.process.kill()
                    self.process.wait(timeout=5)
            self.process.stdout.close()
            self.process = None
