import base64
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from scripts.gerar_evidencias import build_report


class EvidenciasTest(unittest.TestCase):
    def test_preserves_failure_and_embeds_its_screenshot(self):
        with TemporaryDirectory() as folder:
            root = Path(folder)
            image = root / "browser/screenshot/failure.png"
            image.parent.mkdir(parents=True)
            image.write_bytes(base64.b64decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jC1sAAAAASUVORK5CYII="))
            source = root / "output.xml"
            source.write_text('<robot><suite><test name="Falha de valor"><kw name="Verificar"><status status="FAIL"/></kw><msg html="true">&lt;img src="browser/screenshot/failure.png"&gt;</msg><status status="FAIL">R$0,00 != R$10,00</status></test></suite></robot>', encoding="utf-8")
            destination = root / "visual.html"
            result = build_report(source, destination)
            self.assertEqual((result["total"], result["counts"]["FAIL"], result["screenshots"]), (1, 1, 1))
            content = destination.read_text(encoding="utf-8")
            self.assertIn('src="data:image/png;base64,', content)
            self.assertIn('R$0,00 != R$10,00', content)
            self.assertNotIn('src="browser/', content)

    def test_does_not_embed_files_outside_screenshot_directory_or_execute_html(self):
        with TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "private.png").write_bytes(b"DO_NOT_PUBLISH_THIS")
            source = root / "output.xml"
            source.write_text('<robot><suite><test name="&lt;script&gt;alert(1)&lt;/script&gt;"><msg html="true">&lt;img src="browser/screenshot/../../private.png"&gt;</msg><status status="FAIL">&lt;script&gt;alert(2)&lt;/script&gt;</status></test></suite></robot>', encoding="utf-8")
            destination = root / "visual.html"
            result = build_report(source, destination)
            content = destination.read_text(encoding="utf-8")
            self.assertEqual(result["screenshots"], 0)
            self.assertNotIn("DO_NOT_PUBLISH_THIS", content)
            self.assertNotIn("<script>", content)
            self.assertIn("&lt;script&gt;", content)

    def test_missing_output_is_explained_instead_of_claiming_success(self):
        with TemporaryDirectory() as folder:
            root = Path(folder)
            result = build_report(root / "missing.xml", root / "visual.html")
            self.assertEqual(result["total"], 0)
            self.assertIn("indisponível", result["summary"])


if __name__ == "__main__":
    unittest.main()
