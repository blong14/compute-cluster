.PHONY: install venv check-venv

# Default target
all: install

# Check if running in a virtual environment
check-venv:
	@if [ -z "$$VIRTUAL_ENV" ]; then \
		echo "Error: Not running in a virtual environment!"; \
		echo "Please activate a virtual environment first."; \
		exit 1; \
	fi

# Install dependencies with pip
install: check-venv
	@echo "Installing dependencies from pyproject.toml..."
	python -m pip install --upgrade pip
	python -m pip install --upgrade setuptools wheel
	python -m pip install --progress-bar on --require-hashes --use-pep517 -e .

# Create a virtual environment
venv:
	@echo "Creating virtual environment..."
	python -m venv venv
	@echo "Virtual environment created. Activate it with:"
	@echo "  source venv/bin/activate"
