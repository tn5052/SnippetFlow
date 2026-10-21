# Security Policy

## Supported versions

Security fixes are applied to the latest release and the `main` branch. Older
builds are not supported.

## Reporting a vulnerability

Do not open a public issue for a security problem. Use GitHub's private
vulnerability reporting:

<https://github.com/tn5052/SnippetFlow/security/advisories/new>

Please include:

- The affected version or commit.
- The macOS version and hardware architecture.
- Steps to reproduce the issue.
- The potential impact.
- Any suggested mitigation or fix.

You will receive an acknowledgement as soon as possible. This is a volunteer
project, so response times are best effort. Please allow time for a fix before
disclosing the issue publicly.

## Scope

Areas of particular interest include:

- Unintended capture of screen content or clipboard data.
- Permission handling and bypasses.
- Unsafe handling of imported images or file paths.
- Build, signing, or release integrity.

SnippetFlow does not run a network service and does not collect telemetry.

## Safe harbor

Good-faith security research is welcome. Do not access, modify, or disclose data
that does not belong to you, and do not disrupt other users while testing.
