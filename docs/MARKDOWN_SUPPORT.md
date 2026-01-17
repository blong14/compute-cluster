# Markdown Live Preview Server

This document provides instructions for using `markserv` to render and serve markdown files from this directory for live preview in a browser. This is useful for verifying formatting of documentation before committing changes.

## Installation

`markserv` is a NodeJS package and can be in-stalled via `npm`.

```sh
npm install -g markserv
```

## Usage

To serve the markdown files in this `docs` directory, run the following command from the root of the repository:

```sh
markserv docs/
```

This will start a web server, typically on port 8642. You can then navigate to `http://localhost:8642` in your web browser to view the rendered markdown files. The server will live-reload when you make changes to the files.
