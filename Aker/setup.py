"""Minimal setup.py for `pip install -e .`.

Registers the `aker` console script so the CLI can be invoked
directly (instead of `python -m aker`). PyTorch, codex CLI, and a
CUDA toolchain are runtime prerequisites but are NOT pinned here —
they live outside this package.
"""

from setuptools import find_packages, setup

setup(
    name="aker",
    version="0.1.0",
    description="LLM-driven CUDA kernel graph exploration.",
    packages=find_packages(exclude=("tests", "tests.*", "dev", "dev.*")),
    include_package_data=True,
    package_data={"aker": ["prompts/*.md"]},
    python_requires=">=3.9",
    install_requires=[
        "tqdm>=4.0",
    ],
    entry_points={
        "console_scripts": [
            "aker=aker.cli:main",
            "akerjob=aker.gpu.worker_cli:main",
        ],
    },
)
