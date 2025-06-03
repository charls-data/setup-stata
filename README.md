# setup-stata

[![Local Test](https://github.com/charls-data/setup-stata/actions/workflows/local-test.yml/badge.svg)](https://github.com/charls-data/setup-stata/actions/workflows/local-test.yml)
[![Marketplace Test](https://github.com/charls-data/setup-stata/actions/workflows/marketplace-test.yml/badge.svg)](https://github.com/charls-data/setup-stata/actions/workflows/marketplace-test.yml)

A GitHub Action for automatically installing and configuring Stata in GitHub Actions workflows, supporting both Windows and Linux platforms.

## Features

- Automated installation of Stata on GitHub Actions runners
- Support for both Windows and Linux platforms
- Configurable Stata version and edition (MP or SE)
- Automatic license configuration
- Functional testing to ensure proper installation
- Exposes the Stata executable path via environment variable

## Usage

Add the following step to your GitHub Actions workflow:

```yaml
- name: Setup Stata
  uses: charls-data/setup-stata@v1
  with:
    stata-url-windows: ${{ secrets.STATA_URL_WINDOWS }}  # Required when running on Windows
    stata-url-linux: ${{ secrets.STATA_URL_LINUX }}      # Required when running on Linux
    stata-license: ${{ secrets.STATA_LICENSE }}          # Required
    stata-version: '18'                                  # Optional, defaults to '18'
    stata-edition: 'mp'                                  # Optional, defaults to 'mp'
```

After this step completes, Stata will be installed and the executable path will be available in the `STATA_EXE` environment variable.

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `stata-url-windows` | URL to download the Stata installer for Windows (exe file provided by StataCorp) | Required when running on Windows | - |
| `stata-url-linux` | URL to download the Stata installer for Linux (tar.gz file provided by StataCorp) | Required when running on Linux | - |
| `stata-license` | Stata license content (content of `stata.lic`) | Yes | - |
| `stata-version` | Stata version | No | '18' |
| `stata-edition` | Stata edition (only 'mp' or 'se' are allowed) | No | 'mp' |

## Using Stata in subsequent steps

After Stata is installed, you can use it in subsequent steps by referencing the `STATA_EXE` environment variable:

### Windows Example

```yaml
- name: Run Stata analysis
  shell: pwsh
  run: |
    # note this is asychronous execution
    & $env:STATA_EXE "/e" "do" "analysis.do"
```

### Linux Example

```yaml
- name: Run Stata analysis
  shell: bash
  run: |
    "$STATA_EXE" -b "do analysis.do"
```

## Recommended Security Practices

For security reasons, we strongly recommend using GitHub secrets to pass sensitive information to this action:

1. `STATA_URL_WINDOWS`: URL to the Windows Stata installer
2. `STATA_URL_LINUX`: URL to the Linux Stata installer
3. `STATA_LICENSE`: Contents of your Stata license file

Using secrets helps prevent accidental exposure of sensitive information such as download URLs and license details in your workflow files or logs.

To add these secrets to your repository:

1. Navigate to your repository on GitHub
2. Click on "Settings" > "Secrets and variables" > "Actions"
3. Click "New repository secret" and add each secret with its corresponding value

## Requirements

- Windows or Linux GitHub Actions runner
- Access to Stata installation files (via URL)
- Valid Stata license

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Developed by CHARLS Research Team
- Created to facilitate automated statistical analysis using Stata in CI/CD pipelines
