
all: install

.PHONY: install 
install: pyproject.toml
	@echo "Installing dependencies from pyproject.toml..."
	python -m pip install --upgrade setuptools wheel
	python -m pip install --progress-bar on --use-pep517 -e .

