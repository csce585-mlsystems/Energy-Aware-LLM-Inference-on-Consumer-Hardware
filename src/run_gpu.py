"""Run llama.cpp inference on GPU with telemetry logging."""
from __future__ import annotations

import argparse
from pathlib import Path

from telemetry import TelemetryLogger
from workload import configure_prompts, run_prompts


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--model",
        type=Path,
        required=True,
        help="Path to the GGUF model file to load",
    )
    parser.add_argument(
        "--llama-binary",
        type=Path,
        default=Path("..") / "llama.cpp" / "build" / "bin" / "llama-cli.exe",
        help="Path to the llama.cpp CLI binary compiled with CUDA",
    )
    parser.add_argument(
        "--prompt-source",
        choices=["manual", "auto"],
        default="manual",
        help="Load prompts from a manual JSON file or auto-generate them",
    )
    parser.add_argument(
        "--prompt-file",
        type=Path,
        default=Path("data/prompts/manual_prompts.json"),
        help="JSON file containing prompts when using --prompt-source=manual",
    )
    parser.add_argument(
        "--prompt-config",
        type=Path,
        default=Path("config/prompt_config.json"),
        help="Configuration file for automatic prompt generation",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=4,
        help="Batch size for llama.cpp inference",
    )
    parser.add_argument(
        "--n-predict",
        type=int,
        default=256,
        help="Number of tokens to generate per prompt",
    )
    parser.add_argument(
        "--temperature",
        type=float,
        default=0.2,
        help="Sampling temperature",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Skip llama.cpp execution and only exercise telemetry logging",
    )
    parser.add_argument(
        "--gpu-layers",
        type=int,
        default=35,
        help="Number of layers to offload to the GPU (passed to llama.cpp)",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    prompts = configure_prompts(args.prompt_source, args.prompt_file, args.prompt_config)
    logger = TelemetryLogger()

    extra_args = ["--gpu-layers", str(args.gpu_layers)]

    run_prompts(
        prompts=prompts,
        llama_binary=args.llama_binary,
        model_path=args.model,
        backend="gpu",
        logger=logger,
        batch_size=args.batch_size,
        n_predict=args.n_predict,
        temperature=args.temperature,
        dry_run=args.dry_run,
        extra_args=extra_args,
    )


if __name__ == "__main__":
    main()
