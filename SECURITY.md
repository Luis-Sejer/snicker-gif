# Security Policy

## Supported versions

Only the [latest release](https://github.com/Luis-Sejer/snicker-gif/releases/latest) receives security fixes.

## Reporting a vulnerability

Please report vulnerabilities privately through GitHub: go to the [Security tab](https://github.com/Luis-Sejer/snicker-gif/security) and choose **Report a vulnerability**. Don’t open a public issue.

You can expect an acknowledgement within a few days and a fix or a plan as soon as the issue is understood.

## What Snicker does with your data

- Search terms are sent to [KLIPY](https://klipy.com) to find GIFs. Nothing else leaves your Mac.
- Favorites, recents, settings and any API key you enter are stored locally in Snicker’s preferences.
- Copied GIFs are cached in `~/Library/Caches/Snicker`.

## About the built-in API key

Release builds include a KLIPY API key so Snicker works without setup. Like any key shipped inside a client app, it can be extracted by someone determined enough, so it only grants access to KLIPY’s public GIF search. Reports about extracting that key are therefore not considered vulnerabilities.
