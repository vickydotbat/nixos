import importlib.machinery
import importlib.util
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WATCHDOG = ROOT / "scripts" / "opencode-watchdog"


def load_watchdog():
    loader = importlib.machinery.SourceFileLoader("opencode_watchdog", str(WATCHDOG))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    sys.modules[loader.name] = module
    loader.exec_module(module)
    return module


watchdog = load_watchdog()


class CorruptionDetectorTests(unittest.TestCase):
    def assert_corrupted(self, text):
        verdict = watchdog.detect_corruption(text)
        self.assertTrue(verdict.corrupted, verdict)

    def assert_clean(self, text):
        verdict = watchdog.detect_corruption(text)
        self.assertFalse(verdict.corrupted, verdict)

    def test_detects_symbol_heavy_token_soup(self):
        soup = (" @@##::// 991177 %%{{}} <<>> " * 80) + ("zxqv " * 20)
        self.assert_corrupted(soup)

    def test_detects_repeated_raw_tool_markup(self):
        leaked = (
            "normal preface\n"
            + "<tool_call>{\"name\":\"bash\",\"arguments\":\"git status\"}</tool_call>\n" * 6
            + "normal suffix\n"
        )
        self.assert_corrupted(leaked)

    def test_detects_malformed_tool_retry_loop(self):
        retries = (
            "The request failed.\n"
            + "invalid tool call: failed to parse json; retrying tool call\n" * 4
        )
        self.assert_corrupted(retries)

    def test_allows_compiler_and_stack_trace_output(self):
        normal = """
        error[E0308]: mismatched types
          --> src/main.rs:42:18
           |
        42 |     let value: usize = "nope";
           |                -----   ^^^^^^ expected `usize`, found `&str`
           |
        stack backtrace:
           0: anyhow::error::<impl core::convert::From<E> for anyhow::Error>::from
           1: crate::runner::execute
           2: std::sys::backtrace::__rust_begin_short_backtrace
        """ * 12
        self.assert_clean(normal)

    def test_allows_json_and_nix_output(self):
        normal = """
        {
          "provider": {
            "ollama-cloud": {
              "models": {
                "qwen3-coder:480b-cloud": {
                  "limit": { "context": 131072, "input": 98304, "output": 16384 }
                }
              }
            }
          }
        }
        """ * 16
        self.assert_clean(normal)


if __name__ == "__main__":
    unittest.main()
