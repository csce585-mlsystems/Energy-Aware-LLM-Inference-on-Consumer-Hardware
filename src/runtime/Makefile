.PHONY: llama telemetry-daemons

LLAMA_REPO ?= ../llama.cpp
BUILD_DIR ?= $(LLAMA_REPO)/build

llama:
cmake -S $(LLAMA_REPO) -B $(BUILD_DIR) -DLLAMA_CUBLAS=ON -DLLAMA_NATIVE=ON
cmake --build $(BUILD_DIR) --config Release

telemetry-daemons:
@echo "⚙️ Ensure Intel Power Gadget and NVIDIA drivers are installed before running telemetry."
