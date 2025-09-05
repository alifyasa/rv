"""Configuration constants and templates for rv."""

CONFIG_DIR: str = ".rv"

CONFIG_TEMPLATE: str = (
    """
# yaml-language-server: $schema=https://creativeprojects.github.io/resticprofile/jsonschema/config.json

version: "1"

default:
  repository: "{repository}"

  backup:
    verbose: 1
    skip-if-unchanged: true
    exclude-file:            # Relative to config.yaml
     - ".rvignore"
     - "../.rvignore"
    source:
      - "."                  # Relative to CWD

  find:
    human-readable: true

  init:
    password-command: |-
      rv get-pass --confirm

  restore:
    target: .                # Relative to CWD
""".strip()
    + "\n"
)
